import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/night_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('首夜顺序（TB）', () {
    test('11 步，Poisomer 起、Butler 止', () {
      expect(firstNightSteps, hasLength(11));
      expect(firstNightSteps.first.character, Character.poisoner);
      expect(firstNightSteps.last.character, Character.butler);
    });

    test('Imp 在第 4 位且首夜不杀人', () {
      expect(firstNightSteps[3].character, Character.imp);
      expect(firstNightSteps[3].note, contains('首夜不杀人'));
    });

    test('Poisomer 投毒 note 含毒时效', () {
      expect(firstNightSteps.first.note, contains('黄昏解除'));
    });

    test('Scarlet Woman 传位 note 含 SW 存活条件（review R1）', () {
      final sw = firstNightSteps
          .firstWhere((s) => s.character == Character.scarletWoman);
      expect(sw.note, contains('存活'));
      expect(sw.note, contains('5'));
    });

    test('信息角色顺序：Washerwoman→Librarian→Investigator→Chef→Empath→Fortune Teller', () {
      final chars = firstNightSteps.map((s) => s.character).toList();
      final start = chars.indexOf(Character.washerwoman);
      expect(chars.sublist(start, start + 6), [
        Character.washerwoman,
        Character.librarian,
        Character.investigator,
        Character.chef,
        Character.empath,
        Character.fortuneTeller,
      ]);
    });
  });

  group('后续夜顺序（TB）', () {
    test('8 步，Poisomer 起、Spy 止', () {
      expect(otherNightSteps, hasLength(8));
      expect(otherNightSteps.first.character, Character.poisoner);
      expect(otherNightSteps.last.character, Character.spy);
    });

    test('Monk 在 Imp 之前（保护先于杀人）', () {
      final monk = otherNightSteps.indexWhere((s) => s.character == Character.monk);
      final imp = otherNightSteps.indexWhere((s) => s.character == Character.imp);
      expect(monk, lessThan(imp));
      expect(otherNightSteps[imp].action, contains('杀'));
    });

    test('Imp 杀人 note 提示先于占卜师/共情者', () {
      final imp = otherNightSteps.firstWhere((s) => s.character == Character.imp);
      expect(imp.note, contains('共情者'));
    });

    test('含 Undertaker / Ravenkeeper / Spy（后续夜特有或必醒）', () {
      final chars = otherNightSteps.map((s) => s.character).toSet();
      expect(chars, containsAll([
        Character.undertaker,
        Character.ravenkeeper,
        Character.spy,
        Character.monk,
      ]));
    });

    test('不含首夜专属信息角色（Washerwoman/Librarian/Investigator/Chef/Butler）', () {
      final chars = otherNightSteps.map((s) => s.character).toSet();
      expect(chars, isNot(contains(Character.washerwoman)));
      expect(chars, isNot(contains(Character.librarian)));
      expect(chars, isNot(contains(Character.investigator)));
      expect(chars, isNot(contains(Character.chef)));
      expect(chars, isNot(contains(Character.butler)));
    });
  });

  group('nightStepsForDay', () {
    test('day 1 → 首夜', () {
      expect(nightStepsForDay(1), same(firstNightSteps));
    });

    test('day ≥ 2 → 后续夜', () {
      expect(nightStepsForDay(2), same(otherNightSteps));
      expect(nightStepsForDay(5), same(otherNightSteps));
    });
  });
}
