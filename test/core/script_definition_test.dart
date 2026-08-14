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
}
