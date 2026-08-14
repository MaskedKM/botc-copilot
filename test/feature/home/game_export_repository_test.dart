import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/home/data/game_export_repository.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late GameExportRepository repo;
  late int gameId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GameExportRepository(db);
    gameId = await db.gamesDao.insertGame(
      GamesCompanion(
        script: const Value(Script.troubleBrewing),
        playerCount: const Value(7),
        status: const Value(GameStatus.ongoing),
        createdAt: Value(DateTime(2026, 8, 14)),
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
  });

  tearDown(() async {
    await db.close();
  });

  test('导出含格式头 + 九表全量 + game 字段', () async {
    // 造跨表数据：声明 + 天记录 + 信息 + 提名 + 毒 + 备注 + 传承 + 信任。
    final players = await db.playersDao.watchByGame(gameId).first;
    await db.customStatement('INSERT INTO day_records(game_id, day_number) '
        'VALUES($gameId, 1)');
    final dayId = (await db.dayRecordsDao.watchByGame(gameId).first).first.id;
    await db.roleClaimsDao.insertClaim(
      RoleClaimsCompanion(
        playerId: Value(players[0].id),
        dayRecordId: Value(dayId),
        character: const Value(Character.chef),
        claimType: const Value(ClaimType.firstClaim),
      ),
    );
    await db.infoDeclarationsDao.insertDeclaration(
      InfoDeclarationsCompanion(
        playerId: Value(players[1].id),
        dayRecordId: Value(dayId),
        characterType: const Value(Character.empath),
        payloadJson: const Value('{"value": 1}'),
        reliability: const Value(Reliability.unverified),
        isMine: const Value(false),
      ),
    );
    await db.poisonStatusesDao.insertStatus(
      PoisonStatusesCompanion(
        gameId: Value(gameId),
        playerId: Value(players[2].id),
        dayNumber: const Value(1),
        source: const Value(PoisonSource.poisoner),
        isActive: const Value(true),
      ),
    );
    await db.behaviorNotesDao.insertNote(
      BehaviorNotesCompanion(
        gameId: Value(gameId),
        playerId: Value(players[3].id),
        dayNumber: const Value(1),
        note: const Value('首轮发言可疑'),
        createdAt: Value(DateTime(2026, 8, 14)),
      ),
    );
    await db.demonInheritancesDao.insertSuccession(
      DemonInheritancesCompanion(
        gameId: Value(gameId),
        dayNumber: const Value(2),
        fromPlayerId: Value(players[4].id),
        toPlayerId: Value(players[5].id),
        trigger: const Value(SuccessionTrigger.scarletWoman),
      ),
    );

    final json = await repo.exportGameJson(gameId);
    expect(json, isNotNull);
    final decoded = jsonDecode(json!) as Map<String, dynamic>;

    expect(decoded['format'], 'botc-copilot-game-export');
    expect(decoded['version'], 1);
    expect(decoded['exportedAt'], isNotNull);
    final game = decoded['game'] as Map<String, dynamic>;
    expect(game['playerCount'], 7);
    expect(decoded['players'], hasLength(7));
    expect(decoded['dayRecords'], hasLength(1));
    expect(decoded['roleClaims'], hasLength(1));
    expect(decoded['infoDeclarations'], hasLength(1));
    expect(decoded['poisonStatuses'], hasLength(1));
    expect(decoded['behaviorNotes'], hasLength(1));
    expect(decoded['demonInheritances'], hasLength(1));
    // 空表也输出空数组（结构稳定，便于导入侧解构）
    expect(decoded['nominations'], isEmpty);
    expect(decoded['trustLogs'], isEmpty);
    // JSON 可再解析（indent 合法）
    expect(() => JsonDecoder().convert(json), returnsNormally);
  });

  test('对局不存在 → null', () async {
    expect(await repo.exportGameJson(9999), isNull);
  });

  test('多局隔离：只含本局数据', () async {
    final otherId = await db.gamesDao.insertGame(
      GamesCompanion(
        script: const Value(Script.troubleBrewing),
        playerCount: const Value(5),
        status: const Value(GameStatus.ongoing),
        createdAt: Value(DateTime(2026, 8, 14)),
      ),
    );
    await db.playersDao.insertAll([
      for (var i = 1; i <= 5; i++)
        PlayersCompanion(
          gameId: Value(otherId),
          name: Value('他局$i'),
          seatNumber: Value(i),
        ),
    ]);

    final json = await repo.exportGameJson(gameId);
    final decoded = jsonDecode(json!) as Map<String, dynamic>;
    expect(decoded['players'], hasLength(7));
    expect(
      (decoded['players'] as List)
          .every((p) => (p as Map)['name'] != '他局1'),
      isTrue,
    );
  });
}
