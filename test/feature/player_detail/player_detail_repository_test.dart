import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/data/poison_repository.dart';
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

  group('declareInfo · Poisoner 毒目标 reliability 联动（#122）', () {
    late int poisonerId;
    late int targetId;

    setUp(() async {
      // 主 setUp 已插入 Alice(playerId)；追加 Bob 作被毒目标
      await db.playersDao.insertAll([
        PlayersCompanion(
          gameId: Value(gameId),
          name: const Value('Bob'),
          seatNumber: const Value(2),
        ),
      ]);
      final ps = await db.playersDao.watchByGame(gameId).first;
      poisonerId = playerId; // Alice 声明 Poisoner
      targetId = ps.last.id; // Bob 被毒
    });

    test('目标在 Poisoner 声明后录信息 → possiblyTainted（entry-taint）',
        () async {
      await repo.declareInfo(
        playerId: poisonerId,
        dayRecordId: dayRecordId,
        character: Character.poisoner,
        payload: {'playerId': targetId},
      );
      await repo.declareInfo(
        playerId: targetId,
        dayRecordId: dayRecordId,
        character: Character.empath,
        payload: {'value': 1},
      );
      final decls = await db.infoDeclarationsDao.watchByDay(dayRecordId).first;
      final targetDecl = decls.firstWhere((d) => d.playerId == targetId);
      expect(targetDecl.reliability, Reliability.possiblyTainted);
    });

    test('目标在 Poisoner 声明前录信息 → 回溯 possiblyTainted', () async {
      await repo.declareInfo(
        playerId: targetId,
        dayRecordId: dayRecordId,
        character: Character.empath,
        payload: {'value': 0},
      );
      // 此时未中毒
      var decls = await db.infoDeclarationsDao.watchByDay(dayRecordId).first;
      expect(
        decls.firstWhere((d) => d.playerId == targetId).reliability,
        Reliability.unverified,
      );
      // Poisoner 后录 → 回溯降级
      await repo.declareInfo(
        playerId: poisonerId,
        dayRecordId: dayRecordId,
        character: Character.poisoner,
        payload: {'playerId': targetId},
      );
      decls = await db.infoDeclarationsDao.watchByDay(dayRecordId).first;
      expect(
        decls.firstWhere((d) => d.playerId == targetId).reliability,
        Reliability.possiblyTainted,
      );
    });

    test('taint 不外溢到次日（次夜毒已解，信息不受昨夜毒影响）', () async {
      await repo.declareInfo(
        playerId: poisonerId,
        dayRecordId: dayRecordId,
        character: Character.poisoner,
        payload: {'playerId': targetId},
      );
      final day2 = await db.dayRecordsDao.insertDay(
        DayRecordsCompanion(gameId: Value(gameId), dayNumber: const Value(2)),
      );
      await repo.declareInfo(
        playerId: targetId,
        dayRecordId: day2,
        character: Character.empath,
        payload: {'value': 1},
      );
      final decls = await db.infoDeclarationsDao.watchByDay(day2).first;
      expect(decls.single.reliability, Reliability.unverified);
    });

    test('未被毒者信息 → unverified（不误降）', () async {
      await repo.declareInfo(
        playerId: poisonerId,
        dayRecordId: dayRecordId,
        character: Character.poisoner,
        payload: {'playerId': targetId},
      );
      // Poisoner 自己录 Chef 信息（未被毒）
      await repo.declareInfo(
        playerId: poisonerId,
        dayRecordId: dayRecordId,
        character: Character.chef,
        payload: {'value': 1},
      );
      final decls = await db.infoDeclarationsDao.watchByDay(dayRecordId).first;
      final chefDecl = decls.firstWhere(
        (d) => d.playerId == poisonerId && d.characterType == Character.chef,
      );
      expect(chefDecl.reliability, Reliability.unverified);
    });

    test('手动标毒 → 该玩家当夜已录信息回溯 possiblyTainted', () async {
      final poisonRepo = PoisonRepository(db);
      await repo.declareInfo(
        playerId: targetId,
        dayRecordId: dayRecordId,
        character: Character.empath,
        payload: {'value': 0},
      );
      // 手动标毒（与 Poisoner 声明来源不同，对称回溯）
      await poisonRepo.toggleStatus(
        gameId: gameId,
        playerId: targetId,
        dayNumber: 1,
      );
      final decls = await db.infoDeclarationsDao.watchByDay(dayRecordId).first;
      expect(
        decls.firstWhere((d) => d.playerId == targetId).reliability,
        Reliability.possiblyTainted,
      );
    });
  });
}
