import 'package:botc_copilot/feature/game_board/presentation/widgets/night_order_section.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 纯展示 widget（currentDay / helpLevel 由参数传入），无需 provider override。
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('HelpLevel 分层', () {
    testWidgets('expert → 隐藏', (tester) async {
      await tester.pumpWidget(_wrap(const NightOrderSection(
        currentDay: 1,
        helpLevel: HelpLevel.expert,
      )));
      await tester.pump();
      expect(find.text('夜晚行动顺序参考'), findsNothing);
    });

    testWidgets('beginner → 展开标题', (tester) async {
      await tester.pumpWidget(_wrap(const NightOrderSection(
        currentDay: 1,
        helpLevel: HelpLevel.beginner,
      )));
      await tester.pump();
      expect(find.text('夜晚行动顺序参考'), findsOneWidget);
    });

    testWidgets('normal → 折叠 ExpansionTile（标题在）', (tester) async {
      await tester.pumpWidget(_wrap(const NightOrderSection(
        currentDay: 1,
        helpLevel: HelpLevel.normal,
      )));
      await tester.pump();
      expect(find.text('夜晚行动顺序参考'), findsOneWidget);
    });
  });

  group('按天数默认选相', () {
    testWidgets('day 1 → 首夜（含 Chef，不含 Monk）', (tester) async {
      await tester.pumpWidget(_wrap(const NightOrderSection(
        currentDay: 1,
        helpLevel: HelpLevel.beginner,
      )));
      await tester.pump();
      expect(find.textContaining('厨师'), findsOneWidget); // Chef 首夜专属
      expect(find.textContaining('僧侣'), findsNothing); // Monk 后续夜专属
    });

    testWidgets('day 3 → 后续夜（含 Monk，不含 Chef）', (tester) async {
      await tester.pumpWidget(_wrap(const NightOrderSection(
        currentDay: 3,
        helpLevel: HelpLevel.beginner,
      )));
      await tester.pump();
      expect(find.textContaining('僧侣'), findsOneWidget); // Monk
      expect(find.textContaining('厨师'), findsNothing); // Chef 首夜专属
    });
  });

  group('手动切换', () {
    testWidgets('day 1 点「后续夜」→ 出现 Monk', (tester) async {
      await tester.pumpWidget(_wrap(const NightOrderSection(
        currentDay: 1,
        helpLevel: HelpLevel.beginner,
      )));
      await tester.pump();
      expect(find.textContaining('僧侣'), findsNothing); // 初始首夜
      await tester.tap(find.text('后续夜'));
      await tester.pump();
      expect(find.textContaining('僧侣'), findsOneWidget); // 切到后续夜
    });

    testWidgets('天数变化时清除手动覆盖（review R3）', (tester) async {
      await tester.pumpWidget(_wrap(const NightOrderSection(
        currentDay: 3,
        helpLevel: HelpLevel.beginner,
      )));
      await tester.pump();
      expect(find.textContaining('僧侣'), findsOneWidget); // day 3 → 后续夜
      // 手动切到首夜（设置 override）
      await tester.tap(find.text('首夜'));
      await tester.pump();
      expect(find.textContaining('厨师'), findsOneWidget);
      expect(find.textContaining('僧侣'), findsNothing);
      // 推进天数（3 → 4）：didUpdateWidget 清除 override → 重新跟随后续夜
      await tester.pumpWidget(_wrap(const NightOrderSection(
        currentDay: 4,
        helpLevel: HelpLevel.beginner,
      )));
      await tester.pump();
      expect(find.textContaining('僧侣'), findsOneWidget); // 回到后续夜
      expect(find.textContaining('厨师'), findsNothing);
    });
  });

  group('夜序引导勾选流（#216 功能1）', () {
    testWidgets('点行勾选 → 计数/变暗，再点取消', (tester) async {
      await tester.pumpWidget(_wrap(NightOrderSection(
        currentDay: 1,
        helpLevel: HelpLevel.beginner,
      )));
      await tester.pump();
      expect(find.textContaining('已过 0/'), findsOneWidget);

      // 点第一行（投毒者）勾选
      await tester.tap(find.textContaining('投毒').first);
      await tester.pump();
      expect(find.textContaining('已过 1/'), findsOneWidget);

      // 再点取消
      await tester.tap(find.textContaining('投毒').first);
      await tester.pump();
      expect(find.textContaining('已过 0/'), findsOneWidget);
    });

    testWidgets('有勾选 → 显示重置按钮；重置清空', (tester) async {
      await tester.pumpWidget(_wrap(NightOrderSection(
        currentDay: 3,
        helpLevel: HelpLevel.beginner,
      )));
      await tester.pump();
      expect(find.text('重置勾选'), findsNothing);

      await tester.tap(find.textContaining('杀人').first);
      await tester.pump();
      expect(find.text('重置勾选'), findsOneWidget);

      await tester.tap(find.text('重置勾选'));
      await tester.pump();
      expect(find.textContaining('已过 0/'), findsOneWidget);
      expect(find.text('重置勾选'), findsNothing);
    });

    testWidgets('切天 → 勾选重置（didUpdateWidget）', (tester) async {
      await tester.pumpWidget(_wrap(NightOrderSection(
        currentDay: 1,
        helpLevel: HelpLevel.beginner,
      )));
      await tester.pump();
      await tester.tap(find.textContaining('投毒').first);
      await tester.pump();
      expect(find.textContaining('已过 1/'), findsOneWidget);

      // 推进天数 → 重置
      await tester.pumpWidget(_wrap(NightOrderSection(
        currentDay: 2,
        helpLevel: HelpLevel.beginner,
      )));
      await tester.pump();
      // day2 → 后续夜步骤集（不含首夜专属），勾选清零
      expect(find.textContaining('已过 0/'), findsOneWidget);
    });
  });
}
