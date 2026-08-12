import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';

/// 矛盾类型（issue #38，5 条检测规则）。
enum ContradictionType {
  /// ≥2 人声明同一好人角色。
  duplicateRoleClaim('角色重复声明'),

  /// 新声明与已确认角色（掘墓人/死亡揭示）冲突。
  confirmedRoleConflict('与已确认角色冲突'),

  /// 外来者声明数超过配置应有数量。
  outsiderCountAnomaly('外来者数量异常'),

  /// Empath 报有邪恶但邻居都声明好人。
  empathMismatch('Empath 信息与邻居声明不符'),

  /// 无人死亡夜晚。
  noDeathNight('无人死亡夜晚');

  const ContradictionType(this.nameCn);

  /// 中文显示名。
  final String nameCn;
}

/// 严重度。
enum ContradictionSeverity {
  /// 提示（仅列出可能性，如无人死亡夜晚）。
  info,

  /// 注意（需要玩家推理判断）。
  warning,
}

/// 一条矛盾标记。
///
/// 原则：只标记「数据不一致」，**绝不输出身份结论**。
class Contradiction {
  /// 创建矛盾标记。
  const Contradiction({
    required this.type,
    required this.playerIds,
    required this.description,
    required this.severity,
    this.dayNumber,
  });

  /// 矛盾类型。
  final ContradictionType type;

  /// 涉及的玩家 id。
  final List<int> playerIds;

  /// 人类可读的矛盾描述（含相关声明）。
  final String description;

  /// 严重度。
  final ContradictionSeverity severity;

  /// 相关天数（如适用）。
  final int? dayNumber;
}

/// 矛盾检测器（纯函数）。
///
/// 输入全部声明/信息/天记录，输出矛盾标记列表。
abstract final class ContradictionDetector {
  /// 检测全部 5 条规则。
  static List<Contradiction> detect({
    required List<RoleClaim> claims,
    required List<InfoDeclaration> declarations,
    required List<DayRecord> days,
    required Map<int, Player> playersById,
    required Map<int, int> dayRecordToDayNumber,
    required int expectedOutsiders,
    List<PoisonStatus> poisonStatuses = const [],
  }) {
    String labelOf(int playerId) {
      final p = playersById[playerId];
      return p != null ? '${p.seatNumber}号 ${p.name}' : '?';
    }

    // 每玩家最新声明（掘墓人/死亡揭示视为确认信息另行处理）
    final latestClaim = <int, RoleClaim>{};
    for (final c in claims) {
      latestClaim[c.playerId] = c;
    }
    // 已确认角色（issue #82）：仅死亡揭示视为「确认」（村规流程）。
    final confirmedRoles = <int, Character>{}; // playerId → confirmed
    for (final c in claims) {
      if (c.claimType.name == 'revealedOnDeath') {
        confirmedRoles[c.playerId] = c.character;
      }
    }
    // 掘墓人结果：高可信但**可污染**（醉/毒 / Spy 死后登记为好人 /
    // Recluse 登记为邪恶）。掘墓人当天被标毒/醉 → 信息不可靠，跳过。
    final undertakerClaimsList =
        claims.where((c) => c.character == Character.undertaker).toList();
    final undertakerPlayerId =
        undertakerClaimsList.isEmpty ? null : undertakerClaimsList.last.playerId;
    final undertakerRoles = <int, Character>{}; // 被处决者 → 掘墓人报出的角色
    for (final d in days) {
      if (d.undertakerResultRole != null && d.dayExecutionPlayerId != null) {
        final tainted = undertakerPlayerId != null &&
            poisonStatuses.any(
              (p) =>
                  p.playerId == undertakerPlayerId &&
                  p.dayNumber == d.dayNumber &&
                  p.isActive,
            );
        if (!tainted) {
          undertakerRoles[d.dayExecutionPlayerId!] = d.undertakerResultRole!;
        }
      }
    }

    return [
      ..._duplicateRoleClaims(latestClaim, labelOf),
      ..._confirmedRoleConflicts(
        latestClaim,
        confirmedRoles,
        undertakerRoles,
        labelOf,
      ),
      ..._outsiderCountAnomaly(latestClaim, expectedOutsiders, labelOf),
      ..._empathMismatch(
        declarations,
        latestClaim,
        playersById,
        dayRecordToDayNumber,
        labelOf,
      ),
      ..._noDeathNights(days),
    ];
  }

