import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';

/// 游戏语义色 ThemeExtension（docs/UI-STYLE.md §2.4）。
///
/// 信任度 / 信息可靠性 / 阵营等功能色不走 ColorScheme
/// （它们是领域语义而非 Material 角色），统一从这里取。
/// 注意：UI 展示时必须同时配图形/文字记号，不单靠颜色（色弱友好）。
@immutable
class GameColors extends ThemeExtension<GameColors> {
  /// 创建游戏语义色板。
  const GameColors({
    required this.trustConfirmedGood,
    required this.trustLikelyGood,
    required this.trustUnknown,
    required this.trustSuspect,
    required this.trustDemonCandidate,
    required this.reliabilityVerified,
    required this.reliabilityUnverified,
    required this.reliabilityTainted,
    required this.reliabilityInvalidated,
    required this.blood,
    required this.inkViolet,
    required this.lineGold,
    required this.goldBright,
  });

  /// 确信好人（苔绿）。
  final Color trustConfirmedGood;

  /// 偏好（月白青）。
  final Color trustLikelyGood;

  /// 未知（石板灰紫）。
  final Color trustUnknown;

  /// 嫌疑（烬橙）。
  final Color trustSuspect;

  /// 恶魔候选（血红）。
  final Color trustDemonCandidate;

  /// 信息已验证。
  final Color reliabilityVerified;

  /// 信息待验证。
  final Color reliabilityUnverified;

  /// 信息可能醉/毒。
  final Color reliabilityTainted;

  /// 信息已失效。
  final Color reliabilityInvalidated;

  /// 邪恶/死亡/危险（血红）。
  final Color blood;

  /// 次要信息、未激活态。
  final Color inkViolet;

  /// 仪式感金色分隔线。
  final Color lineGold;

  /// 高光金（钟针、当前天数、聚焦态）。
  final Color goldBright;

  /// 暗色主题实例（当前唯一方案）。
  static const GameColors dark = GameColors(
    trustConfirmedGood: AppColors.trustConfirmedGood,
    trustLikelyGood: AppColors.trustLikelyGood,
    trustUnknown: AppColors.trustUnknown,
    trustSuspect: AppColors.trustSuspect,
    trustDemonCandidate: AppColors.trustDemonCandidate,
    reliabilityVerified: AppColors.reliabilityVerified,
    reliabilityUnverified: AppColors.reliabilityUnverified,
    reliabilityTainted: AppColors.reliabilityTainted,
    reliabilityInvalidated: AppColors.reliabilityInvalidated,
    blood: AppColors.blood,
    inkViolet: AppColors.inkViolet,
    lineGold: AppColors.lineGold,
    goldBright: AppColors.goldBright,
  );

  /// 信任度枚举 → 颜色。
  Color ofTrustLevel(TrustLevel level) => switch (level) {
        TrustLevel.confirmedGood => trustConfirmedGood,
        TrustLevel.likelyGood => trustLikelyGood,
        TrustLevel.unknown => trustUnknown,
        TrustLevel.suspect => trustSuspect,
        TrustLevel.demonCandidate => trustDemonCandidate,
      };

  /// 信息可靠性枚举 → 颜色。
  Color ofReliability(Reliability reliability) => switch (reliability) {
        Reliability.verified => reliabilityVerified,
        Reliability.unverified => reliabilityUnverified,
        Reliability.possiblyTainted => reliabilityTainted,
        Reliability.invalidated => reliabilityInvalidated,
      };

  @override
  GameColors copyWith({
    Color? trustConfirmedGood,
    Color? trustLikelyGood,
    Color? trustUnknown,
    Color? trustSuspect,
    Color? trustDemonCandidate,
    Color? reliabilityVerified,
    Color? reliabilityUnverified,
    Color? reliabilityTainted,
    Color? reliabilityInvalidated,
    Color? blood,
    Color? inkViolet,
    Color? lineGold,
    Color? goldBright,
  }) {
    return GameColors(
      trustConfirmedGood: trustConfirmedGood ?? this.trustConfirmedGood,
      trustLikelyGood: trustLikelyGood ?? this.trustLikelyGood,
      trustUnknown: trustUnknown ?? this.trustUnknown,
      trustSuspect: trustSuspect ?? this.trustSuspect,
      trustDemonCandidate: trustDemonCandidate ?? this.trustDemonCandidate,
      reliabilityVerified: reliabilityVerified ?? this.reliabilityVerified,
      reliabilityUnverified:
          reliabilityUnverified ?? this.reliabilityUnverified,
      reliabilityTainted: reliabilityTainted ?? this.reliabilityTainted,
      reliabilityInvalidated:
          reliabilityInvalidated ?? this.reliabilityInvalidated,
      blood: blood ?? this.blood,
      inkViolet: inkViolet ?? this.inkViolet,
      lineGold: lineGold ?? this.lineGold,
      goldBright: goldBright ?? this.goldBright,
    );
  }

  @override
  GameColors lerp(ThemeExtension<GameColors>? other, double t) {
    if (other is! GameColors) return this;
    return GameColors(
      trustConfirmedGood:
          Color.lerp(trustConfirmedGood, other.trustConfirmedGood, t)!,
      trustLikelyGood:
          Color.lerp(trustLikelyGood, other.trustLikelyGood, t)!,
      trustUnknown: Color.lerp(trustUnknown, other.trustUnknown, t)!,
      trustSuspect: Color.lerp(trustSuspect, other.trustSuspect, t)!,
      trustDemonCandidate:
          Color.lerp(trustDemonCandidate, other.trustDemonCandidate, t)!,
      reliabilityVerified:
          Color.lerp(reliabilityVerified, other.reliabilityVerified, t)!,
      reliabilityUnverified:
          Color.lerp(reliabilityUnverified, other.reliabilityUnverified, t)!,
      reliabilityTainted:
          Color.lerp(reliabilityTainted, other.reliabilityTainted, t)!,
      reliabilityInvalidated:
          Color.lerp(reliabilityInvalidated, other.reliabilityInvalidated, t)!,
      blood: Color.lerp(blood, other.blood, t)!,
      inkViolet: Color.lerp(inkViolet, other.inkViolet, t)!,
      lineGold: Color.lerp(lineGold, other.lineGold, t)!,
      goldBright: Color.lerp(goldBright, other.goldBright, t)!,
    );
  }
}

/// 便捷访问：`context.gameColors`。
extension GameColorsContext on BuildContext {
  /// 当前主题的游戏语义色板。
  GameColors get gameColors =>
      Theme.of(this).extension<GameColors>() ?? GameColors.dark;
}
