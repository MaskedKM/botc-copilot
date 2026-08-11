import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/setup/data/setup_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SetupRepository setupRepo;
  late PlayerDetailRepository detailRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    setupRepo = SetupRepository(db);
    detailRepo = PlayerDetailRepository(db);
  });

  tearDown(() => db.close());

  test('恶魔 Bluff 持久化（仅恶魔角色录入）', () async {
    final gameId = await setupRepo.createGame(
      script: Script.troubleBrewing,
      names: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      myRole: Character.imp,
      demonBluffs: [Character.chef, Character.monk, Character.virgin],
    );

    final game = await db.gamesDao.getById(gameId);
    final bluffs =
        (jsonDecode(game!.demonBluffsJson!) as List).cast<String>();
    expect(bluffs, ['chef', 'monk', 'virgin']);
  });

  test('非恶魔不存 Bluff', () async {
    final gameId = await setupRepo.createGame(
      script: Script.troubleBrewing,
      names: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      myRole: Character.empath,
    );
    final game = await db.gamesDao.getById(gameId);
    expect(game!.demonBluffsJson, isNull);
  });

  test('myPlayerId 可写入和读取', () async {
    final gameId = await setupRepo.createGame(
      script: Script.troubleBrewing,
      names: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      myRole: Character.empath,
    );
    final players = await db.playersDao.watchByGame(gameId).first;
    await db.gamesDao.updateMyPlayerId(gameId, players[2].id);

    final game = await db.gamesDao.getById(gameId);
    expect(game!.myPlayerId, players[2].id);
  });

  test('isMine 字段：我的信息 true / 他人声明 false', () async {
    final gameId = await setupRepo.createGame(
      script: Script.troubleBrewing,
      names: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      myRole: Character.empath,
    );
    final players = await db.playersDao.watchByGame(gameId).first;
    final dayId = await db.dayRecordsDao.insertDay(
      DayRecordsCompanion(
        gameId: Value(gameId),
        dayNumber: const Value(1),
      ),
    );

    // 我的信息
    await detailRepo.declareInfo(
      playerId: players[0].id,
      dayRecordId: dayId,
      character: Character.empath,
      payload: {'value': 1},
      isMine: true,
    );
    // 他人声明
    await detailRepo.declareInfo(
      playerId: players[1].id,
      dayRecordId: dayId,
      character: Character.chef,
      payload: {'value': 2},
    );

    final decls = await db.infoDeclarationsDao.watchByGame(gameId).first;
    expect(decls[0].isMine, isTrue);
    expect(decls[1].isMine, isFalse);
  });

  test('migration：v3 schema 包含新字段', () async {
    // 内存数据库直接走 onCreate（v3），验证新列可用即可
    final gameId = await setupRepo.createGame(
      script: Script.troubleBrewing,
      names: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      myRole: Character.mayor,
    );
    final game = await db.gamesDao.getById(gameId);
    // 新列存在且默认 null
    expect(game!.myPlayerId, isNull);
    expect(game.demonBluffsJson, isNull);
  });
}
