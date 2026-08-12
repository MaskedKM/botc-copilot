import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';

/// 构建用于推理判定的「最新声明 + 我的真实身份」map（issue #107）。
///
/// 在每玩家最新声明（claims 须为 `RoleClaimsDao.watchByGame` 结果，按 id
/// 升序，后者覆盖前者）基础上，把 [myRole] 作为我座位（[myPlayerId]）的
/// 隐含身份注入——覆盖任何公开自声明（助手视角 myRole 是真相）。注入项标
/// [ClaimType.myRole]，与公开声明区分；现有规则只显式跳过 `revealedOnDeath`，
/// 故 myRole 自然被规则 1（重复声明）/3（外来者计数）/4（Empath）计入。
///
/// 语义：[myRole] 是玩家**被告知/相信**的角色（Drunk 存的是镇民 bluff）。
/// 原样注入即可——Drunk 因此保持"隐藏"（不计入外来者），保留 #59 的
/// under-count 信号（App 无法也不应识破 Drunk 的自我欺骗）。
Map<int, RoleClaim> latestClaimWithSelf(
  List<RoleClaim> claims, {
  required int? myPlayerId,
  required Character? myRole,
}) {
  final latest = <int, RoleClaim>{};
  for (final c in claims) {
    latest[c.playerId] = c;
  }
  if (myPlayerId != null && myRole != null) {
    latest[myPlayerId] = RoleClaim(
      id: -1, // 合成项，非持久化
      playerId: myPlayerId,
      dayRecordId: -1,
      character: myRole,
      claimType: ClaimType.myRole,
    );
  }
  return latest;
}