  /// 规则 1：≥2 人声明同一好人角色。
  ///
  /// 死亡揭示不算"声明"（那是确认信息），由规则 2 处理冲突。
  static List<Contradiction> _duplicateRoleClaims(
    Map<int, RoleClaim> latestClaim,
    String Function(int) labelOf,
  ) {
    final byCharacter = <Character, List<int>>{};
    for (final e in latestClaim.entries) {
      if (e.value.claimType.name == 'revealedOnDeath') continue;
      // 只看好人角色（镇民/外来者）——爪牙/恶魔重复声明不构成矛盾信息
      if (e.value.character.team == Team.townsfolk ||
          e.value.character.team == Team.outsider) {
        byCharacter.putIfAbsent(e.value.character, () => []).add(e.key);
      }
    }
    return [
      for (final e in byCharacter.entries)
        if (e.value.length >= 2)
          Contradiction(
            type: ContradictionType.duplicateRoleClaim,
            playerIds: e.value,
            description:
                '${e.value.map(labelOf).join('、')} 都声明是 '
                '${e.key.nameCn}。同一角色至多 1 个，至少一人的声明不成立。',
            severity: ContradictionSeverity.warning,
          ),
    ];
  }

  /// 规则 2：新声明与「已确认 / 高可信」角色冲突。
  ///
  /// - 死亡揭示（村规确认）冲突 → warning，确定性结论。
  /// - 掘墓人信息冲突 → info（**可污染**：醉/毒 / Spy 死后登记为好人 /
  ///   Recluse 登记为邪恶），仅提示可能性，不输出身份结论（issue #82）。
  static List<Contradiction> _confirmedRoleConflicts(
    Map<int, RoleClaim> latestClaim,
    Map<int, Character> confirmedRoles,
    Map<int, Character> undertakerRoles,
    String Function(int) labelOf,
  ) {
    final result = <Contradiction>[];
    for (final e in latestClaim.entries) {
      if (e.value.claimType.name == 'revealedOnDeath') continue;
      // 死亡揭示（村规确认）冲突
      if (confirmedRoles.values.contains(e.value.character) &&
          !confirmedRoles.containsKey(e.key)) {
        result.add(
          Contradiction(
            type: ContradictionType.confirmedRoleConflict,
            playerIds: [
              e.key,
              ...confirmedRoles.entries
                  .where((c) => c.value == e.value.character)
                  .map((c) => c.key),
            ],
            description:
                '${labelOf(e.key)} 声明 ${e.value.character.nameCn}，'
                '但该角色已被死亡揭示确认在他人身上（村规确认）。',
            severity: ContradictionSeverity.warning,
          ),
        );
      }
      // 掘墓人信息冲突（可污染，仅提示）
      if (undertakerRoles.values.contains(e.value.character) &&
          !undertakerRoles.containsKey(e.key) &&
          !confirmedRoles.containsKey(e.key)) {
        result.add(
          Contradiction(
            type: ContradictionType.confirmedRoleConflict,
            playerIds: [
              e.key,
              ...undertakerRoles.entries
                  .where((c) => c.value == e.value.character)
                  .map((c) => c.key),
            ],
            description:
                '${labelOf(e.key)} 声明 ${e.value.character.nameCn}，'
                '与掘墓人报出的角色冲突。掘墓人信息可能被毒/醉污染，'
                '或 Spy 死后登记为好人 / Recluse 登记为邪恶。',
            severity: ContradictionSeverity.info,
          ),
        );
      }
    }
    return result;
  }

  /// 规则 3：外来者声明数超过配置应有数量。
  static List<Contradiction> _outsiderCountAnomaly(
    Map<int, RoleClaim> latestClaim,
    int expectedOutsiders,
    String Function(int) labelOf,
  ) {
    final outsiderClaims = latestClaim.entries
        .where((e) => e.value.character.team == Team.outsider)
        .toList();
    if (outsiderClaims.length <= expectedOutsiders) return [];
    return [
      Contradiction(
        type: ContradictionType.outsiderCountAnomaly,
        playerIds: outsiderClaims.map((e) => e.key).toList(),
        description:
            '声明外来者的有 ${outsiderClaims.map((e) => labelOf(e.key)).join('、')}'
            '（共 ${outsiderClaims.length} 人），'
            '但本局配置应有 $expectedOutsiders 个外来者。'
            '可能：Baron 在场改配置（+2）/ 有人假报外来者。',
        severity: ContradictionSeverity.warning,
      ),
    ];
  }

