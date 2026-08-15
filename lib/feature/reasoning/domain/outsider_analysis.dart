import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/reasoning/domain/latest_claim.dart';
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

/// 外来者计数分析结果（issue #59；修正角色泛化 #266②）。
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
    required this.modifierClaims,
    required this.scriptModifiers,
    required this.expectedWithClaimed,
    required this.maxOutsiderDelta,
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

  /// 已声明的 setup 修正角色（最新声明含修正角色或我的角色是修正角色，
  /// #266② 泛化：不再只认男爵）。空 = 无修正角色声明。
  final List<Character> modifierClaims;

  /// 本剧本池中的全部 setup 修正角色（文案命名用，#266②）。
  final List<Character> scriptModifiers;

  /// 已声明修正角色下的期望外来者数（base + [claimedOutsiderDelta]，
  /// #266①：面板差额一律与此锚点或 base 比较，不再与 base+2 硬编码比）。
  final int expectedWithClaimed;

  /// 剧本 setup 修正角色的外来者最大可能增量（TB：Baron → 2）。
  final int maxOutsiderDelta;

  /// 是否检测到修正角色声明（UI 契约保留旧名；实为 modifierClaims 非空）。
  bool get baronClaimed => modifierClaims.isNotEmpty;

  /// 修正角色在场时的外来者数（base + 剧本最大增量；字段名保留 UI 契约）。
  int get baronOutsiders => baseOutsiders + maxOutsiderDelta;
}

/// 分析外来者计数偏差（纯函数，可测试）。
///
/// [claims] 须为 `RoleClaimsDao.watchByGame` 结果（按 id 升序），遍历时
/// 后者覆盖前者得到「每玩家最新声明」。与矛盾检测 rule 3 共用同一来源。
OutsiderCountAnalysis analyzeOutsiderCount({
  required int playerCount,
  required List<RoleClaim> claims,
  required Character? myRole,
  int? myPlayerId,
  Script script = Script.troubleBrewing,
}) {
  final setup = PlayerSetup.forCount(playerCount);
  final base = setup.outsiders;
  final def = ScriptDefinition.of(script);
  // 修正角色在场时的外来者参照数（含未声明的隐藏 Baron 可能，#151 S3）。
  final baronAdj = base + def.maxOutsiderDelta;

  // 每玩家最新声明，并注入「我的真实身份」（issue #107）：我是外来者时
  // 计入（Drunk 除外——其 myRole 为被告知的镇民，保持隐藏，保留 under 信号）。
  final latest = latestClaimWithSelf(
    claims,
    myPlayerId: myPlayerId,
    myRole: myRole,
  );

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

  // #266②：修正角色集合数据驱动（TB=男爵，BMR=教父，S&V=方古/亡骨魔）。
  final claimedCharacters = <Character>{
    ...{for (final c in latest.values) c.character},
    if (myRole != null) myRole,
  };
  final modifierClaims = [
    for (final c in claimedCharacters)
      if (c.setupOutsiderDeltas.isNotEmpty) c,
  ]..sort((a, b) => Character.values.indexOf(a)
      .compareTo(Character.values.indexOf(b)));
  // 已声明修正角色（含 myRole）下的期望增量（「或」型取最大候选，#231；
  // 仅负增量角色（亡骨魔）取其最大候选 -1，#266②）。
  final claimedAdj = base +
      ScriptDefinition.claimedOutsiderDelta(claimedCharacters);
  final modifierInPlay = modifierClaims.isNotEmpty;

  // #151 S3：修正角色在场时期望外来者数 = 修正后锚点，故 claimed==base 应判
  // under（缺额），而非 standard。原逻辑忽略修正角色声明致已声明仍标 standard。
  final OutsiderDeviation deviation;
  if (modifierInPlay) {
    if (claimed == claimedAdj) {
      deviation = OutsiderDeviation.standard;
    } else if (claimed < claimedAdj) {
      deviation = OutsiderDeviation.under;
    } else {
      deviation = OutsiderDeviation.over;
    }
  } else if (claimed == base) {
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
    modifierClaims: modifierClaims,
    scriptModifiers: def.setupModifiers,
    expectedWithClaimed: claimedAdj,
    maxOutsiderDelta: def.maxOutsiderDelta,
  );
}
