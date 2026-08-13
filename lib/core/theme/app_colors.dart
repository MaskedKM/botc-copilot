import 'package:flutter/material.dart';

/// 暗色哥特主题色板（docs/UI-STYLE.md 的唯一代码落地处）。
///
/// 所有组件只允许引用这里的 token，禁止硬编码 hex。
abstract final class AppColors {
  // ── 基础底色 ─────────────────────────────────────────────
  /// 屏幕最底层（"皮质封面"）。
  static const Color bgBase = Color(0xFF0D0B1A);

  /// 卡片、面板。
  static const Color bgSurface1 = Color(0xFF151226);

  /// 抬升面板、底部弹层。
  static const Color bgSurface2 = Color(0xFF1D1936);

  /// 最高层（模态、选中态底色）。
  static const Color bgSurface3 = Color(0xFF262048);

  // ── 描边 / 分隔线 ─────────────────────────────────────────
  /// 默认分隔线。
  static const Color lineHairline = Color(0xFF3A3462);

  /// 仪式感分隔线（标题下、日夜切换条），烛光金 40% 透明度。
  static const Color lineGold = Color(0x66C9A24B);

  // ── 品牌 / 功能色 ─────────────────────────────────────────
  /// 主操作、当前选中、钟面刻度、"我"的座位标记。
  static const Color goldPrimary = Color(0xFFC9A24B);

  /// 高光：钟针、当前天数、聚焦态。
  static const Color goldBright = Color(0xFFE4CC85);

  /// 邪恶阵营、死亡、处决、危险操作、矛盾警告（填充/图标/边框/大字）。
  static const Color blood = Color(0xFFB84A55);

  /// blood 的提亮文字变体（AA 对比度 ~4.7:1，小号正文/标题/caption 用，#135）。
  static const Color bloodBright = Color(0xFFD45A66);

  /// 次要信息、未激活态。
  static const Color inkViolet = Color(0xFF8E86B8);

  // ── 信任度（TrustLevel）───────────────────────────────────
  /// 确信好人（苔绿）。
  static const Color trustConfirmedGood = Color(0xFF57A773);

  /// 偏好（月白青）。
  static const Color trustLikelyGood = Color(0xFF8FB8A8);

  /// 未知（石板灰紫）。
  static const Color trustUnknown = Color(0xFF7E7A99);

  /// 嫌疑（烬橙）。
  static const Color trustSuspect = Color(0xFFD0874A);

  /// 恶魔候选（血红）。
  static const Color trustDemonCandidate = blood;

  // ── 信息可靠性（Reliability）───────────────────────────────
  /// 已验证。
  static const Color reliabilityVerified = trustConfirmedGood;

  /// 待验证。
  static const Color reliabilityUnverified = inkViolet;

  /// 可能醉/毒。
  static const Color reliabilityTainted = trustSuspect;

  /// 已失效。
  static const Color reliabilityInvalidated = Color(0xFF4A4468);

  // ── 文字 ─────────────────────────────────────────────────
  /// 羊皮纸白，主文字。
  static const Color textPrimary = Color(0xFFEDE6D6);

  /// 次要文字。
  static const Color textSecondary = Color(0xFFA79FC4);

  /// 禁用态文字。
  static const Color textDisabled = Color(0xFF5C5680);

  /// 金底上的深墨字。
  static const Color textOnGold = Color(0xFF1A1426);
}
