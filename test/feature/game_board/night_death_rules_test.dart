import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/feature/game_board/domain/night_death_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NightDeathRules.warnings（issue #114）', () {
    test('首夜（第 1 天）→ 警告首夜无人死亡', () {
      final w = NightDeathRules.warnings(
        day: 1,
        claimedCharacter: Character.chef,
      );
      expect(w, hasLength(1));
      expect(w.first, contains('首夜'));
      expect(w.first, contains('Imp'));
    });

    test('非首夜不触发首夜警告', () {
      final w = NightDeathRules.warnings(
        day: 2,
        claimedCharacter: Character.chef,
      );
      expect(w, isEmpty);
    });

    test('声明 Soldier → 警告免疫恶魔能力', () {
      final w = NightDeathRules.warnings(
        day: 3,
        claimedCharacter: Character.soldier,
      );
      expect(w, hasLength(1));
      expect(w.first, contains('士兵'));
      expect(w.first, contains('毒'));
    });

    test('首夜 + Soldier 叠加 → 两条警告', () {
      final w = NightDeathRules.warnings(
        day: 1,
        claimedCharacter: Character.soldier,
      );
      expect(w, hasLength(2));
    });

    test('无声明角色 + 非首夜 → 空', () {
      final w = NightDeathRules.warnings(day: 3, claimedCharacter: null);
      expect(w, isEmpty);
    });
  });
}
