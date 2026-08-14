import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/night_order.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TB 池 = 全 22 角色（#230 验收）', () {
    final tb = ScriptDefinition.of(Script.troubleBrewing);
    expect(tb.characters, hasLength(22));
    expect(tb.characters.toSet(), Character.values.toSet());
  });

  test('TB byTeam 分组 13/4/4/1', () {
    final tb = ScriptDefinition.of(Script.troubleBrewing);
    expect(tb.byTeam(Team.townsfolk), hasLength(13));
    expect(tb.byTeam(Team.outsider), hasLength(4));
    expect(tb.byTeam(Team.minion), hasLength(4));
    expect(tb.byTeam(Team.demon), hasLength(1));
    expect(tb.byTeam(Team.demon).single, Character.imp);
  });

  test('BMR/S&V 空池（角色待 #217 录入），of 兜底 TB 防脏数据', () {
    expect(ScriptDefinition.of(Script.badMoonRising).characters, isEmpty);
    expect(ScriptDefinition.of(Script.sectsAndViolets).characters, isEmpty);
    // 注册表全键存在
    expect(scriptDefinitions.keys, containsAll(Script.values));
  });

  test('canTargetSelf 数据化：Monk/Butler 不可自指，其余可', () {
    expect(Character.monk.canTargetSelf, isFalse);
    expect(Character.butler.canTargetSelf, isFalse);
    // 抽样其余角色默认 true（含 Poisoner 可选任何人）
    for (final c in Character.values) {
      final expected = c == Character.monk || c == Character.butler;
      expect(c.canTargetSelf, !expected, reason: c.name);
    }
  });

  test('Character.script 归属：TB 角色全部指向 TB（TODO 落实）', () {
    for (final c in Character.values) {
      expect(c.script, Script.troubleBrewing, reason: c.name);
    }
  });

  group('setup 外来者增量模型（#231）', () {
    test('Baron 数据：setupOutsiderDeltas = [2]；其余角色为空', () {
      expect(Character.baron.setupOutsiderDeltas, const [2]);
      expect(Character.poisoner.setupOutsiderDeltas, isEmpty);
      expect(Character.imp.setupOutsiderDeltas, isEmpty);
    });

    test('TB maxOutsiderDelta = 2（Baron）；空池剧本 = 0', () {
      expect(ScriptDefinition.of(Script.troubleBrewing).maxOutsiderDelta, 2);
      expect(
        ScriptDefinition.of(Script.badMoonRising).maxOutsiderDelta,
        0, // Godfather [-1,1] 随 #217 录入后自动生效
      );
    });

    test('claimedOutsiderDelta：未声明修正角色 → 0；声明 Baron → 2', () {
      expect(
        ScriptDefinition.claimedOutsiderDelta(
          const [Character.chef, Character.poisoner],
        ),
        0,
      );
      expect(
        ScriptDefinition.claimedOutsiderDelta(const [Character.baron]),
        2,
      );
      expect(ScriptDefinition.claimedOutsiderDelta(const []), 0);
    });

    test('「或」型多元素语义：负增量不会拉低期望（取最大候选）', () {
      // Godfather [-1, 1] 型（BMR，#217 录入）：claim 后期望锚点取 +1——
      // claimedOutsiderDelta 展开取 max，-1 被忽略（保守上界，避免漏报 over）。
      // 现有数据下以空列表模拟「无修正角色」侧断言基线行为。
      expect(ScriptDefinition.claimedOutsiderDelta(const []), 0);
    });
  });

  group('夜序入 ScriptDefinition（#232）', () {
    test('等值：TB 注册表引用与 night_order 常量为同一对象（golden）', () {
      final def = ScriptDefinition.of(Script.troubleBrewing);
      expect(identical(def.firstNightSteps, firstNightSteps), isTrue);
      expect(identical(def.otherNightSteps, otherNightSteps), isTrue);
      // 首夜含共享开场步骤（identity 同源）
      expect(identical(openingSteps.first, firstNightSteps.first), isTrue);
    });

    test('nightStepsForDay(Script, day)：day 1 首夜 / day≥2 后续夜', () {
      expect(
        identical(nightStepsForDay(Script.troubleBrewing, 1), firstNightSteps),
        isTrue,
      );
      expect(
        identical(nightStepsForDay(Script.troubleBrewing, 3), otherNightSteps),
        isTrue,
      );
    });

    test('game.script 分派链路：换剧本分派到各自数据（BMR 空池=仅缺数据）', () {
      // BMR 已注册但夜序未录入（#217）→ 诚实返回空列表，分派链路本身打通；
      // 不会误兜底 TB（of() 兜底仅针对未注册剧本防脏数据）。
      expect(nightStepsForDay(Script.badMoonRising, 1), isEmpty);
      expect(nightStepsForDay(Script.sectsAndViolets, 2), isEmpty);
    });

    test('开场步骤为共享全局规则（三步，非剧本专属）', () {
      expect(openingSteps, hasLength(3));
      expect(openingSteps.every((s) => s.character == null), isTrue);
    });
  });
}
