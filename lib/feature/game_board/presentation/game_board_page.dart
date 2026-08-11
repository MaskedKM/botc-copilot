import 'package:botc_copilot/shared/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';

/// 对局主界面（占位）：座位圆环 + 当日面板。
///
/// 座位圆环 CustomPainter 由 issue #5 实现，主界面组装由 issue #6 实现。
class GameBoardPage extends StatelessWidget {
  /// 创建占位页。
  const GameBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(title: '对局');
  }
}
