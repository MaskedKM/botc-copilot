import 'package:botc_copilot/core/constants/character.dart';

/// 夜晚死亡录入的规则警告（issue #114）。
///
/// 返回规则上「不可能或几乎不可能」的提示文案列表（空 = 无警告）。
/// 遵循「**警告不阻止**」原则：毒/醉可解释部分场景（如 Soldier 被毒则
/// 能力失效可死），村规/实验角色也可能覆盖能力——调用方弹非阻止确认
/// dialog 即可，参考 #85 的处决警告模式。
///
/// 已覆盖（TB 基准）：
/// - **首夜死亡**：Imp 的夜序标记为「仅后续夜晚」——首夜不杀人，TB 无
///   其他夜间致死角色，故首夜必无人死亡。
/// - **声明 Soldier 的玩家夜死**：Soldier 能力 *"You are safe from the
///   Demon."*——免疫恶魔能力；TB 夜死只有恶魔造成，故 Soldier 夜死意味
///   着能力被毒/醉关闭或录错。
///
/// 待 #110（夜间行动记录）落地后补充：当晚有 Monk 保护记录的被保护者
/// 夜死（#114 任务 3）。
abstract final class NightDeathRules {
  /// 返回适用警告文案列表（空 = 无警告）。
  ///
  /// [day] 当前天数（从 1 开始）；[claimedCharacter] 该玩家**声明**的角色
  /// （最新公开声明；调用方对「我」的座位应传 myRole，见 _claimedCharacter）。
  static List<String> warnings({
    required int day,
    Character? claimedCharacter,
  }) {
    final result = <String>[];
    if (day == 1) {
      result.add('官方规则：首夜无人死亡（Imp 首夜不杀人，TB 无其他夜间致死）。');
    }
    if (claimedCharacter == Character.soldier) {
      result.add('该玩家声明为士兵。士兵免疫恶魔能力——除非被毒/醉。');
    }
    return result;
  }
}
