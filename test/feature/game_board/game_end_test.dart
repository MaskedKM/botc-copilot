import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:botc_copilot/feature/game_board/data/nomination_repository.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/setup/data/setup_repository.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameEndRules 纯函数', () {
    test('存活 ≤ 2 → 邪恶获胜候选', () {
      expect(GameEndRules.isEvilWinCandidate(2), isTrue);
      expect(GameEndRules.isEvilWinCandidate(1), isTrue);
      expect(GameEndRules.isEvilWinCandidate(3), isFalse);
    });

    test('被处决者是恶魔 → 善良获胜', () {
      expect(GameEndRules.isGoodWin(executedWasDemon: true), isTrue);
      expect(GameEndRules.isGoodWin(executedWasDemon: false), isFalse);
    });

    test('市长胜利候选：存活 3 + 当日无人被处决（#88）', () {
      expect(
        GameEndRules.isMayorWinCandidate(3, noExecutionToday: true),
        isTrue,
      );
      // 当日有处决 → 不触发（即便 3 人存活）
      expect(
        GameEndRules.isMayorWinCandidate(3, noExecutionToday: false),
        isFalse,
      );
      // 非 3 人 → 不触发
      expect(
        GameEndRules.isMayorWinCandidate(2, noExecutionToday: true),
        isFalse,
      );
      expect(
        GameEndRules.isMayorWinCandidate(4, noExecutionToday: true),
        isFalse,
      );
    });
  });

  group('结束检测集成', () {
    late AppDatabase db;
    late ProviderContainer container;
    late int gameId;

    GameBoardNotifier notifier() =>
        container.read(gameBoardProvider(gameId).notifier);

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      gameId = await SetupRepository(db).createGame(
        script: Script.troubleBrewing,
        names: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        myRole: Character.empath,
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('夜晚死亡后存活 > 2 → 无建议', () async {
      final suggestion = await notifier().setNightDeaths([1]);
      expect(suggestion, isNull);
    });

    test('连续死亡至存活 = 2 → EvilWinCandidate', () async {
      // 7 人局，每天夜晚死 1 个（同一天重复记录视为改选），5 天后剩 2
      for (var i = 1; i <= 4; i++) {
        await notifier().setNightDeaths([i]);
        await notifier().advanceDay();
      }
      final suggestion = await notifier().setNightDeaths([5]);
      expect(suggestion, isA<EvilWinCandidate>());
      expect((suggestion! as EvilWinCandidate).aliveCount, 2);
    });

    test('处决后返回 DemonExecutionCheck', () async {
      final suggestion = await notifier().recordExecution(3);
      expect(suggestion, isA<DemonExecutionCheck>());
      final check = suggestion! as DemonExecutionCheck;
      expect(check.executedPlayerId, 3);
      expect(check.aliveCountAfter, 6);
    });

    test('endGame 善良胜 + 死亡揭示记录', () async {
      await notifier().recordExecution(3);
      await notifier().endGame(
        goodWin: true,
        revealedPlayerId: 3,
        revealedRole: Character.imp,
      );
      final game = await db.gamesDao.getById(gameId);
      expect(game!.status, GameStatus.goodWin);

      final claims = await db.roleClaimsDao.watchByGame(gameId).first;
      expect(claims.length, 1);
      expect(claims[0].character, Character.imp);
      expect(claims[0].claimType, ClaimType.revealedOnDeath);
    });

    test('endGame 邪恶胜', () async {
      await notifier().endGame(goodWin: false);
      final game = await db.gamesDao.getById(gameId);
      expect(game!.status, GameStatus.evilWin);
    });

    test('quickToggleDead 标记死亡后存活 ≤ 2 → 建议', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      // 杀 4 个剩 3
      for (final p in players.take(4)) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      final suggestion = await notifier().quickToggleDead(players[4]);
      expect(suggestion, isA<EvilWinCandidate>());
    });

    // ---- 市长特殊胜利（issue #88）----
    /// 给某玩家插入市长声明。
    Future<void> claimMayor(int playerId, int dayRecordId) async {
      await db.roleClaimsDao.insertClaim(
        RoleClaimsCompanion(
          playerId: Value(playerId),
          dayRecordId: Value(dayRecordId),
          character: const Value(Character.mayor),
          claimType: const Value(ClaimType.firstClaim),
        ),
      );
    }

    test('advanceDay：存活 3 + 无处决 + 市长声明 → MayorVictoryCandidate', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      final day1Id = await notifier().ensureCurrentDayRecord();
      await claimMayor(players[0].id, day1Id);
      // 杀 players[1..4]（4 人），剩 players[0,5,6] 存活 == 3；市长声明者存活
      for (final p in players.skip(1).take(4)) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      final suggestion = await notifier().advanceDay();
      expect(suggestion, isA<MayorVictoryCandidate>());
      expect((suggestion! as MayorVictoryCandidate).aliveCount, 3);
    });

    test('advanceDay：市长不在场（无声明 / 非我方）→ 不提示（门控）', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      await notifier().ensureCurrentDayRecord();
      // myRole = empath（setUp），无人声明市长
      for (final p in players.skip(1).take(4)) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      final suggestion = await notifier().advanceDay();
      expect(suggestion, isNull);
    });

    test('advanceDay：存活 3 但当日有处决 → 不触发市长', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      final day1Id = await notifier().ensureCurrentDayRecord();
      await claimMayor(players[0].id, day1Id);
      for (final p in players.skip(1).take(4)) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      // 当日有处决 → dayExecutionPlayerId != null
      await db.dayRecordsDao.updateDay(
        day1Id,
        DayRecordsCompanion(dayExecutionPlayerId: Value(players[5].id)),
      );
      final suggestion = await notifier().advanceDay();
      expect(suggestion, isNull);
    });

    test('advanceDay：存活 > 3 → 不触发市长', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      final day1Id = await notifier().ensureCurrentDayRecord();
      await claimMayor(players[0].id, day1Id);
      // 只杀 3 个（剩 4）
      for (final p in players.skip(1).take(3)) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      final suggestion = await notifier().advanceDay();
      expect(suggestion, isNull);
    });

    test('advanceDay：我的角色是市长也触发门控', () async {
      final game2 = await SetupRepository(db).createGame(
        script: Script.troubleBrewing,
        names: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        myRole: Character.mayor,
      );
      final players2 = await db.playersDao.watchByGame(game2).first;
      final notifier2 = container.read(gameBoardProvider(game2).notifier);
      await notifier2.ensureCurrentDayRecord();
      for (final p in players2.skip(1).take(4)) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      final suggestion = await notifier2.advanceDay();
      expect(suggestion, isA<MayorVictoryCandidate>());
    });

    test('advanceDay：市长声明已改口 → 不提示（review R3 最新声明）', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      final day1Id = await notifier().ensureCurrentDayRecord();
      await claimMayor(players[0].id, day1Id); // 先声明市长
      // 同天改口为共情者（id 更大 = 最新声明）
      await db.roleClaimsDao.insertClaim(
        RoleClaimsCompanion(
          playerId: Value(players[0].id),
          dayRecordId: Value(day1Id),
          character: const Value(Character.empath),
          claimType: const Value(ClaimType.changed),
        ),
      );
      for (final p in players.skip(1).take(4)) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      final suggestion = await notifier().advanceDay();
      expect(suggestion, isNull); // 最新声明非市长 → 不触发
    });

    test('advanceDay：市长声明者已死 → 不提示（review R4 存活校验）', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      final day1Id = await notifier().ensureCurrentDayRecord();
      await claimMayor(players[0].id, day1Id);
      // 杀 players[0..3]（含市长声明者），剩 [4,5,6] = 3 存活
      for (final p in players.take(4)) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      final suggestion = await notifier().advanceDay();
      expect(suggestion, isNull); // 声明者已死 → 死市长无能力
    });

    test('advanceDay：3 存活但有达阈值待执行提名 → 不触发市长（#136）', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      final day1Id = await notifier().ensureCurrentDayRecord();
      await claimMayor(players[0].id, day1Id);
      // 杀 players[1..4]（4 人），剩 [0,5,6] 存活 == 3
      for (final p in players.skip(1).take(4)) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      // 录一个达阈值的提名（3 存活，阈值 ceil(3/2)=2；2 票赞成 → PendingExecution）
      // 但不标处决 → dayExecutionPlayerId 仍 null
      final alivePlayers = await db.playersDao.watchByGame(gameId).first;
      await NominationRepository(db).addNomination(
        gameId: gameId,
        dayRecordId: day1Id,
        nominatorId: players[0].id,
        nomineeId: players[5].id,
        votes: [
          VoteEntry(playerId: players[0].id, vote: Vote.forVote),
          VoteEntry(playerId: players[5].id, vote: Vote.against),
          VoteEntry(playerId: players[6].id, vote: Vote.forVote),
        ],
        players: alivePlayers,
        todayNominations: [],
        allNominations: [],
      );
      final suggestion2 = await notifier().advanceDay();
      // 待执行提名 → execution 应发生 → 市长条件「no execution occurs」不满足
      expect(suggestion2, isNull);
    });
  });
}
