import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/jinx_rule.dart';
import 'package:botc_copilot/core/constants/night_order.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/team.dart';

/// 剧本定义：剧本级数据的唯一入口（#229 总纲 / #230 骨架）。
///
/// 聚合剧本元数据（[Script]）与**角色池**；夜序 / Jinx / setup 增量随
/// 子任务 3-5 并入。消费端一律经 [of] + [byTeam] / [characters] 取池，
/// **不得**裸用 `Character.values` / `Character.byTeam` 充当剧本角色池
/// （多剧本后全局枚举 ≠ 单局角色池）。
///
/// 名称→角色的**解析**（payload/bluff 反序列化）仍走 `Character.values`
/// 全量查找——那是跨剧本的枚举查找，不是角色池消费。
class ScriptDefinition {
  /// 创建剧本定义。
  const ScriptDefinition({
    required this.script,
    required this.characters,
    this.firstNightSteps = const [],
    this.otherNightSteps = const [],
  });

  /// 剧本标识。
  final Script script;

  /// 该剧本的角色池（TB = 全 22 个；BMR/S&V 待 #217 录入，现为空池）。
  final List<Character> characters;

  /// 首夜步骤（含共享开场步骤，#232）。BMR/S&V 待 #217 录入。
  final List<NightOrderStep> firstNightSteps;

  /// 后续夜步骤（#232）。BMR/S&V 待 #217 录入。
  final List<NightOrderStep> otherNightSteps;

  /// 当天对应的夜晚步骤：day ≤ 1 首夜，否则后续夜（#232 起 game.script
  /// 业务分派入口）。
  List<NightOrderStep> nightStepsFor(int dayNumber) =>
      dayNumber <= 1 ? firstNightSteps : otherNightSteps;

  /// 本剧本适用的 Jinx（#233）：角色对**双双在池**才生效，按全局注册表
  /// [jinxRules] 推导。TB 无适用 Jinx（角色对另一端不在池/无官方 Jinx）。
  List<JinxRule> get applicableJinxes => jinxRules
      .where((j) => characters.contains(j.a) && characters.contains(j.b))
      .toList();

  /// 取剧本定义；未注册剧本（BMR/S&V 角色未录期间）兜底 TB——
  /// 现阶段 setup 已禁用其余剧本，兜底仅为防御脏数据（如换库残留）。
  static ScriptDefinition of(Script script) =>
      scriptDefinitions[script] ?? scriptDefinitions[Script.troubleBrewing]!;

  /// 按阵营取角色池子集。
  List<Character> byTeam(Team team) =>
      characters.where((c) => c.team == team).toList();

  /// 剧本池中的 setup 修正角色（#266②：TB=男爵，BMR=教父，
  /// S&V=方古/亡骨魔——数据驱动，非硬编码）。
  List<Character> get setupModifiers =>
      characters.where((c) => c.setupOutsiderDeltas.isNotEmpty).toList();

  /// 剧本内外来者增量的**最大可能值**（TB：Baron → 2；无修正角色 → 0）。
  ///
  /// 「或」型角色（Godfather ±1）取其各候选的最大值。
  int get maxOutsiderDelta => characters
      .expand((c) => c.setupOutsiderDeltas)
      .fold(0, (a, b) => a > b ? a : b);

  /// 已声明修正角色下的外来者最大可能增量（#231；#266② 负增量修正）。
  ///
  /// [claimedCharacters] 为每玩家最新声明的角色集合（可含 myRole 注入项）。
  /// 未声明任何修正角色 → 0（基础配置）；声明了则取该角色增量候选的最大
  /// 值。仅负增量的修正角色（S&V 亡骨魔 [-1]）声明后取其最大候选（-1）——
  /// 官方：其在场时外来者 base-1，钳 0 会把「少于标准」误判为偏差。
  /// 隐藏的真修正角色未声明时不可知，返回 0 保持保守。
  static int claimedOutsiderDelta(Iterable<Character> claimedCharacters) {
    int? best;
    for (final c in claimedCharacters) {
      for (final d in c.setupOutsiderDeltas) {
        if (best == null || d > best) best = d;
      }
    }
    return best ?? 0;
  }
}

