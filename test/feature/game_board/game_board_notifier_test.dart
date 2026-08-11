import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
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
  });

  test('recordNightDeath(null)：无人死亡只更新记录不标记', () async {
    await notifier().recordNightDeath(null);
    final day = await db.dayRecordsDao.getByGameAndDay(gameId, 1);
    expect(day!.nightDeathPlayerId, isNull);
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated.every((p) => p.isAlive), isTrue);
  });

  test('recordExecution：处决标记死亡', () async {
    await notifier().recordExecution(players[4].id);
    final updated = await db.playersDao.watchByGame(gameId).first;
    expect(updated[4].isAlive, isFalse);
    expect(updated[4].deathCause, DeathCause.execution);
  });

  test('advanceDay：推进天数 + 预建次日记录 + 清空选中', () async {
    notifier().selectPlayer(players[0].id);
    await notifier().advanceDay();

    expect(state().currentDay, 2);
    expect(state().selectedPlayerId, isNull);
    final day2 = await db.dayRecordsDao.getByGameAndDay(gameId, 2);
    expect(day2, isNotNull);
  });

  test('advanceDay 幂等：重复推进不重复建记录', () async {
    await notifier().advanceDay();
    await notifier().advanceDay();
    final days = await db.dayRecordsDao.watchByGame(gameId).first;
    expect(days.map((d) => d.dayNumber), [2, 3]);
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