  /// 规则 4：Empath 报 N>0 邪恶，但当时存活的邻座都声明好人。
  static List<Contradiction> _empathMismatch(
    List<InfoDeclaration> declarations,
    Map<int, RoleClaim> latestClaim,
    Map<int, Player> playersById,
    Map<int, int> dayRecordToDayNumber,
    String Function(int) labelOf,
  ) {
    final results = <Contradiction>[];
    for (final decl in declarations) {
      if (decl.characterType != Character.empath) continue;
      final value = _payloadValue(decl.payloadJson);
      if (value == null || value == 0) continue;
      final day = dayRecordToDayNumber[decl.dayRecordId];
      final empath = playersById[decl.playerId];
      if (day == null || empath == null) continue;

      // 当天存活者的座位集合（deathDay 为空或 > 当天）。
      // 当天被处决者仍算存活邻居（处决在 Empath 读取之后），当夜被杀者
      // 不算（被杀在 Empath 读取之前）——issue #78。
      final aliveThen = playersById.values
          .where(
            (p) =>
                p.deathDay == null ||
                p.deathDay! > day ||
                (p.deathDay == day &&
                    p.deathCause == DeathCause.execution),
          )
          .toList();
      final neighbors = _aliveNeighbors(empath, aliveThen);
      if (neighbors.isEmpty) continue;

      // 邻居都声明好人角色（镇民/外来者）
      final allGoodClaims = neighbors.every((n) {
        final claim = latestClaim[n.id];
        return claim != null &&
            (claim.character.team == Team.townsfolk ||
                claim.character.team == Team.outsider);
      });
      if (allGoodClaims) {
        results.add(
          Contradiction(
            type: ContradictionType.empathMismatch,
            playerIds: [decl.playerId, ...neighbors.map((n) => n.id)],
            description:
                '${labelOf(decl.playerId)} 的 Empath 信息为 $value（有邪恶），'
                '但其邻座 ${neighbors.map((n) => labelOf(n.id)).join('、')}'
                ' 都声明好人角色。信息可能被污染（醉/毒），或有人声明不实。',
            severity: ContradictionSeverity.info,
            dayNumber: day,
          ),
        );
      }
    }
    return results;
  }

  /// 规则 5：无人死亡夜晚 → 列出可能性（仅提示，不涉及具体玩家）。
  ///
  /// 第 1 天跳过：官方规则恶魔首夜不杀人，无夜死是常态。
  /// 仅对**已确认**（nightConfirmed）的天生效，避免预建未录的天误报（#77）。
  static List<Contradiction> _noDeathNights(List<DayRecord> days) {
    return [
      for (final d in days)
        if (d.nightDeathPlayerId == null &&
            d.dayNumber > 1 &&
            d.nightConfirmed)
          Contradiction(
            type: ContradictionType.noDeathNight,
            playerIds: const [],
            description:
                '第 ${d.dayNumber} 天夜晚无人死亡。'
                '可能：Monk 保护成功 / Soldier 免疫 / 恶魔自杀传位 / 恶魔被毒。',
            severity: ContradictionSeverity.info,
            dayNumber: d.dayNumber,
          ),
    ];
  }

  /// 座位收缩后的存活邻座（死亡玩家物理移除，两侧并拢）。
  static List<Player> _aliveNeighbors(Player target, List<Player> aliveThen) {
    final sorted = [...aliveThen]..sort((a, b) => a.seatNumber - b.seatNumber);
    final idx = sorted.indexWhere((p) => p.id == target.id);
    if (idx < 0 || sorted.length < 3) return [];
    return [
      sorted[(idx - 1 + sorted.length) % sorted.length],
      sorted[(idx + 1) % sorted.length],
    ];
  }

  static int? _payloadValue(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map && decoded['value'] is int) {
        return decoded['value'] as int;
      }
      return null;
    } on FormatException {
      return null;
    }
  }
}
