import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
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

  /// Fortune Teller 读数与已确认角色不符（#159 G1）。
  fortuneTellerMismatch('占卜师信息与已确认角色不符'),

  /// 无人死亡夜晚。
  noDeathNight('无人死亡夜晚'),

  /// 声明恶魔 Bluff 角色（公理3，确定性不在场）。
  bluffClaim('声明恶魔 Bluff 角色'),

  /// 镇民/爪牙/恶魔声明总数超过配置槽位（issue #212，硬约束）。
  teamCountOverflow('阵营人数超限'),

  /// 开局指认（洗衣妇/调查员/图书管理员）与已确认角色或 Bluff 冲突（#213）。
  startInfoPingConflict('开局指认与确认冲突'),

  /// 图书管理员「无外来者」信息与已确认外来者冲突（#213）。
  zeroOutsiderConflict('「无外来者」与确认冲突'),

  /// 厨师计数与邪恶配置/已确认邪恶座位冲突（#213）。
  chefCountMismatch('厨师计数与邪恶不符');

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
    PlayerSetup? setup,
    Script script = Script.troubleBrewing,
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

    // 机制层（#234）：facts 一次性打包原始输入与派生视图，规则经注册表
    // 按剧本选择执行——BMR/S&V 落地时「注册新规则」而非改本方法。
    final facts = ContradictionFacts(
      script: script,
      claims: claims,
      declarations: declarations,
      days: days,
      playersById: playersById,
      dayRecordToDayNumber: dayRecordToDayNumber,
      expectedOutsiders: expectedOutsiders,
      setup: setup,
      demonBluffs: demonBluffs,
      myPlayerId: myPlayerId,
      myRole: myRole,
      latestClaim: latestClaim,
      confirmedRoles: confirmedRoles,
      undertakerRoles: undertakerRoles,
    );

    return [
      for (final rule in contradictionRulesFor(script))
        if (rule.applies(facts)) ...rule.run(facts),
    ];
  }

  /// detect 的展示标签（供规则复用；抽取自原内联 labelOf）。
  static String _labelOf(
    Map<int, RoleClaim> latestClaim,
    Map<int, Player> playersById,
    int playerId,
  ) {
    final p = playersById[playerId];
    final name = p != null ? '${p.seatNumber}号 ${p.name}' : '?';
    return latestClaim[playerId]?.claimType == ClaimType.myRole
        ? '$name（你的真实角色）'
        : name;
  }

  /// 规则 3：外来者声明数即便 Baron 在场（+2）也无法解释 → 必有假报（机制层适配）。
  static List<Contradiction> _ruleOutsiderCount(ContradictionFacts f) =>
      _outsiderCountAnomaly(
        f.latestClaim,
        f.expectedOutsiders,
        ScriptDefinition.of(f.script).maxOutsiderDelta,
        (pid) => _labelOf(f.latestClaim, f.playersById, pid),
      );

  /// 规则 3b：阵营人数硬约束（#212；仅 setup 可得时适用，机制层适配）。
  static List<Contradiction> _ruleTeamCountOverflow(ContradictionFacts f) =>
      _teamCountOverflow(
        f.latestClaim,
        f.setup!,
        (pid) => _labelOf(f.latestClaim, f.playersById, pid),
      );

  /// 规则 7：开局指认交叉验证（机制层适配）。
  static List<Contradiction> _ruleStartInfoPing(ContradictionFacts f) =>
      _startInfoPingConflicts(
        f.script,
        f.declarations,
        f.confirmedRoles,
        f.demonBluffs,
        (pid) => _labelOf(f.latestClaim, f.playersById, pid),
        myPlayerId: f.myPlayerId,
        myRole: f.myRole,
      );

  /// 规则 8：厨师计数交叉验证（机制层适配）。
  static List<Contradiction> _ruleChefCount(ContradictionFacts f) =>
      _chefCountMismatch(
        f.declarations,
        f.confirmedRoles,
        f.playersById,
        f.setup,
        (pid) => _labelOf(f.latestClaim, f.playersById, pid),
        myPlayerId: f.myPlayerId,
        myRole: f.myRole,
      );

  // ---- 机制层适配器（#234）：闭包把 facts 摊回既有规则函数，语义零变化 ----

  static List<Contradiction> _ruleDuplicate(ContradictionFacts f) =>
      _duplicateRoleClaims(
        f.latestClaim,
        (pid) => _labelOf(f.latestClaim, f.playersById, pid),
      );

  static List<Contradiction> _ruleConfirmedConflict(ContradictionFacts f) =>
      _confirmedRoleConflicts(
        f.latestClaim,
        f.confirmedRoles,
        f.undertakerRoles,
        (pid) => _labelOf(f.latestClaim, f.playersById, pid),
      );

  static List<Contradiction> _ruleEmpath(ContradictionFacts f) =>
      _empathMismatch(
        f.declarations,
        f.latestClaim,
        f.playersById,
        f.dayRecordToDayNumber,
        f.confirmedRoles,
        (pid) => _labelOf(f.latestClaim, f.playersById, pid),
        myPlayerId: f.myPlayerId,
        myRole: f.myRole,
      );

  static List<Contradiction> _ruleFortuneTeller(ContradictionFacts f) =>
      _fortuneTellerMismatch(
        f.declarations,
        f.confirmedRoles,
        f.dayRecordToDayNumber,
        (pid) => _labelOf(f.latestClaim, f.playersById, pid),
        myPlayerId: f.myPlayerId,
        myRole: f.myRole,
      );

  static List<Contradiction> _ruleNoDeathNight(ContradictionFacts f) =>
      _noDeathNights(f.days, f.declarations, f.dayRecordToDayNumber);

  static List<Contradiction> _ruleBluffClaim(ContradictionFacts f) =>
      _bluffClaims(
        f.latestClaim,
        f.demonBluffs,
        (pid) => _labelOf(f.latestClaim, f.playersById, pid),
      );

  /// TB 规则集（#234 注册表）：顺序即输出顺序（与单体时代一致，golden）。
  /// 新剧本规则经各自注册表追加（#217），不再改 detect 单体。
  static const _tbRules = <ContradictionRule>[
    ContradictionRule(id: 'duplicate-role-claim', run: _ruleDuplicate),
    ContradictionRule(id: 'confirmed-role-conflict', run: _ruleConfirmedConflict),
    ContradictionRule(id: 'outsider-count-anomaly', run: _ruleOutsiderCount),
    ContradictionRule(
      id: 'team-count-overflow',
      applies: _needsSetup,
      run: _ruleTeamCountOverflow,
    ),
    ContradictionRule(id: 'empath-mismatch', run: _ruleEmpath),
    ContradictionRule(id: 'fortune-teller-mismatch', run: _ruleFortuneTeller),
    ContradictionRule(id: 'no-death-night', run: _ruleNoDeathNight),
    ContradictionRule(id: 'bluff-claim', run: _ruleBluffClaim),
    ContradictionRule(id: 'start-info-ping', run: _ruleStartInfoPing),
    ContradictionRule(id: 'chef-count', run: _ruleChefCount),
  ];

  static bool _needsSetup(ContradictionFacts f) => f.setup != null;


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
      // #151 S2：角色唯一公理仅适用好人角色——Imp 传承后 legitimately 存在
      // 新 Imp，恶魔/爪牙重复不应误报冲突（与 _duplicateRoleClaims 口径一致）。
      if (!e.value.character.team.isGood) continue;
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
      // #151 S1：被处决者本人声明 vs 掘墓人对本人的报告冲突。
      // 原 cross-player 检查含 !undertakerRoles.containsKey(e.key) 跳过本人，
      // 漏判「本人声明 X / 掘墓人报其为 Y」的直接冲突（复活 / 早于处决的声明）。
      final reportedSelf = undertakerRoles[e.key];
      if (reportedSelf != null &&
          reportedSelf != e.value.character &&
          !confirmedRoles.containsKey(e.key)) {
        result.add(
          Contradiction(
            type: ContradictionType.confirmedRoleConflict,
            playerIds: [e.key],
            description:
                '${labelOf(e.key)} 声明 ${e.value.character.nameCn}，'
                '但掘墓人报出其为 ${reportedSelf.nameCn}。掘墓人信息可能被毒/醉污染，'
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
  /// 修正角色感知（issue #59 收紧，#231 数据化）：不再对「与修正局一致
  /// （claimed == base+最大增量）」误报。仅在超过时报警；`under / partial /
  /// baronConsistent` 的细致解读交由配置分析面板（SetupAnalysisPanel）。
  static List<Contradiction> _outsiderCountAnomaly(
    Map<int, RoleClaim> latestClaim,
    int expectedOutsiders,
    int maxOutsiderDelta,
    String Function(int) labelOf,
  ) {
    final outsiderClaims = latestClaim.entries
        .where((e) => e.value.character.team == Team.outsider)
        .toList();
    // 修正角色在场最多 base+最大增量（TB：Baron +2）；超过即硬矛盾
    if (outsiderClaims.length <= expectedOutsiders + maxOutsiderDelta) {
      return [];
    }
    return [
      Contradiction(
        type: ContradictionType.outsiderCountAnomaly,
        playerIds: outsiderClaims.map((e) => e.key).toList(),
        description:
            '外来者涉及 ${outsiderClaims.map((e) => labelOf(e.key)).join('、')}'
            '（共 ${outsiderClaims.length} 人），'
            '即便修正角色在场（+$maxOutsiderDelta）'
            '最多 ${expectedOutsiders + maxOutsiderDelta} 个——'
            '必有假报外来者。',
        severity: ContradictionSeverity.warning,
      ),
    ];
  }

  /// 规则 3b：镇民/爪牙/恶魔声明总数超过配置槽位（issue #212，硬约束）。
  ///
  /// 与外来者（规则 3，有 Baron +2 容差）类似，这三阵营声明数也有容差：
  /// - **镇民**：Baron 只减不增（最多 base）；但 Drunk（外来者）以镇民 bluff
  ///   自居、会声明镇民角色，故镇民声明最多 base+1。保守 +1 Drunk 容差，
  ///   仅 > base+1 时报（避免把 Drunk 在场的正常场景误报为矛盾）。
  /// - **爪牙**：Baron 不影响，声明 > base 必有假。
  /// - **恶魔**：TB 恒为 1；**排除死亡揭示**——传承公理下多个玩家可先后当过
  ///   恶魔（原 Imp 死 + 继承人），死揭示的恶魔不计入「在世恶魔槽」，否则
  ///   会误报「死揭示 Imp + 在世继承人声明 Imp」。
  ///
  /// 均为 warning 级（逻辑必然）。Recluse/Spy 的 registration 不影响「声明」
  /// 计数——按声明角色所属阵营统计即可（声明 Imp 即算恶魔声明）。
  static List<Contradiction> _teamCountOverflow(
    Map<int, RoleClaim> latestClaim,
    PlayerSetup setup,
    String Function(int) labelOf,
  ) {
    final result = <Contradiction>[];

    void check(
      Team team,
      int slot,
      String teamName, {
      bool excludeRevealed = false,
      int tolerance = 0,
      String? toleranceNote,
    }) {
      final effective = slot + tolerance;
      final entries = latestClaim.entries.where((e) {
        if (e.value.character.team != team) return false;
        // 恶魔排除死亡揭示（传承可致多人先后为恶魔）。
        if (excludeRevealed &&
            e.value.claimType == ClaimType.revealedOnDeath) {
          return false;
        }
        return true;
      }).toList();
      if (entries.length <= effective) return;
      final note = toleranceNote == null ? '' : '（$toleranceNote）';
      result.add(
        Contradiction(
          type: ContradictionType.teamCountOverflow,
          playerIds: entries.map((e) => e.key).toList(),
          description:
              '$teamName 涉及 ${entries.map((e) => labelOf(e.key)).join('、')}'
              '（共 ${entries.length} 人），'
              '但 ${setup.playerCount} 人局配置最多 $effective 个$teamName'
              '$note——必有假报。',
          severity: ContradictionSeverity.warning,
        ),
      );
    }

    // 镇民：Drunk 是外来者但以镇民 bluff 自居、会声明镇民角色
    // （latestClaimWithSelf 不识破 Drunk——见其 dartdoc），故镇民声明最多
    // base+1。无法确知 Drunk 是否在场，保守 +1 容差——与 _outsiderCountAnomaly
    // 的 Baron +2 容差同哲学，只在确定性矛盾（> base+1）时报，避免把 Drunk
    // 在场的正常场景误报为矛盾。
    check(
      Team.townsfolk,
      setup.townsfolk,
      '镇民',
      tolerance: 1,
      toleranceNote: '含 1 个可能的 Drunk 误声明',
    );
    check(Team.minion, setup.minions, '爪牙');
    check(Team.demon, setup.demons, '恶魔', excludeRevealed: true);
    return result;
  }

  /// 规则 4：Empath 读数与邻居声明 / 已确认邪恶交叉验证。
  ///
  /// - 正向：报 N>0 邪恶，但当时存活的邻座都声明好人。
  /// - 反向（#213）：报 0，但当时存活的邻座已被**死亡揭示 / 真实角色**确认
  ///   为严格邪恶（非 Spy 的爪牙/恶魔）。清醒 Empath 必读 ≥1 → warning。
  ///   Spy/Recluse 邻座不触发（登记弹性：Spy 可向善良登记、Recluse 默认善良）。
  ///
  /// 已知局限（#151 S4，可接受）：正向未建模 Recluse（可登记为邪恶）/ Spy（可登记为
  /// 好人）的 registration——邻座是 Recluse 时 Empath 合法读出邪恶，可能误报。
  /// 属隐藏信息，App 无法确认真身；该矛盾为 info 级（仅提示），且 Recluse/Spy 在场
  /// 时可靠性 overlay 已降级，误报影响可控。
  static List<Contradiction> _empathMismatch(
    List<InfoDeclaration> declarations,
    Map<int, RoleClaim> latestClaim,
    Map<int, Player> playersById,
    Map<int, int> dayRecordToDayNumber,
    Map<int, Character> confirmedRoles,
    String Function(int) labelOf, {
    int? myPlayerId,
    Character? myRole,
  }) {
    final results = <Contradiction>[];
    for (final decl in declarations) {
      if (decl.characterType != Character.empath) continue;
      final value = _payloadValue(decl.payloadJson);
      if (value == null) continue;
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

      // 反向（#213）：0 但当时存活邻座已确认严格邪恶。
      if (value == 0) {
        final evilNeighbors = neighbors
            .where((n) {
              final c = confirmedRoles[n.id] ??
                  (n.id == myPlayerId ? myRole : null);
              return c != null && _strictlyEvil(c);
            })
            .toList();
        if (evilNeighbors.isNotEmpty) {
          results.add(
            Contradiction(
              type: ContradictionType.empathMismatch,
              playerIds: [
                decl.playerId,
                ...evilNeighbors.map((n) => n.id),
              ],
              description:
                  '${labelOf(decl.playerId)} 的 Empath 信息为 0，'
                  '但邻座 ${evilNeighbors.map((n) => labelOf(n.id)).join('、')} '
                  '已确认邪恶（死亡揭示/真实角色）。信息必假（醉/毒已滤）。',
              severity: ContradictionSeverity.warning,
              dayNumber: day,
            ),
          );
        }
        continue;
      }

      // 正向补强（#213 review）：报 >0 但当时存活邻座**全部已确认**善良
      // （镇民/外来者且非隐士）——无任何可登记为邪恶的邻座（隐士可向邪恶
      // 登记；Spy 属邪恶队、确认后仍默认按邪恶登记，二者均排除在「确认
      // 善良」外），读数不可能 → warning。强于下方基于声明的 info 检查，
      // 触发即短路避免同一 decl 双报。
      final allConfirmedGoodNonRecluse = neighbors.every((n) {
        final c =
            confirmedRoles[n.id] ?? (n.id == myPlayerId ? myRole : null);
        return c != null && c.team.isGood && !c.mayRegisterAsEvil;
      });
      if (allConfirmedGoodNonRecluse) {
        results.add(
          Contradiction(
            type: ContradictionType.empathMismatch,
            playerIds: [decl.playerId, ...neighbors.map((n) => n.id)],
            description:
                '${labelOf(decl.playerId)} 的 Empath 信息为 $value，'
                '但当时邻座 ${neighbors.map((n) => labelOf(n.id)).join('、')} '
                '均已确认善良（非隐士）——无人可登记为邪恶，读数必假'
                '（醉/毒已滤）。',
            severity: ContradictionSeverity.warning,
            dayNumber: day,
          ),
        );
        continue;
      }

      // 邻居都声明好人角色（镇民/外来者）
      final allGoodClaims = neighbors.every((n) {
        final claim = latestClaim[n.id];
        return claim != null &&
            (claim.character.team == Team.townsfolk ||
                claim.character.team == Team.outsider);
      });
      // #213 review：邻座已确认是隐士/间谍 → 读邪恶合法（登记弹性：隐士
      // 可向邪恶登记、间谍默认按邪恶登记）。原 #151 S4「隐藏信息不可知」
      // 局限在**有确认证据**时可精确豁免，不再误报。
      final registrationExplains = neighbors.any((n) {
        final c =
            confirmedRoles[n.id] ?? (n.id == myPlayerId ? myRole : null);
        return c != null &&
            (c.mayRegisterAsEvil || c.mayRegisterAsGood);
      });
      if (allGoodClaims && !registrationExplains) {
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

  /// 规则 5（FT）：Fortune Teller 读数与已确认角色交叉验证（#159 G1）。
  ///
  /// 占卜师每夜选 2 人得知「其中是否有恶魔」。registration 语义：
  /// - **Recluse 登记为邪恶** → FT 对含 Recluse 的 pair 读「是」（合法解释）。
  /// - **Spy 登记为好人** → 不触发 FT。
  /// - 官方红鲱鱼机制：FT 信息**不一定准确**（外来者为 0 时有 1/3 概率取反），
  ///   故所有 FT 矛盾均为 **info 级**，仅提示可能性，不输出身份结论。
  ///
  /// 公理4：醉/毒 FT 信息不可靠，跳过（reliability 已 overlay 降级）。
  ///
  /// 已知局限：仅用**死亡揭示 / 我座位真实角色**等「确认」信号交叉验证；
  /// 不依赖公开声明（声称为好人的玩家可能是说谎的恶魔）。Recluse 未确认时
  /// 仍是合法解释，故「是 + 两人确认好人」仅在两人都**确认非 Recluse** 时才提示。
  static List<Contradiction> _fortuneTellerMismatch(
    List<InfoDeclaration> declarations,
    Map<int, Character> confirmedRoles,
    Map<int, int> dayRecordToDayNumber,
    String Function(int) labelOf, {
    int? myPlayerId,
    Character? myRole,
  }) {
    final results = <Contradiction>[];

    // 是否「确认/已知为恶魔」：死亡揭示为恶魔，或我座位真实角色为恶魔。
    bool isKnownDemon(int pid) {
      final c = confirmedRoles[pid];
      if (c != null && c.team == Team.demon) return true;
      if (pid == myPlayerId &&
          myRole != null &&
          myRole.team == Team.demon) {
        return true;
      }
      return false;
    }

    // 是否「登记为恶魔」：真恶魔，或可向邪恶登记的修饰角色（TB=Recluse，
    // #234 数据化）。FT 对二者均读「是」；Spy 向善良登记，不触发。
    bool registersAsDemon(int pid) =>
        isKnownDemon(pid) ||
        (confirmedRoles[pid]?.mayRegisterAsEvil ?? false);

    for (final decl in declarations) {
      if (decl.characterType != Character.fortuneTeller) continue;
      if (decl.reliability == Reliability.possiblyTainted ||
          decl.reliability == Reliability.invalidated) {
        continue;
      }
      final parsed = _parseFortuneTellerPayload(decl.payloadJson);
      if (parsed == null) continue;
      final (pair, demonPresent) = parsed;
      if (pair.length != 2) continue;
      final day = dayRecordToDayNumber[decl.dayRecordId];

      if (!demonPresent) {
        // 读「否」：pair 中不应有登记为恶魔者（Imp / Recluse）。
        final hit = pair.where(registersAsDemon).toList();
        if (hit.isEmpty) continue;
        results.add(
          Contradiction(
            type: ContradictionType.fortuneTellerMismatch,
            playerIds: [decl.playerId, ...hit],
            description:
                '${labelOf(decl.playerId)} 的占卜师读「否」（无恶魔），'
                '但 ${hit.map(labelOf).join('、')} 登记为恶魔'
                '（Imp 或 Recluse）。信息可能被污染（醉/毒）'
                '或受官方红鲱鱼机制影响。',
            severity: ContradictionSeverity.info,
            dayNumber: day,
          ),
        );
      } else {
        // 读「是」：两人都已确认好人且非 Recluse 时，无恶魔/Recluse 解释 → 提示。
        bool confirmedGoodNonRecluse(int pid) {
          final c = confirmedRoles[pid];
          return c != null && c.team.isGood && !c.mayRegisterAsEvil;
        }

        if (pair.every(confirmedGoodNonRecluse)) {
          results.add(
            Contradiction(
              type: ContradictionType.fortuneTellerMismatch,
              playerIds: [decl.playerId, ...pair],
              description:
                  '${labelOf(decl.playerId)} 的占卜师读「是」（有恶魔），'
                  '但 ${pair.map(labelOf).join('、')} 均已确认好人。'
                  '可能被污染（醉/毒）、官方红鲱鱼，'
                  '或有未确认的 Recluse（登记为邪恶）。',
              severity: ContradictionSeverity.info,
              dayNumber: day,
            ),
          );
        }
      }
    }
    return results;
  }

  /// 规则 7（#213）：开局指认与已确认角色 / 恶魔 Bluff 交叉验证。
  ///
  /// 洗衣妇/调查员/图书管理员「{A,B} 中有一人是 Y」——清醒时必真：一人
  /// **是** Y，或**登记为** Y。官方 registration 是**单向且可选**（might
  /// register，说书人决定）：Spy 只能向善良登记（可冒充镇民/外来者）、
  /// Recluse 只能向邪恶登记（可冒充爪牙/恶魔）。故：
  /// - 证据 1：Y 已被死亡揭示 / 我座位确认在**第三人**身上 → 唯一性公理下
  ///   pair 无人是 Y → 只剩登记冒充可解释；
  /// - 证据 2：Y ∈ 恶魔 Bluff（确定性不在场）→ 同上。
  /// 逃生舱：善良 Y 仅 Spy、爪牙 Y 仅 Recluse。pair 全员已确认非逃生角色 →
  /// 无合法解释 → warning；否则 info（可能含未确认的 Spy/Recluse）。
  static List<Contradiction> _startInfoPingConflicts(
    Script script,
    List<InfoDeclaration> declarations,
    Map<int, Character> confirmedRoles,
    Set<Character> demonBluffs,
    String Function(int) labelOf, {
    int? myPlayerId,
    Character? myRole,
  }) {
    final results = <Contradiction>[];
    // 「确认角色」统一视图：死亡揭示优先；我座位补真实角色（#107 注入同源，
    // myRole 对非 Drunk 是真相）。
    Character? confirmedOf(int pid) =>
        confirmedRoles[pid] ?? (pid == myPlayerId ? myRole : null);

    for (final decl in declarations) {
      final type = decl.characterType;
      if (type != Character.washerwoman &&
          type != Character.investigator &&
          type != Character.librarian) {
        continue;
      }
      // 公理4：醉/毒的开局信息可能为假（reliability 已 overlay 降级）。
      if (decl.reliability == Reliability.possiblyTainted ||
          decl.reliability == Reliability.invalidated) {
        continue;
      }
      final parsed = _parsePingPayload(decl.payloadJson);
      if (parsed == null) continue;
      final (pair, y) = parsed;

      // Librarian「无外来者」：任一已确认外来者即证伪（Spy 登记不产生真
      // 外来者，无逃生舱；Drunk 的 myRole 是镇民 bluff，不会误触发）。
      if (y == null && pair.isEmpty) {
        final confirmedOutsiders = <int>[
          for (final e in confirmedRoles.entries)
            if (e.value.team == Team.outsider) e.key,
          if (myPlayerId != null &&
              myRole != null &&
              myRole.team == Team.outsider)
            myPlayerId,
        ];
        if (confirmedOutsiders.isNotEmpty) {
          results.add(
            Contradiction(
              type: ContradictionType.zeroOutsiderConflict,
              playerIds: confirmedOutsiders,
              description:
                  '${labelOf(decl.playerId)} 的图书管理员信息为「无外来者在场」，'
                  '但 ${confirmedOutsiders.map(labelOf).join('、')} 已确认是外来者'
                  '——信息必假。',
              severity: ContradictionSeverity.warning,
            ),
          );
        }
        continue;
      }
      if (y == null || pair.length != 2) continue;

      // pair 成员已确认是 Y → ping 自洽（review 修复）：Y 被冲突揭示在多人
      // 身上时（数据录入冲突，由规则 2 处理），只要 pair 内有确认 Y，本条
      // ping 就不应误报。
      final yInPair = pair.any((pid) => confirmedOf(pid) == y);
      if (yInPair) continue;

      final elsewhere = <int>[
        for (final e in confirmedRoles.entries)
          if (e.value == y && !pair.contains(e.key)) e.key,
        if (myRole == y && myPlayerId != null && !pair.contains(myPlayerId))
          myPlayerId,
      ];
      final isBluff = demonBluffs.contains(y);
      if (elsewhere.isEmpty && !isBluff) continue;

      // 逃生舱数据化（#234）：善良 Y 仅「可向善良登记」者（TB=Spy）可冒充、
      // 爪牙 Y 仅「可向邪恶登记」者（TB=Recluse）。文案名称从剧本池回查
      // 首个具备该修饰的角色（TB 输出与硬编码时代逐字一致）。
      final escapeIsGood = y.team.isGood;
      bool canEscape(Character? c) =>
          c == null ||
          (escapeIsGood ? c.mayRegisterAsGood : c.mayRegisterAsEvil);
      final escapePossible = pair.any((pid) => canEscape(confirmedOf(pid)));
      var escapeName = '登记型角色';
      for (final c in ScriptDefinition.of(script).characters) {
        if (escapeIsGood ? c.mayRegisterAsGood : c.mayRegisterAsEvil) {
          escapeName = c.nameCn;
          break;
        }
      }

      final evidence = isBluff
          ? '${y.nameCn} 在恶魔 Bluff 名单中（确定性不在场）'
          : '${y.nameCn} 已确认在 ${labelOf(elsewhere.first)} 身上';
      results.add(
        Contradiction(
          type: ContradictionType.startInfoPingConflict,
          playerIds: [decl.playerId, ...pair],
          description:
              '${labelOf(decl.playerId)} 的${type.nameCn}信息称 '
              '${pair.map(labelOf).join('、')} 中有一人是 ${y.nameCn}，'
              '但 $evidence——信息为假，或其中有人是$escapeName（登记冒充）。',
          severity: escapePossible
              ? ContradictionSeverity.info
              : ContradictionSeverity.warning,
        ),
      );
    }
    return results;
  }

  /// 规则 8（#213）：厨师计数交叉验证。
  ///
  /// 厨师得知开局「相邻邪恶对数」（登记语义：Spy 默认邪恶但可向善良登记、
  /// Recluse 默认善良但可向邪恶登记）。
  /// - **上界（确定性）**：登记邪恶至多 evilCount + 1 人（邪恶全体 + 1 个
  ///   Recluse），环形相邻对至多 evilCount → N > evilCount 物理不可能。
  /// - **下界**：已确认**严格邪恶**（无登记弹性的爪牙/恶魔，即非 Spy）的
  ///   相邻对必然计入 N → 相邻对数 > N 即矛盾。含 Spy/Recluse 的对不作为
  ///   下界证据（登记弹性双向开脱）。
  static List<Contradiction> _chefCountMismatch(
    List<InfoDeclaration> declarations,
    Map<int, Character> confirmedRoles,
    Map<int, Player> playersById,
    PlayerSetup? setup,
    String Function(int) labelOf, {
    int? myPlayerId,
    Character? myRole,
  }) {
    final strictEvil = <int>{
      for (final e in confirmedRoles.entries)
        if (_strictlyEvil(e.value)) e.key,
      if (myPlayerId != null && myRole != null && _strictlyEvil(myRole))
        myPlayerId,
    };
    // 开局全员存活，相邻 = 座位环上紧邻（死亡揭示只是揭示身份，不改变
    // 开局座位关系）。
    final sorted = [...playersById.values]
      ..sort((a, b) => a.seatNumber - b.seatNumber);
    var adjacentPairs = 0;
    for (var i = 0; i < sorted.length; i++) {
      final a = sorted[i];
      final b = sorted[(i + 1) % sorted.length];
      if (strictEvil.contains(a.id) && strictEvil.contains(b.id)) {
        adjacentPairs++;
      }
    }

    final results = <Contradiction>[];
    for (final decl in declarations) {
      if (decl.characterType != Character.chef) continue;
      if (decl.reliability == Reliability.possiblyTainted ||
          decl.reliability == Reliability.invalidated) {
        continue;
      }
      final n = _payloadValue(decl.payloadJson);
      if (n == null) continue;
      if (setup != null && n > setup.evilCount) {
        results.add(
          Contradiction(
            type: ContradictionType.chefCountMismatch,
            playerIds: [decl.playerId],
            description:
                '${labelOf(decl.playerId)} 的厨师信息为 $n，'
                '但 ${setup.playerCount} 人局邪恶仅 ${setup.evilCount} 人'
                '（含至多 1 个登记为邪恶的隐士），相邻邪恶对至多 '
                '${setup.evilCount}——信息必假。',
            severity: ContradictionSeverity.warning,
          ),
        );
      }
      if (adjacentPairs > n) {
        results.add(
          Contradiction(
            type: ContradictionType.chefCountMismatch,
            playerIds: [decl.playerId, ...strictEvil],
            description:
                '${labelOf(decl.playerId)} 的厨师信息为 $n，'
                '但已确认邪恶座位中已有 $adjacentPairs 对相邻'
                '（${strictEvil.map(labelOf).join('、')}）——信息必假或揭示有误。',
            severity: ContradictionSeverity.warning,
          ),
        );
      }
    }
    return results;
  }

  /// 严格邪恶：无登记弹性的爪牙/恶魔（可作确定性信号）。
  ///
  /// 登记修饰（#234 数据化）：可向善良登记者（TB=Spy）有弹性、不可作
  /// 确定邪恶信号；可向邪恶登记者（TB=Recluse）可解释「读出邪恶」。
  static bool _strictlyEvil(Character c) =>
      (c.team == Team.minion || c.team == Team.demon) &&
      !c.mayRegisterAsGood;

  /// 解析开局指认 payload `{"character": "...", "playerIds": [a, b]}`。
  ///
  /// Librarian「无外来者」为 `{"character": null, "playerIds": []}` →
  /// `([], null)`。损坏 payload 返回 null。
  static (List<int>, Character?)? _parsePingPayload(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is! Map) return null;
      final ids = decoded['playerIds'];
      if (ids is! List) return null;
      final pair = ids.whereType<int>().toList();
      Character? y;
      final name = decoded['character'];
      if (name is String) {
        y = Character.values.where((c) => c.name == name).firstOrNull;
      }
      return (pair, y);
    } on Object {
      return null;
    }
  }

  /// 规则 5：无人死亡夜晚 → 列出可能性（仅提示，不涉及具体玩家）。
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

  /// 解析占卜师 payload `{"playerIds": [a, b], "answer": bool}`（#159 G1）。
  /// answer=true → 读「是」（有恶魔）；false → 读「否」。损坏 payload 返回 null。
  static (List<int>, bool)? _parseFortuneTellerPayload(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is! Map) return null;
      final ids = decoded['playerIds'];
      final answer = decoded['answer'];
      if (ids is! List || answer is! bool) return null;
      return (ids.whereType<int>().toList(), answer);
    } on Object {
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

/// 矛盾检测事实集（机制层，#234）：原始输入 + detect 预计算的派生视图。
///
/// 规则只读 facts，不自行取数/派生——保证同一次检测内视图一致。
class ContradictionFacts {
  /// 创建事实集。
  const ContradictionFacts({
    required this.script,
    required this.claims,
    required this.declarations,
    required this.days,
    required this.playersById,
    required this.dayRecordToDayNumber,
    required this.expectedOutsiders,
    required this.setup,
    required this.demonBluffs,
    required this.myPlayerId,
    required this.myRole,
    required this.latestClaim,
    required this.confirmedRoles,
    required this.undertakerRoles,
  });

  /// 对局剧本（规则集分派依据，#234）。
  final Script script;

  /// 原始输入（与 detect 同名参数语义一致）。
  final List<RoleClaim> claims;
  final List<InfoDeclaration> declarations;
  final List<DayRecord> days;
  final Map<int, Player> playersById;
  final Map<int, int> dayRecordToDayNumber;
  final int expectedOutsiders;
  final PlayerSetup? setup;
  final Set<Character> demonBluffs;
  final int? myPlayerId;
  final Character? myRole;

  /// 派生视图（detect 预计算，规则共享）。
  final Map<int, RoleClaim> latestClaim;
  final Map<int, Character> confirmedRoles;
  final Map<int, Character> undertakerRoles;
}

/// 矛盾规则（机制层，#234）：id + 适用谓词 + 执行。
///
/// [applies] 为数据化谓词（默认恒真；如 team-count 需 setup 可得）；
/// [run] 为静态 tear-off（const 注册表要求）。
class ContradictionRule {
  /// 创建规则。
  const ContradictionRule({
    required this.id,
    required this.run,
    this.applies = _alwaysApplies,
  });

  /// 规则 id（稳定标识，供注册表测试与未来脚本工具对照）。
  final String id;

  /// 适用谓词。
  final bool Function(ContradictionFacts facts) applies;

  /// 执行（输出矛盾列表，可为空）。
  final List<Contradiction> Function(ContradictionFacts facts) run;

  static bool _alwaysApplies(ContradictionFacts facts) => true;
}

/// 按剧本选择矛盾规则集（#234）：TB 全量；BMR/S&V 规则随 #217 注册
/// （机制层已就绪——语义层接口见 #229 决策记录 2，随 #217 设计）。
List<ContradictionRule> contradictionRulesFor(Script script) =>
    switch (script) {
      Script.troubleBrewing => ContradictionDetector._tbRules,
      _ => const [],
    };
