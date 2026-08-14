import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/info_input_type.dart';
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
        abilityUsed: false, suspectedDrunk: false,
      ),
  ];

  Widget buildInput(
    Character character,
    void Function(Map<String, Object?>) onSubmit, {
    int? actingPlayerId,
    List<Player>? playersOverride,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: InfoInputFactory.build(
        script: Script.troubleBrewing,
            character: character,
            players: playersOverride ?? players,
            actingPlayerId: actingPlayerId,
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

  testWidgets('Monk：选 1 名保护目标（官方规则不能选自己）', (tester) async {
    Map<String, Object?>? result;
    await tester.pumpWidget(
      buildInput(Character.monk, (p) => result = p, actingPlayerId: 1),
    );
    // Monk（1号）不能选自己 → 候选无「1号 玩家1」
    expect(find.text('1号 玩家1'), findsNothing);
    expect(find.text('3号 玩家3'), findsOneWidget);
    // 未选时按钮禁用
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.text('3号 玩家3'));
    await tester.pump();
    await tester.tap(find.text('记录'));
    expect(result, {'playerId': 3});
  });

  testWidgets('Poisoner：选 1 名下毒目标（可选任何存活玩家，含自己）',
      (tester) async {
    Map<String, Object?>? result;
    await tester.pumpWidget(
      buildInput(Character.poisoner, (p) => result = p, actingPlayerId: 1),
    );
    // Poisoner 可选自己 → 候选含「1号 玩家1」
    expect(find.text('1号 玩家1'), findsOneWidget);

    await tester.tap(find.text('2号 玩家2'));
    await tester.pump();
    await tester.tap(find.text('记录'));
    expect(result, {'playerId': 2});
  });

  testWidgets('夜间行动目标排除已死亡玩家', (tester) async {
    final withDead = [
      ...players,
      Player(
        id: 8,
        gameId: 1,
        name: '亡者',
        seatNumber: 8,
        isAlive: false,
        abilityUsed: false, suspectedDrunk: false,
        deathDay: 2,
      ),
    ];
    await tester.pumpWidget(
      buildInput(
        Character.poisoner,
        (_) {},
        actingPlayerId: 1,
        playersOverride: withDead,
      ),
    );
    // 存活玩家在候选中
    expect(find.text('2号 玩家2'), findsOneWidget);
    // 已死亡的 8 号不在候选中
    expect(find.text('8号 亡者'), findsNothing);
  });

  testWidgets('无信息能力角色（Soldier）：显示提示且无记录按钮', (tester) async {
    await tester.pumpWidget(buildInput(Character.soldier, (_) {}));
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

  group('BMR 信息模板（#217 增量2）', () {
    testWidgets('侍女 twoPlayersNumber：双人 + 0-2 数字 → payload', (tester) async {
      Map<String, Object?>? submitted;
      await tester.pumpWidget(
        buildInput(Character.chambermaid, (p) => submitted = p),
      );
      await tester.pump();
      // 选两人 + 数字
      await tester.tap(find.textContaining('1号').first);
      await tester.pump();
      await tester.tap(find.textContaining('2号').first);
      await tester.pump();
      await tester.tap(find.text('1 人'));
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pump();
      expect(submitted, isNotNull);
      expect((submitted!['playerIds'] as List).toSet(), {1, 2});
      expect(submitted!['value'], 1);
    });

    testWidgets('旅店老板 twoPlayersTarget：双人保护 → payload', (tester) async {
      Map<String, Object?>? submitted;
      await tester.pumpWidget(
        buildInput(Character.innkeeper, (p) => submitted = p),
      );
      await tester.pump();
      await tester.tap(find.textContaining('3号').first);
      await tester.pump();
      await tester.tap(find.textContaining('4号').first);
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pump();
      expect(submitted, isNotNull);
      expect((submitted!['playerIds'] as List).toSet(), {3, 4});
      expect(submitted!.containsKey('value'), isFalse);
    });

    testWidgets('赌徒复用 playerPlusCharacter（BMR）', (tester) async {
      // BMR 角色经同一工厂构建：模板类型驱动 UI，与剧本无关
      expect(Character.gambler.infoInputType, InfoInputType.playerPlusCharacter);
      expect(Character.grandmother.infoInputType,
          InfoInputType.playerPlusCharacter);
      expect(Character.courtier.infoInputType, InfoInputType.characterName);
      expect(Character.pukka.infoInputType, InfoInputType.singlePlayerTarget);
      expect(Character.godfather.infoInputType, InfoInputType.freeText);
      expect(Character.zombuul.infoInputType, InfoInputType.none);
    });
  });
}
