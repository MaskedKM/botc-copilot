import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/setup/presentation/providers/setup_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  SetupNotifier notifier() => container.read(setupProvider.notifier);
  dynamic state() => container.read(setupProvider);

  test('默认状态：TB / 7 人 / 7 个空名字 / 第 0 步', () {
    expect(state().script, Script.troubleBrewing);
    expect(state().playerCount, 7);
    expect(state().playerNames.length, 7);
    expect(state().step, 0);
  });

  test('setPlayerCount 保留已输入名字并调整列表长度', () {
    notifier().setPlayerName(0, 'Alice');
    notifier().setPlayerName(1, 'Bob');
    notifier().setPlayerCount(5);
    expect(state().playerNames, ['Alice', 'Bob', '', '', '']);

    notifier().setPlayerCount(8);
    expect(state().playerNames.length, 8);
    expect(state().playerNames[0], 'Alice');
  });

  test('reorderSeat 拖拽换座', () {
    notifier()
      ..setPlayerName(0, 'A')
      ..setPlayerName(1, 'B')
      ..setPlayerName(2, 'C');
    // 把 0 号位拖到下标 2（ReorderableListView 语义：newIndex=3）
    notifier().reorderSeat(0, 3);
    expect(state().playerNames.sublist(0, 3), ['B', 'C', 'A']);
  });

  test('canProceed 门控：名字未填完 / 未选角色不可前进', () {
    notifier()
      ..nextStep() // → 1 人数
      ..nextStep(); // → 2 座位
    expect(state().step, 2);
    expect(state().canProceed, isFalse);

    for (var i = 0; i < 7; i++) {
      notifier().setPlayerName(i, 'P$i');
    }
    expect(state().canProceed, isTrue);

    notifier().nextStep(); // → 3 角色
    expect(state().canProceed, isFalse);
    notifier().selectRole(Character.empath);
    expect(state().canProceed, isTrue);
  });

  test('submit 写入 Game + 7 个玩家，座位号 1-7', () async {
    for (var i = 0; i < 7; i++) {
      notifier().setPlayerName(i, '玩家$i');
    }
    notifier().selectRole(Character.fortuneTeller);

    final gameId = await notifier().submit();

    final game = await db.gamesDao.getById(gameId);
    expect(game!.playerCount, 7);
    expect(game.myRole, Character.fortuneTeller);

    final players = await db.playersDao.watchByGame(gameId).first;
    expect(players.map((p) => p.seatNumber), [1, 2, 3, 4, 5, 6, 7]);
    expect(players.map((p) => p.name), containsAll(['玩家0', '玩家6']));
  });
}
