import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';

/// 外来者计数偏差类型（issue #59）。
///
/// 设 `base` = 标准配置外来者数，`baron` = base + 2（Baron 在场修正），
/// `claimed` = 最新声明外来者数。按 claimed 与 base / baron 的关系分类：
enum OutsiderDeviation {
  /// claimed == base：与标准配置一致。
  standard,

  /// claimed == base+2：与 Baron 局配置一致（+2）。
  baronConsistent,

  /// base < claimed < base+2：介于标准与 Baron 配置（仅 base+1 一种）。
  partial,

  /// claimed < base：少于标准配置（Drunk 自以为镇民 / 有人未声明）。
  under,

  /// claimed > base+2：即便 Baron 在场也超出——必有假报。
  over,
}

/// 单个声明外来者的展示信息。
class OutsiderClaimer {
  /// 创建声明外来者。
  const OutsiderClaimer({
    required this.playerId,
    required this.character,
    required this.confirmed,
  });

  /// 声明者玩家 id。
  final int playerId;

  /// 声明的角色。
  final Character character;

  /// 是否死亡揭示（确认身份，非仅声明）。
  final bool confirmed;
}

/// 外来者计数分析结果（issue #59）。
class OutsiderCountAnalysis {
  /// 创建分析结果。
  const OutsiderCountAnalysis({
    required this.playerCount,
    required this.townsfolk,
    required this.baseOutsiders,
    required this.minions,
    required this.demons,
    required this.claimedOutsiders,
    required this.deviation,
    required this.claimers,
    required this.baronClaimed,
  });

  /// 玩家数。
  final int playerCount;

  /// 标准配置镇民数。
  final int townsfolk;

  /// 标准配置外来者数（base）。
  final int baseOutsiders;

  /// 标准配置爪牙数。
  final int minions;

  /// 标准配置恶魔数。
  final int demons;

  /// 已声明外来者数。
  final int claimedOutsiders;

  /// 偏差类型。
  final OutsiderDeviation deviation;

  /// 声明外来者的玩家列表（含是否确认）。
  final List<OutsiderClaimer> claimers;

  /// 是否检测到 Baron 声明（最新声明含 Baron 或我的角色是 Baron）。
  final bool baronClaimed;

  /// Baron 在场时的外来者数（base + 2）。
  int get baronOutsiders => baseOutsiders + 2;
}

/// 分析外来者计数偏差（纯函数，可测试）。
///
/// [claims] 须为 `RoleClaimsDao.watchByGame` 结果（按 id 升序），遍历时
/// 后者覆盖前者得到「每玩家最新声明」。与矛盾检测 rule 3 共用同一来源。
OutsiderCountAnalysis analyzeOutsiderCount({
  required int playerCount,
  required List<RoleClaim> claims,
  required Character? myRole,
}) {
  final setup = PlayerSetup.forCount(playerCount);
  final base = setup.outsiders;
  final baronAdj = base + 2;

  // 每玩家最新声明（watchByGame 已按 id 升序，后者覆盖前者）
  final latest = <int, RoleClaim>{};
  for (final c in claims) {
    latest[c.playerId] = c;
  }

  final claimers = <OutsiderClaimer>[];
  for (final c in latest.values) {
    if (c.character.team == Team.outsider) {
      claimers.add(OutsiderClaimer(
        playerId: c.playerId,
        character: c.character,
        confirmed: c.claimType == ClaimType.revealedOnDeath,
      ));
    }
  }
  final claimed = claimers.length;

  final baronClaimed = myRole == Character.baron ||
      latest.values.any((c) => c.character == Character.baron);

  final OutsiderDeviation deviation;
  if (claimed == base) {
    deviation = OutsiderDeviation.standard;
  } else if (claimed == baronAdj) {
    deviation = OutsiderDeviation.baronConsistent;
  } else if (claimed > baronAdj) {
    deviation = OutsiderDeviation.over;
  } else if (claimed < base) {
    deviation = OutsiderDeviation.under;
  } else {
    // base < claimed < baronAdj
    deviation = OutsiderDeviation.partial;
  }

  return OutsiderCountAnalysis(
    playerCount: playerCount,
    townsfolk: setup.townsfolk,
    baseOutsiders: base,
    minions: setup.minions,
    demons: setup.demons,
    claimedOutsiders: claimed,
    deviation: deviation,
    claimers: claimers,
    baronClaimed: baronClaimed,
  );
}
