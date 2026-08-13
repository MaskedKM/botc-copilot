import 'dart:math' as math;

import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 相对亮度。
double _luminance(Color c) {
  double channel(double s) {
    return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  // c.r/g/b 为 0.0-1.0 浮点通道值。
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

/// WCAG 对比度（1.0-21.0）。
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('对比度 AA（#135）', () {
    test('bloodBright 对 bgSurface1 ≥ 4.5（正文 AA）', () {
      expect(
        contrast(AppColors.bloodBright, AppColors.bgSurface1),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('bloodBright 对 bgBase ≥ 4.5', () {
      expect(
        contrast(AppColors.bloodBright, AppColors.bgBase),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('blood（原色）低于 AA 正文，故需 bloodBright 变体', () {
      // 佐证为何要单独的文字变体
      expect(
        contrast(AppColors.blood, AppColors.bgSurface1),
        lessThan(4.5),
      );
    });

    test('textPrimary@45% 对 bgSurface1 仍可读（≥ 3，死亡弱化态）', () {
      final dim = AppColors.textPrimary.withValues(alpha: 0.45);
      // alpha 合成到底色后的实际颜色
      final blended = Color.alphaBlend(dim, AppColors.bgSurface1);
      expect(
        contrast(blended, AppColors.bgSurface1),
        greaterThanOrEqualTo(3),
      );
    });
  });
}
