import 'package:botc_copilot/shared/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';

/// 开局设置流程页（占位）。
///
/// 完整流程（选剧本 → 人数 → 排座位 → 选角色）由 issue #4 实现。
class SetupPage extends StatelessWidget {
  /// 创建占位页。
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(title: '开局设置');
  }
}
