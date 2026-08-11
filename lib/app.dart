import 'package:botc_copilot/core/router.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 根 Widget：MaterialApp.router + 暗色哥特主题 + go_router。
class BotcApp extends StatelessWidget {
  /// 创建根 Widget。
  const BotcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BotC Copilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
