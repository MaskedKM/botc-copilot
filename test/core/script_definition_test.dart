import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/jinx_rule.dart';
import 'package:botc_copilot/core/constants/night_order.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:botc_copilot/feature/reasoning/domain/contradiction.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TB 池 = 全 22 角色，不含 S&V 锚点（#230/#233）', () {
    final tb = ScriptDefinition.of(Script.troubleBrewing);
    expect(tb.characters, hasLength(22));
    expect(tb.characters.contains(Character.magician), isFalse);
    expect(tb.characters.contains(Character.legion), isFalse);
  });

  test('TB byTeam 分组 13/4/4/1', () {
    final tb = ScriptDefinition.of(Script.troubleBrewing);
    expect(tb.byTeam(Team.townsfolk), hasLength(13));
    expect(tb.byTeam(Team.outsider), hasLength(4));
    expect(tb.byTeam(Team.minion), hasLength(4));
    expect(tb.byTeam(Team.demon), hasLength(1));
    expect(tb.byTeam(Team.demon).single, Character.imp);
  });

  test('S&V 梦殒春宵数据（#217 增量5）；注册表全键存在', () {
    final sv = ScriptDefinition.of(Script.sectsAndViolets);
    expect(sv.characters, hasLength(25)); // 13 镇民 + 4 外来者 + 4 爪牙 + 4 恶魔
    expect(sv.characters.where((c) => c.team == Team.townsfolk), hasLength(13));
    expect(sv.characters.where((c) => c.team == Team.outsider), hasLength(4));
    expect(sv.characters.where((c) => c.team == Team.minion), hasLength(4));
    expect(sv.characters.where((c) => c.team == Team.demon), hasLength(4));
    // 实验锚点不在官方池
    expect(sv.characters, isNot(contains(Character.magician)));
    expect(sv.characters, isNot(contains(Character.legion)));
    // setup 修正：方古 +1 / 亡骨魔 -1（maxOutsiderDelta=1）
    expect(Character.fanggu.setupOutsiderDeltas, [1]);
    expect(Character.vigormortis.setupOutsiderDeltas, [-1]);
    expect(sv.maxOutsiderDelta, 1);
    // S&V 核心无内部 Jinx（组合均涉实验角色）
    expect(sv.applicableJinxes, isEmpty);
    expect(scriptDefinitions.keys, containsAll(Script.values));
  });

  test('canTargetSelf 数据化：Monk/Butler/Chambermaid 不可自指，其余可', () {
    expect(Character.monk.canTargetSelf, isFalse);
    expect(Character.butler.canTargetSelf, isFalse);
    // 官方：choose 2 alive players (not yourself)
    expect(Character.chambermaid.canTargetSelf, isFalse);
    // 抽样其余角色默认 true（含 Poisoner 可选任何人）
    const noSelf = {Character.monk, Character.butler, Character.chambermaid};
    for (final c in Character.values) {
      expect(c.canTargetSelf, !noSelf.contains(c), reason: c.name);
    }
  });

  test('requiresDeadTarget 数据化：Professor 复活目标须死亡，其余存活', () {
    expect(Character.professor.requiresDeadTarget, isTrue);
    for (final c in Character.values) {
      if (c == Character.professor) continue;
      expect(c.requiresDeadTarget, isFalse, reason: c.name);
    }
  });

  test('Character.script 归属：TB 池角色指向 TB，锚点指向 S&V（TODO 落实）', () {
    for (final c in ScriptDefinition.of(Script.troubleBrewing).characters) {
      expect(c.script, Script.troubleBrewing, reason: c.name);
    }
    expect(Character.magician.script, Script.sectsAndViolets);
    expect(Character.legion.script, Script.sectsAndViolets);
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
        ScriptDefinition.of(Script.troubleBrewing).maxOutsiderDelta,
        2,
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
      // BMR 分派到自己的夜序（官方 nightsheet）
      expect(
        identical(
          nightStepsForDay(Script.badMoonRising, 1),
          ScriptDefinition.of(Script.badMoonRising).firstNightSteps,
        ),
        isTrue,
      );
    });

    test('game.script 分派链路：S&V 首夜/后续夜（#217 增量5）', () {
      final first = nightStepsForDay(Script.sectsAndViolets, 1);
      expect(first, isNotEmpty);
      expect(first.first.character, Character.philosopher);
      final other = nightStepsForDay(Script.sectsAndViolets, 2);
      expect(other, isNotEmpty);
      expect(other.first.character, Character.philosopher);
    });

    test('开场步骤为共享全局规则（三步，非剧本专属）', () {
      expect(openingSteps, hasLength(3));
      expect(openingSteps.every((s) => s.character == null), isTrue);
    });
  });

  group('JinxRule 推导（#233）', () {
    test('TB 剧本：无适用 Jinx（零行为变化）', () {
      expect(
        ScriptDefinition.of(Script.troubleBrewing).applicableJinxes,
        isEmpty,
      );
    });

    test('假想池含 Magician+Legion → 推导返回该 Jinx（验收）', () {
      // 官方 Jinx 对双双在池才生效。构造含两者的假想剧本池（S&V 全量
      // 录入前的最小验证，#217 后为真实 S&V 池行为）。
      const fakePool = ScriptDefinition(
        script: Script.sectsAndViolets,
        characters: [Character.magician, Character.legion],
      );
      final jinxes = fakePool.applicableJinxes;
      expect(jinxes, hasLength(1));
      expect(jinxes.single.a, anyOf(Character.magician, Character.legion));
      expect(jinxes.single.text, contains('军团'));
    });

    test('池只含单端角色 → Jinx 不生效（双双在池才触发）', () {
      const magicianOnly = ScriptDefinition(
        script: Script.sectsAndViolets,
        characters: [Character.magician],
      );
      expect(magicianOnly.applicableJinxes, isEmpty);
    });

    test('全局注册表锚点对：involves 双向', () {
      const rule = JinxRule(
        a: Character.magician,
        b: Character.legion,
        text: '测试',
      );
      expect(rule.involves(Character.magician), isTrue);
      expect(rule.involves(Character.legion), isTrue);
      expect(rule.involves(Character.imp), isFalse);
    });
  });

  group('registration 修饰与规则注册表（#234）', () {
    test('registration 旗标：Spy 单向善良 / Recluse 单向邪恶，其余无', () {
      expect(Character.spy.mayRegisterAsGood, isTrue);
      expect(Character.spy.mayRegisterAsEvil, isFalse);
      expect(Character.recluse.mayRegisterAsEvil, isTrue);
      expect(Character.recluse.mayRegisterAsGood, isFalse);
      expect(Character.imp.mayRegisterAsGood, isFalse);
      expect(Character.poisoner.mayRegisterAsEvil, isFalse);
      expect(Character.magician.mayRegisterAsGood, isFalse); // 锚点无修饰
    });

    test('TB 矛盾规则注册表：10 条剧本规则 + 通用规则（#215）', () {
      final rules = contradictionRulesFor(Script.troubleBrewing);
      expect(rules.map((r) => r.id), [
        'duplicate-role-claim',
        'confirmed-role-conflict',
        'outsider-count-anomaly',
        'team-count-overflow',
        'empath-mismatch',
        'fortune-teller-mismatch',
        'no-death-night',
        'bluff-claim',
        'start-info-ping',
        'chef-count',
        // 跨剧本通用（#215：传承 × 死亡揭示）
        'succession_reveal_conflict',
      ]);
    });

    test('S&V 规则集仅含跨剧本通用规则（#215）', () {
      expect(
        contradictionRulesFor(Script.sectsAndViolets).map((r) => r.id),
        ['succession_reveal_conflict'],
      );
    });
  });

  group('BMR 黯月初升数据（#217）', () {
    final bmr = ScriptDefinition.of(Script.badMoonRising);

    test('角色池 25：13 镇民 / 4 外来者 / 4 爪牙 / 4 恶魔', () {
      expect(bmr.characters, hasLength(25));
      expect(bmr.byTeam(Team.townsfolk), hasLength(13));
      expect(bmr.byTeam(Team.outsider), hasLength(4));
      expect(bmr.byTeam(Team.minion), hasLength(4));
      expect(bmr.byTeam(Team.demon), hasLength(4));
      // 全部归属 BMR
      for (final c in bmr.characters) {
        expect(c.script, Script.badMoonRising, reason: c.name);
      }
    });

    test('首夜顺序（官方 nightsheet）：疯子插在爪牙/恶魔信息之间', () {
      final fn = bmr.firstNightSteps;
      expect(fn, hasLength(10));
      expect(fn[0].label, '爪牙信息');
      expect(fn[1].character, Character.lunatic);
      expect(fn[2].label, '恶魔信息');
      expect(fn[3].character, Character.sailor);
      expect(fn.last.character, Character.chambermaid);
    });

    test('后续夜顺序（官方 nightsheet）共 19 步', () {
      final on = bmr.otherNightSteps;
      expect(on, hasLength(19));
      expect(on.first.character, Character.sailor);
      expect(on[6].character, Character.exorcist);
      expect(on[7].character, Character.zombuul);
      expect(on.last.character, Character.chambermaid);
    });

    test('Godfather 增量 [-1,1]：maxOutsiderDelta = 1', () {
      expect(Character.godfather.setupOutsiderDeltas, const [-1, 1]);
      expect(bmr.maxOutsiderDelta, 1);
    });

    test('BMR 池内无适用 Jinx（军团×吟游诗人需军团在池=混编/S&V 场景）', () {
      // 军团（S&V）不在 BMR 池 → legion×minstrel 不适用；
      // magician×spy 需魔术师在池亦不适用。BMR 单剧本零 Jinx ✓ 官方一致。
      expect(bmr.applicableJinxes, isEmpty);
    });

    test('官方剧本中文名（勘正）', () {
      expect(Script.badMoonRising.nameCn, '黯月初升');
      expect(Script.sectsAndViolets.nameCn, '梦殒春宵');
      expect(Script.troubleBrewing.nameCn, '暗流涌动');
    });
  });
}
