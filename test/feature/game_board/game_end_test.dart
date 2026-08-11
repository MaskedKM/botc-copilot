import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/setup/data/setup_repository.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameEndRules 纯函数', () {
    test('存活 ≤ 2 → 邪恶获胜候选', () {
      expect(GameEndRules.isEvilWinCandidate(2), isTrue);
      expect(GameEndRules.isEvilWinCandidate(1), isTrue);
      expect(GameEndRules.isEvilWinCandidate(3), isFalse);
    });

    test('被处决者是恶魔 → 善良获胜', () {
      expect(GameEndRules.isGoodWin(executedWasDemon: true), isTrue);
      expect(GameEndRules.isGoodWin(executedWasDemon: false), isFalse);
    });
  });

  group('结束检测集成', () {
    late AppDatabase db;
    late ProviderContainer container;
    late int gameId;

    GameBoardNotifier notifier() =>
        container.read(gameBoardProvider(gameId).notifier);

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

    test('夜晚死亡后存活 > 2 → 无建议', () async {
      final suggestion = await notifier().recordNightDeath(1);
      expect(suggestion, isNull);
    });

    test('连续死亡至存活 = 2 → EvilWinCandidate', () async {
      // 7 人局，杀 5 个剩 2
      await notifier().recordNightDeath(1);
      await notifier().recordNightDeath(2);
      await notifier().recordNightDeath(3);
      await notifier().recordNightDeath(4);
      final suggestion = await notifier().recordNightDeath(5);
      expect(suggestion, isA<EvilWinCandidate>());
      expect((suggestion! as EvilWinCandidate).aliveCount, 2);
    });

    test('处决后返回 DemonExecutionCheck', () async {
      final suggestion = await notifier().recordExecution(3);
      expect(suggestion, isA<DemonExecutionCheck>());
      final check = suggestion! as DemonExecutionCheck;
      expect(check.executedPlayerId, 3);
      expect(check.aliveCountAfter, 6);
    });

    test('endGame 善良胜 + 死亡揭示记录', () async {
      await notifier().recordExecution(3);
      await notifier().endGame(
        goodWin: true,
        revealedPlayerId: 3,
        revealedRole: Character.imp,
      );
      final game = await db.gamesDao.getById(gameId);
      expect(game!.status, GameStatus.goodWin);

      final claims = await db.roleClaimsDao.watchByGame(gameId).first;
      expect(claims.length, 1);
      expect(claims[0].character, Character.imp);
      expect(claims[0].claimType, ClaimType.revealedOnDeath);
    });

    test('endGame 邪恶胜', () async {
      await notifier().endGame(goodWin: false);
      final game = await db.gamesDao.getById(gameId);
      expect(game!.status, GameStatus.evilWin);
    });

    test('quickToggleDead 标记死亡后存活 ≤ 2 → 建议', () async {
      final players = await db.playersDao.watchByGame(gameId).first;
      // 杀 4 个剩 3
      for (final p in players.take(4)) {
        await db.playersDao.markDead(p.id, 1, DeathCause.nightKill);
      }
      final suggestion = await notifier().quickToggleDead(players[4]);
      expect(suggestion, isA<EvilWinCandidate>());
    });
  });
}
