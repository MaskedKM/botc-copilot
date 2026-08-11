import 'package:botc_copilot/app.dart';
import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/setup/data/setup_repository.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/setup/presentation/providers/setup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 假仓库：记录调用参数，不触碰真实数据库。
///
/// 最佳实践（drift#3323 / flutter async 测试指南）：
/// widget test 跑在 FakeAsync 区域，真实数据库 IO 会导致
/// pump 挂起 / close 死锁。DB 正确性由集成测试
/// （app_database_test.dart）覆盖，widget test 只验证 UI 流程
/// 和"正确参数传给了仓库"。
class FakeSetupRepository implements SetupRepository {
  Script? lastScript;
  List<String>? lastNames;
  Character? lastMyRole;
  List<Character>? lastDemonBluffs;
  var nextGameId = 1;

  @override
  Future<int> createGame({
    required Script script,
    required List<String> names,
    required Character myRole,
    List<Character> demonBluffs = const [],
  }) async {
    lastScript = script;
    lastNames = names;
    lastMyRole = myRole;
    lastDemonBluffs = demonBluffs;
    return nextGameId;
  }
}

void main() {
  late FakeSetupRepository repo;

  setUp(() {
    repo = FakeSetupRepository();
  });

  Widget buildApp() => ProviderScope(
        overrides: [
          setupRepositoryProvider.overrideWithValue(repo),
          // widget test 不碰真实数据库：存档列表/对局页均用空流占位。
          allGamesProvider.overrideWith((ref) => Stream.value(<Game>[])),
          gameByIdProvider(1).overrideWith((ref) => Stream.value(null)),
        ],
        child: const BotcApp(),
      );

  /// 从首页进入设置向导。
  Future<void> enterWizard(WidgetTester tester) async {
    await tester.tap(find.text('新建对局'));
    await tester.pumpAndSettle();
    expect(find.text('选择剧本'), findsOneWidget);
  }

  /// 走完前四步到确认页。
  Future<void> walkToConfirm(WidgetTester tester, {int playerCount = 7}) async {
    await tester.tap(find.text('下一步')); // 剧本 → 人数
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步')); // 人数 → 座位
    await tester.pumpAndSettle();
    for (var i = 0; i < playerCount; i++) {
      await tester.enterText(
        find.byType(TextField).at(i),
        '玩家${i + 1}',
      );
    }
    await tester.pump(); // 等按钮可用态重建
    await tester.tap(find.text('下一步')); // 座位 → 角色
    await tester.pumpAndSettle();
  }

  testWidgets('非 TB 剧本禁用（角色数据未就绪）', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await enterWizard(tester);

    // TB 可选，BMR/S&V 禁用（卡片标题是组合文本 “名字 · 缩写”）
    expect(find.textContaining('血月升起'), findsOneWidget);
    expect(find.textContaining('即将支持'), findsNWidgets(2));

    // 点 BMR 不会切换选中态
    await tester.tap(find.textContaining('血月升起'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    // 座位页出现 = 流程仍按 TB 走，未被 BMR 干扰
    expect(find.text('排座位'), findsOneWidget);
  });

  testWidgets('完整设置流程：五步走到确认页', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await enterWizard(tester);

    // Step 1 剧本
    expect(find.text('选择剧本'), findsOneWidget);
    await walkToConfirm(tester);

    // Step 4 选角色（未选时不可前进）
    expect(find.text('我的角色'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
      isFalse,
    );
    await tester.tap(find.text('占卜师'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    // Step 5 确认页
    expect(find.text('确认开局'), findsOneWidget);
    expect(find.text('1. 玩家1'), findsOneWidget);
    expect(find.text('7. 玩家7'), findsOneWidget);
  });

  testWidgets('开始对局 → 调用仓库并跳转对局页', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await enterWizard(tester);

    await walkToConfirm(tester);
    await tester.tap(find.text('共情者'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步')); // → 确认页
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始对局'));
    await tester.pumpAndSettle();

    // 跳转对局主界面（game id=1 被 override 为 null → 显示提示）
    expect(find.textContaining('对局不存在或已删除'), findsOneWidget);

    // 仓库收到正确参数
    expect(repo.lastScript, Script.troubleBrewing);
    expect(repo.lastNames, hasLength(7));
    expect(repo.lastNames!.first, '玩家1');
    expect(repo.lastMyRole, Character.empath);
  });
}
