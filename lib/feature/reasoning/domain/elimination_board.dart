import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';

/// 演绎依据来源（issue #214）。
enum DeductionSource {
  /// 死亡揭示（村规确认）。
  deathReveal('死亡揭示'),

  /// 我座位的真实角色（玩家自知；Drunk 例外见引擎 dartdoc）。
  myRole('我的真实角色'),

  /// 恶魔私密爪牙名单（7+ 局官方：恶魔首夜得知全部爪牙）。
  privateMinion('恶魔爪牙名单'),

  /// 传承记录（用户在传承确认框裁决的继承人）。
  succession('传承记录'),

  /// 邪恶计数收缩（slot 硬约束推导）。
  evilCountForcing('邪恶计数收缩'),

  /// 占卜师读「否」——若信息为真，pair 内无恶魔（弱排除）。
  fortuneTellerNo('占卜师读「否」'),

  /// 共情者读 0——若信息为真，邻座非恶魔（弱排除）。
  empathZero('共情者读 0');

  const DeductionSource(this.nameCn);

  /// 中文显示名。
  final String nameCn;
}

/// 一条演绎依据。
class Deduction {
  /// 创建依据。
  const Deduction({required this.source, required this.description});

  /// 来源类型。
  final DeductionSource source;

  /// 人类可读描述（含相关座位/角色）。
  final String description;
}

/// 排除法棋盘（issue #214 domain 层，纯函数）。
///
/// 联合多源约束自动收敛「确认好人 / 恶魔候选」。**分层**：
/// - **确认层（deterministic）**：死亡揭示、我座位真实角色、恶魔私密爪牙
///   名单、传承记录、邪恶计数收缩——这些在 App 的信息模型下为真。
/// - **弱排除层（conditional）**：占卜师读「否」/ 共情者读 0 的目标——
///   **若该信息为真**则非恶魔；声明可为谎，故只作候选的弱标注，不移出
///   候选集。
///
/// 官方规则要点（引擎正确性基石）：
/// - **myRole 善良 ⇒ 确认好人**：唯一自我认知偏差是 Drunk（以为自己是
///   镇民），而 Drunk 是外来者、本就善良——两种可能都善良，结论不变。
///   邪恶玩家被告知真身，myRole 邪恶 ⇒ 确认邪恶。
/// - **邪恶总数恒定**（[PlayerSetup.evilCount]）：Baron 只改外来者/镇民；
///   SW 传承是爪牙变恶魔、成员集合不变；邪恶只减（死亡）不增。
/// - **计数收缩**：`minAliveEvil = max(0, E - 可能邪恶的死者数)`，其中
///   可能邪恶的死者 = 死亡总数 - 已揭示善良的死者（后者不可能邪恶）。
///   当「存活 ∧ 未确认好人」的玩家数恰等于 minAliveEvil 时，**未确认
///   （未揭示）的死者必然全为邪恶**、且该剩余集就是全部存活邪恶（否则
///   与确认好人矛盾——等式迫使「邪恶死亡数 = 可能邪恶的死亡数」）。
/// - **弱排除时效**：读数只证明**当时**非恶魔；此后传承可让爪牙成为新
///   恶魔——故任何传承记录的继承人豁免弱排除。
///
/// 原则：给出候选集合与依据，**不输出身份结论**（「X 是恶魔」由用户裁决）。
class EliminationBoard {
  /// 创建棋盘。
  const EliminationBoard({
    required this.confirmedGood,
    required this.confirmedEvil,
    required this.knownMinionIds,
    required this.confirmedDemonPlayerId,
    required this.confirmedDemonReason,
    required this.forcedEvilRemaining,
    required this.demonCandidates,
    required this.weakDemonExclusions,
    required this.minAliveEvil,
    required this.maxAliveEvil,
    required this.anomalies,
  });

  /// 确认好人（含已死）：playerId → 依据列表。
  final Map<int, List<Deduction>> confirmedGood;

