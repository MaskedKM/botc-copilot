import 'package:botc_copilot/app.dart';
import 'package:botc_copilot/feature/setup/presentation/providers/setup_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feature/setup/setup_wizard_test.dart' show FakeSetupRepository;

void main() {
  testWidgets('App 启动显示开局设置向导', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          setupRepositoryProvider.overrideWithValue(FakeSetupRepository()),
        ],
        child: const BotcApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('开局设置'), findsWidgets);
    expect(find.text('选择剧本'), findsOneWidget);
  });
}
