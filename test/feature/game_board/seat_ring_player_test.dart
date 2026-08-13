import 'package:botc_copilot/feature/game_board/domain/seat_ring_player.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeatRingPlayer.semanticLabel（#135 a11y）', () {
    test('含座位号/名字/存活/信任度', () {
      final p = SeatRingPlayer(
        id: 1,
        name: '阿强',
        seatNumber: 3,
        isAlive: true,
        trustLevel: TrustLevel.confirmedGood,
      );
      final label = p.semanticLabel;
      expect(label, contains('3号 阿强'));
      expect(label, contains('存活'));
      expect(label, contains('确信好人'));
      // 默认无我/毒/醉/矛盾
      expect(label, isNot(contains('这是我')));
      expect(label, isNot(contains('疑似被毒')));
      expect(label, isNot(contains('疑似醉汉')));
      expect(label, isNot(contains('矛盾标记')));
    });

    test('死亡/我/毒/矛盾标记全包含', () {
      final p = SeatRingPlayer(
        id: 1,
        name: 'A',
        seatNumber: 1,
        isAlive: false,
        isMe: true,
        isPoisoned: true,
        hasContradiction: true,
      );
      final label = p.semanticLabel;
      expect(label, contains('已死亡'));
      expect(label, contains('这是我'));
      expect(label, contains('疑似被毒'));
      expect(label, contains('矛盾标记'));
    });
  });

  group('SeatRingPlayer 醉汉口径（#156 B1）', () {
    test('suspectedDrunk：label 含「疑似醉汉」、不含「疑似被毒」', () {
      final p = SeatRingPlayer(
        id: 2,
        name: '阿珍',
        seatNumber: 5,
        isAlive: true,
        suspectedDrunk: true,
      );
      final label = p.semanticLabel;
      expect(label, contains('疑似醉汉'));
      expect(label, isNot(contains('疑似被毒')));
    });

    test('isPoisoned + suspectedDrunk：label 同时含两者', () {
      final p = SeatRingPlayer(
        id: 3,
        name: 'B',
        seatNumber: 7,
        isAlive: true,
        isPoisoned: true,
        suspectedDrunk: true,
      );
      final label = p.semanticLabel;
      expect(label, contains('疑似被毒'));
      expect(label, contains('疑似醉汉'));
    });

    test('isTainted：醉或毒任一为真即为 tainted', () {
      expect(
        SeatRingPlayer(
          id: 1, name: 'x', seatNumber: 1, isAlive: true,
        ).isTainted,
        isFalse,
      );
      expect(
        SeatRingPlayer(
          id: 1, name: 'x', seatNumber: 1, isAlive: true,
          isPoisoned: true,
        ).isTainted,
        isTrue,
      );
      expect(
        SeatRingPlayer(
          id: 1, name: 'x', seatNumber: 1, isAlive: true,
          suspectedDrunk: true,
        ).isTainted,
        isTrue,
      );
    });

    test('== / hashCode 含 suspectedDrunk', () {
      final base = SeatRingPlayer(
        id: 1, name: 'x', seatNumber: 1, isAlive: true, suspectedDrunk: false,
      );
      final drunk = SeatRingPlayer(
        id: 1, name: 'x', seatNumber: 1, isAlive: true, suspectedDrunk: true,
      );
      expect(base == drunk, isFalse);
      expect(base.hashCode == drunk.hashCode, isFalse);
      expect(base, base.copyWith()); // copyWith 默认保留 suspectedDrunk
      expect(drunk, drunk.copyWith());
    });
  });
}
