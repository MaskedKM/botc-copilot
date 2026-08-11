import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 暗色哥特主题（docs/UI-STYLE.md 的 ThemeData 落地）。
///
/// 字体计划：展示体 Noto Serif SC（标题/仪式感数字），
/// 正文 Noto Sans SC——字体文件随 #10 打包进 assets 后在此接入。
abstract final class AppTheme {
  /// 暗色主题（唯一必做方案）。
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.goldPrimary,
      onPrimary: AppColors.textOnGold,
      secondary: AppColors.goldBright,
      onSecondary: AppColors.textOnGold,
      surface: AppColors.bgSurface1,
      onSurface: AppColors.textPrimary,
      error: AppColors.blood,
      onError: AppColors.textPrimary,
      outline: AppColors.lineHairline,
      surfaceContainerHighest: AppColors.bgSurface3,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      dividerColor: AppColors.lineHairline,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.bgSurface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.lineHairline, width: 0.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.goldPrimary,
          foregroundColor: AppColors.textOnGold,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgSurface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.bgSurface3,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
