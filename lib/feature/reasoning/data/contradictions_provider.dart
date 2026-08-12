import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/contradiction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 某对局的全部角色声明流。
final gameClaimsProvider =
    StreamProvider.family<List<RoleClaim>, int>((ref, gameId) {
  return ref.watch(appDatabaseProvider).roleClaimsDao.watchByGame(gameId);
});

final _declarationsProvider =
    StreamProvider.family<List<InfoDeclaration>, int>((ref, gameId) {
  return ref
      .watch(appDatabaseProvider)
      .infoDeclarationsDao
      .watchByGame(gameId);
});

final _daysProvider =
    StreamProvider.family<List<DayRecord>, int>((ref, gameId) {
  return ref.watch(appDatabaseProvider).dayRecordsDao.watchByGame(gameId);
});

/// 当前对局的矛盾标记流（issue #38）。
final contradictionsProvider = Provider.family<List<Contradiction>, int>(
  (ref, gameId) {
    final claims = ref.watch(gameClaimsProvider(gameId)).valueOrNull ?? [];
    final declarations =
        ref.watch(_declarationsProvider(gameId)).valueOrNull ?? [];
    final days = ref.watch(_daysProvider(gameId)).valueOrNull ?? [];
    final players =
        ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final game = ref.watch(gameByIdProvider(gameId)).valueOrNull;
    final expectedOutsiders =
        game != null ? PlayerSetup.forCount(game.playerCount).outsiders : 0;

    return ContradictionDetector.detect(
      claims: claims,
      declarations: declarations,
      days: days,
      playersById: {for (final p in players) p.id: p},
      dayRecordToDayNumber: {for (final d in days) d.id: d.dayNumber},
      expectedOutsiders: expectedOutsiders,
      myPlayerId: game?.myPlayerId,
      myRole: game?.myRole,
    );
  },
);
