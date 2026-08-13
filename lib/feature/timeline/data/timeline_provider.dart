import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/data/nomination_repository.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/game_board/data/poison_repository.dart';
import 'package:botc_copilot/feature/player_detail/data/behavior_note_repository.dart';
import 'package:botc_copilot/feature/timeline/domain/timeline_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 某局的全部每日记录。
final _daysProvider =
    StreamProvider.family<List<DayRecord>, int>((ref, gameId) {
  final db = ref.watch(appDatabaseProvider);
  return db.dayRecordsDao.watchByGame(gameId);
});

/// 某局的全部角色声明。
final _claimsProvider =
    StreamProvider.family<List<RoleClaim>, int>((ref, gameId) {
  final db = ref.watch(appDatabaseProvider);
  return db.roleClaimsDao.watchByGame(gameId);
});

/// 某局的全部信息声明。
final _declarationsProvider =
    StreamProvider.family<List<InfoDeclaration>, int>((ref, gameId) {
  final db = ref.watch(appDatabaseProvider);
  return db.infoDeclarationsDao.watchByGame(gameId);
});

/// 某局的全部恶魔传承事件（issue #89）。
final _successionsProvider =
    StreamProvider.family<List<DemonInheritance>, int>((ref, gameId) {
  final db = ref.watch(appDatabaseProvider);
  return db.demonInheritancesDao.watchByGame(gameId);
});

/// 某局的时间线数据（按天分组）。
///
/// 组合多个流（days/players/claims/declarations/nominations/poison/behavior）：
/// 任一变化都触发重建（声明/信息录入后时间线立即刷新），
/// 数据源均为小数据量，全量重算开销可忽略。
final timelineProvider =
    Provider.family<AsyncValue<List<TimelineDay>>, int>((ref, gameId) {
  final days = ref.watch(_daysProvider(gameId));
  final players = ref.watch(gamePlayersProvider(gameId));
  final claims = ref.watch(_claimsProvider(gameId));
  final declarations = ref.watch(_declarationsProvider(gameId));
  // nominations 与 claims/declarations 同级 watch：须在 loading gate 之前
  // 订阅，否则首帧（loading 提前 return）不会订阅它，冷读会拿到空列表。
  final nominations = ref.watch(gameNominationsProvider(gameId));

  // 任一在加载/出错 → 整体跟随
  if (days.isLoading || players.isLoading) {
    return const AsyncValue.loading();
  }
  final error = [days, players, claims, declarations, nominations]
      .where((a) => a.hasError)
      .firstOrNull;
  if (error != null) {
    return AsyncValue.error(error.error!, error.stackTrace!);
  }

  final dayList = days.valueOrNull ?? [];
  return AsyncValue.data(
    TimelineBuilder.build(
      days: dayList,
      claims: claims.valueOrNull ?? [],
      declarations: declarations.valueOrNull ?? [],
      playersById: {
        for (final p in players.valueOrNull ?? <Player>[]) p.id: p,
      },
      dayRecordToDayNumber: {for (final d in dayList) d.id: d.dayNumber},
      poisonStatuses: ref
              .watch(gamePoisonStatusesProvider(gameId))
              .valueOrNull ??
          [],
      behaviorNotes:
          ref.watch(gameBehaviorNotesProvider(gameId)).valueOrNull ?? [],
      nominations: nominations.valueOrNull ?? [],
      successions:
          ref.watch(_successionsProvider(gameId)).valueOrNull ?? [],
    ),
  );
});
