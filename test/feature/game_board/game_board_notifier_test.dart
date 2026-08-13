import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/data/poison_repository.dart';
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

  test('recordNightDeath：标记玩家死亡 + 写入当日记录', () async {
    await notifier().recordNightDeath(players[2].id);

    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].isAlive, isFalse);
    expect(updated[2].deathCause, DeathCause.nightKill);
    expect(updated[2].deathDay, 1);

    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.nightDeathPlayerId, players[2].id);
    expect(day.nightConfirmed, isTrue); // 确认夜晚（#77）
  });

  test('recordNightDeath(null)：无人死亡确认夜晚，只更新记录不标记', () async {
    await notifier().recordNightDeath(null);
    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.nightDeathPlayerId, isNull);
    expect(day.nightConfirmed, isTrue); // 「无人死亡」也确认（#77）
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated.every((p) => p.isAlive), isTrue);
  });

  test('recordNightDeath：撤销（改选无人死亡）复活已标死的玩家', () async {
    await notifier().recordNightDeath(players[2].id);
    await notifier().recordNightDeath(null);

    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.nightDeathPlayerId, isNull);
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].isAlive, isTrue);
    expect(updated[2].deathDay, isNull);
    expect(updated[2].deathCause, isNull);
  });

  test('recordNightDeath：改选他人时复活上一个夜晚死亡者', () async {
    await notifier().recordNightDeath(players[1].id);
    await notifier().recordNightDeath(players[3].id);

    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[1].isAlive, isTrue);
    expect(updated[3].isAlive, isFalse);
    expect(updated[3].deathCause, DeathCause.nightKill);
    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.nightDeathPlayerId, players[3].id);
  });

  test('recordExecution：撤销（置 null）复活被处决者', () async {
    await notifier().recordExecution(players[4].id);
    await notifier().recordExecution(null);

    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.dayExecutionPlayerId, isNull);
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[4].isAlive, isTrue);
  });

  test('revivePlayer：复活误标死亡的玩家', () async {
    await notifier().quickToggleDead(players[1]);
    await notifier().revivePlayer(players[1].id);

    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[1].isAlive, isTrue);
    expect(updated[1].deathDay, isNull);
    expect(updated[1].deathCause, isNull);
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
    await notifier().recordNightDeath(players[2].id);
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
    await notifier().recordNightDeath(players[2].id); // players[2] 夜死
    await notifier().recordExecution(players[2].id); // 处决死人
    // 改处决为 players[3] → 撤销对死人的处决
    await notifier().recordExecution(players[3].id);

    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].isAlive, isFalse); // 仍死，未被复活
    expect(updated[3].isAlive, isFalse); // 新处决者死
  });

  // review M1：夜杀 A + 处决 A + 改夜杀目标 → A 不应被复活（处决仍生效）
  test('夜杀+处决同一人后改夜杀目标：不复活（跨字段守卫）', () async {
    await notifier().recordNightDeath(players[2].id); // 夜杀 players[2]
    await notifier().recordExecution(players[2].id); // 处决同一人（死人）
    await notifier().recordNightDeath(players[3].id); // 改夜杀目标

    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[2].isAlive, isFalse); // 仍死（处决仍指向他）
    expect(updated[3].isAlive, isFalse); // 新夜杀目标死
    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.nightDeathPlayerId, players[3].id);
    expect(day.dayExecutionPlayerId, players[2].id);
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
    await notifier().recordNightDeath(players[1].id); // day 2 有夜死
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
}
