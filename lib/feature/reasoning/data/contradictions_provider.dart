import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/dependency_chain_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/contradiction.dart';
import 'package:botc_copilot/shared/game_private.dart';
import 'package:botc_copilot/shared/reliability.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 某对局的全部角色声明流。
final gameClaimsProvider =
    StreamProvider.family<List<RoleClaim>, int>((ref, gameId) {
  return ref.watch(appDatabaseProvider).roleClaimsDao.watchByGame(gameId);
});

/// 某对局的全部信息声明流（公共：矛盾引擎与排除法棋盘共用一份订阅）。
final gameAllDeclarationsProvider =
    StreamProvider.family<List<InfoDeclaration>, int>((ref, gameId) {
  return ref
      .watch(appDatabaseProvider)
      .infoDeclarationsDao
      .watchByGame(gameId);
});

/// 某对局的全部天记录流（公共：矛盾引擎与排除法棋盘共用一份订阅）。
final gameAllDaysProvider =
    StreamProvider.family<List<DayRecord>, int>((ref, gameId) {
  return ref.watch(appDatabaseProvider).dayRecordsDao.watchByGame(gameId);
});

/// 矛盾引擎计算结果（issue #211）。
///
/// [failed] = true 表示 [ContradictionDetector.detect] 抛异常被兜底捕获——
/// 此时 [contradictions] 为空但**不代表「无矛盾」**，UI 须展示降级提示，
/// 而非按空成功渲染。原先 release 下 `debugPrint` 是 no-op、直接返回 `[]`，
/// 引擎真出 bug 时会**无信号地关闭全部矛盾检测**（注释「不静默」仅在 debug
/// 成立）。
class ContradictionResult {
  const ContradictionResult(this.contradictions, {this.failed = false});

  /// 检测到的矛盾标记（[failed] 时为空）。
  final List<Contradiction> contradictions;

  /// 引擎是否异常兜底。true → UI 展示「推理引擎暂不可用」。
  final bool failed;
}

/// 当前对局的矛盾标记流（issue #38）。
final contradictionsProvider = Provider.family<ContradictionResult, int>(
  (ref, gameId) {
    return detectWithOverlay(
      claims: ref.watch(gameClaimsProvider(gameId)).valueOrNull ?? [],
      declarations:
          ref.watch(gameAllDeclarationsProvider(gameId)).valueOrNull ?? [],
      days: ref.watch(gameAllDaysProvider(gameId)).valueOrNull ?? [],
      players: ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [],
      game: ref.watch(gameByIdProvider(gameId)).valueOrNull,
    );
  },
);

/// 沙箱假设下的本地矛盾试算（仅依赖链页，#211 Part2 方案3）。
///
/// 把依赖链页的「假设 X 醉」并入疑似醉 overlay 后重算——验证「假设 X 醉
/// 则哪些矛盾消失」。**不并入 [contradictionsProvider]**：后者被主界面
/// 整局常驻 watch，合并会让 autoDispose 沙箱永不释放、假设污染主界面
/// 角标整局。空假设短路返回空（页面据此隐藏卡片）。
final sandboxContradictionsProvider =
    Provider.family<ContradictionResult, int>((ref, gameId) {
  final sandbox = ref.watch(dependencySandboxProvider(gameId));
  if (sandbox.isEmpty) return const ContradictionResult([]);
  return detectWithOverlay(
    claims: ref.watch(gameClaimsProvider(gameId)).valueOrNull ?? [],
    declarations:
        ref.watch(gameAllDeclarationsProvider(gameId)).valueOrNull ?? [],
    days: ref.watch(gameAllDaysProvider(gameId)).valueOrNull ?? [],
    players: ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [],
    game: ref.watch(gameByIdProvider(gameId)).valueOrNull,
    extraDrunkIds: sandbox,
  );
});

/// 矛盾检测共享计算：持久「疑似醉汉」（#109）∪ [extraDrunkIds]（沙箱假设）
/// overlay 到声明 reliability 后交给 [ContradictionDetector.detect]。
///
/// 异常兜底同 #164 B5 / #211：返回 failed=true 让 UI 展示降级提示，
/// 绝不无信号返回空成功。
ContradictionResult detectWithOverlay({
  required List<RoleClaim> claims,
  required List<InfoDeclaration> declarations,
  required List<DayRecord> days,
  required List<Player> players,
  required Game? game,
  Set<int> extraDrunkIds = const {},
}) {
  try {
    final setup = game != null ? PlayerSetup.forCount(game.playerCount) : null;
    final expectedOutsiders = setup?.outsiders ?? 0;

    // 整局「疑似醉汉」overlay（#109）：被疑醉玩家的声明 reliability 实时降级，
    // 再交给 detect()。按天的毒已在存档 reliability 中（#122）。沙箱假设
    // （#211 Part2）以同一通道并入——醉=毒=信息可能为假（公理4）。
    final playersById = {for (final p in players) p.id: p};
    final effectiveDeclarations = [
      for (final d in declarations)
        d.copyWith(
          reliability: effectiveReliability(
            d.reliability,
            (playersById[d.playerId]?.suspectedDrunk ?? false) ||
                extraDrunkIds.contains(d.playerId),
          ),
        ),
    ];

    return ContradictionResult(
      ContradictionDetector.detect(
        claims: claims,
        declarations: effectiveDeclarations,
        days: days,
        playersById: playersById,
        dayRecordToDayNumber: {for (final d in days) d.id: d.dayNumber},
        expectedOutsiders: expectedOutsiders,
        setup: setup,
        script: game?.script ?? Script.troubleBrewing,
        demonBluffs: game != null ? demonBluffsOf(game) : const {},
        myPlayerId: game?.myPlayerId,
        myRole: game?.myRole,
      ),
    );
  } on Object catch (e, st) {
    // 兜底：损坏数据不应让同步 Provider 抛异常致界面红屏（#164 B5）。
    // #211：release 下 debugPrint 是 no-op，原先返回空 [] 等于无信号关闭全部
    // 检测；现返回 failed=true 让 UI 展示降级横幅。debugPrint 仍保留 debug 诊断。
    if (kDebugMode) {
      debugPrint('矛盾检测兜底捕获异常: $e\n$st');
    }
    return const ContradictionResult([], failed: true);
  }
}