  /// 确认邪恶（含已死）：playerId → 依据列表。
  final Map<int, List<Deduction>> confirmedEvil;

  /// 已知爪牙（非恶魔）：恶魔私密名单 + myRole 爪牙 + 揭示爪牙。
  final Set<int> knownMinionIds;

  /// 现任恶魔已知时的 playerId（传承继承人 / myRole 恶魔），否则 null。
  final int? confirmedDemonPlayerId;

  /// 现任恶魔的确认依据。
  final Deduction? confirmedDemonReason;

  /// 计数收缩结果：该集合整体即全部存活邪恶（确定性），否则为空集。
  final Set<int> forcedEvilRemaining;

  /// 恶魔候选：存活 ∧ 非确认好人 ∧ 非已知爪牙 ∧ ≠ [confirmedDemonPlayerId]。
  final List<int> demonCandidates;

  /// 候选中被信息弱排除的目标：playerId → 依据（若真则非现任恶魔）。
  final Map<int, List<Deduction>> weakDemonExclusions;

  /// 存活邪恶数的下界（未揭示死者可能邪恶）。
  final int minAliveEvil;

  /// 存活邪恶数的上界（仅扣除已确认死亡的邪恶）。
  final int maxAliveEvil;

  /// 数据异常（如确认好人过多、上下界倒挂），提示用户核对录入。
  final List<String> anomalies;
}

