import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/feature/game_board/domain/succession.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/setup/data/setup_repository.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SuccessionRules 纯函数', () {
    test('isDemonDeath：仅 Imp 触发', () {
      expect(SuccessionRules.isDemonDeath(Character.imp), isTrue);
      expect(SuccessionRules.isDemonDeath(Character.soldier), isFalse);
      expect(SuccessionRules.isDemonDeath(Character.scarletWoman), isFalse);
      expect(SuccessionRules.isDemonDeath(null), isFalse);
    });

    test('isScarletWomanThreshold：死后存活 ≥4（死前 ≥5）触发', () {
      expect(SuccessionRules.isScarletWomanThreshold(4), isTrue); // 死前 5
      expect(SuccessionRules.isScarletWomanThreshold(5), isTrue);
      expect(SuccessionRules.isScarletWomanThreshold(3), isFalse); // 死前 4
      expect(SuccessionRules.isScarletWomanThreshold(0), isFalse);
    });
  });

  group('恶魔传承集成（issue #89）', () {
    late AppDatabase db;
    late ProviderContainer container;
    late int gameId;

    GameBoardNotifier notifier() =>
        container.read(gameBoardProvider(gameId).notifier);

    Future<void> claimRole(int playerId, Character c) async {
      final dayId = await notifier().ensureCurrentDayRecord();
      await db.roleClaimsDao.insertClaim(
        RoleClaimsCompanion(
          playerId: Value(playerId),
          dayRecordId: Value(dayId),
          character: Value(c),
          claimType: const Value(ClaimType.firstClaim),
        ),
      );
    }

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      gameId = await SetupRepository(db).createGame(
        script: Script.troubleBrewing,
        names: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        myRole: Character.empath,
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('夜死自杀（无 SW）→ DemonSuccessionCandidate(suicide, 无 SW)', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      await claimRole(players[0].id, Character.imp);
      final suggestion = await notifier().setNightDeaths([players[0].id]);
      expect(suggestion, isA<DemonSuccessionCandidate>());
      final cand = suggestion! as DemonSuccessionCandidate;
      expect(cand.way, DeathWay.suicide);
      expect(cand.scarletWomanEligible, isFalse);
      expect(cand.aliveCountAfter, 6); // 7 - 1
    });

    test('夜死自杀：死者被标 demonCandidate（未声明 Imp）→ 兜底触发', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      // 不声明 Imp，但信任度标 demonCandidate（好人视角兜底）
      await db.trustLogsDao.insertLog(
        TrustLogsCompanion(
          gameId: Value(gameId),
          playerId: Value(players[0].id),
          dayNumber: const Value(1),
          trustLevel: const Value(TrustLevel.demonCandidate),
        ),
      );
      final suggestion = await notifier().setNightDeaths([players[0].id]);
      expect(suggestion, isA<DemonSuccessionCandidate>());
    });

    test('夜死自杀 + SW 在场（死前 ≥5）→ SW eligible', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      await claimRole(players[0].id, Character.imp);
      await claimRole(players[1].id, Character.scarletWoman);
      final suggestion = await notifier().setNightDeaths([players[0].id]);
      final cand = suggestion! as DemonSuccessionCandidate;
      expect(cand.way, DeathWay.suicide);
      expect(cand.scarletWomanEligible, isTrue);
      expect(cand.scarletWomanPlayerId, players[1].id);
    });

    test('处决恶魔 + SW 在场 → SW eligible（不终局路径）', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      await claimRole(players[1].id, Character.scarletWoman);
      await db.playersDao.markDead(players[0].id, 1, DeathCause.execution);
      final suggestion = await notifier().checkDemonDeath(
        players[0].id,
        way: DeathWay.execution,
      );
      expect(suggestion, isA<DemonSuccessionCandidate>());
      expect(
        (suggestion! as DemonSuccessionCandidate).scarletWomanEligible,
        isTrue,
      );
    });

    test('处决恶魔 + 无 SW → null（善良胜）', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      await db.playersDao.markDead(players[0].id, 1, DeathCause.execution);
      final suggestion = await notifier().checkDemonDeath(
        players[0].id,
        way: DeathWay.execution,
      );
      expect(suggestion, isNull);
    });

    test('Slayer 杀恶魔 + 无 SW → null（善良胜）', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      await db.playersDao.markDead(players[0].id, 1, DeathCause.other);
      final suggestion = await notifier().checkDemonDeath(
        players[0].id,
        way: DeathWay.slayer,
      );
      expect(suggestion, isNull);
    });

    test('SW 阈值：死后 4 存活（死前 5）+ SW → eligible', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      await claimRole(players[6].id, Character.scarletWoman);
      for (final p in [players[1], players[2]]) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      await db.playersDao.markDead(players[0].id, 1, DeathCause.execution);
      // 存活 = 7 - 3 = 4；死前 5 ≥ 5 → SW eligible
      final suggestion = await notifier().checkDemonDeath(
        players[0].id,
        way: DeathWay.execution,
      );
      expect(suggestion, isA<DemonSuccessionCandidate>());
      expect(
        (suggestion! as DemonSuccessionCandidate).scarletWomanEligible,
        isTrue,
      );
    });

    test('SW 阈值：死后 3 存活（死前 4）→ SW 不 eligible，处决 → null', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      await claimRole(players[6].id, Character.scarletWoman);
      for (final p in [players[1], players[2], players[3]]) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      await db.playersDao.markDead(players[0].id, 1, DeathCause.execution);
      // 存活 = 7 - 4 = 3；死前 4 < 5 → SW 不 eligible
      final suggestion = await notifier().checkDemonDeath(
        players[0].id,
        way: DeathWay.execution,
      );
      expect(suggestion, isNull);
    });

    test('recordSuccession：写事件 + 继承人标 demonCandidate', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      await notifier().recordSuccession(
        fromPlayerId: players[0].id,
        toPlayerId: players[1].id,
        trigger: SuccessionTrigger.scarletWoman,
      );
      final succs = await db.demonInheritancesDao.watchByGame(gameId).first;
      expect(succs.length, 1);
      expect(succs[0].fromPlayerId, players[0].id);
      expect(succs[0].toPlayerId, players[1].id);
      expect(succs[0].trigger, SuccessionTrigger.scarletWoman);
      // 继承人 trustLog = demonCandidate
      final logs = await db.trustLogsDao.watchByGame(gameId).first;
      final heirLog = logs.lastWhere((l) => l.playerId == players[1].id);
      expect(heirLog.trustLevel, TrustLevel.demonCandidate);
    });

    test('SW 仅首次：已有 scarletWoman 传承 → 不再 eligible', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      await claimRole(players[1].id, Character.scarletWoman);
      // 先记录一次 SW 传承（首次）
      await notifier().recordSuccession(
        fromPlayerId: players[0].id,
        toPlayerId: players[1].id,
        trigger: SuccessionTrigger.scarletWoman,
      );
      // 新恶魔 players[0] 再死：suicide 仍返回 candidate，但 SW 不再 eligible
      await db.playersDao.markDead(players[0].id, 1, DeathCause.nightKill);
      final suggestion = await notifier().checkDemonDeath(
        players[0].id,
        way: DeathWay.suicide,
      );
      final cand = suggestion! as DemonSuccessionCandidate;
      expect(cand.scarletWomanEligible, isFalse);
    });

    // #156 BUG-A：长按标死恶魔（当天）必返非空 DemonSuccessionCandidate——
    // 这是 game_board_page 撤销 SnackBar「suggestion == null 才提供撤销」
    // 守卫的不变式（非空 ⟺ 终局，revivePlayer 无法回退传承/终局，撤销会留
    // 双恶魔/在已结束对局复活）。
    test('长按标死恶魔（当天）→ quickToggleDead 返回 DemonSuccessionCandidate', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      await claimRole(players[0].id, Character.imp);
      final suggestion = await notifier().quickToggleDead(players[0]);
      expect(suggestion, isA<DemonSuccessionCandidate>());
      final updated = await db.playersDao.watchByGame(gameId).first;
      expect(updated[0].isAlive, isFalse);
    });
  });
}
