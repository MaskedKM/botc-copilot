import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/dependency_chain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 某对局的全部信息声明流（issue #58）。
///
/// autoDispose：仅依赖链页使用，离开页面即释放订阅。
final gameDeclarationsProvider =
    StreamProvider.autoDispose.family<List<InfoDeclaration>, int>(
        (ref, gameId) {
  return ref
      .watch(appDatabaseProvider)
      .infoDeclarationsDao
      .watchByGame(gameId);
});

final _daysProvider =
    StreamProvider.autoDispose.family<List<DayRecord>, int>((ref, gameId) {
  return ref.watch(appDatabaseProvider).dayRecordsDao.watchByGame(gameId);
});

/// 沙盒假设：本页试算的额外「假设醉」玩家集合（issue #58）。
///
/// **不写入存档**——仅用于「假设 X 醉 → 下游信息高亮」的试错探索。
/// autoDispose：离开页面即销毁，下次进入从空假设开始（回到只反映持久
/// suspectedDrunk 的基线）；页内亦可手动「重置」。
class DependencySandboxNotifier extends StateNotifier<Set<int>> {
  DependencySandboxNotifier() : super(const <int>{});

  /// 切换某玩家的「假设醉」。
  void toggleAssumeDrunk(int playerId) {
    final next = {...state};
    if (next.contains(playerId)) {
      next.remove(playerId);
    } else {
      next.add(playerId);
    }
    state = next;
  }

  /// 清空所有沙盒假设。
  void reset() => state = const <int>{};
}

/// 某对局的沙盒假设状态。
final dependencySandboxProvider = StateNotifierProvider.autoDispose
    .family<DependencySandboxNotifier, Set<int>, int>(
  (ref, gameId) => DependencySandboxNotifier(),
);

/// 当前假设下的依赖节点列表（持久 suspectedDrunk ∪ 沙盒）。
final dependencyNodesProvider =
    Provider.autoDispose.family<List<InfoDependencyNode>, int>((ref, gameId) {
  final declarations =
      ref.watch(gameDeclarationsProvider(gameId)).valueOrNull ?? [];
  final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
  final days = ref.watch(_daysProvider(gameId)).valueOrNull ?? [];
  final sandbox = ref.watch(dependencySandboxProvider(gameId));
  return DependencyChainBuilder.build(
    declarations: declarations,
    playersById: {for (final p in players) p.id: p},
    dayRecordToDayNumber: {for (final d in days) d.id: d.dayNumber},
    extraDrunkIds: sandbox,
  );
});
