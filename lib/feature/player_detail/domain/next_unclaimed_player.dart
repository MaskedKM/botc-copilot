import 'package:botc_copilot/core/database/app_database.dart';

/// 选取下一个未声明角色的玩家（issue #134 首夜队列加速器）。
///
/// 从 [fromPlayerId] 座位**之后**开始，按座位序环绕查找第一个「无任何角色
/// 声明」且「非己方」的玩家；全部已声明或仅剩己方时返回 null。
///
/// 首夜逐座记录声明 + 信息时，「保存并下一位」据此自动跳转，免去每次手动
/// 点圆环找下一个未声明的玩家。
///
/// - [players] 须为全部玩家（内部按 seatNumber 排序）。
/// - [claimedPlayerIds] 已有角色声明的玩家 id 集合。
/// - [fromPlayerId] 当前玩家（不计入候选，从其下一座开始）。
/// - [myPlayerId] 己方座位（跳过，不进入「他人声明」队列）。
Player? nextUnclaimedPlayer({
  required List<Player> players,
  required Set<int> claimedPlayerIds,
  required int fromPlayerId,
  int? myPlayerId,
}) {
  if (players.isEmpty) return null;
  final sorted = [...players]
    ..sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
  final startIndex = sorted.indexWhere((p) => p.id == fromPlayerId);
  if (startIndex < 0) return null;
  // 从下一座开始环绕，**仅遍历其余 n-1 座**（i ∈ [1, n-1]）——i == n 会折回
  // 当前玩家自身，必须排除，否则当前玩家是唯一未声明者时会返回自身导致死循环。
  for (var i = 1; i < sorted.length; i++) {
    final p = sorted[(startIndex + i) % sorted.length];
    if (p.id == myPlayerId) continue;
    if (!claimedPlayerIds.contains(p.id)) return p;
  }
  return null;
}
