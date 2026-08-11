import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/shared/widgets/help_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTooltip(HelpLevel level) {
    return MaterialApp(
      home: Scaffold(
        body: HelpTooltip(level: level, text: '测试规则提示内容'),
      ),
    );
  }

  testWidgets('beginner：内容直接展开可见', (tester) async {
    await tester.pumpWidget(buildTooltip(HelpLevel.beginner));
    expect(find.text('测试规则提示内容'), findsOneWidget);
    // 无折叠入口
    expect(find.text('规则提示'), findsNothing);
  });

  testWidgets('normal：折叠为「规则提示」，点开后可见', (tester) async {
    await tester.pumpWidget(buildTooltip(HelpLevel.normal));
    // 折叠态：只显示标题
    expect(find.text('规则提示'), findsOneWidget);
    expect(find.text('测试规则提示内容'), findsNothing);

    // 点开
    await tester.tap(find.text('规则提示'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('测试规则提示内容'), findsOneWidget);
  });

  testWidgets('expert：零干扰，什么都不渲染', (tester) async {
    await tester.pumpWidget(buildTooltip(HelpLevel.expert));
    expect(find.text('测试规则提示内容'), findsNothing);
    expect(find.text('规则提示'), findsNothing);
  });
}
