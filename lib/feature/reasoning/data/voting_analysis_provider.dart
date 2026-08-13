import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/data/nomination_repository.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/voting_analysis.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _daysProvider =
    StreamProvider.family<List<DayRecord>, int>((ref, gameId) {
  return ref.watch(appDatabaseProvider).dayRecordsDao.watchByGame(gameId);
});

/// 某对局的投票模式分析（issue #57）。
///
/// 纯派生：从既有提名/玩家/天记录流计算，无写入、无 schema 依赖。
final votingAnalysisProvider =
    Provider.family<VotingAnalysis?, int>((ref, gameId) {
  final nominations =
      ref.watch(gameNominationsProvider(gameId)).valueOrNull ?? [];
  if (nominations.isEmpty) return null;
  final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
  final days = ref.watch(_daysProvider(gameId)).valueOrNull ?? [];
  return VotingAnalyzer.analyze(
    nominations: nominations,
    players: players,
    dayRecordToDayNumber: {for (final d in days) d.id: d.dayNumber},
  );
});
