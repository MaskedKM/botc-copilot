import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/data/poison_repository.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/setup/data/setup_repository.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PoisonRepository repo;
  late int gameId;
  late List<Player> players;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PoisonRepository(db);
    gameId = await SetupRepository(db).createGame(
      script: Script.troubleBrewing,
      names: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      myRole: Character.empath,
    );
    players = await db.playersDao.watchByGame(gameId).first;
  });

  tearDown(() => db.close());

  test('toggleStatus 标记与取消', () async {
    await repo.toggleStatus(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
    );
    var statuses = await db.poisonStatusesDao.watchByGame(gameId).first;
    expect(statuses.length, 1);
    expect(statuses[0].isActive, isTrue);
    expect(statuses[0].source, PoisonSource.poisoner);

    // 再切一次 = 取消
    await repo.toggleStatus(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
    );
    statuses = await db.poisonStatusesDao.watchByGame(gameId).first;
    expect(statuses, isEmpty);
  });

  test('isTainted 按天隔离', () async {
    await repo.toggleStatus(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
    );
    expect(
      await repo.isTainted(
        gameId: gameId,
        playerId: players[0].id,
        dayNumber: 2,
      ),
      isTrue,
    );
    // 其他天不污染
    expect(
      await repo.isTainted(
        gameId: gameId,
        playerId: players[0].id,
        dayNumber: 3,
      ),
      isFalse,
    );
    // 其他玩家不污染
    expect(
      await repo.isTainted(
        gameId: gameId,
        playerId: players[1].id,
        dayNumber: 2,
      ),
      isFalse,
    );
  });

  test('deactivate 后不再污染', () async {
    await repo.toggleStatus(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
    );
    final statuses = await db.poisonStatusesDao.watchByGame(gameId).first;
    await db.poisonStatusesDao.deactivate(statuses[0].id);
    expect(
      await repo.isTainted(
        gameId: gameId,
        playerId: players[0].id,
        dayNumber: 2,
      ),
      isFalse,
    );
  });

  test('录入信息时当天被毒 → 可靠性自动 possiblyTainted', () async {
    final detailRepo = PlayerDetailRepository(db);
    final dayId = await db.dayRecordsDao.insertDay(
      DayRecordsCompanion(gameId: Value(gameId), dayNumber: const Value(2)),
    );
    // 先标毒
    await repo.toggleStatus(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
    );
    // 录入信息
    await detailRepo.declareInfo(
      playerId: players[0].id,
      dayRecordId: dayId,
      character: Character.chef,
      payload: {'value': 1},
      gameId: gameId,
      dayNumber: 2,
    );
    final decls = await db.infoDeclarationsDao.watchByGame(gameId).first;
    expect(decls[0].reliability, Reliability.possiblyTainted);
  });

  test('无毒时录入信息 → 可靠性保持 unverified', () async {
    final detailRepo = PlayerDetailRepository(db);
    final dayId = await db.dayRecordsDao.insertDay(
      DayRecordsCompanion(gameId: Value(gameId), dayNumber: const Value(2)),
    );
    await detailRepo.declareInfo(
      playerId: players[0].id,
      dayRecordId: dayId,
      character: Character.chef,
      payload: {'value': 1},
      gameId: gameId,
      dayNumber: 2,
    );
    final decls = await db.infoDeclarationsDao.watchByGame(gameId).first;
    expect(decls[0].reliability, Reliability.unverified);
  });

  // #150 R1/B1：唯一约束兜底——同 (game,player,day) 第二条插入应抛异常。
  test('poison_statuses 唯一约束：同 (game,player,day) 重复插入抛异常', () async {
    await db.poisonStatusesDao.insertStatus(
      PoisonStatusesCompanion(
        gameId: Value(gameId),
        playerId: Value(players[0].id),
        dayNumber: const Value(1),
        source: const Value(PoisonSource.poisoner),
      ),
    );
    // 直接 DAO 插入绕过 toggleStatus，唯一约束应拦截
    expect(
      () => db.poisonStatusesDao.insertStatus(
        PoisonStatusesCompanion(
          gameId: Value(gameId),
          playerId: Value(players[0].id),
          dayNumber: const Value(1),
          source: const Value(PoisonSource.poisoner),
        ),
      ),
      throwsA(isA<Object>()),
    );
  });
}
