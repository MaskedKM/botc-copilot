import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/shared/widgets/loading_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// #138：加载占位 = spinner + 文案（替代裸转圈）。
  testWidgets('LoadingView 渲染 spinner + 文案', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: LoadingView(message: '正在分析投票')),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在分析投票'), findsOneWidget);
  });

  /// #138：错误占位 = 图标 + 文案 + 重试，点重试触发回调。
  testWidgets('ErrorRetryView 渲染重试按钮并触发回调', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ErrorRetryView(
            message: '出错了',
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('出错了'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(retries, 1);
  });

  /// onRetry 为 null 时不显示重试按钮。
  testWidgets('ErrorRetryView 无 onRetry 时不渲染按钮', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: ErrorRetryView()),
      ),
    );
    expect(find.text('重试'), findsNothing);
  });
}
