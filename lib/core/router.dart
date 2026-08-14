import 'package:botc_copilot/feature/game_board/presentation/game_board_page.dart';
import 'package:botc_copilot/feature/home/presentation/home_page.dart';
import 'package:botc_copilot/feature/reasoning/presentation/dependency_chain_page.dart';
import 'package:botc_copilot/feature/reasoning/presentation/role_matrix_page.dart';
import 'package:botc_copilot/feature/reasoning/presentation/voting_analysis_page.dart';
import 'package:botc_copilot/feature/setup/presentation/setup_wizard_page.dart';
import 'package:botc_copilot/feature/timeline/presentation/timeline_page.dart';
import 'package:go_router/go_router.dart';

/// 路由路径常量。
abstract final class AppRoutes {
  /// 首页：对局存档列表。
  static const String home = '/';

  /// 开局设置（选剧本 → 人数 → 排座位 → 选角色）。
  static const String setup = '/setup';

  /// 对局主界面（座位圆环 + 当日面板），携带对局 id。
  static String gameBoard(int gameId) => '/game/$gameId';

  /// 每日事件流时间线，携带对局 id。
  static String timeline(int gameId) => '/game/$gameId/timeline';

  /// 角色声明矩阵，携带对局 id（#138 入路由表）。
  static String roleMatrix(int gameId) => '/game/$gameId/role-matrix';

  /// 投票模式分析，携带对局 id（#138 入路由表）。
  static String votingAnalysis(int gameId) => '/game/$gameId/voting-analysis';

  /// 信息依赖链，携带对局 id（#138 入路由表）。
  static String dependencyChain(int gameId) => '/game/$gameId/dependency-chain';
}

/// 创建全局路由。
///
/// 注意：GoRouter 持有内部导航状态，跨测试共享单例会导致串扰，
/// 因此用工厂函数——app 启动与每个 test 各建实例。
GoRouter createAppRouter() => GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.setup,
      builder: (context, state) => const SetupWizardPage(),
    ),
    GoRoute(
      path: '/game/:id',
      builder: (context, state) {
        final gameId = int.parse(state.pathParameters['id']!);
        return GameBoardPage(gameId: gameId);
      },
    ),
    GoRoute(
      path: '/game/:id/timeline',
      builder: (context, state) {
        final gameId = int.parse(state.pathParameters['id']!);
        return TimelinePage(gameId: gameId);
      },
    ),
    GoRoute(
      path: '/game/:id/role-matrix',
      builder: (context, state) {
        final gameId = int.parse(state.pathParameters['id']!);
        return RoleMatrixPage(gameId: gameId);
      },
    ),
    GoRoute(
      path: '/game/:id/voting-analysis',
      builder: (context, state) {
        final gameId = int.parse(state.pathParameters['id']!);
        return VotingAnalysisPage(gameId: gameId);
      },
    ),
    GoRoute(
      path: '/game/:id/dependency-chain',
      builder: (context, state) {
        final gameId = int.parse(state.pathParameters['id']!);
        return DependencyChainPage(gameId: gameId);
      },
    ),
  ],
);
