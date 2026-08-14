import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';

/// 恶魔存活性判定结果（issue #208）。
enum DemonStatus {
  /// 恶魔确定存活（我是恶魔且存活 / 传承继承人存活 / starpass 推断）。
  alive,

  /// 恶魔确定死亡且无存活继承人 → 善良胜（人头邪恶胜前提不成立）。
  dead,

  /// 无足够信息（视为可能存活，走人头候选由用户裁决）。
  unknown,
}

/// 恶魔存活性 resolver（纯函数，issue #208 design v2）。
///
/// 官方语义（#149/#155 已核实 Wiki）：
/// - 人头邪恶胜前提「恶魔**活到**只剩 2 人」；
/// - 恶魔死亡 → SW 检查（死前 ≥5 + 存活 + 未毒醉，**自动**继承，优先且
///   覆盖所有死亡方式）→ 无 SW 按死亡方式：
///   - 处决 / Slayer 等白天击杀：仅 SW 可继承 → 无记录即善良胜；
///   - 夜死自杀（starpass）：**强制**传给一名存活爪牙（非可选）；无爪牙
///     可传 → 善良胜。
///
/// 认知极限（App 只知记录在案的事实）：
/// - SW 自动继承若未记录（用户关闭确认框）不可知——`dead` 判定仅作对话
///   框首选，由用户终裁；
/// - 「存活爪牙候选」按声明 / 私密名单推断，有弱性，方向保守（宁给
///   evil candidate 不误报 good win）；
/// - BMR 僵怖「首次死亡视为已死但活着」未建模（#217 增量 4），以 App
///   记录的 isAlive 为准。
abstract final class DemonStatusResolver {
  /// 判定恶魔存活性。
  ///
  /// [claims] 须为 id 升序（`watchByGame` 语义）；[inheritances] 同理。
  /// [aliveMinionCandidates] 为按声明 / 私密名单推断的存活爪牙 id 集。
  static DemonStatus resolve({
    required List<Player> players,
    Character? myRole,
    int? myPlayerId,
    List<RoleClaim> claims = const [],
    List<DemonInheritance> inheritances = const [],
    Set<int> aliveMinionCandidates = const {},
  }) {
    final byId = {for (final p in players) p.id: p};
    final iAmDemon =
        myPlayerId != null && myRole != null && myRole.team == Team.demon;

    // 1. 我 = 恶魔且存活。
    if (iAmDemon && (byId[myPlayerId]?.isAlive ?? false)) {
      return DemonStatus.alive;
    }

    // 2. 传承记录本身即恶魔事实（不依赖声明）：有记录 = 传承已发生——
    // 最新记录的继承人存活 → alive；继承人未知 → alive（恶魔存在，身份
    // 未知）；继承人死了且无更新传承 → 恶魔已死无继 → dead（任何恶魔死亡
    // 都应再走 SW/传承，无记录即无继）。
    for (final e in inheritances.reversed) {
      final heir = e.toPlayerId;
      if (heir == null) return DemonStatus.alive;
      final p = byId[heir];
      if (p == null) continue;
      return p.isAlive ? DemonStatus.alive : DemonStatus.dead;
    }

    // 3. 无传承记录：已知恶魔死亡（揭示 / 我是死恶魔）→ 按死因分流。
    //    传承确认框被关闭的僵尸态在此被纠正（#208 根因）。
    Player? knownDeadDemon;
    if (iAmDemon && byId[myPlayerId]?.isAlive == false) {
      knownDeadDemon = byId[myPlayerId];
    }
    knownDeadDemon ??= _latestRevealedDeadDemon(byId, claims);
    if (knownDeadDemon == null) return DemonStatus.unknown;

    return switch (knownDeadDemon.deathCause) {
      // 夜死自杀：官方 starpass 强制。有存活爪牙候选 → 新恶魔在场；
      // 无爪牙可传 → 善良胜。
      DeathCause.nightKill => aliveMinionCandidates.isEmpty
          ? DemonStatus.dead
          : DemonStatus.alive,
      // 处决 / Slayer 等白天击杀：仅 SW 可继承，无传承记录 → 善良胜。
      DeathCause.execution || DeathCause.other => DemonStatus.dead,
      // 旧数据无死因 → 认知不足，保守走人头候选。
      null => DemonStatus.unknown,
    };
  }

  /// 最新的「已死玩家 + 恶魔揭示」声明对应的玩家（无则 null）。
  static Player? _latestRevealedDeadDemon(
    Map<int, Player> byId,
    List<RoleClaim> claims,
  ) {
    Player? result;
    var latestClaimId = -1;
    for (final c in claims) {
      if (c.claimType != ClaimType.revealedOnDeath) continue;
      if (c.character.team != Team.demon) continue;
      final p = byId[c.playerId];
      // 死亡揭示语义上必然已死；防御旧数据（揭示后被复活）——只认死者。
      if (p == null || p.isAlive) continue;
      if (c.id > latestClaimId) {
        latestClaimId = c.id;
        result = p;
      }
    }
    return result;
  }
}
