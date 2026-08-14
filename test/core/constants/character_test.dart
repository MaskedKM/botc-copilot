import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/info_input_type.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Character 元数据完整性', () {
    test('TB 22 + BMR 25 + S&V 25 + 实验锚点 2 = 74（#217 增量5）', () {
      expect(Character.values.length, 74);
      expect(Character.byTeam(Team.townsfolk).length, 40); // 13*3+Magician
      expect(Character.byTeam(Team.outsider).length, 12); // 4*3
      expect(Character.byTeam(Team.minion).length, 12); // 4*3
      expect(Character.byTeam(Team.demon).length, 10); // 1TB+4BMR+4S&V+Legion
    });

    test('每个角色都有完整元数据', () {
      for (final c in Character.values) {
        expect(c.nameCn, isNotEmpty, reason: '${c.name} 缺中文名');
        expect(c.nameEn, isNotEmpty, reason: '${c.name} 缺英文名');
        expect(c.ability, isNotEmpty, reason: '${c.name} 缺能力描述');
      }
    });

    test('信息输入模板映射符合 AGENTS.md 角色表', () {
      expect(Character.chef.infoInputType, InfoInputType.numberRange);
      expect(Character.empath.infoInputType, InfoInputType.numberZeroToTwo);
      expect(
        Character.fortuneTeller.infoInputType,
        InfoInputType.twoPlayersYesNo,
      );
      expect(
        Character.investigator.infoInputType,
        InfoInputType.minionPlusTwoPlayers,
      );
      expect(
        Character.washerwoman.infoInputType,
        InfoInputType.townsfolkPlusTwoPlayers,
      );
      expect(
        Character.librarian.infoInputType,
        InfoInputType.outsiderPlusTwoPlayersOrNone,
      );
      expect(Character.undertaker.infoInputType, InfoInputType.characterName);
      // Spy 看魔典 → 自由文本（#136，原误设 none 致角色不可用）
      expect(Character.spy.infoInputType, InfoInputType.freeText);
    });

    test('阵营善恶标记正确', () {
      expect(Character.imp.isGood, isFalse);
      expect(Character.baron.isGood, isFalse);
      expect(Character.saint.isGood, isTrue);
      expect(Character.mayor.isGood, isTrue);
    });

    // #152 BUG-1：恶魔 Bluff 候选 = 不在场的好人角色（镇民 + 外来者）。
    // confirm_step 用 c.team.isGood 筛选；此处守住「好人阵营不含爪牙/恶魔」契约。
    test('Bluff 候选（team.isGood）只含镇民 + 外来者，不含爪牙/恶魔（#152）', () {
      final bluffEligible = Character.values.where((c) => c.team.isGood).toSet();
      // 含镇民、外来者
      expect(bluffEligible, contains(Character.chef)); // 镇民
      expect(bluffEligible, contains(Character.saint)); // 外来者
      // 不含任何爪牙或恶魔
      for (final c in Character.values) {
        if (c.team == Team.minion || c.team == Team.demon) {
          expect(bluffEligible, isNot(contains(c)), reason: '${c.name} 不应在 Bluff 候选');
        }
      }
    });
  });
}
