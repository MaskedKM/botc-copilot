import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/info_input_type.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Character 元数据完整性', () {
    test('TB 共 22 个角色：13 镇民 / 4 外来者 / 4 爪牙 / 1 恶魔', () {
      expect(Character.values.length, 22);
      expect(Character.byTeam(Team.townsfolk).length, 13);
      expect(Character.byTeam(Team.outsider).length, 4);
      expect(Character.byTeam(Team.minion).length, 4);
      expect(Character.byTeam(Team.demon).length, 1);
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
  });
}
