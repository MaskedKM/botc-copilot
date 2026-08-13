import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/player_detail/domain/info_payload_formatter.dart';
import 'package:botc_copilot/feature/reasoning/domain/latest_claim.dart';
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
  noDeathNight('无人死亡夜晚'),

  /// 声明恶魔 Bluff 角色（公理3，确定性不在场）。
  bluffClaim('声明恶魔 Bluff 角色');

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
    Set<Character> demonBluffs = const {},
    int? myPlayerId,
    Character? myRole,
  }) {
    // 每玩家最新声明，并注入「我的真实身份」（issue #107）——使我座位对
    // 规则 1/3/4 可见。死亡揭示仍另行计入 confirmedRoles（myRole 不计入）。
    final latestClaim = latestClaimWithSelf(
      claims,
      myPlayerId: myPlayerId,
      myRole: myRole,
    );

    String labelOf(int playerId) {
      final p = playersById[playerId];
      final name = p != null ? '${p.seatNumber}号 ${p.name}' : '?';
      // 我座位的注入项标 myRole——描述中区分「你的真实角色」与公开声明
      return latestClaim[playerId]?.claimType == ClaimType.myRole
          ? '$name（你的真实角色）'
          : name;
    }
    // 已确认角色（issue #82）：仅死亡揭示视为「确认」（村规流程）。
    final confirmedRoles = <int, Character>{}; // playerId → confirmed
    for (final c in claims) {
      if (c.claimType == ClaimType.revealedOnDeath) {
        confirmedRoles[c.playerId] = c.character;
      }
    }
    // 掘墓人结果：高可信但**可污染**（醉/毒 / Spy 死后登记为好人 /
    // Recluse 登记为邪恶）。
    //
    // 官方时序（issue #106）：掘墓人「每夜*得知当日被投票处决者的角色」，
    // 即在第 N+1 夜得知第 N 日的处决，次日报出。掘墓人信息录入于
    // `info_declarations`（characterType == undertaker），其 dayRecordId
    // 指向**报告日**，描述的是**前一日的处决**——故按「声明日之前最近一次
    // 处决」关联被处决者。可靠性直接读 decl.reliability（录入时自动污染
    // 降级，比按天查毒标记更精确）；possiblyTainted / invalidated 视为不可靠。
    final undertakerRoles =
        _undertakerReportedRoles(declarations, days, dayRecordToDayNumber);

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
      ..._noDeathNights(days, declarations, dayRecordToDayNumber),
      ..._bluffClaims(latestClaim, demonBluffs, labelOf),
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
      if (e.value.claimType == ClaimType.revealedOnDeath) continue;
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
                '${e.value.map(labelOf).join('、')} 均指向 '
                '${e.key.nameCn}。同一角色至多 1 个，至少一人不成立。',
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
      if (e.value.claimType == ClaimType.revealedOnDeath) continue;
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

  /// 规则 3：外来者声明数即便 Baron 在场（+2）也无法解释 → 必有假报。
  ///
  /// Baron 感知（issue #59 收紧）：不再对「与 Baron 局一致（claimed == base+2）」
  /// 误报。仅在 `claimed > base+2` 时报警；`under / partial / baronConsistent`
  /// 的细致解读交由配置分析面板（SetupAnalysisPanel）。
  static List<Contradiction> _outsiderCountAnomaly(
    Map<int, RoleClaim> latestClaim,
    int expectedOutsiders,
    String Function(int) labelOf,
  ) {
    final outsiderClaims = latestClaim.entries
        .where((e) => e.value.character.team == Team.outsider)
        .toList();
    // Baron 在场最多 base+2；超过即硬矛盾
    if (outsiderClaims.length <= expectedOutsiders + 2) return [];
    return [
      Contradiction(
        type: ContradictionType.outsiderCountAnomaly,
        playerIds: outsiderClaims.map((e) => e.key).toList(),
        description:
            '外来者涉及 ${outsiderClaims.map((e) => labelOf(e.key)).join('、')}'
            '（共 ${outsiderClaims.length} 人），'
            '即便 Baron 在场（+2）最多 ${expectedOutsiders + 2} 个——'
            '必有假报外来者。',
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
      // 公理4：醉/毒 Empath 信息为假，邻座全好人不构成矛盾（#136）。
      // reliability 已由 contradictions_provider 的 effectiveReliability overlay
      // 降级（整局醉 + 按天毒），故此处直接判。
      if (decl.reliability == Reliability.possiblyTainted ||
          decl.reliability == Reliability.invalidated) {
        continue;
      }
      final day = dayRecordToDayNumber[decl.dayRecordId];
      final empath = playersById[decl.playerId];
      if (day == null || empath == null) continue;

      // 当天存活者的座位集合（deathDay 为空或 > 当天）。
      // Empath 在当夜读取（早于该日所有白天事件）：同日**非夜杀**死亡者
      // （处决 / Slayer 击杀 / 长按标死，均为白天）读取时仍存活，算邻居；
      // 同日夜杀者读取前已死，不算——issue #78 / #151 C1。
      final aliveThen = playersById.values
          .where(
            (p) =>
                p.deathDay == null ||
                p.deathDay! > day ||
                (p.deathDay == day &&
                    p.deathCause != DeathCause.nightKill),
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
  ///
  /// 联动（#110）：当晚有 Monk 保护记录时，提示优先指向「保护成功」。
  static List<Contradiction> _noDeathNights(
    List<DayRecord> days,
    List<InfoDeclaration> declarations,
    Map<int, int> dayRecordToDayNumber,
  ) {
    return [
      for (final d in days)
        if (d.nightDeathPlayerId == null &&
            d.dayNumber > 1 &&
            d.nightConfirmed)
          Contradiction(
            type: ContradictionType.noDeathNight,
            playerIds: const [],
            description: _noDeathNightDescription(
              d.dayNumber,
              declarations
                  .where(
                    (decl) =>
                        decl.characterType == Character.monk &&
                        dayRecordToDayNumber[decl.dayRecordId] == d.dayNumber,
                  )
                  .isNotEmpty,
            ),
            severity: ContradictionSeverity.info,
            dayNumber: d.dayNumber,
          ),
    ];
  }

  /// 规则 6：某玩家声明 ∈ 恶魔 Bluff（公理3，确定性不在场）。
  ///
  /// Bluff 的 3 个好人角色是恶魔方确定性得知的「不在场」角色；声明其一 = 假声明。
  /// 仅「我是恶魔」视角可用（demonBluffsJson 仅恶魔录入）。
  static List<Contradiction> _bluffClaims(
    Map<int, RoleClaim> latestClaim,
    Set<Character> demonBluffs,
    String Function(int) labelOf,
  ) {
    if (demonBluffs.isEmpty) return [];
    return [
      for (final e in latestClaim.entries)
        if (e.value.claimType != ClaimType.revealedOnDeath &&
            e.value.claimType != ClaimType.myRole &&
            demonBluffs.contains(e.value.character))
          Contradiction(
            type: ContradictionType.bluffClaim,
            playerIds: [e.key],
            description:
                '${labelOf(e.key)} 声明 ${e.value.character.nameCn}，'
                '但该角色在恶魔 Bluff 名单中（确定性不在场）——声明必假。',
            severity: ContradictionSeverity.warning,
          ),
    ];
  }

  /// 无人死亡夜晚的提示文案：有 Monk 保护记录时优先指向保护成功（#110）。
  static String _noDeathNightDescription(int dayNumber, bool hasMonkProtect) {
    if (hasMonkProtect) {
      return '第 $dayNumber 天夜晚无人死亡。当晚有僧侣保护记录——很可能是保护成功。';
    }
    return '第 $dayNumber 天夜晚无人死亡。'
        '可能：Monk 保护成功 / Soldier 免疫 / 恶魔自杀传位 / 恶魔被毒。';
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

  /// 构造「被处决者 → 掘墓人报出的角色」映射（issue #106）。
  ///
  /// 从 `info_declarations` 读掘墓人信息（`DayRecords.undertakerResultRole`
  /// 字段在生产环境无写入方，是死代码）。每条声明按官方时序关联到**声明日
  /// 之前最近一次处决**的被处决者。可靠性非 `possiblyTainted` /
  /// `invalidated` 方可采用。
  static Map<int, Character> _undertakerReportedRoles(
    List<InfoDeclaration> declarations,
    List<DayRecord> days,
    Map<int, int> dayRecordToDayNumber,
  ) {
    if (days.isEmpty) return const {};
    final sortedDays = [...days]..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    final roles = <int, Character>{};
    for (final decl in declarations) {
      if (decl.characterType != Character.undertaker) continue;
      if (decl.reliability == Reliability.possiblyTainted ||
          decl.reliability == Reliability.invalidated) {
        continue;
      }
      final reported = InfoPayloadFormatter.characterOf(decl);
      if (reported == null) continue;
      final declDay = dayRecordToDayNumber[decl.dayRecordId];
      if (declDay == null) continue;
      // 声明日之前最近一次处决（掘墓人在次夜得知前日处决）。
      DayRecord? latestExec;
      for (final d in sortedDays) {
        if (d.dayNumber >= declDay) break;
        if (d.dayExecutionPlayerId != null) latestExec = d;
      }
      if (latestExec != null) {
        roles[latestExec.dayExecutionPlayerId!] = reported;
      }
    }
    return roles;
  }
}
