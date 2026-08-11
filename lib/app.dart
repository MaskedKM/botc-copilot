import 'package:botc_copilot/core/router.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 根 Widget：MaterialApp.router + 暗色哥特主题 + go_router。
class BotcApp extends StatefulWidget {
  /// 创建根 Widget。
  const BotcApp({super.key});

  @override
  State<BotcApp> createState() => _BotcAppState();
}

class _BotcAppState extends State<BotcApp> {
  // 路由实例随 app 生命周期只建一次（重建不重置导航状态）。
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BotC Copilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
