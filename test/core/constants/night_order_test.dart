import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/night_order.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('首夜顺序（TB，官方数据）', () {
    // #267 勘正：官方 botc-release nightsheet——首夜无 SW 位与 Imp 行动位
    //（恶魔信息在开场共享步骤；首夜不杀人），Spy 与 Butler 居末两位。
    test('12 步：开场 → Poisoner → WW…FT → Butler → Spy（官方逐位）', () {
      expect(firstNightSteps, hasLength(12));
      expect(firstNightSteps.first.label, contains('醉汉'));
      expect(firstNightSteps.first.character, isNull); // 说明性步骤
      expect(firstNightSteps.last.character, Character.spy);
      expect(firstNightSteps[firstNightSteps.length - 2].character,
          Character.butler);
      expect(
        firstNightSteps.map((s) => s.character).toList(),
        [
          null, null, null, // 醉汉/爪牙信息/恶魔信息
          Character.poisoner,
          Character.washerwoman,
          Character.librarian,
          Character.investigator,
          Character.chef,
          Character.empath,
          Character.fortuneTeller,
          Character.butler,
          Character.spy,
        ],
      );
    });

    test('开场两步为说明性（爪牙信息 / 恶魔信息，character=null）', () {
      expect(firstNightSteps[1].label, '爪牙信息');
      expect(firstNightSteps[1].character, isNull);
      expect(firstNightSteps[2].label, '恶魔信息');
      expect(firstNightSteps[2].character, isNull);
      expect(firstNightSteps[2].note, contains('Bluff'));
    });

    test('首夜无 SW / Imp 行动位（#267：#111 当时引的来源与官方不符）', () {
      expect(
        firstNightSteps.any((s) => s.character == Character.scarletWoman),
        isFalse,
      );
      expect(
        firstNightSteps.any((s) => s.character == Character.imp),
        isFalse, // 恶魔信息在开场共享步骤；首夜不杀人
      );
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
    test('10 步：官方逐位 …→Ravenkeeper→Empath→FT→Undertaker→Butler→Spy', () {
      expect(otherNightSteps, hasLength(10));
      expect(otherNightSteps.first.character, Character.poisoner);
      expect(otherNightSteps.last.character, Character.spy);
      expect(
        otherNightSteps.map((s) => s.character).toList(),
        [
          Character.poisoner,
          Character.monk,
          Character.scarletWoman,
          Character.imp,
          Character.ravenkeeper,
          Character.empath,
          Character.fortuneTeller,
          Character.undertaker,
          Character.butler,
          Character.spy,
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

    test('Undertaker 在 Fortune Teller 之后（#267 勘正）', () {
      final undertaker =
          otherNightSteps.indexWhere((s) => s.character == Character.undertaker);
      final ft = otherNightSteps
          .indexWhere((s) => s.character == Character.fortuneTeller);
      expect(undertaker, greaterThan(ft));
    });

    test('Empath 在 Fortune Teller 之前', () {
      final empath =
          otherNightSteps.indexWhere((s) => s.character == Character.empath);
      final ft = otherNightSteps
          .indexWhere((s) => s.character == Character.fortuneTeller);
      expect(empath, lessThan(ft));
    });

    test('Spy 居末位（Butler 之后，官方 Butler → Spy）', () {
      final spy =
          otherNightSteps.indexWhere((s) => s.character == Character.spy);
      final butler =
          otherNightSteps.indexWhere((s) => s.character == Character.butler);
      expect(spy, greaterThan(butler));
      expect(spy, otherNightSteps.length - 1);
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
      expect(
        nightStepsForDay(Script.troubleBrewing, 1),
        same(firstNightSteps),
      );
      expect(
        nightStepsForDay(Script.troubleBrewing, 2),
        same(otherNightSteps),
      );
      expect(
        nightStepsForDay(Script.troubleBrewing, 5),
        same(otherNightSteps),
      );
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
