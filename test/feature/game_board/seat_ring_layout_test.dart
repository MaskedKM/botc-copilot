import 'dart:math' as math;

import 'package:botc_copilot/feature/game_board/domain/seat_ring_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeatRingLayout.computeCenters', () {
    const size = Size(400, 400);

    test('5-15 人都能计算，1 号位在 12 点方向', () {
      for (var n = 5; n <= 15; n++) {
        final centers = SeatRingLayout.computeCenters(size: size, count: n);
        expect(centers, hasLength(n));
        // 1 号位（index 0）：圆心正上方
        expect(centers[0].dx, closeTo(200, 0.01));
        expect(centers[0].dy, lessThan(200));
      }
    });

    test('所有节点等距分布在同一圆周上', () {
      final centers = SeatRingLayout.computeCenters(size: size, count: 7);
      const center = Offset(200, 200);
      final r = (centers[0] - center).distance;
      for (final c in centers) {
        expect((c - center).distance, closeTo(r, 0.01));
      }
      // 相邻夹角 = 360/7
      final angle1 = (centers[1] - center).direction;
      final angle0 = (centers[0] - center).direction;
      var diff = angle1 - angle0;
      if (diff < 0) diff += 2 * math.pi;
      expect(diff, closeTo(2 * math.pi / 7, 0.01));
    });

    test('顺时针：2 号位在 1 号位右侧（顺时针方向）', () {
      final centers = SeatRingLayout.computeCenters(size: size, count: 8);
      // 8 人：1 号 12 点，2 号顺时针 45°（右上象限）
      expect(centers[1].dx, greaterThan(200));
      expect(centers[1].dy, lessThan(200));
    });
  });

  group('SeatRingLayout.hitTest', () {
    test('命中节点返回索引，空白处返回 null', () {
      const size = Size(400, 400);
      final centers = SeatRingLayout.computeCenters(size: size, count: 7);

      expect(
        SeatRingLayout.hitTest(position: centers[3], centers: centers),
        3,
      );
      // 节点边缘内
      expect(
        SeatRingLayout.hitTest(
          position: centers[3] + const Offset(20, 0),
          centers: centers,
        ),
        3,
      );
      // 圆心（空白）
      expect(
        SeatRingLayout.hitTest(
          position: const Offset(200, 200),
          centers: centers,
        ),
        isNull,
      );
    });

    test('命中区重叠时返最近中心（#135，修恒判首个）', () {
      // 两中心都在 hitRadius(34) 内的重叠场景
      const centers = [Offset(100, 100), Offset(110, 100)];
      // 距 index1 更近 → 返 1（旧行为会返首个 0）
      expect(
        SeatRingLayout.hitTest(
          position: const Offset(108, 100),
          centers: centers,
        ),
        1,
      );
      // 距 index0 更近 → 返 0
      expect(
        SeatRingLayout.hitTest(
          position: const Offset(102, 100),
          centers: centers,
        ),
        0,
      );
    });
  });

  group('座位收缩（邻座计算跳过死亡）', () {
    test('nextAliveClockwise 跳过死亡玩家', () {
      // 7 人，3、4 号死亡（index 2、3）
      final alive = [true, true, false, false, true, true, true];
      // 2 号（index 1）的顺时针邻座 = 5 号（index 4）
      expect(SeatRingLayout.nextAliveClockwise(alive, 1), 4);
      // 5 号（index 4）的邻座 = 6 号（index 5）
      expect(SeatRingLayout.nextAliveClockwise(alive, 4), 5);
      // 7 号（index 6）的邻座绕回 = 1 号（index 0）
      expect(SeatRingLayout.nextAliveClockwise(alive, 6), 0);
    });

    test('nextAliveCounterClockwise 跳过死亡玩家', () {
      final alive = [true, true, false, false, true, true, true];
      // 5 号（index 4）的逆时针邻座 = 2 号（index 1）
      expect(SeatRingLayout.nextAliveCounterClockwise(alive, 4), 1);
    });

    test('只剩 1 人存活时返回自身', () {
      final alive = [false, false, false, true, false, false, false];
      expect(SeatRingLayout.nextAliveClockwise(alive, 3), 3);
    });
  });
}
