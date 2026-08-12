import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/night_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('首夜顺序（TB，官方数据）', () {
    test('14 步：开场 醉汉/爪牙信息/恶魔信息 → Poisoner ... → Butler', () {
      expect(firstNightSteps, hasLength(14));
      expect(firstNightSteps.first.label, contains('醉汉'));
      expect(firstNightSteps.first.character, isNull); // 说明性步骤
      expect(firstNightSteps.last.character, Character.butler);
    });

    test('开场两步为说明性（爪牙信息 / 恶魔信息，character=null）', () {
      expect(firstNightSteps[1].label, '爪牙信息');
      expect(firstNightSteps[1].character, isNull);
      expect(firstNightSteps[2].label, '恶魔信息');
      expect(firstNightSteps[2].character, isNull);
      expect(firstNightSteps[2].note, contains('Bluff'));
    });

    test('首夜含 Scarlet Woman（#111 称「无」是错的——按权威数据）', () {
      expect(
        firstNightSteps.any((s) => s.character == Character.scarletWoman),
        isTrue,
      );
    });

    test('Imp 首夜不杀人，位于第 7 位', () {
      expect(firstNightSteps[6].character, Character.imp);
      expect(firstNightSteps[6].note, contains('首夜不杀人'));
    });

    test('Poisomer 投毒 note 含毒时效', () {
      final poisoner =
          firstNightSteps.firstWhere((s) => s.character == Character.poisoner);
      expect(poisoner.note, contains('黄昏解除'));
    });

    test('信息角色顺序：WW→Lib→Inv→Chef→Empath→FT', () {
      final chars = firstNightSteps
          .where((s) => s.character != null)
          .map((s) => s.character!)
          .toList();
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

  group('后续夜顺序（TB，官方数据）', () {
    test('10 步：Poisoner→Monk→SW→Imp→Ravenkeeper→Undertaker→Empath→FT→Spy→Butler', () {
      expect(otherNightSteps, hasLength(10));
      expect(otherNightSteps.first.character, Character.poisoner);
      expect(otherNightSteps.last.character, Character.butler);
      expect(
        otherNightSteps.map((s) => s.character).toList(),
        [
          Character.poisoner,
          Character.monk,
          Character.scarletWoman,
          Character.imp,
          Character.ravenkeeper,
          Character.undertaker,
          Character.empath,
          Character.fortuneTeller,
          Character.spy,
          Character.butler,
        ],
      );
    });

    test('Monk 在 Imp 之前（保护先于杀人）', () {
      final monk =
          otherNightSteps.indexWhere((s) => s.character == Character.monk);
      final imp =
          otherNightSteps.indexWhere((s) => s.character == Character.imp);
      expect(monk, lessThan(imp));
      expect(otherNightSteps[imp].action, contains('杀'));
    });

    test('Ravenkeeper 紧跟 Imp（被杀即醒）', () {
      final imp =
          otherNightSteps.indexWhere((s) => s.character == Character.imp);
      expect(otherNightSteps[imp + 1].character, Character.ravenkeeper);
      expect(otherNightSteps[imp + 1].note, contains('紧跟'));
    });

    test('Undertaker 在 Empath / Fortune Teller 之前', () {
      final undertaker =
          otherNightSteps.indexWhere((s) => s.character == Character.undertaker);
      final empath =
          otherNightSteps.indexWhere((s) => s.character == Character.empath);
      final ft = otherNightSteps
          .indexWhere((s) => s.character == Character.fortuneTeller);
      expect(undertaker, lessThan(empath));
      expect(undertaker, lessThan(ft));
    });

    test('Empath 在 Fortune Teller 之前', () {
      final empath =
          otherNightSteps.indexWhere((s) => s.character == Character.empath);
      final ft = otherNightSteps
          .indexWhere((s) => s.character == Character.fortuneTeller);
      expect(empath, lessThan(ft));
    });

    test('Spy 在 Empath/FT 之后、Butler 之前（#111 称第 3 位是错的）', () {
      final spy =
          otherNightSteps.indexWhere((s) => s.character == Character.spy);
      final ft = otherNightSteps
          .indexWhere((s) => s.character == Character.fortuneTeller);
      final butler =
          otherNightSteps.indexWhere((s) => s.character == Character.butler);
      expect(spy, greaterThan(ft));
      expect(spy, lessThan(butler));
    });

    test('含 Scarlet Woman + Butler（#104 旧实现的遗漏，已修正）', () {
      final chars = otherNightSteps
          .where((s) => s.character != null)
          .map((s) => s.character)
          .toSet();
      expect(chars, contains(Character.scarletWoman));
      expect(chars, contains(Character.butler));
    });

    test('不含首夜专属信息角色（WW/Lib/Inv/Chef）', () {
      final chars = otherNightSteps
          .where((s) => s.character != null)
          .map((s) => s.character)
          .toSet();
      for (final c in [
        Character.washerwoman,
        Character.librarian,
        Character.investigator,
        Character.chef,
      ]) {
        expect(chars, isNot(contains(c)));
      }
    });
  });

  group('nightStepsForDay', () {
    test('day 1 → 首夜；day ≥ 2 → 后续夜', () {
      expect(nightStepsForDay(1), same(firstNightSteps));
      expect(nightStepsForDay(2), same(otherNightSteps));
      expect(nightStepsForDay(5), same(otherNightSteps));
    });
  });

  group('displayLabel', () {
    test('角色步骤 label 为空，displayLabel 派生自 nameCn（避免硬编码漂移）', () {
      final poisoner = firstNightSteps
          .firstWhere((s) => s.character == Character.poisoner);
      expect(poisoner.label, isNull);
      expect(poisoner.displayLabel, Character.poisoner.nameCn);
    });

    test('说明性步骤用 label', () {
      expect(firstNightSteps[1].displayLabel, '爪牙信息');
      expect(firstNightSteps[2].displayLabel, '恶魔信息');
    });
  });
}
