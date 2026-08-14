import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/feature/game_board/presentation/game_board_page.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/seat_ring.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final game = Game(
    id: 1,
    script: Script.troubleBrewing,
    playerCount: 7,
    status: GameStatus.ongoing,
    createdAt: DateTime(2026, 8, 12),
    helpLevel: HelpLevel.normal,
    myRole: Character.empath,
  );

  final players = [
    for (var i = 1; i <= 7; i++)
      Player(
        id: i,
        gameId: 1,
        name: '玩家$i',
        seatNumber: i,
        isAlive: i != 3, // 3 号已死亡
        abilityUsed: false, suspectedDrunk: false,
        fakeDead: false,
        deathDay: i == 3 ? 1 : null,
        deathCause: i == 3 ? DeathCause.nightKill : null,
      ),
  ];

  /// 用 provider override 提供假数据（widget test 不碰真实数据库）。
  Widget buildBoard() {
    return ProviderScope(
      overrides: [
        gameByIdProvider(1).overrideWith((ref) => Stream.value(game)),
        gamePlayersProvider(1).overrideWith((ref) => Stream.value(players)),
        // 跳过 restoreState 的 DB IO（widget test 不碰真实 DB，#154 ISSUE-3）。
        gameBoardProvider(1)
            .overrideWith((ref) => _FakeGameBoardNotifier(ref, 1)),
        latestTrustLevelsProvider(1)
            .overrideWith((ref) => Stream.value(const <int, TrustLevel>{})),
        currentDayRecordProvider((1, 1))
            .overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const GameBoardPage(gameId: 1),
      ),
    );
  }

  testWidgets('渲染：圆环 + 天数 + 存活人数 + 当日三 Tab + 底部推理 tab', (tester) async {
    await tester.pumpWidget(buildBoard());
    await tester.pumpAndSettle();

    expect(find.byType(SeatRing), findsOneWidget);
    expect(find.text('第 1 天'), findsWidgets); // AppBar + 圆环中心
    expect(find.text('暗流涌动 · 存活 6/7 人'), findsOneWidget);
    expect(find.text('夜晚'), findsOneWidget);
    expect(find.text('白天'), findsOneWidget);
    expect(find.text('投票'), findsOneWidget);
    expect(find.text('推理'), findsOneWidget);
  });

  testWidgets('白天 Tab：处决面板可见', (tester) async {
    await tester.pumpWidget(buildBoard());
    await tester.pumpAndSettle();

    await tester.tap(find.text('白天'));
    await tester.pumpAndSettle();

    expect(find.text('第 1 天 · 白天处决'), findsOneWidget);
    expect(find.text('无处决'), findsOneWidget);
    // 死亡玩家不在候选里
    expect(find.text('3号 玩家3'), findsNothing);
    expect(find.text('1号 玩家1'), findsOneWidget);
  });

  testWidgets('对局不存在时显示提示', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameByIdProvider(99).overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const GameBoardPage(gameId: 99),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('对局不存在或已删除'), findsOneWidget);
  });
}

/// 跳过 restoreState 的 DB IO（widget test 不碰真实 DB，#154 ISSUE-3）。
class _FakeGameBoardNotifier extends GameBoardNotifier {
  _FakeGameBoardNotifier(super.ref, super.gameId);

  @override
  Future<void> restoreState() async {
    state = state.copyWith(initialized: true);
  }
}
