import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/game_private.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Game _game({String? minionIdsJson, String? demonBluffsJson}) => Game(
      id: 1,
      script: Script.troubleBrewing,
      playerCount: 7,
      status: GameStatus.ongoing,
      createdAt: DateTime(2026, 8, 12),
      helpLevel: HelpLevel.normal,
      myMinionIdsJson: minionIdsJson,
      demonBluffsJson: demonBluffsJson,
    );

void main() {
  group('minionIdsOf（#108）', () {
    test('null → 空', () {
      expect(minionIdsOf(_game()), isEmpty);
    });

    test('[1, 2, 3] → {1, 2, 3}', () {
      expect(minionIdsOf(_game(minionIdsJson: '[1,2,3]')), {1, 2, 3});
    });

    test('malformed JSON → 空', () {
      expect(minionIdsOf(_game(minionIdsJson: 'not json')), isEmpty);
    });

    test('空数组 → 空', () {
      expect(minionIdsOf(_game(minionIdsJson: '[]')), isEmpty);
    });

    // #164 B3/B5：JSON 合法但非数组时 as List 抛 TypeError 逃逸 FormatException。
    test('合法 JSON 但非数组（int/object/null）→ 空，不抛', () {
      expect(() => minionIdsOf(_game(minionIdsJson: '123')), returnsNormally);
      expect(minionIdsOf(_game(minionIdsJson: '123')), isEmpty);
      expect(minionIdsOf(_game(minionIdsJson: '{"a":1}')), isEmpty);
      expect(minionIdsOf(_game(minionIdsJson: 'null')), isEmpty);
    });
  });

  group('demonBluffsOf（#136 / #164 B3/B5）', () {
    test('null → 空', () {
      expect(demonBluffsOf(_game()), isEmpty);
    });

    test('合法角色名数组 → 解析', () {
      expect(
        demonBluffsOf(_game(demonBluffsJson: '["chef", "empath"]')),
        {Character.chef, Character.empath},
      );
    });

    test('合法 JSON 但非数组 → 空，不抛', () {
      expect(() => demonBluffsOf(_game(demonBluffsJson: '123')), returnsNormally);
      expect(demonBluffsOf(_game(demonBluffsJson: '123')), isEmpty);
      expect(demonBluffsOf(_game(demonBluffsJson: '{"a":1}')), isEmpty);
    });

    test('malformed JSON → 空', () {
      expect(demonBluffsOf(_game(demonBluffsJson: 'not json')), isEmpty);
    });
  });

  group('gamesDao.updateMyMinionIds（#108）', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.gamesDao.insertGame(
        GamesCompanion(
          script: const Value(Script.troubleBrewing),
          playerCount: const Value(7),
          status: const Value(GameStatus.ongoing),
          createdAt: Value(DateTime(2026, 8, 12)),
        ),
      );
    });

    tearDown(() => db.close());

    test('写入 + 读回', () async {
      await db.gamesDao.updateMyMinionIds(1, '[3, 5]');
      final game = await db.gamesDao.getById(1);
      expect(game?.myMinionIdsJson, '[3, 5]');
      expect(minionIdsOf(game!), {3, 5});
    });

    test('清空（写入 []）', () async {
      await db.gamesDao.updateMyMinionIds(1, '[3]');
      await db.gamesDao.updateMyMinionIds(1, '[]');
      final game = await db.gamesDao.getById(1);
      expect(minionIdsOf(game!), isEmpty);
    });
  });
}
