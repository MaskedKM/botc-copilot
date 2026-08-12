import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/character_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('关键角色条目', () {
    test('empath：确认路径 + 3 交互（含 recluse / spy / poisoner）', () {
      final ref = characterReferences[Character.empath]!;
      expect(ref.confirmPath, isNotNull);
      expect(ref.interactions, hasLength(3));
      final allRelated = ref.interactions.expand((i) => i.relatedTo).toSet();
      expect(
        allRelated,
        containsAll([
          Character.recluse,
          Character.spy,
          Character.poisoner,
        ]),
      );
    });

    test('fortuneTeller：含隐士红鲱鱼交互', () {
      final ref = characterReferences[Character.fortuneTeller]!;
      expect(
        ref.interactions.any((i) => i.relatedTo.contains(Character.recluse)),
        isTrue,
      );
    });

    test('recluse：relatedTo 含 empath / fortuneTeller / undertaker', () {
      final ref = characterReferences[Character.recluse]!;
      final related = ref.interactions.expand((i) => i.relatedTo).toSet();
      expect(
        related,
        containsAll([
          Character.empath,
          Character.fortuneTeller,
          Character.undertaker,
        ]),
      );
    });

    test('undertaker：relatedTo 含 spy / recluse（死后登记错误）', () {
      final ref = characterReferences[Character.undertaker]!;
      final related = ref.interactions.expand((i) => i.relatedTo).toSet();
      expect(related, containsAll([Character.spy, Character.recluse]));
    });

    test('可验证角色均有确认路径', () {
      for (final c in [
        Character.virgin,
        Character.slayer,
        Character.undertaker,
        Character.empath,
        Character.chef,
        Character.monk,
        Character.soldier,
        Character.ravenkeeper,
      ]) {
        expect(
          characterReferences[c]?.confirmPath,
          isNotNull,
          reason: '$c 应有确认路径',
        );
      }
    });

    test('scarletWoman ↔ imp、imp ↔ scarletWoman 双向关联', () {
      final sw = characterReferences[Character.scarletWoman]!;
      final imp = characterReferences[Character.imp]!;
      expect(
        sw.interactions.any((i) => i.relatedTo.contains(Character.imp)),
        isTrue,
      );
      expect(
        imp.interactions.any((i) => i.relatedTo.contains(Character.scarletWoman)),
        isTrue,
      );
    });
  });

  group('interactionActive（上下文感知高亮）', () {
    test('涉及已声明角色 → 活跃', () {
      const poison =
          CharacterInteraction('x', relatedTo: {Character.poisoner});
      expect(interactionActive(poison, {Character.poisoner}), isTrue);
    });

    test('未涉及 → 不活跃', () {
      const poison =
          CharacterInteraction('x', relatedTo: {Character.poisoner});
      expect(interactionActive(poison, {Character.chef}), isFalse);
    });

    test('通用交互（relatedTo 空）→ 始终不活跃（不高亮）', () {
      const general = CharacterInteraction('x');
      expect(interactionActive(general, {Character.poisoner}), isFalse);
      expect(interactionActive(general, const {}), isFalse);
    });
  });
}
