import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/feature/game_board/domain/seat_ring_layout.dart';
import 'package:botc_copilot/feature/game_board/domain/seat_ring_player.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/seat_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

List<SeatRingPlayer> makePlayers(int count) => [
      for (var i = 0; i < count; i++)
        SeatRingPlayer(
          id: i + 1,
          name: '玩家${i + 1}',
          seatNumber: i + 1,
          isAlive: true,
          isMe: i == 0,
        ),
    ];

void main() {
  Widget buildRing({
    required List<SeatRingPlayer> players,
    ValueChanged<int>? onTap,
    ValueChanged<int>? onLongPress,
    int? selectedPlayerId,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: SeatRing(
              players: players,
              onPlayerTap: onTap,
              onPlayerLongPress: onLongPress,
              selectedPlayerId: selectedPlayerId,
            ),
          ),
        ),
      ),
    );
  }

  group('SeatRing widget', () {
    testWidgets('5-15 人都能渲染', (tester) async {
      for (var n = 5; n <= 15; n++) {
        await tester.pumpWidget(buildRing(players: makePlayers(n)));
        await tester.pumpAndSettle();
        expect(find.byType(SeatRing), findsOneWidget);
      }
    });

    testWidgets('点击节点触发回调，点击空白不触发', (tester) async {
      int? tappedId;
      await tester.pumpWidget(
        buildRing(players: makePlayers(7), onTap: (id) => tappedId = id),
      );
      await tester.pumpAndSettle();

      final ringTopLeft = tester.getTopLeft(find.byType(SeatRing));
      // SeatRing 是 AspectRatio 1:1，宽 400 → 高 400
      final centers = SeatRingLayout.computeCenters(
        size: const Size(400, 400),
        count: 7,
      );

      // 点击 3 号位（index 2）
      await tester.tapAt(ringTopLeft + centers[2]);
      expect(tappedId, 3);

      // 点击圆心空白
      await tester.tapAt(ringTopLeft + const Offset(200, 200));
      expect(tappedId, 3); // 未变
    });

    testWidgets('长按节点触发长按回调', (tester) async {
      int? longPressedId;
      await tester.pumpWidget(
        buildRing(
          players: makePlayers(7),
          onLongPress: (id) => longPressedId = id,
        ),
      );
      await tester.pumpAndSettle();

      final ringTopLeft = tester.getTopLeft(find.byType(SeatRing));
      final centers = SeatRingLayout.computeCenters(
        size: const Size(400, 400),
        count: 7,
      );
      await tester.longPressAt(ringTopLeft + centers[4]);
      expect(longPressedId, 5);
    });

    testWidgets('死亡状态变化触发过渡动画', (tester) async {
      final players = makePlayers(7);
      await tester.pumpWidget(buildRing(players: players));
      await tester.pumpAndSettle();

      // 3 号死亡
      final updated = [
        for (final p in players)
          if (p.seatNumber == 3) p.copyWith(isAlive: false) else p,
      ];
      await tester.pumpWidget(buildRing(players: updated));
      // 动画启动（未到结束态）
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.byType(SeatRing), findsOneWidget);
    });

    testWidgets('选中玩家时渲染不报错（邻座高亮路径）', (tester) async {
      final players = makePlayers(7);
      await tester.pumpWidget(
        buildRing(players: players, selectedPlayerId: 1),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SeatRing), findsOneWidget);
    });
  });
}
