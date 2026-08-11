import 'package:botc_copilot/app.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/setup/presentation/providers/setup_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feature/setup/setup_wizard_test.dart' show FakeSetupRepository;

void main() {
  testWidgets('App 启动显示对局存档首页', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          setupRepositoryProvider.overrideWithValue(FakeSetupRepository()),
          // widget test 不碰真实数据库，存档列表返回空
          allGamesProvider.overrideWith(
            (ref) => Stream.value(<Game>[]),
          ),
        ],
        child: const BotcApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('血染钟楼 · 对局'), findsOneWidget);
    expect(find.text('新建对局'), findsOneWidget);
  });
}
