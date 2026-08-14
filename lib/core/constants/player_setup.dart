/// 玩家配置表（人数 → 各阵营角色数量）。
///
/// 基础人数分布表（5-15）**各官方剧本通用**（已核实官方 Wiki，#231 纠错：
/// 原「TB 基准」表述有误）；剧本差异全部来自 setup 修正角色的外来者增量
/// （[Character.setupOutsiderDeltas]，如 TB Baron +2 / BMR Godfather ±1 /
/// S&V Balloonist 0/+1），经 [withOutsiderDelta] 应用，镇民反向补偿。
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

  /// 应用 setup 修正角色的外来者增量（#231 数据化，替代 Baron 特判）。
  ///
  /// [delta] 为外来者增量（Baron +2、Godfather -1/+1 等），镇民反向
  /// 补偿（总人数不变）。断言修正后两阵营数非负——5 人局 + Baron 后剩
  /// 1 镇民，规则上合法但极端。
  PlayerSetup withOutsiderDelta(int delta) {
    assert(
      townsfolk - delta >= 0 && outsiders + delta >= 0,
      '修正后阵营数为负（镇民 $townsfolk、外来者 $outsiders、增量 $delta）',
    );
    return PlayerSetup._(
      playerCount: playerCount,
      townsfolk: townsfolk - delta,
      outsiders: outsiders + delta,
      minions: minions,
      demons: demons,
    );
  }
}
