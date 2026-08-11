import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 座位圆环布局算法（纯数学，无 widget 依赖）。
///
/// 按 UI-STYLE.md：完整钟面（非马蹄形）——1 号位在 12 点方向，
/// 顺时针等分圆周，与真实钟楼钟面同构。
abstract final class SeatRingLayout {
  /// 玩家节点半径（直径 56dp，UI-STYLE §6.1）。
  static const double nodeRadius = 28;

  /// 节点外侧留白（信任度色环 + 描边）。
  static const double outerPadding = 6;

  /// 计算各座位节点的圆心坐标。
  ///
  /// [size] 为绘制区域（取短边为直径），返回长度 = [count] 的列表，
  /// 索引 i 对应座位号 i+1。
  static List<Offset> computeCenters({
    required Size size,
    required int count,
    double scale = 1.0,
  }) {
    assert(count >= 5 && count <= 15, '支持 5-15 人');
    final center = Offset(size.width / 2, size.height / 2);
    final ringRadius =
        (math.min(size.width, size.height) / 2 - nodeRadius - outerPadding) *
            scale;
    return List.generate(count, (i) {
      // 12 点方向为 -90°，顺时针递增。
      final angle = -math.pi / 2 + (2 * math.pi * i / count);
      return center +
          Offset(
            ringRadius * math.cos(angle),
            ringRadius * math.sin(angle),
          );
    });
  }

  /// 命中测试：返回被点中的座位索引（0-based），未命中返回 null。
  static int? hitTest({
    required Offset position,
    required List<Offset> centers,
    double scale = 1.0,
  }) {
    final hitRadius = (nodeRadius + outerPadding) * scale;
    for (var i = 0; i < centers.length; i++) {
      if ((position - centers[i]).distance <= hitRadius) return i;
    }
    return null;
  }

  /// 沿顺时针方向找 [fromIndex] 之后最近的存活座位索引。
  ///
  /// 实现"座位收缩"公理：死亡玩家从邻座计算中跳过。
  /// [alive] 长度 = 玩家数，索引 0 = 1 号位。
  static int nextAliveClockwise(List<bool> alive, int fromIndex) {
    assert(alive.any((a) => a), '至少一名存活');
    var i = fromIndex;
    do {
      i = (i + 1) % alive.length;
    } while (!alive[i]);
    return i;
  }

  /// 沿逆时针方向找 [fromIndex] 之前最近的存活座位索引。
  static int nextAliveCounterClockwise(List<bool> alive, int fromIndex) {
    assert(alive.any((a) => a), '至少一名存活');
    var i = fromIndex;
    do {
      i = (i - 1 + alive.length) % alive.length;
    } while (!alive[i]);
    return i;
  }
}
