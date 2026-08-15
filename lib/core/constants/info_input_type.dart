/// 角色信息输入模板类型。
///
/// 决定该角色获得信息时 App 提供的结构化输入 UI
/// （对应 docs/DESIGN.md 的"信息输入模板按角色自动适配"）。
enum InfoInputType {
  /// 该角色无信息类能力，不提供信息输入。
  none,

  /// 数字输入 0-N（如 Chef，N 随存活人数变化）。
  numberRange,

  /// 数字输入 0-2（如 Empath）。
  numberZeroToTwo,

  /// 选 2 名玩家 + 是/否（如 Fortune Teller）。
  twoPlayersYesNo,

  /// 选 1 个爪牙角色 + 选 2 名玩家（如 Investigator）。
  minionPlusTwoPlayers,

  /// 选 1 个镇民角色 + 选 2 名玩家（如 Washerwoman）。
  townsfolkPlusTwoPlayers,

  /// 选 1 个外来者角色 + 选 2 名玩家或"无"（如 Librarian）。
  outsiderPlusTwoPlayersOrNone,

  /// 选 1 个角色名（如 Undertaker 报被处决者身份）。
  characterName,

  /// 选 1 名玩家 + 选 1 个角色名（如 Ravenkeeper）。
  playerPlusCharacter,

  /// 选 1 名玩家（夜间行动目标，如 Monk 保护 / Butler 主人 / Poisoner 下毒）。
  /// payload: {"playerId": n}
  singlePlayerTarget,

  /// 选 2 名玩家 + 数字 0-2（BMR 侍女：得知两人中几人夜间醒来）。
  /// payload: {"playerIds": [a, b], "value": n}
  twoPlayersNumber,

  /// 选 2 名玩家（BMR 旅店老板：保护目标）。
  /// payload: {"playerIds": [a, b]}
  twoPlayersTarget,

  /// 是/否（S&V 卖花女孩/城镇公告员）。
  /// payload: {"answer": true}
  yesNo,

  /// 选 1 名玩家 + 1 个善良角色 + 1 个邪恶角色（S&V 筑梦师）。
  /// payload: {"playerId": 3, "goodCharacter": "empath", "evilCharacter": "poisoner"}
  playerPlusGoodEvilCharacters,

  /// 自由文本（其余角色的通用兜底）。
  freeText,
}
