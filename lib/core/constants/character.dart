import 'package:botc_copilot/core/constants/info_input_type.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/team.dart';

/// 角色（TB 全 22 + BMR 全 25（#217 数据录入）+ 2 个 S&V 锚点 #233：
/// Magician/Legion。名称与能力为官方中文魔典译名 / 官方英文转述；
/// 夜序以官方 nightsheet 为准）。
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
        '有一名善良玩家会被你误判为恶魔（"红鲱鱼"）。',
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
    infoInputType: InfoInputType.singlePlayerTarget,
    canTargetSelf: false,
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
    infoInputType: InfoInputType.singlePlayerTarget,
    canTargetSelf: false,
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
    ability: '你可能被判定为邪恶阵营，或登记为爪牙 / 恶魔，即使你已经死亡。',
    infoInputType: InfoInputType.none,
    mayRegisterAsEvil: true,
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
    infoInputType: InfoInputType.singlePlayerTarget,
  ),

  /// 间谍：每晚查看魔典；可能被判定为善良阵营。
  spy(
    nameCn: '间谍',
    nameEn: 'Spy',
    team: Team.minion,
    ability: '每个夜晚，你可以查看魔典。你可能被判定为善良阵营，或登记为镇民 / 外来者，即使你已经死亡。',
    infoInputType: InfoInputType.freeText,
    mayRegisterAsGood: true,
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
    setupOutsiderDeltas: const [2],
  ),

  // ── 恶魔 (1) ─────────────────────────────────────────────
  /// 小恶魔：每晚选择一名玩家杀死；死亡时可由爪牙继承。
  imp(
    nameCn: '小恶魔',
    nameEn: 'Imp',
    team: Team.demon,
    ability: '每个夜晚（除首夜），选择一名玩家：他死亡。'
        '若你选择自己（自杀），一名爪牙成为新的小恶魔。',
    infoInputType: InfoInputType.none,
  ),

  // ── S&V 锚点角色（#233）──────────────────────────────────
  // 提前录入 Magician/Legion 真实数据对，为 JinxRule 推导 API 提供官方
  // 锚点（两者间存在官方 Jinx）。**不入任何剧本角色池**（TB 池 22 个不变，
  // S&V 池待 #217 全量录入后开放）。能力文本已核官方 Wiki。

  /// 魔术师（S&V 镇民）：爪牙以为你是恶魔（登记混淆，被动）。
  magician(
    nameCn: '魔术师',
    nameEn: 'Magician',
    team: Team.townsfolk,
    ability: '爪牙们以为你是恶魔。',
    infoInputType: InfoInputType.none,
    script: Script.sectsAndViolets,
  ),

  /// 军团（S&V 恶魔）：多人恶魔，处决与登记全面特殊。
  legion(
    nameCn: '军团',
    nameEn: 'Legion',
    team: Team.demon,
    ability: '每个夜晚*，可能有一名玩家死亡。若只有邪恶玩家投票，处决失败。'
        '本局没有爪牙和醉汉——即便看似有。',
    infoInputType: InfoInputType.none,
    script: Script.sectsAndViolets,
  ),

  // ── BMR 黯月初升（#217 数据录入，官方 botc-release roles.json）────

  /// 侍女（BMR 镇民）。
  chambermaid(
    nameCn: '侍女',
    nameEn: 'Chambermaid',
    team: Team.townsfolk,
    ability: '每个夜晚，选择两名存活玩家（不能是自己）：你得知今晚'
        '有多少人因他们的能力被唤醒。',
    infoInputType: InfoInputType.twoPlayersNumber,
    // 官方：choose 2 alive players (not yourself)。
    canTargetSelf: false,
    script: Script.badMoonRising,
  ),

  /// 侍臣（BMR 镇民）。
  courtier(
    nameCn: '侍臣',
    nameEn: 'Courtier',
    team: Team.townsfolk,
    ability: '每局限一次，在夜晚选择一个角色：该角色醉 3 夜 3 天。',
    infoInputType: InfoInputType.characterName,
    script: Script.badMoonRising,
  ),

  /// 驱魔人（BMR 镇民）。
  exorcist(
    nameCn: '驱魔人',
    nameEn: 'Exorcist',
    team: Team.townsfolk,
    ability: '每个夜晚*，选择一名玩家（须与昨夜不同）：若选中恶魔，'
        '恶魔得知你是谁，且当晚不再行动。',
    infoInputType: InfoInputType.singlePlayerTarget,
    script: Script.badMoonRising,
  ),

  /// 弄臣（BMR 镇民）。
  fool(
    nameCn: '弄臣',
    nameEn: 'Fool',
    team: Team.townsfolk,
    ability: '你第一次死亡时，你不会死。',
    infoInputType: InfoInputType.none,
    script: Script.badMoonRising,
  ),

  /// 赌徒（BMR 镇民）。
  gambler(
    nameCn: '赌徒',
    nameEn: 'Gambler',
    team: Team.townsfolk,
    ability: '每个夜晚*，选择一名玩家并猜测其角色：猜错则你死亡。',
    infoInputType: InfoInputType.playerPlusCharacter,
    script: Script.badMoonRising,
  ),

  /// 造谣者（BMR 镇民）。
  gossip(
    nameCn: '造谣者',
    nameEn: 'Gossip',
    team: Team.townsfolk,
    ability: '每个白天，你可以公开发表一项声明。当晚，若声明为真，'
        '则有一名玩家死亡。',
    infoInputType: InfoInputType.freeText,
    script: Script.badMoonRising,
  ),

  /// 祖母（BMR 镇民）。
  grandmother(
    nameCn: '祖母',
    nameEn: 'Grandmother',
    team: Team.townsfolk,
    ability: '开局得知一名好人玩家及其角色。若恶魔杀死该玩家，'
        '你也死亡。',
    infoInputType: InfoInputType.playerPlusCharacter,
    script: Script.badMoonRising,
  ),

  /// 旅店老板（BMR 镇民）。
  innkeeper(
    nameCn: '旅店老板',
    nameEn: 'Innkeeper',
    team: Team.townsfolk,
    ability: '每个夜晚*，选择两名玩家：他们当晚不会死亡，'
        '但其中一人醉至黄昏。',
    infoInputType: InfoInputType.twoPlayersTarget,
    script: Script.badMoonRising,
  ),

  /// 吟游诗人（BMR 镇民）。
  minstrel(
    nameCn: '吟游诗人',
    nameEn: 'Minstrel',
    team: Team.townsfolk,
    ability: '当一名爪牙被处决时，其他所有玩家（除旅行者外）'
        '醉至次日黄昏。',
    infoInputType: InfoInputType.none,
    script: Script.badMoonRising,
  ),

  /// 和平主义者（BMR 镇民）。
  pacifist(
    nameCn: '和平主义者',
    nameEn: 'Pacifist',
    team: Team.townsfolk,
    ability: '被处决的好人玩家可能不会死。',
    infoInputType: InfoInputType.none,
    script: Script.badMoonRising,
  ),

  /// 教授（BMR 镇民）。
  professor(
    nameCn: '教授',
    nameEn: 'Professor',
    team: Team.townsfolk,
    ability: '每局限一次，在夜晚*选择一名已死玩家：若其为镇民，'
        '将其复活。',
    infoInputType: InfoInputType.singlePlayerTarget,
    // 官方：choose a dead player（复活目标，区别于常规存活目标）。
    requiresDeadTarget: true,
    script: Script.badMoonRising,
  ),

  /// 水手（BMR 镇民）。
  sailor(
    nameCn: '水手',
    nameEn: 'Sailor',
    team: Team.townsfolk,
    ability: '每个夜晚，选择一名存活玩家：你或其中一人醉至黄昏。'
        '你不会死亡。',
    infoInputType: InfoInputType.singlePlayerTarget,
    script: Script.badMoonRising,
  ),

  /// 茶艺师（BMR 镇民）。
  teaLady(
    nameCn: '茶艺师',
    nameEn: 'Tea Lady',
    team: Team.townsfolk,
    ability: '若你的两名存活邻座都是好人，他们不会死亡。',
    infoInputType: InfoInputType.none,
    script: Script.badMoonRising,
  ),

  /// 莽夫（BMR 外来者）。
  goon(
    nameCn: '莽夫',
    nameEn: 'Goon',
    team: Team.outsider,
    ability: '每个夜晚，第一个以能力选择你的玩家醉至黄昏，'
        '你变为与其同阵营。',
    infoInputType: InfoInputType.none,
    script: Script.badMoonRising,
  ),

  /// 疯子（BMR 外来者）。
  lunatic(
    nameCn: '疯子',
    nameEn: 'Lunatic',
    team: Team.outsider,
    ability: '你以为自己是恶魔，但你不是。恶魔知道你是谁、'
        '知道你每晚的选择。',
    infoInputType: InfoInputType.singlePlayerTarget,
    script: Script.badMoonRising,
  ),

  /// 月之子（BMR 外来者）。
  moonchild(
    nameCn: '月之子',
    nameEn: 'Moonchild',
    team: Team.outsider,
    ability: '当你得知自己死亡时，公开选择一名存活玩家。当晚，'
        '若其为好人，则其死亡。',
    infoInputType: InfoInputType.singlePlayerTarget,
    script: Script.badMoonRising,
  ),

  /// 修补匠（BMR 外来者）。
  tinker(
    nameCn: '修补匠',
    nameEn: 'Tinker',
    team: Team.outsider,
    ability: '你随时可能死亡。',
    infoInputType: InfoInputType.none,
    script: Script.badMoonRising,
  ),

  /// 刺客（BMR 爪牙）。
  assassin(
    nameCn: '刺客',
    nameEn: 'Assassin',
    team: Team.minion,
    ability: '每局限一次，在夜晚*选择一名玩家：其死亡——'
        '即使因某些原因本不能死。',
    infoInputType: InfoInputType.singlePlayerTarget,
    script: Script.badMoonRising,
  ),

  /// 魔鬼代言人（BMR 爪牙）。
  devilsAdvocate(
    nameCn: '魔鬼代言人',
    nameEn: "Devil's Advocate",
    team: Team.minion,
    ability: '每个夜晚，选择一名存活玩家（须与昨夜不同）：'
        '其明日被处决也不会死。',
    infoInputType: InfoInputType.singlePlayerTarget,
    script: Script.badMoonRising,
  ),

  /// 教父（BMR 爪牙，setup 修正角色）。
  godfather(
    nameCn: '教父',
    nameEn: 'Godfather',
    team: Team.minion,
    ability: '开局得知在场的外来者。若当日有一名外来者死亡，'
        '当晚选择一名玩家：其死亡。',
    infoInputType: InfoInputType.freeText,
    setupOutsiderDeltas: const [-1, 1],
    script: Script.badMoonRising,
  ),

  /// 主谋（BMR 爪牙）。
  mastermind(
    nameCn: '主谋',
    nameEn: 'Mastermind',
    team: Team.minion,
    ability: '若恶魔被处决而死（本应结束游戏），游戏多进行一天。'
        '若此后有玩家被处决，其阵营落败。',
    infoInputType: InfoInputType.none,
    script: Script.badMoonRising,
  ),

  /// 珀（BMR 恶魔）。
  po(
    nameCn: '珀',
    nameEn: 'Po',
    team: Team.demon,
    ability: '每个夜晚*，你可以选择一名玩家：其死亡。若你上一次选择'
        '不杀人，今晚可选择三名玩家。',
    infoInputType: InfoInputType.none,
    script: Script.badMoonRising,
  ),

  /// 普卡（BMR 恶魔）。
  pukka(
    nameCn: '普卡',
    nameEn: 'Pukka',
    team: Team.demon,
    ability: '每个夜晚，选择一名玩家：其中毒。上一名中毒的玩家死亡'
        '并恢复健康。',
    infoInputType: InfoInputType.singlePlayerTarget,
    script: Script.badMoonRising,
  ),

  /// 沙巴洛斯（BMR 恶魔）。
  shabaloth(
    nameCn: '沙巴洛斯',
    nameEn: 'Shabaloth',
    team: Team.demon,
    ability: '每个夜晚*，选择两名玩家：他们死亡。昨夜选中的一名'
        '已死玩家可能被吐出（复活）。',
    infoInputType: InfoInputType.none,
    script: Script.badMoonRising,
  ),

  /// 僵怖（BMR 恶魔）。
  zombuul(
    nameCn: '僵怖',
    nameEn: 'Zombuul',
    team: Team.demon,
    ability: '每个夜晚*，若当日无人死亡，选择一名玩家：其死亡。'
        '你第一次死亡时，你活着但被视为已死。',
    infoInputType: InfoInputType.none,
    script: Script.badMoonRising,
  ),

  // ── S&V 梦殒春宵（#217 增量5：官方 botc-release + 魔典 wiki
  //    图片文件名交叉验证 EN↔CN 映射；旅行者/实验角色不在池）────

  /// 钟表匠（S&V 镇民）。
  clockmaker(
    nameCn: '钟表匠',
    nameEn: 'Clockmaker',
    team: Team.townsfolk,
    ability: '在你的首个夜晚，你会得知恶魔与爪牙之间最近的距离（邻座距离为 1）。',
    infoInputType: InfoInputType.freeText,
    script: Script.sectsAndViolets,
  ),
  /// 筑梦师（S&V 镇民）。
  dreamer(
    nameCn: '筑梦师',
    nameEn: 'Dreamer',
    team: Team.townsfolk,
    ability: '每个夜晚，'
        '选择一名玩家（不能是自己或旅行者）：你得知一个善良角色和一个邪恶角色，'
        '该玩家是其中一个角色。',
    infoInputType: InfoInputType.freeText,
    script: Script.sectsAndViolets,
  ),
  /// 舞蛇人（S&V 镇民）。
  snakecharmer(
    nameCn: '舞蛇人',
    nameEn: 'Snake Charmer',
    team: Team.townsfolk,
    ability: '每个夜晚，选择一名存活玩家：若选中恶魔，你与其交换角色和阵营，且他中毒。',
    infoInputType: InfoInputType.singlePlayerTarget,
    script: Script.sectsAndViolets,
  ),
  /// 数学家（S&V 镇民）。
  mathematician(
    nameCn: '数学家',
    nameEn: 'Mathematician',
    team: Team.townsfolk,
    ability: '每个夜晚，'
        '你得知自上个黎明以来有多少玩家的能力因其他角色的能力而未能正常生效。',
    infoInputType: InfoInputType.freeText,
    script: Script.sectsAndViolets,
  ),
  /// 卖花女孩（S&V 镇民）。
  flowergirl(
    nameCn: '卖花女孩',
    nameEn: 'Flowergirl',
    team: Team.townsfolk,
    ability: '每个夜晚*，你得知今天白天是否有恶魔投过票。',
    infoInputType: InfoInputType.freeText,
    script: Script.sectsAndViolets,
  ),
  /// 城镇公告员（S&V 镇民）。
  towncrier(
    nameCn: '城镇公告员',
    nameEn: 'Town Crier',
    team: Team.townsfolk,
    ability: '每个夜晚*，你得知今天白天是否有爪牙发起过提名。',
    infoInputType: InfoInputType.freeText,
    script: Script.sectsAndViolets,
  ),
  /// 神谕者（S&V 镇民）。
  oracle(
    nameCn: '神谕者',
    nameEn: 'Oracle',
    team: Team.townsfolk,
    ability: '每个夜晚*，你得知有多少名死亡的玩家是邪恶的。',
    infoInputType: InfoInputType.freeText,
    script: Script.sectsAndViolets,
  ),
  /// 博学者（S&V 镇民）。
  savant(
    nameCn: '博学者',
    nameEn: 'Savant',
    team: Team.townsfolk,
    ability: '每个白天，你可以私下询问说书人得知两条信息：一条为真，一条为假。',
    infoInputType: InfoInputType.freeText,
    script: Script.sectsAndViolets,
  ),
  /// 女裁缝（S&V 镇民）。
  seamstress(
    nameCn: '女裁缝',
    nameEn: 'Seamstress',
    team: Team.townsfolk,
    ability: '每局限一次，在夜晚选择除你以外的两名玩家：你得知他们是否为同一阵营。',
    infoInputType: InfoInputType.freeText,
    script: Script.sectsAndViolets,
  ),
  /// 哲学家（S&V 镇民）。
  philosopher(
    nameCn: '哲学家',
    nameEn: 'Philosopher',
    team: Team.townsfolk,
    ability: '每局限一次，在夜晚选择一个善良角色：你获得该角色的能力。若该角色在场，'
        '其玩家醉酒。',
    infoInputType: InfoInputType.characterName,
    script: Script.sectsAndViolets,
  ),
  /// 艺术家（S&V 镇民）。
  artist(
    nameCn: '艺术家',
    nameEn: 'Artist',
    team: Team.townsfolk,
    ability: '每局限一次，在白天私下询问说书人一个是非问题，你得知答案。',
    infoInputType: InfoInputType.freeText,
    script: Script.sectsAndViolets,
  ),
  /// 杂耍艺人（S&V 镇民）。
  juggler(
    nameCn: '杂耍艺人',
    nameEn: 'Juggler',
    team: Team.townsfolk,
    ability: '在你的首个白天，你可以公开猜测任意玩家的角色最多五次；当晚你得知猜对了几个。',
    infoInputType: InfoInputType.freeText,
    script: Script.sectsAndViolets,
  ),
  /// 贤者（S&V 镇民）。
  sage(
    nameCn: '贤者',
    nameEn: 'Sage',
    team: Team.townsfolk,
    ability: '如果恶魔杀死了你，当晚你得知两名玩家，其中一名是杀死你的恶魔。',
    infoInputType: InfoInputType.twoPlayersTarget,
    script: Script.sectsAndViolets,
  ),
  /// 畸形秀演员（S&V 外来者）。
  mutant(
    nameCn: '畸形秀演员',
    nameEn: 'Mutant',
    team: Team.outsider,
    ability: '如果你「疯狂」地证明自己是外来者，你可能被处决。',
    infoInputType: InfoInputType.none,
    script: Script.sectsAndViolets,
  ),
  /// 心上人（S&V 外来者）。
  sweetheart(
    nameCn: '心上人',
    nameEn: 'Sweetheart',
    team: Team.outsider,
    ability: '当你死亡时，会有一名玩家从现在开始醉酒。',
    infoInputType: InfoInputType.none,
    script: Script.sectsAndViolets,
  ),
  /// 理发师（S&V 外来者）。
  barber(
    nameCn: '理发师',
    nameEn: 'Barber',
    team: Team.outsider,
    ability: '如果你今日或今晚死亡，恶魔可以选择两名玩家（不能是其他恶魔）交换角色。',
    infoInputType: InfoInputType.none,
    script: Script.sectsAndViolets,
  ),
  /// 呆瓜（S&V 外来者）。
  klutz(
    nameCn: '呆瓜',
    nameEn: 'Klutz',
    team: Team.outsider,
    ability: '当你得知自己死亡时，公开选择一名存活玩家：若其为邪恶，你的阵营落败。',
    infoInputType: InfoInputType.none,
    script: Script.sectsAndViolets,
  ),
  /// 镜像双子（S&V 爪牙）。
  eviltwin(
    nameCn: '镜像双子',
    nameEn: 'Evil Twin',
    team: Team.minion,
    ability: '你与一名对立阵营的玩家互相知道对方。若该好人被处决，'
        '邪恶获胜；你们都存活则善良无法获胜。',
    infoInputType: InfoInputType.playerPlusCharacter,
    script: Script.sectsAndViolets,
  ),
  /// 女巫（S&V 爪牙）。
  witch(
    nameCn: '女巫',
    nameEn: 'Witch',
    team: Team.minion,
    ability: '每个夜晚，选择一名玩家：若其明天白天发起提名，其死亡。若只剩三名存活玩家，'
        '你失去此能力。',
    infoInputType: InfoInputType.singlePlayerTarget,
    script: Script.sectsAndViolets,
  ),
  /// 洗脑师（S&V 爪牙）。
  cerenovus(
    nameCn: '洗脑师',
    nameEn: 'Cerenovus',
    team: Team.minion,
    ability: '每个夜晚，'
        '选择一名玩家和一个善良角色：其明天白天和夜晚须「疯狂」地证明自己是该角色，'
        '否则可能被处决。',
    infoInputType: InfoInputType.playerPlusCharacter,
    script: Script.sectsAndViolets,
  ),
  /// 麻脸巫婆（S&V 爪牙）。
  pithag(
    nameCn: '麻脸巫婆',
    nameEn: 'Pit-Hag',
    team: Team.minion,
    ability: '每个夜晚*，选择一名玩家和一个角色：若该角色不在场，'
        '其变成该角色。若因此产生新恶魔，当晚的死亡由说书人决定。',
    infoInputType: InfoInputType.playerPlusCharacter,
    script: Script.sectsAndViolets,
  ),
  /// 方古（S&V 恶魔）。
  fanggu(
    nameCn: '方古',
    nameEn: 'Fang Gu',
    team: Team.demon,
    ability: '每个夜晚*，'
        '选择一名玩家：其死亡。第一个因此死亡的外来者变成邪恶的方古且你代替其死亡。',
    infoInputType: InfoInputType.none,
    setupOutsiderDeltas: const [1],
    script: Script.sectsAndViolets,
  ),
  /// 亡骨魔（S&V 恶魔）。
  vigormortis(
    nameCn: '亡骨魔',
    nameEn: 'Vigormortis',
    team: Team.demon,
    ability: '每个夜晚*，'
        '选择一名玩家：其死亡。你杀死的爪牙保留能力并使其一名镇民邻座中毒。',
    infoInputType: InfoInputType.none,
    setupOutsiderDeltas: const [-1],
    script: Script.sectsAndViolets,
  ),
  /// 诺-达鲺（S&V 恶魔）。
  nodashii(
    nameCn: '诺-达鲺',
    nameEn: 'No Dashii',
    team: Team.demon,
    ability: '每个夜晚*，选择一名玩家：其死亡。你的两名镇民邻座中毒。',
    infoInputType: InfoInputType.none,
    script: Script.sectsAndViolets,
  ),
  /// 涡流（S&V 恶魔）。
  vortox(
    nameCn: '涡流',
    nameEn: 'Vortox',
    team: Team.demon,
    ability: '每个夜晚*，'
        '选择一名玩家：其死亡。镇民能力给出错误信息。每个白天若无人被处决，邪恶获胜。',
    infoInputType: InfoInputType.none,
    script: Script.sectsAndViolets,
  );

  const Character({
    required this.nameCn,
    required this.nameEn,
    required this.team,
    required this.ability,
    required this.infoInputType,
    // #230：剧本归属参数化（原 script getter 硬编码 TB 的 TODO 落实）。
    // 现仅 TB 角色，默认 TB；BMR/S&V 角色录入（#217）时显式传入。
    this.script = Script.troubleBrewing,
    // 官方规则：Monk/Butler/Chambermaid 的目标不能选自己（#230 数据化）。
    this.canTargetSelf = true,
    // 官方规则：Professor 的复活目标须为已死玩家（其余夜间目标为存活者）。
    this.requiresDeadTarget = false,
    // #231：setup 修正角色的外来者增量模型。固定增量为单元素（Baron [2]）；
    // 「说书人选」型为多元素（BMR Godfather [-1,1]、S&V Balloonist [0,1]，
    // 随 #217 录入）。外来者增减由镇民反向补偿。
    this.setupOutsiderDeltas = const [],
    // #234：登记修饰（registration，跨剧本通用机制，官方 might register
    // ——说书人可选，默认按真实身份登记，方向**单向**：mayRegisterAsGood
    // 只能向善良登记（冒充镇民/外来者，TB=Spy）；mayRegisterAsEvil 只能向
    // 邪恶登记（冒充爪牙/恶魔，TB=Recluse）。S&V Marionette/Vortox 等同型
    // 随 #217 录入。语义基石见 #213。
    this.mayRegisterAsGood = false,
    this.mayRegisterAsEvil = false,
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

  /// 所属剧本（#230 参数化；现仅 TB 角色，默认 TB）。
  final Script script;

  /// 夜间行动目标能否选自己（Monk/Butler/Chambermaid 官方不可，其余可）。
  final bool canTargetSelf;

  /// 目标须为已死玩家（Professor 复活；其余默认存活目标）。
  final bool requiresDeadTarget;

  /// setup 外来者增量候选（空 = 非修正角色；「或」型含多个可能值）。
  final List<int> setupOutsiderDeltas;

  /// 可能向善良登记（冒充镇民/外来者；TB=Spy）。
  final bool mayRegisterAsGood;

  /// 可能向邪恶登记（冒充爪牙/恶魔；TB=Recluse）。
  final bool mayRegisterAsEvil;

  /// 是否善良阵营。
  bool get isGood => team.isGood;

  /// 按阵营筛选角色列表。
  static List<Character> byTeam(Team team) =>
      values.where((c) => c.team == team).toList();
}
