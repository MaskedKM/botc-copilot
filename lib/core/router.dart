import 'package:botc_copilot/feature/game_board/presentation/game_board_page.dart';
import 'package:botc_copilot/feature/setup/presentation/setup_wizard_page.dart';
import 'package:botc_copilot/feature/timeline/presentation/timeline_page.dart';
import 'package:go_router/go_router.dart';

/// 路由路径常量。
abstract final class AppRoutes {
  /// 开局设置（选剧本 → 人数 → 排座位 → 选角色）。
  static const String setup = '/setup';

  /// 对局主界面（座位圆环 + 当日面板）。
  static const String gameBoard = '/game';

  /// 每日事件流时间线。
  static const String timeline = '/timeline';
}

/// 全局路由骨架。各 feature 页面当前为占位实现，
/// 随对应 issue（#4 / #6 / #8）替换。
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.setup,
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => AppRoutes.setup,
    ),
    GoRoute(
      path: AppRoutes.setup,
      builder: (context, state) => const SetupWizardPage(),
    ),
    GoRoute(
      path: AppRoutes.gameBoard,
      builder: (context, state) => const GameBoardPage(),
    ),
    GoRoute(
      path: AppRoutes.timeline,
      builder: (context, state) => const TimelinePage(),
    ),
  ],
);
