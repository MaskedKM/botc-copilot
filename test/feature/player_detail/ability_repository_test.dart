import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/player_detail/data/ability_repository.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AbilityRepository repo;
  late int gameId;
  late List<Player> players;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AbilityRepository(db);
    gameId = await db.gamesDao.insertGame(
      GamesCompanion(
        script: const Value(Script.troubleBrewing),
        playerCount: const Value(7),
        status: const Value(GameStatus.ongoing),
        createdAt: Value(DateTime(2026, 8, 12)),
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

  tearDown(() => db.close());

  group('Slayer 猜测（issue #54）', () {
    test('猜中恶魔（未毒）→ 目标死亡 + 能力消耗', () async {
      final result = await repo.recordSlayerGuess(
        slayerId: players[0].id,
        targetId: players[1].id,
        targetIsDemon: true,
        wasPoisoned: false,
        day: 2,
      );
      expect(result, SlayerGuessResult.killed);
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[0].abilityUsed, isTrue); // Slayer 已消耗
      expect(updated[1].isAlive, isFalse); // 目标死亡
    });

    test('未猜中 → 目标存活，能力仍消耗', () async {
      final result = await repo.recordSlayerGuess(
        slayerId: players[0].id,
        targetId: players[1].id,
        targetIsDemon: false,
        wasPoisoned: false,
        day: 2,
      );
      expect(result, SlayerGuessResult.missed);
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[0].abilityUsed, isTrue);
      expect(updated[1].isAlive, isTrue);
    });

    test('被毒时猜中 → 不击杀但永久消耗（官方：一次性能力醉毒永久消耗）',
        () async {
      final result = await repo.recordSlayerGuess(
        slayerId: players[0].id,
        targetId: players[1].id,
        targetIsDemon: true,
        wasPoisoned: true,
        day: 2,
      );
      expect(result, SlayerGuessResult.missed);
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[0].abilityUsed, isTrue);
      expect(updated[1].isAlive, isTrue);
    });
  });

  group('一次性能力追踪', () {
    test('setAbilityUsed 可标记 / 撤销（Virgin 触发 / 误标回退）', () async {
      await repo.setAbilityUsed(players[2].id, used: true);
      var updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[2].abilityUsed, isTrue);

      await repo.setAbilityUsed(players[2].id, used: false);
      updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[2].abilityUsed, isFalse);
    });

    test('新建玩家默认 abilityUsed=false', () {
      expect(players.every((p) => !p.abilityUsed), isTrue);
    });
  });
}
