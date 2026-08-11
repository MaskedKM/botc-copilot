/// 玩家配置表（人数 → 各阵营角色数量）。
///
/// 数据为 Trouble Brewing 基准（AGENTS.md 配置表）。
/// Baron 在场时外来者 +2、镇民 -2，见 [PlayerSetup.withBaron]。
class PlayerSetup {
  const PlayerSetup._({
    required this.playerCount,
    required this.townsfolk,
    required this.outsiders,
    required this.minions,
    required this.demons,
  });

  /// 玩家总数（5-15）。
  final int playerCount;

  /// 镇民数。
  final int townsfolk;

  /// 外来者数。
  final int outsiders;

  /// 爪牙数。
  final int minions;

  /// 恶魔数。
  final int demons;

  /// 邪恶阵营总数（爪牙 + 恶魔）。
  int get evilCount => minions + demons;

  /// 善良阵营总数（镇民 + 外来者）。
  int get goodCount => townsfolk + outsiders;

  static const Map<int, PlayerSetup> _table = {
    5: PlayerSetup._(
      playerCount: 5,
      townsfolk: 3,
      outsiders: 0,
      minions: 1,
      demons: 1,
    ),
    6: PlayerSetup._(
      playerCount: 6,
      townsfolk: 3,
      outsiders: 1,
      minions: 1,
      demons: 1,
    ),
    7: PlayerSetup._(
      playerCount: 7,
      townsfolk: 5,
      outsiders: 0,
      minions: 1,
      demons: 1,
    ),
    8: PlayerSetup._(
      playerCount: 8,
      townsfolk: 5,
      outsiders: 1,
      minions: 1,
      demons: 1,
    ),
    9: PlayerSetup._(
      playerCount: 9,
      townsfolk: 5,
      outsiders: 2,
      minions: 1,
      demons: 1,
    ),
    10: PlayerSetup._(
      playerCount: 10,
      townsfolk: 7,
      outsiders: 0,
      minions: 2,
      demons: 1,
    ),
    11: PlayerSetup._(
      playerCount: 11,
      townsfolk: 7,
      outsiders: 1,
      minions: 2,
      demons: 1,
    ),
    12: PlayerSetup._(
      playerCount: 12,
      townsfolk: 7,
      outsiders: 2,
      minions: 2,
      demons: 1,
    ),
    13: PlayerSetup._(
      playerCount: 13,
      townsfolk: 9,
      outsiders: 0,
      minions: 3,
      demons: 1,
    ),
    14: PlayerSetup._(
      playerCount: 14,
      townsfolk: 9,
      outsiders: 1,
      minions: 3,
      demons: 1,
    ),
    15: PlayerSetup._(
      playerCount: 15,
      townsfolk: 9,
      outsiders: 2,
      minions: 3,
      demons: 1,
    ),
  };

  /// 支持的最小玩家数。
  static const int minPlayers = 5;

  /// 支持的最大玩家数。
  static const int maxPlayers = 15;

  /// 查询指定人数的配置。
  ///
  /// 人数不在 5-15 范围时抛出 [ArgumentError]。
  factory PlayerSetup.forCount(int playerCount) {
    final setup = _table[playerCount];
    if (setup == null) {
      throw ArgumentError.value(
        playerCount,
        'playerCount',
        '玩家数必须在 $minPlayers-$maxPlayers 之间',
      );
    }
    return setup;
  }

  /// Baron 在场时的修正配置：+2 外来者、-2 镇民。
  ///
  /// 断言镇民数足够（5 人局 + Baron 后剩 1 镇民，规则上合法但极端）。
  PlayerSetup withBaron() {
    assert(
      townsfolk >= 2,
      'Baron 修正后镇民数不能为负（当前 $townsfolk）',
    );
    return PlayerSetup._(
      playerCount: playerCount,
      townsfolk: townsfolk - 2,
      outsiders: outsiders + 2,
      minions: minions,
      demons: demons,
    );
  }
}
