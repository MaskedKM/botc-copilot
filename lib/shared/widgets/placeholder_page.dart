import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 骨架期占位页：暗色底 + 居中标题。
///
/// 仅用于路由骨架验证，各 feature 实现后逐个删除引用。
class PlaceholderPage extends StatelessWidget {
  /// 创建占位页。
  const PlaceholderPage({required this.title, super.key});

  /// 页面标题。
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            height: 36 / 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