/// 修正角色的单行可读描述（#266②，配置分析/setup 提示共用）。
///
/// 单增量：「男爵」→ `+2 外来者、-2 镇民`；负增量方向相反。
/// 「或」型 ±：「教父」（[-1, 1]）→ `±1 外来者（镇民反向增减）`。
String describeSetupModifier(Character c) {
  final ds = c.setupOutsiderDeltas;
  if (ds.length == 1) {
    final d = ds.single;
    final outsider = d >= 0 ? '+$d' : '$d';
    final town = d >= 0 ? '-$d' : '+${-d}';
    return '$outsider 外来者、$town 镇民';
  }
  final max = ds.reduce((a, b) => a > b ? a : b);
  final min = ds.reduce((a, b) => a < b ? a : b);
  if (min == -max) return '±$max 外来者（镇民反向增减）';
  return '外来者 ${ds.map((d) => d >= 0 ? '+$d' : '$d').join(' 或 ')}'
      '（镇民反向增减）';
}

/// 剧本注册表（剧本级数据唯一入口，#230）。
const scriptDefinitions = <Script, ScriptDefinition>{
  Script.troubleBrewing: ScriptDefinition(
    script: Script.troubleBrewing,
    firstNightSteps: firstNightSteps,
    otherNightSteps: otherNightSteps,
    characters: [
      // 镇民 13
      Character.washerwoman,
      Character.librarian,
      Character.investigator,
      Character.chef,
      Character.empath,
      Character.fortuneTeller,
      Character.undertaker,
      Character.monk,
      Character.ravenkeeper,
      Character.virgin,
      Character.slayer,
      Character.soldier,
      Character.mayor,
      // 外来者 4
      Character.butler,
      Character.drunk,
      Character.recluse,
      Character.saint,
      // 爪牙 4
      Character.poisoner,
      Character.spy,
      Character.scarletWoman,
      Character.baron,
      // 恶魔 1
      Character.imp,
    ],
  ),
  // BMR 黯月初升（#217 数据录入：25 角色 + 官方夜序；旅行者不在池）。
  Script.badMoonRising: ScriptDefinition(
    script: Script.badMoonRising,
    firstNightSteps: _bmrFirstNightSteps,
    otherNightSteps: _bmrOtherNightSteps,
    characters: [
      // 镇民 13
      Character.chambermaid,
      Character.courtier,
      Character.exorcist,
      Character.fool,
      Character.gambler,
      Character.gossip,
      Character.grandmother,
      Character.innkeeper,
      Character.minstrel,
      Character.pacifist,
      Character.professor,
      Character.sailor,
      Character.teaLady,
      // 外来者 4
      Character.goon,
      Character.lunatic,
      Character.moonchild,
      Character.tinker,
      // 爪牙 4
      Character.assassin,
      Character.devilsAdvocate,
      Character.godfather,
      Character.mastermind,
      // 恶魔 4（每局仅一在场）
      Character.po,
      Character.pukka,
      Character.shabaloth,
      Character.zombuul,
    ],
  ),
  // S&V 梦殒春宵（#217 增量5：官方 botc-release + 魔典 wiki；
  // 核心 25 角色，旅行者/实验角色不在池——magician/legion 锚点为
  // 实验角色，不进官方池）。
  Script.sectsAndViolets: ScriptDefinition(
    script: Script.sectsAndViolets,
    firstNightSteps: _svFirstNightSteps,
    otherNightSteps: _svOtherNightSteps,
    characters: [
      // 镇民 13
      Character.artist,
      Character.clockmaker,
      Character.dreamer,
      Character.flowergirl,
      Character.juggler,
      Character.mathematician,
      Character.oracle,
      Character.philosopher,
      Character.sage,
      Character.savant,
      Character.seamstress,
      Character.snakecharmer,
      Character.towncrier,
      // 外来者 4
      Character.barber,
      Character.klutz,
      Character.mutant,
      Character.sweetheart,
      // 爪牙 4
      Character.cerenovus,
      Character.eviltwin,
      Character.pithag,
      Character.witch,
      // 恶魔 4（每局仅一在场）
      Character.fanggu,
      Character.nodashii,
      Character.vigormortis,
      Character.vortox,
    ],
  ),
};

