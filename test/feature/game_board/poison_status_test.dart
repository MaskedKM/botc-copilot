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

    Future<bool> tainted(int pid, int day) async =>
        (await db.poisonStatusesDao.findByPlayerAndDay(pid, day))?.isActive ??
        false;

  test('setStatus 标记与取消（set-by-value）', () async {
    await repo.setStatus(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
      marked: true,
    );
    var statuses = await db.poisonStatusesDao.watchByGame(gameId).first;
    expect(statuses.length, 1);
    expect(statuses[0].isActive, isTrue);
    expect(statuses[0].source, PoisonSource.poisoner);

    // 再设为 false = 取消
    await repo.setStatus(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
      marked: false,
    );
    statuses = await db.poisonStatusesDao.watchByGame(gameId).first;
    expect(statuses, isEmpty);
  });

  test('isTainted 按天隔离', () async {
    await repo.setStatus(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
      marked: true,
    );
    expect(
      await tainted(players[0].id, 2),
      isTrue,
    );
    // 其他天不污染
    expect(
      await tainted(players[0].id, 3),
      isFalse,
    );
    // 其他玩家不污染
    expect(
      await tainted(players[1].id, 2),
      isFalse,
    );
  });

  test('deactivate 后不再污染', () async {
    await repo.setStatus(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
      marked: true,
    );
    final statuses = await db.poisonStatusesDao.watchByGame(gameId).first;
    await db.poisonStatusesDao.deactivate(statuses[0].id);
    expect(
      await tainted(players[0].id, 2),
      isFalse,
    );
  });

  test('录入信息时当天被毒 → 可靠性自动 possiblyTainted', () async {
    final detailRepo = PlayerDetailRepository(db);
    final dayId = await db.dayRecordsDao.insertDay(
      DayRecordsCompanion(gameId: Value(gameId), dayNumber: const Value(2)),
    );
    // 先标毒
    await repo.setStatus(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
      marked: true,
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
    // 直接 DAO 插入绕过 setStatus，唯一约束应拦截
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

  group('#263 吟游诗人醉潮（两日窗口）', () {
    test('开 = 触发日 + 次日各全员醉潮行（source=minstrel）', () async {
      await repo.setMinstrelTide(
        gameId: gameId,
        playerIds: [for (final p in players) p.id],
        dayNumber: 3,
        on: true,
      );
      final statuses = await db.poisonStatusesDao.watchByGame(gameId).first;
      expect(statuses.length, players.length * 2); // day 3 + day 4
      expect(
        statuses.every((s) => s.source == PoisonSource.minstrel),
        isTrue,
      );
      expect(
        statuses.every((s) => s.dayNumber == 3 || s.dayNumber == 4),
        isTrue,
      );
    });

    test('已有标毒者不覆盖来源；关 = 清两日醉潮并保留他人标毒', () async {
      await repo.setStatus(
        gameId: gameId,
        playerId: players[0].id,
        dayNumber: 3,
        marked: true,
      );
      await repo.setMinstrelTide(
        gameId: gameId,
        playerIds: [for (final p in players) p.id],
        dayNumber: 3,
        on: true,
      );
      var statuses = await db.poisonStatusesDao.watchByGame(gameId).first;
      expect(statuses.length, players.length * 2);
      expect(
        statuses.firstWhere((s) => s.playerId == players[0].id).source,
        PoisonSource.poisoner, // 不覆盖
      );
      await repo.setMinstrelTide(
        gameId: gameId,
        playerIds: [for (final p in players) p.id],
        dayNumber: 3,
        on: false,
      );
      statuses = await db.poisonStatusesDao.watchByGame(gameId).first;
      expect(statuses.length, 1); // 仅剩 players[0] day3 的标毒
      expect(statuses.single.dayNumber, 3);
    });

    test('排除名单由调用方传入（吟游诗人本座不污染，UI 层职责）', () async {
      final ids = [
        for (final p in players)
          if (p != players[2]) p.id,
      ];
      await repo.setMinstrelTide(
        gameId: gameId,
        playerIds: ids,
        dayNumber: 3,
        on: true,
      );
      final statuses = await db.poisonStatusesDao.watchByGame(gameId).first;
      expect(
        statuses.any((s) => s.playerId == players[2].id),
        isFalse,
      );
      expect(statuses.length, (players.length - 1) * 2);
    });
  });
}
