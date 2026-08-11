import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  /// 快速建一局 7 人局，返回 (gameId, playerIds)。
  Future<(int, List<int>)> seedGame() async {
    final gameId = await db.gamesDao.insertGame(
      GamesCompanion(
        script: const Value(Script.troubleBrewing),
        playerCount: const Value(7),
        status: const Value(GameStatus.ongoing),
        createdAt: Value(DateTime(2026, 8, 12)),
        myRole: const Value(Character.empath),
      ),
    );
    final playerIds = <int>[];
    for (var i = 1; i <= 7; i++) {
      await db.playersDao.insertAll([
        PlayersCompanion(
          gameId: Value(gameId),
          name: Value('玩家$i'),
          seatNumber: Value(i),
        ),
      ]);
    }
    final players =
        await db.playersDao.watchByGame(gameId).first;
    playerIds.addAll(players.map((p) => p.id));
    return (gameId, playerIds);
  }

  group('GamesDao', () {
    test('CRUD + watch 按创建时间倒序', () async {
      final (gameId, _) = await seedGame();

      final game = await db.gamesDao.getById(gameId);
      expect(game!.script, Script.troubleBrewing);
      expect(game.playerCount, 7);
      expect(game.myRole, Character.empath);

      await db.gamesDao.updateStatus(gameId, GameStatus.goodWin);
      await db.gamesDao.updateMyRole(gameId, Character.mayor);
      final updated = await db.gamesDao.getById(gameId);
      expect(updated!.status, GameStatus.goodWin);
      expect(updated.myRole, Character.mayor);

      // watch 流能收到数据
      final all = await db.gamesDao.watchAll().first;
      expect(all, hasLength(1));

      await db.gamesDao.deleteGame(gameId);
      expect(await db.gamesDao.getById(gameId), isNull);
    });

    test('删除对局级联删除玩家', () async {
      final (gameId, _) = await seedGame();
      await db.gamesDao.deleteGame(gameId);
      final players = await db.playersDao.watchByGame(gameId).first;
      expect(players, isEmpty);
    });
  });

  group('PlayersDao', () {
    test('watchByGame 按座位号排序', () async {
      final (gameId, _) = await seedGame();
      final players = await db.playersDao.watchByGame(gameId).first;
      expect(players.map((p) => p.seatNumber), [1, 2, 3, 4, 5, 6, 7]);
      expect(players.every((p) => p.isAlive), isTrue);
    });

    test('markDead / revive', () async {
      final (gameId, playerIds) = await seedGame();
      await db.playersDao.markDead(playerIds[2], 1, DeathCause.nightKill);
      var players = await db.playersDao.watchByGame(gameId).first;
      expect(players[2].isAlive, isFalse);
      expect(players[2].deathDay, 1);
      expect(players[2].deathCause, DeathCause.nightKill);

      await db.playersDao.revive(playerIds[2]);
      players = await db.playersDao.watchByGame(gameId).first;
      expect(players[2].isAlive, isTrue);
      expect(players[2].deathDay, isNull);
    });
  });

  group('DayRecordsDao', () {
    test('按天 CRUD + watch', () async {
      final (gameId, playerIds) = await seedGame();
      final dayId = await db.dayRecordsDao.insertDay(
        DayRecordsCompanion(
          gameId: Value(gameId),
          dayNumber: const Value(1),
          nightDeathPlayerId: Value(playerIds[3]),
          notes: const Value('首夜死亡'),
        ),
      );

      final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
      expect(day!.nightDeathPlayerId, playerIds[3]);
      expect(day.notes, '首夜死亡');

      await db.dayRecordsDao.updateDay(
        dayId,
        DayRecordsCompanion(dayExecutionPlayerId: Value(playerIds[5])),
      );
      final updated = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
      expect(updated!.dayExecutionPlayerId, playerIds[5]);

      final days = await db.dayRecordsDao.watchByGame(gameId).first;
      expect(days, hasLength(1));
    });
  });

  group('RoleClaimsDao / InfoDeclarationsDao', () {
    test('角色声明 CRUD + 跨天 watchByGame', () async {
      final (gameId, playerIds) = await seedGame();
      final dayId = await db.dayRecordsDao.insertDay(
        DayRecordsCompanion(
          gameId: Value(gameId),
          dayNumber: const Value(1),
        ),
      );
      await db.roleClaimsDao.insertClaim(
        RoleClaimsCompanion(
          playerId: Value(playerIds[0]),
          dayRecordId: Value(dayId),
          character: const Value(Character.chef),
          claimType: const Value(ClaimType.firstClaim),
        ),
      );

      final claims = await db.roleClaimsDao.watchByGame(gameId).first;
      expect(claims, hasLength(1));
      expect(claims.single.character, Character.chef);
      expect(claims.single.claimType, ClaimType.firstClaim);
    });

    test('信息声明 + 可靠性更新', () async {
      final (gameId, playerIds) = await seedGame();
      final dayId = await db.dayRecordsDao.insertDay(
        DayRecordsCompanion(
          gameId: Value(gameId),
          dayNumber: const Value(1),
        ),
      );
      final declId = await db.infoDeclarationsDao.insertDeclaration(
        InfoDeclarationsCompanion(
          playerId: Value(playerIds[1]),
          dayRecordId: Value(dayId),
          characterType: const Value(Character.empath),
          payloadJson: const Value('{"value": 1}'),
          reliability: const Value(Reliability.unverified),
        ),
      );

      await db.infoDeclarationsDao
          .updateReliability(declId, Reliability.possiblyTainted);
      final decls =
          await db.infoDeclarationsDao.watchByGame(gameId).first;
      expect(decls.single.reliability, Reliability.possiblyTainted);
      expect(decls.single.payloadJson, '{"value": 1}');
    });
  });

  group('TrustLogsDao', () {
    test('按天记录 + 查询最新信任度', () async {
      final (gameId, playerIds) = await seedGame();

      await db.trustLogsDao.insertLog(
        TrustLogsCompanion(
          gameId: Value(gameId),
          playerId: Value(playerIds[4]),
          dayNumber: const Value(1),
          trustLevel: const Value(TrustLevel.unknown),
        ),
      );
      await db.trustLogsDao.insertLog(
        TrustLogsCompanion(
          gameId: Value(gameId),
          playerId: Value(playerIds[4]),
          dayNumber: const Value(2),
          trustLevel: const Value(TrustLevel.suspect),
        ),
      );

      final latest = await db.trustLogsDao
          .watchLatestForPlayer(gameId, playerIds[4])
          .first;
      expect(latest!.trustLevel, TrustLevel.suspect);
      expect(latest.dayNumber, 2);

      final all = await db.trustLogsDao.watchByGame(gameId).first;
      expect(all, hasLength(2));
    });
  });
}
