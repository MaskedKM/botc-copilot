import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 相对亮度。
double _luminance(Color c) => c.computeLuminance();

/// WCAG 对比度。
double _contrast(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppTheme.dark', () {
    test('挂载 GameColors 扩展', () {
      final theme = AppTheme.dark;
      expect(theme.extension<GameColors>(), isNotNull);
    });

    test('scaffold 底色与主色符合 UI-STYLE token', () {
      final theme = AppTheme.dark;
      expect(theme.scaffoldBackgroundColor, AppColors.bgBase);
      expect(theme.colorScheme.primary, AppColors.goldPrimary);
      expect(theme.colorScheme.error, AppColors.blood);
    });
  });

  group('GameColors 语义映射', () {
    const colors = GameColors.dark;

    test('信任度五色映射', () {
      expect(
        colors.ofTrustLevel(TrustLevel.confirmedGood),
        AppColors.trustConfirmedGood,
      );
      expect(
        colors.ofTrustLevel(TrustLevel.demonCandidate),
        AppColors.trustDemonCandidate,
      );
      expect(colors.ofTrustLevel(TrustLevel.unknown), AppColors.trustUnknown);
    });

    test('信息可靠性四色映射', () {
      expect(
        colors.ofReliability(Reliability.verified),
        AppColors.reliabilityVerified,
      );
      expect(
        colors.ofReliability(Reliability.possiblyTainted),
        AppColors.reliabilityTainted,
      );
    });
  });

  group('对比度（WCAG AA 正文 ≥ 4.5:1）', () {
    test('主文字 / 各层底色', () {
      for (final bg in [
        AppColors.bgBase,
        AppColors.bgSurface1,
        AppColors.bgSurface2,
        AppColors.bgSurface3,
      ]) {
        expect(
          _contrast(AppColors.textPrimary, bg),
          greaterThanOrEqualTo(4.5),
          reason: 'textPrimary 在 $bg 上对比度不足',
        );
      }
    });

    test('次要文字 / 最浅面板', () {
      expect(
        _contrast(AppColors.textSecondary, AppColors.bgSurface3),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('金底深字（按钮）', () {
      expect(
        _contrast(AppColors.textOnGold, AppColors.goldPrimary),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}
