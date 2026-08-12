import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/setup_analysis_provider.dart';
import 'package:botc_copilot/feature/reasoning/presentation/reasoning_dashboard.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// widget test 用 provider override，不碰真实 DB（Learning：Drift stream
// 在 widget test 留 pending timer）。
Player _player(int id, int seat, String name, {bool alive = true}) => Player(
      id: id,
      gameId: 1,
      name: name,
      seatNumber: seat,
      isAlive: alive,
      abilityUsed: false,
      deathDay: alive ? null : 1,
      deathCause: alive ? null : DeathCause.nightKill,
    );

void main() {
  final players = [
    _player(1, 1, 'A'),
    _player(2, 2, 'B'),
    _player(3, 3, 'C'),
    _player(4, 4, 'D'),
    _player(5, 5, 'E'),
    _player(6, 6, 'F'),
    _player(7, 7, 'G'),
  ];

  Widget buildDashboard(Map<int, TrustLevel> trustLevels) {
    return ProviderScope(
      // key 携带 trustLevels 散列：Riverpod 的 overrides 只在 ProviderScope
      // 创建时读取，换 key 强制新建作用域让新值生效。
      key: ValueKey(Object.hashAll(trustLevels.entries)),
      overrides: [
        gamePlayersProvider.overrideWith(
          (ref, gameId) => Stream.value(players),
        ),
        latestTrustLevelsProvider.overrideWith(
          (ref, gameId) => Stream.value(trustLevels),
        ),
        // 配置分析面板（#59）不经真实 DB：返回 null → 面板 shrink。
        setupAnalysisProvider.overrideWith((ref, gameId) => null),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ReasoningDashboard(gameId: 1)),
      ),
    );
  }

  testWidgets('默认全部未知 → 恶魔候选池 = 全部存活玩家', (tester) async {
    await tester.pumpWidget(buildDashboard({}));
    await tester.pump();
    expect(find.text('恶魔候选池（未标记好人）'), findsOneWidget);
    expect(find.textContaining('共 7 人'), findsOneWidget);
  });

  testWidgets('标记确信好人后从候选池移除 + ≤2 高亮', (tester) async {
    final trust = {
      for (var i = 1; i <= 5; i++) i: TrustLevel.confirmedGood,
    };
    await tester.pumpWidget(buildDashboard(trust));
    await tester.pump();
    expect(find.textContaining('仅剩 2 人未标记'), findsOneWidget);
    expect(find.textContaining('值得重点推理'), findsOneWidget);
  });

  testWidgets('信任度分组显示', (tester) async {
    await tester.pumpWidget(buildDashboard({
      1: TrustLevel.confirmedGood,
      2: TrustLevel.suspect,
    }));
    await tester.pump();
    expect(find.textContaining('确信好人（1）'), findsOneWidget);
    expect(find.textContaining('嫌疑（1）'), findsOneWidget);
    expect(find.textContaining('未知（5）'), findsOneWidget);
  });

  testWidgets('死亡玩家不在恶魔候选池', (tester) async {
    final withDead = [...players]..[0] = _player(1, 1, 'A', alive: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamePlayersProvider.overrideWith(
            (ref, gameId) => Stream.value(withDead),
          ),
          latestTrustLevelsProvider.overrideWith(
            (ref, gameId) => Stream.value(const {}),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ReasoningDashboard(gameId: 1)),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('共 6 人'), findsOneWidget);
  });

  testWidgets('信任度调整后重建 → 面板立即更新', (tester) async {
    // 第一次：全未知
    await tester.pumpWidget(buildDashboard({}));
    await tester.pump();
    expect(find.textContaining('共 7 人'), findsOneWidget);

    // 重建（新 trust map）→ 面板立即更新
    await tester.pumpWidget(buildDashboard({1: TrustLevel.confirmedGood}));
    await tester.pump();
    expect(find.textContaining('共 6 人'), findsOneWidget);
    expect(find.textContaining('确信好人（1）'), findsOneWidget);
  });
}
