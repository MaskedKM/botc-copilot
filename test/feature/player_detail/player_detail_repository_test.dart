import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PlayerDetailRepository repo;
  late int gameId;
  late int playerId;
  late int dayRecordId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlayerDetailRepository(db);
    gameId = await db.gamesDao.insertGame(
      GamesCompanion(
        script: const Value(Script.troubleBrewing),
        playerCount: const Value(7),
        status: const Value(GameStatus.ongoing),
        createdAt: Value(DateTime(2026, 8, 12)),
      ),
    );
    await db.playersDao.insertAll([
      PlayersCompanion(
        gameId: Value(gameId),
        name: const Value('Alice'),
        seatNumber: const Value(1),
      ),
    ]);
    playerId = (await db.playersDao.watchByGame(gameId).first).single.id;
    dayRecordId = await db.dayRecordsDao.insertDay(
      DayRecordsCompanion(gameId: Value(gameId), dayNumber: const Value(1)),
    );
  });

  tearDown(() => db.close());

  group('claimRole', () {
    test('首次声明 = firstClaim，再次声明 = changed', () async {
      await repo.claimRole(
        playerId: playerId,
        dayRecordId: dayRecordId,
        character: Character.chef,
      );
      await repo.claimRole(
        playerId: playerId,
        dayRecordId: dayRecordId,
        character: Character.empath,
      );

      final claims = await db.roleClaimsDao.watchByPlayer(playerId).first;
      expect(claims, hasLength(2));
      expect(claims[0].claimType, ClaimType.firstClaim);
      expect(claims[0].character, Character.chef);
      expect(claims[1].claimType, ClaimType.changed);
      expect(claims[1].character, Character.empath);
    });
  });

  group('declareInfo', () {
    test('payload 正确编码为 JSON + 默认 unverified', () async {
      await repo.declareInfo(
        playerId: playerId,
        dayRecordId: dayRecordId,
        character: Character.fortuneTeller,
        payload: {'playerIds': [1, 2], 'answer': true},
      );

      final decls = await db.infoDeclarationsDao.watchByGame(gameId).first;
      expect(decls, hasLength(1));
      final payload =
          jsonDecode(decls.single.payloadJson) as Map<String, dynamic>;
      expect(payload['playerIds'], [1, 2]);
      expect(payload['answer'], isTrue);
      expect(decls.single.reliability, Reliability.unverified);
      expect(decls.single.characterType, Character.fortuneTeller);
    });
  });

  group('setTrustLevel', () {
    test('追加 trust log 并按天记录', () async {
      await repo.setTrustLevel(
        gameId: gameId,
        playerId: playerId,
        day: 1,
        level: TrustLevel.unknown,
      );
      await repo.setTrustLevel(
        gameId: gameId,
        playerId: playerId,
        day: 2,
        level: TrustLevel.demonCandidate,
      );

      final latest =
          await db.trustLogsDao.watchLatestForPlayer(gameId, playerId).first;
      expect(latest!.trustLevel, TrustLevel.demonCandidate);
      expect(latest.dayNumber, 2);
    });
  });
}
