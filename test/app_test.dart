import 'package:botc_copilot/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App 启动显示开局设置占位页', (tester) async {
    await tester.pumpWidget(const BotcApp());
    expect(find.text('开局设置'), findsWidgets);
  });
}
