import 'package:botc_copilot/shared/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';

/// 每日事件流时间线（占位）。
///
/// 完整实现由 issue #8 完成。
class TimelinePage extends StatelessWidget {
  /// 创建占位页。
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(title: '时间线');
  }
}
