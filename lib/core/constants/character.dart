import 'package:botc_copilot/core/constants/info_input_type.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/team.dart';

/// 角色（当前覆盖 Trouble Brewing 全 22 个）。
///
/// 每个角色携带完整元数据：阵营、能力描述、信息输入模板。
/// 能力描述以官方 Wiki 为准的中文转述。
enum Character {
  // ── 镇民 (13) ─────────────────────────────────────────────
  /// 洗衣妇：首夜得知两名玩家中有一名指定的镇民角色。
  washerwoman(
    nameCn: '洗衣妇',
    nameEn: 'Washerwoman',
    team: Team.townsfolk,
    ability: '首个夜晚，你会得知两名玩家中有一名指定的镇民角色。',
    infoInputType: InfoInputType.townsfolkPlusTwoPlayers,
  ),

  /// 图书管理员：首夜得知两名玩家中有一名指定的外来者（或没有外来者）。
  librarian(
    nameCn: '图书管理员',
    nameEn: 'Librarian',
    team: Team.townsfolk,
    ability: '首个夜晚，你会得知两名玩家中有一名指定的外来者角色；或得知本局没有外来者。',
    infoInputType: InfoInputType.outsiderPlusTwoPlayersOrNone,
  ),

  /// 调查员：首夜得知两名玩家中有一名指定的爪牙角色。
  investigator(
    nameCn: '调查员',
    nameEn: 'Investigator',
    team: Team.townsfolk,
    ability: '首个夜晚，你会得知两名玩家中有一名指定的爪牙角色。',
    infoInputType: InfoInputType.minionPlusTwoPlayers,
  ),

  /// 厨师：首夜得知有多少对相邻的邪恶玩家。
  chef(
    nameCn: '厨师',
    nameEn: 'Chef',
    team: Team.townsfolk,
    ability: '首个夜晚，你会得知有多少对相邻的邪恶玩家。',
    infoInputType: InfoInputType.numberRange,
  ),

  /// 共情者：每晚得知两侧最近存活邻居中的邪恶玩家数（0-2）。
  empath(
    nameCn: '共情者',
    nameEn: 'Empath',
    team: Team.townsfolk,
    ability: '每个夜晚，你会得知与你相邻的两名最近存活玩家中有多少名邪恶玩家（0-2）。',
    infoInputType: InfoInputType.numberZeroToTwo,
  ),

  /// 占卜师：每晚选两名玩家，得知其中是否有恶魔。
  fortuneTeller(
    nameCn: '占卜师',
    nameEn: 'Fortune Teller',
    team: Team.townsfolk,
    ability: '每个夜晚，选择两名玩家：你会得知他们之中是否有恶魔。'
        '有一名善良玩家会被你误判为恶魔（"宿敌"）。',
    infoInputType: InfoInputType.twoPlayersYesNo,
  ),

  /// 掘墓人：每晚得知当天被处决玩家的角色。
  undertaker(
    nameCn: '掘墓人',
    nameEn: 'Undertaker',
    team: Team.townsfolk,
    ability: '每个夜晚（除首夜），你会得知今天白天被处决玩家的角色。',
    infoInputType: InfoInputType.characterName,
  ),

  /// 僧侣：每晚选一名存活玩家保护其免受恶魔杀害（不能选自己）。
  monk(
    nameCn: '僧侣',
    nameEn: 'Monk',
    team: Team.townsfolk,
    ability: '每个夜晚（除首夜），选择一名除你以外的存活玩家：'
        '恶魔的能力今晚不会杀死他。',
    infoInputType: InfoInputType.none,
  ),

  /// 渡鸦守护者：夜晚死亡时选择一名玩家，得知其角色。
  ravenkeeper(
    nameCn: '渡鸦守护者',
    nameEn: 'Ravenkeeper',
    team: Team.townsfolk,
    ability: '如果你在夜晚死亡，选择一名玩家：你会得知他的角色。',
    infoInputType: InfoInputType.playerPlusCharacter,
  ),

  /// 处女：首次被镇民提名时，若提名者是镇民则其立即被处决。
  virgin(
    nameCn: '处女',
    nameEn: 'Virgin',
    team: Team.townsfolk,
    ability: '你第一次被提名时，如果提名者是镇民，他立即被处决。',
    infoInputType: InfoInputType.none,
  ),

  /// 猎杀者：每局一次，白天公开选择一名玩家，若是恶魔则其死亡。
  slayer(
    nameCn: '猎杀者',
    nameEn: 'Slayer',
    team: Team.townsfolk,
    ability: '每局游戏限一次，白天公开选择一名玩家：如果他是恶魔，他死亡。',
    infoInputType: InfoInputType.none,
  ),

