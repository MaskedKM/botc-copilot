import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/outsider_analysis.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 外来者计数分析流（issue #59）。
///
/// 组合 game（人数 / myRole）+ claims（最新声明）。声明变化即重算，
/// 驱动 [SetupAnalysisPanel] 实时展示「配置 vs 声明」对比与偏差解读。
final setupAnalysisProvider =
    Provider.family<OutsiderCountAnalysis?, int>((ref, gameId) {
  final game = ref.watch(gameByIdProvider(gameId)).valueOrNull;
  final claims = ref.watch(gameClaimsProvider(gameId)).valueOrNull ?? [];
  if (game == null) return null; // 游戏未加载
  return analyzeOutsiderCount(
    playerCount: game.playerCount,
    claims: claims,
    myRole: game.myRole,
    myPlayerId: game.myPlayerId,
  );
});