/// S&V 首夜步骤（官方 nightsheet 顺序，#267 勘正）：
/// philosopher → 爪牙信息 → 恶魔信息 → snakecharmer → eviltwin → witch →
/// cerenovus → clockmaker → dreamer → seamstress → mathematician。
/// 恶魔信息紧跟爪牙信息之后（舞蛇人之前）——此前误按「BMR 惯例」内联
/// 在爪牙块之后，与官方数据不符。
const _svFirstNightSteps = <NightOrderStep>[
  NightOrderStep(
    character: Character.philosopher,
    action: '每局限一次：选择一个善良角色，获得其能力',
    note: '若该角色在场，其玩家醉酒',
  ),
  NightOrderStep(
    label: '爪牙信息',
    action: '爪牙互认识；恶魔向爪牙亮明',
    note: '7+ 人局恶魔亦知爪牙；≤6 人局恶魔不知爪牙',
  ),
  NightOrderStep(
    label: '恶魔信息',
    action: '恶魔看爪牙 + 3 个不在场好人角色（Bluff）',
    note: '仅 7+ 人局；≤6 人局恶魔无 Bluff',
  ),
  NightOrderStep(
    character: Character.snakecharmer,
    action: '选择一名存活玩家：选中恶魔则互换角色与阵营，其中毒',
  ),
  NightOrderStep(
    character: Character.eviltwin,
    action: '镜像双子与对立玩家互相得知对方角色',
    note: '若好人方被处决，邪恶获胜；两者都存活则善良无法获胜',
  ),
  NightOrderStep(
    character: Character.witch,
    action: '选择一名玩家：其明日提名则死亡',
    note: '仅剩 3 名存活玩家时失去能力',
  ),
  NightOrderStep(
    character: Character.cerenovus,
    action: '选择一名玩家与一个善良角色：其须疯狂证明',
    note: '不疯狂则可能被处决',
  ),
  NightOrderStep(
    character: Character.clockmaker,
    action: '得知恶魔与最近爪牙的座位距离',
  ),
  NightOrderStep(
    character: Character.dreamer,
    action: '选择一名玩家（非自己）：得知一善一恶两角色，其一为真',
  ),
  NightOrderStep(
    character: Character.seamstress,
    action: '每局限一次：选择两名玩家，得知是否同阵营',
  ),
  NightOrderStep(
    character: Character.mathematician,
    action: '得知自上个黎明起能力异常生效的玩家数',
  ),
];

/// S&V 后续夜步骤（官方 nightsheet 顺序）。
const _svOtherNightSteps = <NightOrderStep>[
  NightOrderStep(
    character: Character.philosopher,
    action: '每局限一次：选择一个善良角色，获得其能力',
  ),
  NightOrderStep(
    character: Character.snakecharmer,
    action: '选择一名存活玩家：选中恶魔则互换角色与阵营，其中毒',
  ),
  NightOrderStep(
    character: Character.witch,
    action: '选择一名玩家：其明日提名则死亡',
  ),
  NightOrderStep(
    character: Character.cerenovus,
    action: '选择一名玩家与一个善良角色：其须疯狂证明',
  ),
  NightOrderStep(
    character: Character.pithag,
    action: '选择一名玩家与一个角色：不在场则其变身',
    note: '若因此产生新恶魔，当晚死亡由说书人决定',
  ),
  NightOrderStep(
    label: '恶魔行动',
    action: '恶魔选择一名玩家：其死亡',
    note: '方古/亡骨魔/诺-达鲺/涡流四恶魔其一在场',
  ),
  NightOrderStep(
    character: Character.barber,
    action: '理发师当日/当晚死亡后：恶魔可选两名玩家交换角色',
  ),
  NightOrderStep(
    character: Character.sweetheart,
    action: '心上人死亡后：一名玩家从此醉酒',
  ),
  NightOrderStep(
    character: Character.sage,
    action: '被恶魔杀死：得知两名玩家，其一为凶手',
  ),
  NightOrderStep(
    character: Character.dreamer,
    action: '选择一名玩家：得知一善一恶两角色，其一为真',
  ),
  NightOrderStep(
    character: Character.flowergirl,
    action: '得知今天白天是否有恶魔投过票',
  ),
  NightOrderStep(
    character: Character.towncrier,
    action: '得知今天白天是否有爪牙发起过提名',
  ),
  NightOrderStep(
    character: Character.oracle,
    action: '得知有多少名死亡的玩家是邪恶的',
  ),
  NightOrderStep(
    character: Character.seamstress,
    action: '每局限一次：选择两名玩家，得知是否同阵营',
  ),
  NightOrderStep(
    character: Character.juggler,
    action: '首日公开猜测后：得知猜对数量',
  ),
  NightOrderStep(
    character: Character.mathematician,
    action: '得知自上个黎明起能力异常生效的玩家数',
  ),
];

/// 当天对应的夜晚步骤（按剧本分派，#232）。
///
/// [script] 经 game.script 传入——这是 game.script 首次业务消费点；
/// 未注册剧本经 [ScriptDefinition.of] 兜底 TB。
List<NightOrderStep> nightStepsForDay(Script script, int dayNumber) =>
    ScriptDefinition.of(script).nightStepsFor(dayNumber);