  /// 士兵：恶魔的能力不会杀死你。
  soldier(
    nameCn: '士兵',
    nameEn: 'Soldier',
    team: Team.townsfolk,
    ability: '恶魔的能力不会杀死你。',
    infoInputType: InfoInputType.none,
  ),

  /// 市长：仅剩三人存活且白天无人被处决时，善良阵营获胜。
  mayor(
    nameCn: '市长',
    nameEn: 'Mayor',
    team: Team.townsfolk,
    ability: '如果只有三名玩家存活且白天没有人被处决，你的阵营获胜。'
        '如果你在夜晚即将死亡，可能有另一名玩家代替你死亡。',
    infoInputType: InfoInputType.none,
  ),

  // ── 外来者 (4) ────────────────────────────────────────────
  /// 管家：每晚选择一名主人，次日只能在其投票时投票。
  butler(
    nameCn: '管家',
    nameEn: 'Butler',
    team: Team.outsider,
    ability: '每个夜晚，选择一名除你以外的玩家作为"主人"：'
        '明天你只能在主人投票时投票。',
    infoInputType: InfoInputType.none,
  ),

  /// 醉汉：不知道自己是醉汉，以为自己是一个镇民角色，能力无效。
  drunk(
    nameCn: '醉汉',
    nameEn: 'Drunk',
    team: Team.outsider,
    ability: '你不知道自己是醉汉。你以为自己是一个镇民角色，但你的能力无效。',
    infoInputType: InfoInputType.none,
  ),

  /// 隐士：可能被判定为邪恶阵营，即使已死亡。
  recluse(
    nameCn: '隐士',
    nameEn: 'Recluse',
    team: Team.outsider,
    ability: '你可能被判定为邪恶阵营，即使你已经死亡。',
    infoInputType: InfoInputType.none,
  ),

  /// 圣徒：被处决时善良阵营立即落败。
  saint(
    nameCn: '圣徒',
    nameEn: 'Saint',
    team: Team.outsider,
    ability: '如果你被处决，你的阵营落败。',
    infoInputType: InfoInputType.none,
  ),

  // ── 爪牙 (4) ─────────────────────────────────────────────
  /// 投毒者：每晚选择一名玩家，其中毒至次日黄昏。
  poisoner(
    nameCn: '投毒者',
    nameEn: 'Poisoner',
    team: Team.minion,
    ability: '每个夜晚，选择一名玩家：他今晚和明天白天中毒（能力失效、信息错误）。',
    infoInputType: InfoInputType.none,
  ),

  /// 间谍：每晚查看魔典；可能被判定为善良阵营。
  spy(
    nameCn: '间谍',
    nameEn: 'Spy',
    team: Team.minion,
    ability: '每个夜晚，你可以查看魔典。你可能被判定为善良阵营，即使你已经死亡。',
    infoInputType: InfoInputType.none,
  ),

  /// 绯红女：恶魔死亡且存活玩家≥5时，你成为新恶魔。
  scarletWoman(
    nameCn: '绯红女',
    nameEn: 'Scarlet Woman',
    team: Team.minion,
    ability: '如果恶魔死亡时存活玩家不少于五人，你成为新的恶魔。',
    infoInputType: InfoInputType.none,
  ),

  /// 男爵：本局额外增加两名外来者（替换两名镇民）。
  baron(
    nameCn: '男爵',
    nameEn: 'Baron',
    team: Team.minion,
    ability: '本局游戏额外有两名外来者在场（替换两名镇民）。',
    infoInputType: InfoInputType.none,
  ),

  // ── 恶魔 (1) ─────────────────────────────────────────────
  /// 小恶魔：每晚选择一名玩家杀死；死亡时可由爪牙继承。
  imp(
    nameCn: '小恶魔',
    nameEn: 'Imp',
    team: Team.demon,
    ability: '每个夜晚（除首夜），选择一名玩家：他死亡。'
        '如果你死亡，一名爪牙可能成为新的小恶魔。',
    infoInputType: InfoInputType.none,
  );

  const Character({
    required this.nameCn,
    required this.nameEn,
    required this.team,
    required this.ability,
    required this.infoInputType,
  });

  /// 中文名。
  final String nameCn;

  /// 英文名。
  final String nameEn;

  /// 阵营。
  final Team team;

  /// 能力描述（中文）。
  final String ability;

  /// 信息输入模板类型。
  final InfoInputType infoInputType;

  /// 所属剧本（当前全部角色均属 TB）。
  // TODO: 扩展 BMR/S&V 角色时改为构造参数（搜索本标记）。
  Script get script => Script.troubleBrewing;

  /// 是否善良阵营。
  bool get isGood => team.isGood;

  /// 按阵营筛选角色列表。
  static List<Character> byTeam(Team team) =>
      values.where((c) => c.team == team).toList();
}
