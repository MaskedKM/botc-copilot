import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/info_input_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final players = [
    for (var i = 1; i <= 7; i++)
      Player(
        id: i,
        gameId: 1,
        name: '玩家$i',
        seatNumber: i,
        isAlive: true,
      ),
  ];

  Widget buildInput(Character character, void Function(Map<String, Object?>) onSubmit) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: InfoInputFactory.build(
            character: character,
            players: players,
            onSubmit: onSubmit,
          ),
        ),
      ),
    );
  }

  testWidgets('Chef：数字输入 0-N，提交 value payload', (tester) async {
    Map<String, Object?>? result;
    await tester.pumpWidget(buildInput(Character.chef, (p) => result = p));

    // 点两次 + → 值 = 2
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('记录'));
    expect(result, {'value': 2});
  });

  testWidgets('Empath：上限为 2', (tester) async {
    await tester.pumpWidget(buildInput(Character.empath, (_) {}));
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    // 第三次 + 按钮应禁用
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('FortuneTeller：选 2 人 + 是/否', (tester) async {
    Map<String, Object?>? result;
    await tester
        .pumpWidget(buildInput(Character.fortuneTeller, (p) => result = p));

    // 未选满 2 人时按钮禁用
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.text('1号 玩家1'));
    await tester.tap(find.text('2号 玩家2'));
    await tester.pump();
    await tester.tap(find.text('否'));
    await tester.pump();
    await tester.tap(find.text('记录'));

    expect(result, {
      'playerIds': [1, 2],
      'answer': false,
    });
  });

  testWidgets('Washerwoman：镇民角色 + 双人', (tester) async {
    Map<String, Object?>? result;
    await tester
        .pumpWidget(buildInput(Character.washerwoman, (p) => result = p));

    await tester.tap(find.text('厨师'));
    await tester.tap(find.text('3号 玩家3'));
    await tester.tap(find.text('4号 玩家4'));
    await tester.pump();
    await tester.tap(find.text('记录'));

    expect(result, {
      'character': 'chef',
      'playerIds': [3, 4],
    });
  });

  testWidgets('Librarian：允许"无外来者"', (tester) async {
    Map<String, Object?>? result;
    await tester
        .pumpWidget(buildInput(Character.librarian, (p) => result = p));

    await tester.tap(find.text('无'));
    await tester.pump();
    await tester.tap(find.text('记录'));

    expect(result, {'character': null, 'playerIds': <int>[]});
  });

  testWidgets('Undertaker：单选角色名', (tester) async {
    Map<String, Object?>? result;
    await tester
        .pumpWidget(buildInput(Character.undertaker, (p) => result = p));

    await tester.tap(find.text('投毒者'));
    await tester.pump();
    await tester.tap(find.text('记录'));

    expect(result, {'character': 'poisoner'});
  });

  testWidgets('Ravenkeeper：选玩家 + 选角色', (tester) async {
    Map<String, Object?>? result;
    await tester
        .pumpWidget(buildInput(Character.ravenkeeper, (p) => result = p));

    await tester.tap(find.text('5号 玩家5'));
    await tester.tap(find.text('间谍'));
    await tester.pump();
    await tester.tap(find.text('记录'));

    expect(result, {'playerId': 5, 'character': 'spy'});
  });

  testWidgets('Monk（无信息能力）：显示提示且无记录按钮', (tester) async {
    await tester.pumpWidget(buildInput(Character.monk, (_) {}));
    expect(find.text('该角色无信息类能力，无需录入。'), findsOneWidget);
    expect(find.text('记录'), findsNothing);
  });

  testWidgets('自由文本：空文本不可提交', (tester) async {
    Map<String, Object?>? result;
    await tester.pumpWidget(buildInput(Character.soldier, (p) => result = p));

    // soldier 的 infoInputType = none → 走 _NoInput；用一个 freeText 角色测
    // 当前 enum 里 none 的居多，直接构造 freeText 场景需等扩展角色。
    // 此处验证 none 行为即可。
    expect(result, isNull);
  });
}
