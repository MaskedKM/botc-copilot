import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:flutter/material.dart';

/// 暗色哥特主题（docs/UI-STYLE.md 的 ThemeData 落地）。
///
/// 层级表达用明度阶梯（bgBase → surface1/2/3），不用投影堆叠。
/// 字体文件（Noto Serif/Sans SC）打包后仅需改 AppTextStyles 的族名常量。
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
      textTheme: AppTextStyles.textTheme,
      extensions: const [GameColors.dark],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.title,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.bgSurface1,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.lineHairline, width: 0.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.goldPrimary,
          foregroundColor: AppColors.textOnGold,
          textStyle: AppTextStyles.label,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldBright,
          textStyle: AppTextStyles.label,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: AppColors.lineHairline),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldBright,
          textStyle: AppTextStyles.label,
          minimumSize: const Size(48, 48),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.bgSurface3,
        titleTextStyle: AppTextStyles.title,
        contentTextStyle: AppTextStyles.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
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
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.bgSurface1,
        indicatorColor: AppColors.bgSurface3,
        labelTextStyle: WidgetStatePropertyAll(AppTextStyles.label),
      ),
      tabBarTheme: const TabBarThemeData(
        labelStyle: AppTextStyles.label,
        unselectedLabelStyle: AppTextStyles.label,
        labelColor: AppColors.goldBright,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.goldPrimary,
        dividerColor: AppColors.lineHairline,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface1,
        labelStyle: AppTextStyles.label,
        hintStyle: TextStyle(color: AppColors.textDisabled),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.lineHairline, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.lineHairline, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.goldPrimary),
        ),
      ),
    );
  }

  /// 破坏性操作按钮样式（死亡/处决/删除，需配合二次确认）。
  ///
  /// 用法：`OutlinedButton(style: AppTheme.dangerButtonStyle, ...)`
  static ButtonStyle get dangerButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: AppColors.bloodBright,
        textStyle: AppTextStyles.label,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: AppColors.blood, width: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      );
}
