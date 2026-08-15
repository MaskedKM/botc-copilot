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

  group('教授复活（#217 增量4D）', () {
    test('复活确认 → 目标复活（isAlive=true）+ 能力消耗', () async {
      await db.playersDao.markDead(players[1].id, 2, DeathCause.nightKill);
      final result = await repo.recordProfessorResurrect(
        professorId: players[0].id,
        targetId: players[1].id,
        resurrected: true,
        day: 4,
      );
      expect(result, ProfessorResurrectResult.resurrected);
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[1].isAlive, isTrue);
      expect(updated[1].deathDay, isNull);
      expect(updated[0].abilityUsed, isTrue);
    });

    test('未复活 → 能力仍消耗（公理4 一次性），目标保持死亡', () async {
      await db.playersDao.markDead(players[1].id, 2, DeathCause.nightKill);
      final result = await repo.recordProfessorResurrect(
        professorId: players[0].id,
        targetId: players[1].id,
        resurrected: false,
        day: 4,
      );
      expect(result, ProfessorResurrectResult.notResurrected);
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[1].isAlive, isFalse);
      expect(updated[0].abilityUsed, isTrue);
    });

    test('复活保留死亡当日记录（历史事件不回擦，区别于撤销误标）', () async {
      final dayId = await db.dayRecordsDao.insertDay(
        DayRecordsCompanion(gameId: Value(gameId), dayNumber: Value(2)),
      );
      await db.dayRecordsDao.updateDay(
        dayId,
        DayRecordsCompanion(
          nightDeathPlayerIds: Value('[${players[1].id}]'),
          nightConfirmed: const Value(true),
        ),
      );
      await db.playersDao.markDead(players[1].id, 2, DeathCause.nightKill);
      await repo.recordProfessorResurrect(
        professorId: players[0].id,
        targetId: players[1].id,
        resurrected: true,
        day: 4,
      );
      final day = await db.dayRecordsDao.getByGameAndDay(gameId, 2);
      expect(nightDeathIdsOf(day), isNotEmpty); // 死亡史保留
    });
  });
  group('#264 死亡真相源一致性', () {
    test('resurrect：盖章周期 + 清 abilityUsed（复活重获能力）', () async {
      await db.playersDao.markDead(players[1].id, 2, DeathCause.nightKill);
      await db.playersDao.markAbilityUsed(players[1].id, used: true);
      await db.playersDao.resurrect(players[1].id, 4);
      final u = await db.playersDao.watchByGame(gameId).first;
      expect(u[1].isAlive, isTrue);
      expect(u[1].revivedDay, 4);
      expect(u[1].abilityUsed, isFalse); // 官方：复活者重获一次性能力
      expect(u[1].deathDay, isNull);
    });

    test('revive（撤销误标）：不盖章、清复活标记——死亡视为未发生', () async {
      await db.playersDao.markDead(players[1].id, 2, DeathCause.nightKill);
      await db.playersDao.resurrect(players[1].id, 4);
      await db.playersDao.markDead(players[1].id, 5, DeathCause.nightKill);
      await db.playersDao.revive(players[1].id);
      final u = await db.playersDao.watchByGame(gameId).first;
      expect(u[1].isAlive, isTrue);
      expect(u[1].revivedDay, isNull); // 撤销 ≠ 复活
      expect(u[1].deathDay, isNull);
    });

    test('教授复活走 resurrect：目标获得周期锚点', () async {
      await db.playersDao.markDead(players[1].id, 2, DeathCause.nightKill);
      await db.playersDao.markAbilityUsed(players[1].id, used: true);
      await repo.recordProfessorResurrect(
        professorId: players[0].id,
        targetId: players[1].id,
        resurrected: true,
        day: 4,
      );
      final u = await db.playersDao.watchByGame(gameId).first;
      expect(u[1].revivedDay, 4);
      expect(u[1].abilityUsed, isFalse);
    });

    test('Slayer 击中僵怖假死：目标存活 + fakeDead + 能力消耗', () async {
      final result = await repo.recordSlayerGuess(
        slayerId: players[0].id,
        targetId: players[1].id,
        targetIsDemon: true,
        wasPoisoned: false,
        day: 3,
        targetFakeDied: true,
      );
      expect(result, SlayerGuessResult.killed);
      final u = await db.playersDao.watchByGame(gameId).first;
      expect(u[1].isAlive, isTrue); // 登记为死但活着
      expect(u[1].fakeDead, isTrue);
      expect(u[1].deathDay, 3);
      expect(u[0].abilityUsed, isTrue);
    });

    test('手动假死 stamp deathDay（两真相源一致，#264 ③）', () async {
      await db.playersDao.setFakeDeadFlag(players[1].id, fake: true, day: 3);
      var u = await db.playersDao.watchByGame(gameId).first;
      expect(u[1].fakeDead, isTrue);
      expect(u[1].deathDay, 3); // 推理/Empath 按死亡重建 → 一致
      expect(u[1].isAlive, isTrue);
      // 清除（存活态）→ stamp 同步清
      await db.playersDao.setFakeDeadFlag(players[1].id, fake: false, day: 3);
      u = await db.playersDao.watchByGame(gameId).first;
      expect(u[1].fakeDead, isFalse);
      expect(u[1].deathDay, isNull);
    });

    test('手动假死不覆盖真死者', () async {
      await db.playersDao.markDead(players[1].id, 2, DeathCause.nightKill);
      await db.playersDao.setFakeDeadFlag(players[1].id, fake: true, day: 3);
      final u = await db.playersDao.watchByGame(gameId).first;
      expect(u[1].fakeDead, isFalse); // isAlive=false 守卫
      expect(u[1].deathDay, 2); // 原死亡信息不动
    });
  });
}
