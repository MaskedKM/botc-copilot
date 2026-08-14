import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/data/poison_repository.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int gameId;
  late List<Player> players;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    gameId = await db.gamesDao.insertGame(
      GamesCompanion(
        script: const Value(Script.troubleBrewing),
        playerCount: const Value(7),
        status: const Value(GameStatus.ongoing),
        createdAt: Value(DateTime(2026, 8, 12)),
        myRole: const Value(Character.empath),
      ),
    );
    await db.playersDao.insertAll([
      for (var i = 1; i <= 7; i++)
        PlayersCompanion(
          gameId: Value(gameId),
          name: Value('玩家$i'),
          seatNumber: Value(i),
        ),
    ]);
    players = await db.playersDao.watchByGame(gameId).first;
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  GameBoardNotifier notifier() =>
      container.read(gameBoardProvider(gameId).notifier);
  GameBoardState state() => container.read(gameBoardProvider(gameId));

  test('setNightDeaths：标记玩家死亡 + 写入当日记录', () async {
    await notifier().setNightDeaths([players[2].id]);

    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].isAlive, isFalse);
    expect(updated[2].deathCause, DeathCause.nightKill);
    expect(updated[2].deathDay, 1);

    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(nightDeathIdsOf(day), [players[2].id]);
    expect(day!.nightConfirmed, isTrue); // 确认夜晚（#77）
  });

  test('setNightDeaths(const [])：无人死亡确认夜晚，只更新记录不标记', () async {
    await notifier().setNightDeaths(const []);
    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(nightDeathIdsOf(day), isEmpty);
    expect(day!.nightConfirmed, isTrue); // 「无人死亡」也确认（#77）
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated.every((p) => p.isAlive), isTrue);
  });

  test('setNightDeaths：撤销（改选无人死亡）复活已标死的玩家', () async {
    await notifier().setNightDeaths([players[2].id]);
    await notifier().setNightDeaths(const []);

    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(nightDeathIdsOf(day), isEmpty);
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].isAlive, isTrue);
    expect(updated[2].deathDay, isNull);
    expect(updated[2].deathCause, isNull);
  });

  test('setNightDeaths：改选他人时复活上一个夜晚死亡者', () async {
    await notifier().setNightDeaths([players[1].id]);
    await notifier().setNightDeaths([players[3].id]);

    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[1].isAlive, isTrue);
    expect(updated[3].isAlive, isFalse);
    expect(updated[3].deathCause, DeathCause.nightKill);
    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(nightDeathIdsOf(day), [players[3].id]);
  });

  test('recordExecution：撤销（置 null）复活被处决者', () async {
    await notifier().recordExecution(players[4].id);
    await notifier().recordExecution(null);

    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.dayExecutionPlayerId, isNull);
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[4].isAlive, isTrue);
  });

  test('recordExecution：确认白天结果 dayConfirmed（#156 S2）', () async {
    await notifier().recordExecution(null); // 无处决
    var day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.dayExecutionPlayerId, isNull);
    expect(day.dayConfirmed, isTrue); // 显式确认「无处决」（非预选中）

    await notifier().recordExecution(players[4].id); // 处决
    day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.dayConfirmed, isTrue);

    await notifier().revivePlayer(players[4].id); // 撤销处决
    day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.dayConfirmed, isFalse); // 撤销 → 不再视为已确认
  });

  test('revivePlayer：复活误标死亡的玩家', () async {
    await notifier().quickToggleDead(players[1]);
    await notifier().revivePlayer(players[1].id);

    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[1].isAlive, isTrue);
    expect(updated[1].deathDay, isNull);
    expect(updated[1].deathCause, isNull);
  });

  // #149 BUG-1：恶魔死亡应先传承（DemonSuccessionCandidate），不得被
  // _evilWinCheck 短路成 EvilWinCandidate（Imp 自杀无爪牙时应善良胜，非邪恶胜）。
  test('setNightDeaths：恶魔死先传承，不短路邪恶胜（#149 BUG-1）', () async {
    // 我是 Imp（座位1），杀到剩 3 存活（我 + 2 好人，无爪牙）
    await db.gamesDao.updateMyRole(gameId, Character.imp);
    await db.gamesDao.updateMyPlayerId(gameId, players[0].id);
    for (final i in [2, 3, 4, 5]) {
      await db.playersDao.markDead(players[i].id, 1, DeathCause.nightKill);
    }
    // Imp 夜死 → 返回传承候选（先传承/善良胜），非 EvilWinCandidate
    final suggestion = await notifier().setNightDeaths([players[0].id]);
    expect(suggestion, isA<DemonSuccessionCandidate>());
  });

  test('setNightDeaths：非恶魔死 + 存活 ≤2 → 邪恶胜候选（#149）', () async {
    // 杀到 3 存活（均好人：myPlayerId 未设）
    for (final i in [2, 3, 4, 5]) {
      await db.playersDao.markDead(players[i].id, 1, DeathCause.nightKill);
    }
    // players[1]（好人）夜死 → 非恶魔 → 人头邪恶胜
    final suggestion = await notifier().setNightDeaths([players[1].id]);
    expect(suggestion, isA<EvilWinCandidate>());
  });

  test('quickToggleDead：恶魔长按标死先传承（#149 BUG-1）', () async {
    await db.gamesDao.updateMyRole(gameId, Character.imp);
    await db.gamesDao.updateMyPlayerId(gameId, players[0].id);
    for (final i in [2, 3, 4, 5]) {
      await db.playersDao.markDead(players[i].id, 1, DeathCause.nightKill);
    }
    final suggestion = await notifier().quickToggleDead(players[0]);
    expect(suggestion, isA<DemonSuccessionCandidate>());
  });

  test('recordExecution：处决标记死亡', () async {
    await notifier().recordExecution(players[4].id);
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[4].isAlive, isFalse);
    expect(updated[4].deathCause, DeathCause.execution);
  });

  // issue #80：处决死人消耗处决额度但不覆盖原死亡信息；撤销不复活死者。
  test('处决已死玩家：消耗处决额度，原死亡信息不变', () async {
    // 先夜晚杀死 players[2]
    await notifier().setNightDeaths([players[2].id]);
    var updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].deathCause, DeathCause.nightKill);

    // 处决已死的 players[2]
    await notifier().recordExecution(players[2].id);
    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.dayExecutionPlayerId, players[2].id); // 消耗处决额度

    updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].deathCause, DeathCause.nightKill); // 未被覆盖
    expect(updated[2].deathDay, 1);
  });

  test('撤销对死人的处决：不复活早就死了的人', () async {
    await notifier().setNightDeaths([players[2].id]); // players[2] 夜死
    await notifier().recordExecution(players[2].id); // 处决死人
    // 改处决为 players[3] → 撤销对死人的处决
    await notifier().recordExecution(players[3].id);

    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].isAlive, isFalse); // 仍死，未被复活
    expect(updated[3].isAlive, isFalse); // 新处决者死
  });

  // #154 BUG-1：夜杀+处决同一人后依次清空两字段，玩家不得孤立致死。
  test('夜杀+处决同一人后清空两者：玩家正确复活（#154 BUG-1）', () async {
    await notifier().setNightDeaths([players[2].id]);
    await notifier().recordExecution(players[2].id); // markDead no-op，cause 仍 nightKill
    await notifier().setNightDeaths(const []);
    await notifier().recordExecution(null);

    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].isAlive, isTrue); // 不再孤立致死
    expect(updated[2].deathDay, isNull);
    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(nightDeathIdsOf(day), isEmpty);
    expect(day!.dayExecutionPlayerId, isNull);
  });

  // #154 review Finding 1：长按致死（无 day-record 字段）+ 处决同一人后清处决，
  // 玩家应仍死（长按致死是真实死亡，非处决）。删 deathCause 守卫会误复活；
  // 根治（跨字段重对齐 cause + 保留守卫）正确不复活。
  test('长按致死+处决同一人后清处决：玩家不复活（#154 review）', () async {
    // 长按标死（夜阶段 → nightKill，无 day-record 字段）
    await notifier().quickToggleDead(players[2]);
    await notifier().recordExecution(players[2].id); // 处决已死者，markDead no-op
    await notifier().recordExecution(null); // 清处决
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].isAlive, isFalse); // 长按致死为真，不复活
  });

  // #154 BUG-2：复活须同步清 day-record 死亡字段，否则投票面板锁死 / timeline 残留。
  test('revivePlayer：同步清当天 day-record 死亡字段（#154 BUG-2）', () async {
    await notifier().recordExecution(players[2].id);
    var day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.dayExecutionPlayerId, players[2].id);

    await notifier().revivePlayer(players[2].id);
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].isAlive, isTrue);
    day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.dayExecutionPlayerId, isNull); // 不再锁死投票面板
  });

  test('长按复活已处决者：清 day-record（#154 BUG-2）', () async {
    await notifier().recordExecution(players[3].id);
    final dead = (await db.playersDao.watchByGame(gameId).first)
        .where((p) => p.id == players[3].id)
        .first;
    // players[3] 已死 → quickToggleDead 走复活分支
    await notifier().quickToggleDead(dead);
    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.dayExecutionPlayerId, isNull);
  });

  // review M1：夜杀 A + 处决 A + 改夜杀目标 → A 不应被复活（处决仍生效）
  test('夜杀+处决同一人后改夜杀目标：不复活（跨字段守卫）', () async {
    await notifier().setNightDeaths([players[2].id]); // 夜杀 players[2]
    await notifier().recordExecution(players[2].id); // 处决同一人（死人）
    await notifier().setNightDeaths([players[3].id]); // 改夜杀目标

    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].isAlive, isFalse); // 仍死（处决仍指向他）
    expect(updated[3].isAlive, isFalse); // 新夜杀目标死
    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(nightDeathIdsOf(day), [players[3].id]);
    expect(day!.dayExecutionPlayerId, players[2].id);
  });

  test('advanceDay：推进天数 + 预建次日记录 + 清空选中', () async {
    notifier().selectPlayer(players[0].id);
    await notifier().advanceDay();

    expect(state().currentDay, 2);
    expect(state().selectedPlayerId, isNull);
    final day2 = await db.dayRecordsDao.getByGameAndDay(gameId, 2);
    expect(day2, isNotNull);
  });

  test('revertAdvanceDay：空记录的预建天可回退（#87）', () async {
    await notifier().advanceDay(); // → day 2（预建，空）
    expect(state().currentDay, 2);
    final ok = await notifier().revertAdvanceDay();
    expect(ok, isTrue);
    expect(state().currentDay, 1);
    final day2 = await db.dayRecordsDao.getByGameAndDay(gameId, 2);
    expect(day2, isNull); // 预建记录已删
  });

  test('revertAdvanceDay：当天有夜晚死亡不可回退（#87）', () async {
    await notifier().advanceDay(); // → day 2
    await notifier().setNightDeaths([players[1].id]); // day 2 有夜死
    final ok = await notifier().revertAdvanceDay();
    expect(ok, isFalse);
    expect(state().currentDay, 2); // 未回退
  });

  test('revertAdvanceDay：当天有角色声明不可回退（review M1 级联）', () async {
    await notifier().advanceDay(); // → day 2
    final day2 = await db.dayRecordsDao.getByGameAndDay(gameId, 2);
    await db.roleClaimsDao.insertClaim(
      RoleClaimsCompanion(
        playerId: Value(players[0].id),
        dayRecordId: Value(day2!.id),
        character: const Value(Character.empath),
        claimType: const Value(ClaimType.firstClaim),
      ),
    );
    final ok = await notifier().revertAdvanceDay();
    expect(ok, isFalse); // 有声明 → 拒绝回退（避免级联删声明）
    expect(state().currentDay, 2);
    final claims = await db.roleClaimsDao.watchByDay(day2.id).first;
    expect(claims, hasLength(1)); // 声明仍在，未被级联删除
  });

  test('advanceDay 幂等：重复推进不重复建记录', () async {
    await notifier().advanceDay();
    await notifier().advanceDay();
    final days = await db.dayRecordsDao.watchByGame(gameId).first;
    expect(days.map((d) => d.dayNumber), [2, 3]);
  });

  // issue #67 BUG-3 回归保护：advanceDay 不清除毒的 isActive——毒跨天过期
  // 由 dayNumber 过滤保证。直接清 isActive 会破坏 timeline 的历史回看
  // （过去天数会被错误地显示为「未中毒」）。
  test('advanceDay 不清除毒标记：跨天过期由 dayNumber 过滤保证', () async {
    final poisonRepo = PoisonRepository(db);
    await poisonRepo.toggleStatus(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 1,
    );

    await notifier().advanceDay(); // → 第 2 天

    // day 1 的毒记录 isActive 保持不变：timeline 历史回看仍正确
    final statuses = await db.poisonStatusesDao.watchByGame(gameId).first;
    expect(statuses.length, 1);
    expect(statuses.single.isActive, isTrue);

    // 历史 day 1 仍判为中毒
    expect(
      await poisonRepo.isTainted(
        gameId: gameId,
        playerId: players[0].id,
        dayNumber: 1,
      ),
      isTrue,
    );
    // 新 day 2 自然不中毒（无 day 2 的记录，dayNumber 过滤兜底）
    expect(
      await poisonRepo.isTainted(
        gameId: gameId,
        playerId: players[0].id,
        dayNumber: 2,
      ),
      isFalse,
    );
  });

  test('selectPlayer：再次点同一玩家取消选中', () {
    notifier().selectPlayer(players[0].id);
    expect(state().selectedPlayerId, players[0].id);
    notifier().selectPlayer(players[0].id);
    expect(state().selectedPlayerId, isNull);
  });

  test('quickToggleDead：死亡/复活切换', () async {
    await notifier().quickToggleDead(players[1]);
    var updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[1].isAlive, isFalse);

    await notifier().quickToggleDead(updated[1]);
    updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[1].isAlive, isTrue);
  });

  test('quickToggleDead：指定 deathDay 补记历史死亡（#91）', () async {
    // 推进到第 3 天
    await notifier().advanceDay();
    await notifier().advanceDay();
    expect(state().currentDay, 3);
    // 补记第 1 天的死亡——deathDay 应为指定值，而非当前天 3
    await notifier().quickToggleDead(players[1], deathDay: 1);
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[1].isAlive, isFalse);
    expect(updated[1].deathDay, 1);
  });

  test('quickToggleDead：deathDay 越界自动 clamp（防御纵深）', () async {
    await notifier().advanceDay();
    expect(state().currentDay, 2);
    // 99 远超当前天 → clamp 到 currentDay
    await notifier().quickToggleDead(players[1], deathDay: 99);
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[1].deathDay, 2);
  });

  // #151 C1 review：长按标死的 deathCause 按夜晚是否确认区分——夜阶段记
  // nightKill（Empath 读取前已死，排除邻座），白天阶段记 other（算存活邻居）。
  test('quickToggleDead：夜阶段记 nightKill / 白天阶段记 other（#151 review）',
      () async {
    // 夜晚未确认 → 长按标死 = 夜死
    await notifier().quickToggleDead(players[1]);
    var updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[1].deathCause, DeathCause.nightKill);

    // 复活后确认夜晚（nightConfirmed=true）→ 长按标死 = 白天死
    await notifier().revivePlayer(players[1].id);
    await notifier().setNightDeaths(const []);
    await notifier().quickToggleDead(players[2]);
    updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].deathCause, DeathCause.other);
  });

  test('quickToggleDead：标死声明 Imp 的玩家 → 传承候选（#136 公理5）', () async {
    final dayId = await notifier().ensureCurrentDayRecord();
    await db.roleClaimsDao.insertClaim(
      RoleClaimsCompanion(
        playerId: Value(players[1].id),
        dayRecordId: Value(dayId),
        character: const Value(Character.imp),
        claimType: const Value(ClaimType.firstClaim),
      ),
    );
    final suggestion = await notifier().quickToggleDead(players[1]);
    expect(suggestion, isA<DemonSuccessionCandidate>());
  });

  test('quickToggleDead：补记历史死亡（deathDay<currentDay）不触发传承（#136）', () async {
    final day1Id = await notifier().ensureCurrentDayRecord();
    await db.roleClaimsDao.insertClaim(
      RoleClaimsCompanion(
        playerId: Value(players[1].id),
        dayRecordId: Value(day1Id),
        character: const Value(Character.imp),
        claimType: const Value(ClaimType.firstClaim),
      ),
    );
    await notifier().advanceDay(); // currentDay → 2
    // 补记第 1 天死亡——App 无历史存活快照，不自动检测传承（避免 SW 阈值错时点）
    final suggestion = await notifier().quickToggleDead(players[1], deathDay: 1);
    expect(suggestion, isNull);
  });

  test('endGame：更新对局状态后 currentGameProvider 不再返回该局', () async {
    await notifier().endGame(goodWin: true);
    final game = await db.gamesDao.getById(gameId);
    expect(game!.status, GameStatus.goodWin);

    final current = await container.read(currentGameProvider.future);
    expect(current, isNull);
  });

  test('latestTrustLevelsProvider：取每玩家最新信任度', () async {
    await db.trustLogsDao.insertLog(
      TrustLogsCompanion(
        gameId: Value(gameId),
        playerId: Value(players[0].id),
        dayNumber: const Value(1),
        trustLevel: const Value(TrustLevel.unknown),
      ),
    );
    await db.trustLogsDao.insertLog(
      TrustLogsCompanion(
        gameId: Value(gameId),
        playerId: Value(players[0].id),
        dayNumber: const Value(2),
        trustLevel: const Value(TrustLevel.confirmedGood),
      ),
    );
    final levels =
        await container.read(latestTrustLevelsProvider(gameId).future);
    expect(levels[players[0].id], TrustLevel.confirmedGood);
  });

  // 等待构造中 fire 的 _restoreState 完成（#154 ISSUE-3）。
  Future<void> waitForRestore() async {
    for (var i = 0; i < 50 && !state().initialized; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('恢复 currentDay：从 day_records 最大 dayNumber 恢复（#154 ISSUE-3）', () async {
    // 预建 day 1-3 记录（模拟进行到第 3 天后重启）
    for (var d = 1; d <= 3; d++) {
      await db.dayRecordsDao.insertDay(
        DayRecordsCompanion(gameId: Value(gameId), dayNumber: Value(d)),
      );
    }
    notifier(); // 构造 fire _restoreState
    await waitForRestore();
    expect(state().initialized, isTrue);
    expect(state().currentDay, 3);
  });

  test('全新局恢复 currentDay=1（无 day 记录，#154 ISSUE-3）', () async {
    notifier();
    await waitForRestore();
    expect(state().initialized, isTrue);
    expect(state().currentDay, 1);
  });

  test('revertAdvanceDay：回退清理孤儿注释三表（#154 R-1）', () async {
    notifier();
    await waitForRestore();
    // 推进到第 2 天（空记录）
    await notifier().advanceDay();
    expect(state().currentDay, 2);
    // 在第 2 天设信任度、标毒、加备注（按 gameId+dayNumber 挂载，无 dayRecordId FK）
    await db.trustLogsDao.insertLog(TrustLogsCompanion(
      gameId: Value(gameId),
      playerId: Value(players[0].id),
      dayNumber: const Value(2),
      trustLevel: const Value(TrustLevel.confirmedGood),
    ));
    await db.poisonStatusesDao.insertStatus(PoisonStatusesCompanion(
      gameId: Value(gameId),
      playerId: Value(players[1].id),
      dayNumber: const Value(2),
      source: const Value(PoisonSource.poisoner),
    ));
    await db.behaviorNotesDao.insertNote(BehaviorNotesCompanion(
      gameId: Value(gameId),
      playerId: Value(players[2].id),
      dayNumber: const Value(2),
      note: const Value('可疑发言'),
      createdAt: Value(DateTime(2026, 8, 13)),
    ));
    // 回退第 2 天
    final ok = await notifier().revertAdvanceDay();
    expect(ok, isTrue);
    expect(state().currentDay, 1);
    // 三表第 2 天的记录已清空（不再成孤儿）
    expect(await db.trustLogsDao.watchByGame(gameId).first, isEmpty);
    expect(await db.poisonStatusesDao.watchByGame(gameId).first, isEmpty);
    expect(await db.behaviorNotesDao.watchByGame(gameId).first, isEmpty);
    // day 2 记录已删
    expect(await db.dayRecordsDao.getByGameAndDay(gameId, 2), isNull);
  });

  group('#208 人头终局：恶魔存活性门控（checkHeadsWin）', () {
    // 僵尸态种子：1 号被处决（可选死亡揭示=恶魔），2-4 号已死 → 存活 3 人。
    Future<void> seed({required bool withDemonReveal}) async {
      final dayId = await db.dayRecordsDao.insertDay(
        DayRecordsCompanion(gameId: Value(gameId), dayNumber: const Value(1)),
      );
      await db.playersDao.markDead(players[0].id, 1, DeathCause.execution);
      if (withDemonReveal) {
        await db.roleClaimsDao.insertClaim(
          RoleClaimsCompanion(
            playerId: Value(players[0].id),
            dayRecordId: Value(dayId),
            character: Value(Character.imp),
            claimType: const Value(ClaimType.revealedOnDeath),
          ),
        );
      }
      for (final i in [1, 2, 3]) {
        await db.playersDao.markDead(players[i].id, 1, DeathCause.nightKill);
      }
    }

    test('僵尸态：恶魔已处决无传承 → 夜死压到 2 人 → GoodWinCandidate',
        () async {
      await seed(withDemonReveal: true);
      final suggestion = await notifier().setNightDeaths([players[4].id]);
      expect(suggestion, isA<GoodWinCandidate>());
      expect((suggestion as GoodWinCandidate).aliveCount, 2);
    });

    test('无恶魔死亡记录（现状回归）→ EvilWinCandidate', () async {
      await seed(withDemonReveal: false);
      final suggestion = await notifier().setNightDeaths([players[4].id]);
      expect(suggestion, isA<EvilWinCandidate>());
    });

    test('checkHeadsWin：存活 > 2 → null', () async {
      expect(await notifier().checkHeadsWin(), isNull);
    });
  });

  group('#217 增量4：多杀夜（setNightDeaths 集合语义）', () {
    test('一晚两人（BMR 沙巴洛斯双杀）→ 都标死 + 数组保序', () async {
      final suggestion = await notifier().setNightDeaths(
        [players[2].id, players[5].id],
      );
      // 5 人存活 → 无终局建议
      expect(suggestion, isNull);
      final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
      expect(nightDeathIdsOf(day), [players[2].id, players[5].id]);
      expect(day!.nightConfirmed, isTrue);
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[2].isAlive, isFalse);
      expect(updated[5].isAlive, isFalse);
      expect(updated[2].deathCause, DeathCause.nightKill);
    });

    test('移出一人 → 该人复活，另一人保留且 nightConfirmed 不回退', () async {
      await notifier().setNightDeaths([players[2].id, players[5].id]);
      await notifier().setNightDeaths([players[5].id]);
      final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
      expect(nightDeathIdsOf(day), [players[5].id]);
      expect(day!.nightConfirmed, isTrue);
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[2].isAlive, isTrue); // 差集复活
      expect(updated[5].isAlive, isFalse);
    });

    test('移出最后一个 → 字段清空 + nightConfirmed 回退（#154 语义保持）',
        () async {
      await notifier().setNightDeaths([players[2].id]);
      await notifier().setNightDeaths(const []);
      final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
      expect(nightDeathIdsOf(day), isEmpty);
      // 显式「无人死亡」= 空数组 + confirmed（#77：null 才是未录入）
      expect(day!.nightDeathPlayerIds, '[]');
      expect(day.nightConfirmed, isTrue);
    });

    test('夜死+处决同人后移出夜死 → 不复活，cause 重对齐处决（#154 BUG-1）',
        () async {
      // 夜杀 players[2] 后又处决同一人（markDead no-op，cause 保持 nightKill）
      await notifier().setNightDeaths([players[2].id]);
      await notifier().recordExecution(players[2].id);
      // 从夜死名单移除：处决记录仍锁定 → 不复活，cause 对齐 execution
      await notifier().setNightDeaths(const []);
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[2].isAlive, isFalse);
      expect(updated[2].deathCause, DeathCause.execution);
      // 再撤销处决 → 此时无夜死记录锁定 → 复活
      await notifier().recordExecution(null);
      final revived = await db.playersDao.watchByGame(gameId).first;
      expect(revived[2].isAlive, isTrue);
    });

    test('双杀压到 2 人 → checkHeadsWin 生效（EvilWinCandidate）', () async {
      // 预置 3 人已死 → 存活 4，双杀 2 人 → 存活 2
      for (final i in [1, 3, 4]) {
        await db.playersDao.markDead(players[i].id, 1, DeathCause.nightKill);
      }
      final suggestion = await notifier().setNightDeaths(
        [players[2].id, players[5].id],
      );
      expect(suggestion, isA<EvilWinCandidate>());
    });
  });

  group('#217 增量4B：僵怖假死', () {
    setUp(() async {
      await (db.update(db.games)..where((g) => g.id.equals(gameId))).write(
        GamesCompanion(
          myRole: const Value(Character.zombuul),
          myPlayerId: Value(players[0].id),
        ),
      );
    });

    test('我=僵怖首次被处决 → 登记假死（存活 + deathDay 落库 + 无终局）',
        () async {
      final suggestion = await notifier().recordExecution(players[0].id);
      expect(suggestion, isNull); // 恶魔未死：无传承/终局提示
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[0].isAlive, isTrue); // 官方：活着但登记为死
      expect(updated[0].fakeDead, isTrue);
      expect(updated[0].deathDay, 1); // 邻座收缩按死亡重建 → 自动排除
      expect(updated[0].deathCause, DeathCause.execution);
      final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
      expect(day!.dayExecutionPlayerId, players[0].id); // 处决记录照写
    });

    test('次日再处决 → 真死（isAlive=false）+ 走恶魔处决确认流', () async {
      await notifier().recordExecution(players[0].id);
      await notifier().advanceDay(); // 僵怖第二次死亡须跨天（同日重录=重登假死）
      final suggestion = await notifier().recordExecution(players[0].id);
      expect(suggestion, isA<DemonExecutionCheck>());
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[0].isAlive, isFalse);
    });

    test('撤销处决（改选无人）→ 清除假死标记', () async {
      await notifier().recordExecution(players[0].id);
      await notifier().recordExecution(null);
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[0].isAlive, isTrue);
      expect(updated[0].fakeDead, isFalse);
      expect(updated[0].deathDay, isNull);
    });

    test('markFakeDead 守卫：已假死者与已死者 no-op', () async {
      await notifier().recordExecution(players[0].id);
      // 已假死 → no-op（不覆盖 deathDay）
      await db.playersDao.markFakeDead(players[0].id, 9, DeathCause.other);
      var updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[0].deathDay, 1);
      // 已死者 → no-op
      await db.playersDao.markDead(players[1].id, 1, DeathCause.nightKill);
      await db.playersDao.markFakeDead(players[1].id, 9, DeathCause.other);
      updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[1].fakeDead, isFalse);
    });
  });
}