/// 排除法演绎引擎（纯函数，可测试）。
abstract final class EliminationEngine {
  /// 评估当前棋盘。
  ///
  /// [confirmedRoles] 死亡揭示（村规确认）；[successions] 传承记录（按
  /// id 升序，末条为最新）；[privateMinionIds] 恶魔私密爪牙名单（仅我=
  /// 恶魔时有意义）；[declarations] 信息声明（FT/Empath 弱排除）；
  /// [dayRecordToDayNumber] 供 Empath 邻座时序判定（#78）。
  /// [labelFor] 必填（#145：禁止把 db id 当座位号渲染）。
  static EliminationBoard evaluate({
    required List<Player> players,
    required PlayerSetup setup,
    required Map<int, Character> confirmedRoles,
    List<DemonInheritance> successions = const [],
    Set<int> privateMinionIds = const {},
    List<InfoDeclaration> declarations = const [],
    Map<int, int> dayRecordToDayNumber = const {},
    int? myPlayerId,
    Character? myRole,
    required String Function(int playerId) labelFor,
  }) {
    final confirmedGood = <int, List<Deduction>>{};
    final confirmedEvil = <int, List<Deduction>>{};
    final knownMinions = <int>{};

    void addGood(int pid, Deduction d) =>
        confirmedGood.putIfAbsent(pid, () => []).add(d);
    void addEvil(int pid, Deduction d) =>
        confirmedEvil.putIfAbsent(pid, () => []).add(d);

    // ---- 确认层 1：死亡揭示 ----
    for (final e in confirmedRoles.entries) {
      final c = e.value;
      final d = Deduction(
        source: DeductionSource.deathReveal,
        description: '死亡揭示为${c.nameCn}（${c.team.nameCn}）',
      );
      if (c.team.isGood) {
        addGood(e.key, d);
      } else {
        addEvil(e.key, d);
        if (c.team == Team.minion) knownMinions.add(e.key);
      }
    }

    // ---- 确认层 2：我座位真实角色 ----
    // Drunk 例外：myRole 善良时实情可能是 Drunk（外来者，仍善良），结论不变。
    if (myPlayerId != null && myRole != null) {
      final d = Deduction(
        source: DeductionSource.myRole,
        description: '我的真实角色是${myRole.nameCn}'
            '${myRole.team.isGood ? '（即便实为 Drunk 也是外来者·善良）' : ''}',
      );
      if (myRole.team.isGood) {
        addGood(myPlayerId, d);
      } else {
        addEvil(myPlayerId, d);
        if (myRole.team == Team.minion) knownMinions.add(myPlayerId);
      }
    }

    // ---- 确认层 3：恶魔私密爪牙名单 ----
    for (final pid in privateMinionIds) {
      addEvil(
        pid,
        Deduction(
          source: DeductionSource.privateMinion,
          description: '恶魔首夜得知的爪牙（仅你可见）',
        ),
      );
      knownMinions.add(pid);
    }

    // ---- 同一玩家善恶双确认（数据冲突）→ 异常提示 ----
    final anomalies = <String>[
      for (final pid in confirmedGood.keys)
        if (confirmedEvil.containsKey(pid))
          '${labelFor(pid)} 同时有善良与邪恶的确认依据，请核对死亡揭示/我的角色录入',
    ];

    final playersById = {for (final p in players) p.id: p};

    // ---- 确认层 4：现任恶魔（最新传承记录优先，其次 myRole 恶魔）----
    int? demonId;
    Deduction? demonReason;
    final successorIds = <int>{
      for (final s in successions)
        if (s.toPlayerId != null) s.toPlayerId!,
    };
    // 防御排序：drift watch 无排序保证，不依赖调用方有序（review F3）。
    final ordered = [...successions]
      ..sort((a, b) => a.id.compareTo(b.id));
    if (ordered.isNotEmpty) {
      final latest = ordered.last;
      final target = latest.toPlayerId;
      // 目标须存活：恶魔死亡必触发新传承/善良胜——最新目标已死说明
      // 后续传承未录入，现任恶魔实际未知，不确认（review F2）。
      if (target != null && playersById[target]?.isAlive == true) {
        demonId = target;
        demonReason = Deduction(
          source: DeductionSource.succession,
          description: '第 ${latest.dayNumber} 天传承（${latest.trigger.nameCn}）'
              '确认的现任恶魔',
        );
      }
    } else if (myPlayerId != null &&
        myRole != null &&
        myRole.team == Team.demon) {
      demonId = myPlayerId;
      demonReason = Deduction(
        source: DeductionSource.myRole,
        description: '我的真实角色是${myRole.nameCn}（恶魔）',
      );
    }

    // ---- 确认层 5：邪恶计数收缩 ----
    final aliveIds = [
      for (final p in players)
        if (p.isAlive) p.id,
    ];
    final deadIds = [
      for (final p in players)
        if (!p.isAlive) p.id,
    ];
    final deadConfirmedGood =
        confirmedGood.keys.where(deadIds.contains).length;
    final deadConfirmedEvil =
        confirmedEvil.keys.where(deadIds.contains).length;
    final evilTotal = setup.evilCount;
    // 已揭示善良的死者不可能邪恶 → 只有「未揭示/未确认」的死者才可能占邪恶
    // 槽位。漏掉这一点会让终局（多名揭示善良死者）的收缩永远不触发。
    final deadPossiblyEvil = deadIds.length - deadConfirmedGood;
    final minAliveEvil =
        (evilTotal - deadPossiblyEvil) > 0 ? evilTotal - deadPossiblyEvil : 0;
    final maxAliveEvil = evilTotal - deadConfirmedEvil;

    if (maxAliveEvil > aliveIds.length) {
      anomalies.add('存活玩家（${aliveIds.length} 人）少于存活邪恶上界'
          '（$maxAliveEvil）——数据不一致，请核对');
    }
    if (maxAliveEvil < 0) {
      anomalies.add('已确认死亡的邪恶（$deadConfirmedEvil 人）超过配置邪恶总数'
          '（$evilTotal）——请核对死亡揭示或对局人数');
    }

    final goodAlive = confirmedGood.keys.where(aliveIds.contains).toSet();
    final others = aliveIds.where((id) => !goodAlive.contains(id)).toSet();
    final forcedEvil = <int>{};
    if (others.length < minAliveEvil) {
      anomalies.add('确认好人过多：存活未确认好人的仅 ${others.length} 人，'
          '但存活邪恶至少 $minAliveEvil 人——与配置矛盾，请核对（或有人假报）');
    } else if (minAliveEvil > 0 && others.length == minAliveEvil) {
      forcedEvil.addAll(others);
      final forcingDeduction = Deduction(
        source: DeductionSource.evilCountForcing,
        description: '存活未确认好人仅 ${others.length} 人 = 存活邪恶下界'
            '（$evilTotal 邪恶 - $deadPossiblyEvil 可能邪恶的死者），'
            '该集合即全部存活邪恶，且未确认（未揭示）的死者均为邪恶',
      );
      for (final pid in forcedEvil) {
        addEvil(pid, forcingDeduction);
      }
    }

    // ---- 恶魔候选：存活 ∧ 非确认好人 ∧ 非已知爪牙 ∧ ≠ 已确认恶魔 ----
    final candidates = [
      ...aliveIds.where(
        (id) =>
            !confirmedGood.containsKey(id) &&
            !knownMinions.contains(id) &&
            id != demonId,
      ),
    ]..sort(
        (a, b) => (playersById[a]?.seatNumber ?? 1 << 30)
            .compareTo(playersById[b]?.seatNumber ?? 1 << 30),
      );

    // ---- 弱排除层（#234 机制化）：按信息角色类型经注册表分派 ----
    // 「若信息为真 → 目标非现任恶魔」；传承继承人豁免（读数只证明当时
    // 非恶魔，其后传承可使其成为新恶魔）。
    final weakExclusions = <int, List<Deduction>>{};
    for (final decl in declarations) {
      if (decl.reliability == Reliability.possiblyTainted ||
          decl.reliability == Reliability.invalidated) {
        continue;
      }
      final rule = weakExclusionRulesFor(
        decl.characterType,
      );
      if (rule == null) continue;
      for (final (pid, source, text) in rule.extract(
        WeakExclusionFacts(
          decl: decl,
          day: dayRecordToDayNumber[decl.dayRecordId],
          playersById: playersById,
          candidates: candidates,
          successorIds: successorIds,
          labelFor: labelFor,
        ),
      )) {
        if (successorIds.contains(pid)) continue;
        weakExclusions.putIfAbsent(pid, () => []).add(
          Deduction(source: source, description: text),
        );
      }
    }

    return EliminationBoard(
      confirmedGood: confirmedGood,
      confirmedEvil: confirmedEvil,
      knownMinionIds: knownMinions,
      confirmedDemonPlayerId: demonId,
      confirmedDemonReason: demonReason,
      forcedEvilRemaining: forcedEvil,
      demonCandidates: candidates,
      weakDemonExclusions: weakExclusions,
      minAliveEvil: minAliveEvil,
      maxAliveEvil: maxAliveEvil,
      anomalies: anomalies,
    );
  }

