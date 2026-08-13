import 'package:botc_copilot/core/constants/character.dart';

/// 恶魔传承规则（issue #89 公理5，纯函数，可测试）。
///
/// 权威：官方 Wiki Scarlet_Woman / Imp + Reddit Courtier/SW。
/// - **SW 触发**：恶魔**任何方式**死 + **死前** ≥5 存活 + SW 存活未醉毒 +
///   仅恶魔**第一次**死时；满足时**强制优先**于其他爪牙。
/// - **Imp 自杀普通传位**：无 SW 时，恶魔/说书人选一名存活爪牙继承。
/// - **处决/Slayer 杀恶魔 + 无 SW**：善良胜（不传位）。
abstract final class SuccessionRules {
  /// 死者是否疑似恶魔（触发传承提示）。
  ///
  /// App 按玩家**有效角色**判定：「我」的座位取 myRole（真身），他人取
  /// 最新公开声明（可能是 bluff，由用户在确认框裁决）。
  static bool isDemonDeath(Character? effectiveCharacter) =>
      effectiveCharacter == Character.imp;

  /// SW 自动继承的人数阈值：**死前** ≥5 存活（等价死后 ≥4）。
  ///
  /// 官方原文「5 or more alive players immediately before the Demon died」。
  /// [aliveAfter] 为恶魔死后的存活数，死前 = aliveAfter + 1。
  static bool isScarletWomanThreshold(int aliveAfter) => aliveAfter + 1 >= 5;

  /// 好人视角的继承人候选角色（声明爪牙角色的存活玩家）。
  ///
  /// 我不是恶魔时无法确知真实爪牙，只能按公开声明推断继承人候选。
  static const List<Character> minionClaimCandidates = [
    Character.poisoner,
    Character.spy,
    Character.scarletWoman,
    Character.baron,
  ];
}
