import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/home/presentation/home_page.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final games = [
    Game(
      id: 1,
      script: Script.troubleBrewing,
      playerCount: 7,
      status: GameStatus.ongoing,
      createdAt: DateTime(2026, 8, 12, 20, 30),
      helpLevel: HelpLevel.normal,
      myRole: Character.empath,
    ),
    Game(
      id: 2,
      script: Script.troubleBrewing,
      playerCount: 12,
      status: GameStatus.goodWin,
      createdAt: DateTime(2026, 8, 10, 15),
      helpLevel: HelpLevel.normal,
    ),
  ];

  Widget buildHome({List<Game> items = const []}) {
    return ProviderScope(
      overrides: [
        allGamesProvider.overrideWith((ref) => Stream.value(items)),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const HomePage()),
    );
  }

  testWidgets('空列表：引导文案 + 新建按钮', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();

    expect(find.text('还没有对局'), findsOneWidget);
    expect(find.text('新建对局'), findsOneWidget);
  });

  testWidgets('存档列表：剧本/人数/角色/状态徽章', (tester) async {
    await tester.pumpWidget(buildHome(items: games));
    await tester.pumpAndSettle();

    expect(find.text('暗流涌动 · 7 人局'), findsOneWidget);
    expect(find.text('暗流涌动 · 12 人局'), findsOneWidget);
    expect(find.textContaining('我的角色：共情者'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);
    expect(find.text('善良获胜'), findsOneWidget);
  });

  testWidgets('滑动删除弹出确认框', (tester) async {
    await tester.pumpWidget(buildHome(items: games));
    await tester.pumpAndSettle();

    // fling 快速滑过 dismiss 阈值（drag 短距离不触发）
    await tester.fling(find.text('暗流涌动 · 7 人局'), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('删除对局'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
  });
}
