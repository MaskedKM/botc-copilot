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

  /// 当天是否被标记为可能被毒/醉（圆环画紫色微光）。
  final bool isPoisoned;

  /// 是否涉及矛盾标记（圆环画警示微标记，不改变信任度颜色）。
  final bool hasContradiction;

  /// 名字首字符（节点内显示）。
  String get initial => name.isEmpty ? '?' : name.characters.first;

  /// 复制并修改部分字段。
  SeatRingPlayer copyWith({
    bool? isAlive,
    TrustLevel? trustLevel,
    bool? isMe,
    bool? isPoisoned,
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
      other.hasContradiction == hasContradiction;

  @override
  int get hashCode =>
      Object.hash(
      id, name, seatNumber, isAlive, trustLevel, isMe, isPoisoned,
      hasContradiction,
    );
}
