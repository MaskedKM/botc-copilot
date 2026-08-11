import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 字体排印刻度（docs/UI-STYLE.md §三）。
///
/// - 展示体（serif）：仅 display/title 级与仪式感数字
/// - 正文/操作体（sans）：一切正文、按钮、表单、列表
/// 字体文件（Noto Serif SC / Noto Sans SC）打包进 assets 前，
/// 先以系统 serif/sans-serif 兜底，接入后只需改 family 常量。
abstract final class AppTextStyles {
  /// 展示体（衬线）族名：思源宋体，可变字重单文件。
  static const String displayFamily = 'NotoSerifSC';

  /// 正文/操作体（无衬线）族名：思源黑体，可变字重单文件。
  static const String bodyFamily = 'NotoSansSC';

  /// 28/36 Serif Bold —— 页面主标题（每屏至多一处）。
  static const TextStyle display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 20/28 Serif SemiBold —— 卡片标题、天数标题、角色名。
  static const TextStyle title = TextStyle(
    fontFamily: displayFamily,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// 17/24 Sans Medium —— 分组标题、面板标题。
  static const TextStyle headline = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// 15/22 Sans Regular —— 正文、记录内容。
  static const TextStyle body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// 13/18 Sans Medium —— 按钮、Tab、表单标签。
  static const TextStyle label = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// 11/16 Sans Regular —— 辅助说明、时间戳（字号下限）。
  static const TextStyle caption = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// 映射到 Material TextTheme（保持平台组件语义）。
  static TextTheme get textTheme => const TextTheme(
        displaySmall: display,
        titleLarge: title,
        titleMedium: headline,
        bodyMedium: body,
        labelLarge: label,
        bodySmall: caption,
      );
}
