import 'package:botc_copilot/core/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// #138：推理子页入路由表——路径助手生成正确的声明式路由路径。
  test('推理子页路由路径（#138）', () {
    expect(AppRoutes.roleMatrix(3), '/game/3/role-matrix');
    expect(AppRoutes.votingAnalysis(3), '/game/3/voting-analysis');
    expect(AppRoutes.dependencyChain(3), '/game/3/dependency-chain');
    // 既有路径不回归。
    expect(AppRoutes.gameBoard(3), '/game/3');
    expect(AppRoutes.timeline(3), '/game/3/timeline');
  });
}