  /// 解析 FT payload 的「否」读数目标（answer=false 且 pair 恰 2 人）。
  static List<int>? _parseFortuneTellerNo(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is! Map) return null;
      final ids = decoded['playerIds'];
      final answer = decoded['answer'];
      if (ids is! List || answer != false) return null;
      final pair = ids.whereType<int>().toList();
      return pair.length == 2 ? pair : null;
    } on Object {
      return null;
    }
  }

  /// 解析 `{"value": n}` payload。
  static int? _payloadValue(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map && decoded['value'] is int) {
        return decoded['value'] as int;
      }
      return null;
    } on Object {
      return null;
    }
  }

  /// 座位环上 [target] 的两名存活邻座（公理2：死亡玩家物理移除、两侧并拢；
  /// 时序语义与矛盾引擎 #78 一致：同日非夜杀死亡读取时仍存活）。
  static List<Player> _seatNeighbors(Player target, List<Player> aliveThen) {
    final sorted = [...aliveThen]..sort((a, b) => a.seatNumber - b.seatNumber);
    final idx = sorted.indexWhere((p) => p.id == target.id);
    if (idx < 0 || sorted.length < 3) return [];
    return [
      sorted[(idx - 1 + sorted.length) % sorted.length],
      sorted[(idx + 1) % sorted.length],
    ];
  }
}

