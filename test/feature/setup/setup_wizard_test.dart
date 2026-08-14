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
  int? lastMySeat;
  var nextGameId = 1;

  @override
  Future<int> createGame({
    required Script script,
    required List<String> names,
    required Character myRole,
    List<Character> demonBluffs = const [],
    int? mySeat,
  }) async {
    lastScript = script;
    lastNames = names;
    lastMyRole = myRole;
    lastDemonBluffs = demonBluffs;
    lastMySeat = mySeat;
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

  testWidgets('三官方剧本全可选（#217 增量5 收官）', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await enterWizard(tester);

    // 全部剧本数据就绪 → 无「即将支持」
    expect(find.textContaining('即将支持'), findsNothing);

    // 点 S&V 卡片可选中（出现对勾）
    await tester.tap(find.textContaining('梦殒春宵'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('BMR 全流程：角色池/Bluff 池按剧本、提交带 BMR 参数', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await enterWizard(tester);

    // 选 BMR 后走完前四步
    await tester.tap(find.textContaining('黯月初升'));
    await tester.pumpAndSettle();
    await walkToConfirm(tester);

    // Step 4 角色池来自 BMR：侍女在，TB 独有角色（占卜师）不在
    expect(find.text('我的角色'), findsOneWidget);
    expect(find.text('侍女'), findsOneWidget);
    expect(find.text('占卜师'), findsNothing);

    // 恶魔区在 25 角色池底部，须滚动到位再点选
    await tester.scrollUntilVisible(
      find.text('普卡'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('普卡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    // Step 5 确认页：剧本行 + Bluff 池为 BMR 好人角色
    expect(find.text('确认开局'), findsOneWidget);
    expect(find.text('黯月初升'), findsOneWidget);
    expect(find.text('恶魔 Bluff（选 3 个）'), findsOneWidget);
    expect(find.text('侍女'), findsOneWidget); // BMR 镇民在池
    expect(find.text('士兵'), findsNothing); // TB 镇民不在池

    // 选 3 个 BMR Bluff 后开始对局（chip 可能在视口外，逐个滚动到位再点）
    Future<void> tapBluff(String name) async {
      await tester.scrollUntilVisible(
        find.text(name),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(name));
      await tester.pump();
    }

    await tapBluff('侍女');
    await tapBluff('造谣者');
    await tapBluff('茶艺师');
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始对局'));
    await tester.pumpAndSettle();

    // 仓库收到 BMR 参数
    expect(repo.lastScript, Script.badMoonRising);
    expect(repo.lastMyRole, Character.pukka);
    expect(repo.lastDemonBluffs, hasLength(3));
    expect(repo.lastDemonBluffs, containsAll([Character.chambermaid]));
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

  // #165 A1：上下移按钮换序后视图须同步（按钮不经拖拽重建路径，曾致 TextField 不刷新）。
  testWidgets('上下移按钮换序后视图同步刷新（#165 A1）', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await enterWizard(tester);
    await tester.tap(find.text('下一步')); // 剧本 → 人数
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步')); // 人数 → 座位
    await tester.pumpAndSettle();
    expect(find.text('排座位'), findsOneWidget);

    List<String> rowTexts() => find
        .byType(TextField)
        .evaluate()
        .map((e) => (e.widget as TextField).controller?.text ?? '')
        .toList();
    expect(rowTexts().take(2).toList(), ['A', 'B']);

    // 第 2 行（B）上移 → 视图应刷新为 B, A
    await tester.tap(find.byTooltip('上移').at(1));
    await tester.pumpAndSettle();
    expect(rowTexts().take(2).toList(), ['B', 'A']);

    // 第 1 行（现 B）下移 → 刷新回 A, B
    await tester.tap(find.byTooltip('下移').at(0));
    await tester.pumpAndSettle();
    expect(rowTexts().take(2).toList(), ['A', 'B']);
  });
}
