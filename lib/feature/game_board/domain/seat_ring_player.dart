import 'package:botc_copilot/shared/models/enums.dart';
import 'package:characters/characters.dart';

/// 座位圆环上的玩家视图模型。
class SeatRingPlayer {
  /// 创建座位玩家。
  const SeatRingPlayer({
    required this.id,
    required this.name,
    required this.seatNumber,
    required this.isAlive,
    this.trustLevel = TrustLevel.unknown,
    this.isMe = false,
    this.isPoisoned = false,
    this.suspectedDrunk = false,
    this.hasContradiction = false,
  });

  /// 数据库玩家 id。
  final int id;

  /// 玩家名。
  final String name;

  /// 座位号（1-N）。
  final int seatNumber;

  /// 是否存活。
  final bool isAlive;

  /// 信任度（决定节点外圈色环）。
  final TrustLevel trustLevel;

  /// 是否是我自己。
  final bool isMe;

  /// 当天是否被活跃毒污染（圆环画紫色微光）。
  final bool isPoisoned;

  /// 整局是否被标记为疑似醉汉（圆环画紫色微光）。
  ///
  /// 与 [isPoisoned] 同属「能力失效（醉/毒）」tainted 口径——圆环用同一
  /// 紫色微光表示，与 `_tainted()` / 矛盾检测 / 可靠性 overlay 对齐
  /// （#156 B1）。BotC 规则上 Drunk 整局失能、Poison 当夜+次日，二者在
  /// 「能力失效」上等价。
  final bool suspectedDrunk;

  /// 是否涉及矛盾标记（圆环画警示微标记，不改变信任度颜色）。
  final bool hasContradiction;

  /// 名字首字符（节点内显示）。
  String get initial => name.isEmpty ? '?' : name.characters.first;

  /// 是否处于「能力失效（醉/毒）」状态——圆环紫色微光的判定来源。
  ///
  /// 醉（[suspectedDrunk]）与毒（[isPoisoned]）在 BotC 中均令玩家能力失效，
  /// 圆环用同一紫色微光表示；具体原因由 [semanticLabel] 区分（#156 B1）。
  bool get isTainted => isPoisoned || suspectedDrunk;

  /// 读屏语义标签（issue #135 a11y）：座位号 + 名字 + 存活状态 + 信任度
  /// + 我/中毒/醉汉/矛盾标记。供圆环每座位的 [Semantics] 节点。
  String get semanticLabel {
    final parts = <String>[
      '$seatNumber号 $name',
      isAlive ? '存活' : '已死亡',
      '信任：${trustLevel.nameCn}',
    ];
    if (isMe) parts.add('这是我');
    if (isPoisoned) parts.add('疑似被毒');
    if (suspectedDrunk) parts.add('疑似醉汉');
    if (hasContradiction) parts.add('矛盾标记');
    return parts.join('，');
  }

  /// 复制并修改部分字段。
  SeatRingPlayer copyWith({
    bool? isAlive,
    TrustLevel? trustLevel,
    bool? isMe,
    bool? isPoisoned,
    bool? suspectedDrunk,
    bool? hasContradiction,
  }) {
    return SeatRingPlayer(
      id: id,
      name: name,
      seatNumber: seatNumber,
      isAlive: isAlive ?? this.isAlive,
      trustLevel: trustLevel ?? this.trustLevel,
      isMe: isMe ?? this.isMe,
      isPoisoned: isPoisoned ?? this.isPoisoned,
      suspectedDrunk: suspectedDrunk ?? this.suspectedDrunk,
      hasContradiction: hasContradiction ?? this.hasContradiction,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SeatRingPlayer &&
      other.id == id &&
      other.name == name &&
      other.seatNumber == seatNumber &&
      other.isAlive == isAlive &&
      other.trustLevel == trustLevel &&
      other.isMe == isMe &&
      other.isPoisoned == isPoisoned &&
      other.suspectedDrunk == suspectedDrunk &&
      other.hasContradiction == hasContradiction;

  @override
  int get hashCode =>
      Object.hash(
      id, name, seatNumber, isAlive, trustLevel, isMe, isPoisoned,
      suspectedDrunk, hasContradiction,
    );
}
