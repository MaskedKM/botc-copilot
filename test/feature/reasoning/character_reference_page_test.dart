import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/presentation/character_reference_page.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RoleClaim _claim(int playerId, Character c) => RoleClaim(
      id: playerId,
      playerId: playerId,
      dayRecordId: 1,
      character: c,
      claimType: ClaimType.firstClaim,
    );

Widget _page(List<RoleClaim> claims) => ProviderScope(
      overrides: [
        // widget test 不碰真实 DB：声明流用固定值
        gameClaimsProvider.overrideWith((ref, gameId) => Stream.value(claims)),
      ],
      child: const MaterialApp(
        home: CharacterReferencePage(gameId: 1),
      ),
    );

void main() {
  // washerwoman（1 号）位于镇民分组顶部，必定可见（避免长 ListView 懒加载）
  final claims = [_claim(1, Character.washerwoman)];

  testWidgets('已声明角色带「已声明」徽标', (tester) async {
    await tester.pumpWidget(_page(claims));
    await tester.pump();
    expect(find.text('已声明'), findsOneWidget); // washerwoman
  });

  testWidgets('展开角色 → 显示能力 / 确认路径 / 关键交互', (tester) async {
    await tester.pumpWidget(_page(claims));
    await tester.pump();
    await tester.tap(find.textContaining('洗衣妇').first);
    await tester.pump();
    expect(find.text('确认路径'), findsOneWidget);
    expect(find.text('关键交互'), findsOneWidget);
    // washerwoman 的毒交互
    expect(find.textContaining('被毒'), findsOneWidget);
  });

  testWidgets('「只看声明」过滤 → 未声明角色消失', (tester) async {
    await tester.pumpWidget(_page(claims));
    await tester.pump();
    expect(find.textContaining('厨师'), findsWidgets); // 过滤前：厨师在
    await tester.tap(find.text('只看声明'));
    await tester.pump();
    expect(find.textContaining('厨师'), findsNothing); // 过滤后：消失
    expect(find.textContaining('洗衣妇'), findsWidgets); // 已声明的仍在
  });

  testWidgets('无声明时「只看声明」提示空', (tester) async {
    await tester.pumpWidget(_page(const []));
    await tester.pump();
    await tester.tap(find.text('只看声明'));
    await tester.pump();
    expect(find.text('尚无角色声明。'), findsOneWidget);
  });

  testWidgets('涉及已声明角色的交互高亮 ⚡（上下文感知）', (tester) async {
    // washerwoman + poisoner 均声明 → washerwoman 的「被毒」交互活跃
    await tester.pumpWidget(_page([
      _claim(1, Character.washerwoman),
      _claim(4, Character.poisoner),
    ]));
    await tester.pump();
    await tester.tap(find.textContaining('洗衣妇').first);
    await tester.pump();
    expect(find.byIcon(Icons.bolt), findsOneWidget); // 活跃交互高亮
  });

  testWidgets('未涉及已声明角色的交互不高亮', (tester) async {
    await tester.pumpWidget(_page([_claim(1, Character.washerwoman)]));
    await tester.pump();
    await tester.tap(find.textContaining('洗衣妇').first);
    await tester.pump();
    expect(find.byIcon(Icons.bolt), findsNothing); // 无活跃交互
  });
}