/// BMR 首夜步骤（官方 nightsheet：爪牙信息 → 疯子 → 恶魔信息 → 水手 →
/// 侍臣 → 教父 → 魔鬼代言人 → 普卡 → 祖母 → 侍女）。醉汉分配为全局
/// 开场步骤但 BMR 无 Drunk，不列。
const _bmrFirstNightSteps = <NightOrderStep>[
  NightOrderStep(
    label: '爪牙信息',
    action: '爪牙互认识；恶魔向爪牙亮明',
    note: '7+ 人局恶魔亦知爪牙；≤6 人局恶魔不知爪牙',
  ),
  NightOrderStep(
    character: Character.lunatic,
    action: '以为自己是恶魔，按恶魔流程「行动」',
    note: '说书人引导但不生效；真恶魔得知疯子身份与其选择',
  ),
  NightOrderStep(
    label: '恶魔信息',
    action: '恶魔看爪牙 + 3 个不在场好人角色（Bluff）',
    note: '仅 7+ 人局；≤6 人局恶魔无 Bluff',
  ),
  NightOrderStep(
    character: Character.sailor,
    action: '选择一名存活玩家（其一醉至黄昏）',
    note: '水手不会死亡',
  ),
  NightOrderStep(
    character: Character.courtier,
    action: '每局限一次：选择一个角色（醉 3 夜 3 天）',
  ),
  NightOrderStep(
    character: Character.godfather,
    action: '得知在场的外来者',
    note: '外来者数 = 基础 -1 或 +1（说书人选）',
  ),
  NightOrderStep(
    character: Character.devilsAdvocate,
    action: '选择一名存活玩家（须与昨夜不同；明日处决不死）',
  ),
  NightOrderStep(
    character: Character.pukka,
    action: '选择一名玩家下毒',
    note: '上一名中毒者死亡并恢复健康',
  ),
  NightOrderStep(
    character: Character.grandmother,
    action: '得知一名好人玩家及其角色',
  ),
  NightOrderStep(
    character: Character.chambermaid,
    action: '选择两名存活玩家（不能是自己）：得知几人夜间醒来',
  ),
];

/// BMR 后续夜步骤（官方 nightsheet 顺序）。
const _bmrOtherNightSteps = <NightOrderStep>[
  NightOrderStep(
    character: Character.sailor,
    action: '选择一名存活玩家（其一醉至黄昏）',
  ),
  NightOrderStep(
    character: Character.courtier,
    action: '每局限一次：选择一个角色（醉 3 夜 3 天）',
  ),
  NightOrderStep(
    character: Character.innkeeper,
    action: '选择两名玩家（当晚不死，其一醉至黄昏）',
  ),
  NightOrderStep(
    character: Character.gambler,
    action: '选一人并猜其角色（猜错则死）',
  ),
  NightOrderStep(
    character: Character.devilsAdvocate,
    action: '选择一名存活玩家（须与昨夜不同；明日处决不死）',
  ),
  NightOrderStep(
    character: Character.lunatic,
    action: '以为自己是恶魔，按恶魔流程「行动」',
  ),
  NightOrderStep(
    character: Character.exorcist,
    action: '选择一名玩家（须与昨夜不同）',
    note: '若选中恶魔：恶魔得知驱魔人是谁，当晚不行动',
  ),
  NightOrderStep(
    character: Character.zombuul,
    action: '若当日无人死亡：选一人死亡',
    note: '僵怖第一次死亡时活着但被视为已死',
  ),
  NightOrderStep(
    character: Character.pukka,
    action: '选一人下毒；上一名中毒者死亡并恢复健康',
  ),
  NightOrderStep(
    character: Character.shabaloth,
    action: '选两名玩家死亡；昨夜目标可能被吐出（复活）',
  ),
  NightOrderStep(
    character: Character.po,
    action: '可杀一人；若上晚未杀，今晚可杀三人',
  ),
  NightOrderStep(
    character: Character.assassin,
    action: '每局限一次：选一人死亡（无法阻止）',
  ),
  NightOrderStep(
    character: Character.godfather,
    action: '若当日有外来者死亡：选一人死亡',
  ),
  NightOrderStep(
    character: Character.gossip,
    action: '若当日公开声明为真：选一人死亡',
  ),
  NightOrderStep(
    character: Character.professor,
    action: '每局限一次：选一名已死玩家（若为镇民则复活）',
  ),
  NightOrderStep(
    character: Character.tinker,
    action: '（说书人可令其死亡）',
  ),
  NightOrderStep(
    character: Character.moonchild,
    action: '（死时已公开选目标）若目标为好人：其死亡',
  ),
  NightOrderStep(
    character: Character.grandmother,
    action: '（若「孙儿」已死）得知其死讯',
  ),
  NightOrderStep(
    character: Character.chambermaid,
    action: '选择两名存活玩家：得知几人夜间醒来',
  ),
];