/// 弱排除规则事实（#234 机制层）。
class WeakExclusionFacts {
  /// 创建事实。
  const WeakExclusionFacts({
    required this.decl,
    required this.day,
    required this.playersById,
    required this.candidates,
    required this.successorIds,
    required this.labelFor,
  });

  /// 触发读数的信息声明（reliability 已滤醉/毒）。
  final InfoDeclaration decl;

  /// 读数天数（缺失映射时 null，规则自行跳过）。
  final int? day;

  /// 全体玩家视图。
  final Map<int, Player> playersById;

  /// 恶魔候选（弱排除仅作用于候选）。
  final List<int> candidates;

  /// 传承继承人（时效豁免）。
  final Set<int> successorIds;

  /// 展示标签（#145 必填模式）。
  final String Function(int playerId) labelFor;
}

/// 弱排除规则（#234 机制层）：按信息角色类型分派。
///
/// extract 返回 `(目标, 依据来源, 描述)` 列表；目标不在候选由引擎过滤，
/// 继承人豁免统一在引擎层（规则只管「读数意味着谁非恶魔」）。
class WeakExclusionRule {
  /// 创建规则。
  const WeakExclusionRule({required this.characterType, required this.extract});

  /// 信息角色类型（分派键）。
  final Character characterType;

  /// 执行。
  final List<(int, DeductionSource, String)> Function(WeakExclusionFacts f)
      extract;
}

/// 弱排除规则注册表（TB：FT「否」/ Empath 0；新剧本随 #217 追加）。
const _weakExclusionRules = <WeakExclusionRule>[
  WeakExclusionRule(
    characterType: Character.fortuneTeller,
    extract: _fortuneTellerNoRule,
  ),
  WeakExclusionRule(
    characterType: Character.empath,
    extract: _empathZeroRule,
  ),
];

/// 按信息角色类型取弱排除规则（无则 null）。
WeakExclusionRule? weakExclusionRulesFor(Character characterType) {
  for (final r in _weakExclusionRules) {
    if (r.characterType == characterType) return r;
  }
  return null;
}

/// FT 读「否」：pair（若真）无恶魔——「否」不受红鲱鱼影响，恶魔必登记为恶魔。
List<(int, DeductionSource, String)> _fortuneTellerNoRule(
  WeakExclusionFacts f,
) {
  final pair = EliminationEngine._parseFortuneTellerNo(f.decl.payloadJson);
  if (pair == null) return const [];
  return [
    for (final pid in pair)
      if (f.candidates.contains(pid))
        (
          pid,
          DeductionSource.fortuneTellerNo,
          '${f.labelFor(f.decl.playerId)} 的占卜师读「否」'
              '${f.day != null ? '（第 ${f.day} 天）' : ''}——若信息为真，'
              '其中无恶魔（「否」不受红鲱鱼影响，恶魔必登记为恶魔）',
        ),
  ];
}

/// Empath 读 0：当时存活邻座（若真）登记为善良、非恶魔。
List<(int, DeductionSource, String)> _empathZeroRule(WeakExclusionFacts f) {
  final value = EliminationEngine._payloadValue(f.decl.payloadJson);
  if (value != 0) return const [];
  final day = f.day;
  final empath = f.playersById[f.decl.playerId];
  if (day == null || empath == null) return const [];
  final aliveThen = f.playersById.values
      .where(
        (p) =>
            p.deathDay == null ||
            p.deathDay! > day ||
            (p.deathDay == day && p.deathCause != DeathCause.nightKill),
      )
      .toList();
  return [
    for (final n in EliminationEngine._seatNeighbors(empath, aliveThen))
      if (f.candidates.contains(n.id))
        (
          n.id,
          DeductionSource.empathZero,
          '${f.labelFor(f.decl.playerId)} 的共情者读 0'
              '（第 $day 天）——若信息为真，'
              '${f.labelFor(n.id)} 当时登记为善良、非恶魔',
        ),
  ];
}
