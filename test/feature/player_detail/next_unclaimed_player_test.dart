import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/player_detail/domain/next_unclaimed_player.dart';
import 'package:flutter_test/flutter_test.dart';

Player _p(int id, int seat) => Player(
      id: id,
      gameId: 1,
      name: 'P$id',
      seatNumber: seat,
      isAlive: true,
      abilityUsed: false,
      suspectedDrunk: false,
      fakeDead: false,
      deathDay: null,
      deathCause: null,
    );

void main() {
  // 7 人局，座位 1..7（玩家 id 与座位号一致，便于断言）。
  final players = [for (var i = 1; i <= 7; i++) _p(i, i)];

  test('从当前座之后开始，返回第一个未声明者', () {
    // 我=1号；2、3 已声明；当前=1。期望下一个未声明=4号。
    final next = nextUnclaimedPlayer(
      players: players,
      claimedPlayerIds: const {2, 3},
      fromPlayerId: 1,
      myPlayerId: 1,
    );
    expect(next?.id, 4);
  });

  test('跳过己方（myPlayerId）', () {
    // 我=4号；5、6、7 已声明；当前=3。环绕到 1、2、3，但 4(己)要跳过——
    // 不过当前是 3，从 4 开始：4=己跳过，5/6/7 已声明，环绕到 1（未声明）。
    final next = nextUnclaimedPlayer(
      players: players,
      claimedPlayerIds: const {5, 6, 7},
      fromPlayerId: 3,
      myPlayerId: 4,
    );
    expect(next?.id, 1);
  });

  test('环绕：末尾座位折回首部', () {
    // 当前=7；1、2 已声明；期望 3（7 之后环绕到 1=已声明、2=已声明、3=未声明）。
    final next = nextUnclaimedPlayer(
      players: players,
      claimedPlayerIds: const {1, 2},
      fromPlayerId: 7,
      myPlayerId: 99, // 己方不在局内，确保不误跳
    );
    expect(next?.id, 3);
  });

  test('全部已声明（或仅剩己方）→ null', () {
    final next = nextUnclaimedPlayer(
      players: players,
      claimedPlayerIds: {for (var i = 1; i <= 7; i++) if (i != 4) i}, // 除己外全声明
      fromPlayerId: 1,
      myPlayerId: 4,
    );
    expect(next, isNull);
  });

  test('不把当前玩家自身算作候选（即使其未声明）', () {
    // 当前=3 未声明；其余未声明者中最小座位=1，但应从 3 之后开始 → 4。
    final next = nextUnclaimedPlayer(
      players: players,
      claimedPlayerIds: const {},
      fromPlayerId: 3,
      myPlayerId: 99,
    );
    expect(next?.id, 4);
  });

  test('乱序输入也能按座位序查找', () {
    final shuffled = [players[6], players[0], players[3], players[1]];
    // 座位序：1,2,4,7。当前=2(id2)，下一个未声明=4(id4)。
    final next = nextUnclaimedPlayer(
      players: shuffled,
      claimedPlayerIds: const {},
      fromPlayerId: 2,
      myPlayerId: 99,
    );
    expect(next?.id, 4);
  });

  test('空列表 → null', () {
    expect(
      nextUnclaimedPlayer(
        players: const [],
        claimedPlayerIds: const {},
        fromPlayerId: 1,
      ),
      isNull,
    );
  });

  test('fromPlayerId 不在列表 → null', () {
    expect(
      nextUnclaimedPlayer(
        players: players,
        claimedPlayerIds: const {},
        fromPlayerId: 999,
      ),
      isNull,
    );
  });

  // 回归（off-by-one）：当前玩家是唯一未声明者时不得返回自身 → null，
  // 否则「下一位」会重开同一玩家导致队列死循环。
  test('当前玩家是唯一未声明者 → null（不返回自身）', () {
    // 7 座，仅 3 号未声明，当前=3，其余全声明。
    final next = nextUnclaimedPlayer(
      players: players,
      claimedPlayerIds: const {1, 2, 4, 5, 6, 7},
      fromPlayerId: 3,
      myPlayerId: 99, // 不误跳 3
    );
    expect(next, isNull);
  });
}
