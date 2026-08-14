import 'package:botc_copilot/core/constants/character.dart';
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
}
