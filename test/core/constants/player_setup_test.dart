import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerSetup.forCount', () {
    test('7 人局：5 镇民 / 0 外来者 / 1 爪牙 / 1 恶魔', () {
      final setup = PlayerSetup.forCount(7);
      expect(setup.townsfolk, 5);
      expect(setup.outsiders, 0);
      expect(setup.minions, 1);
      expect(setup.demons, 1);
      expect(setup.evilCount, 2);
      expect(setup.goodCount, 5);
    });

    test('15 人局：9 镇民 / 2 外来者 / 3 爪牙 / 1 恶魔', () {
      final setup = PlayerSetup.forCount(15);
      expect(setup.townsfolk, 9);
      expect(setup.outsiders, 2);
      expect(setup.minions, 3);
      expect(setup.demons, 1);
      expect(setup.evilCount, 4);
    });

    test('所有人数的配置总和等于玩家数', () {
      for (var n = PlayerSetup.minPlayers; n <= PlayerSetup.maxPlayers; n++) {
        final s = PlayerSetup.forCount(n);
        expect(
          s.townsfolk + s.outsiders + s.minions + s.demons,
          n,
          reason: '$n 人局配置总和错误',
        );
      }
    });

    test('越界人数抛出 ArgumentError', () {
      expect(() => PlayerSetup.forCount(4), throwsArgumentError);
      expect(() => PlayerSetup.forCount(16), throwsArgumentError);
    });

    test('withBaron：+2 外来者、-2 镇民', () {
      final setup = PlayerSetup.forCount(7).withBaron();
      expect(setup.townsfolk, 3);
      expect(setup.outsiders, 2);
      expect(setup.minions, 1);
      expect(setup.demons, 1);
    });
  });
}
