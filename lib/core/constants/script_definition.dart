import 'package:botc_copilot/core/constants/character.dart';
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

  /// 取剧本定义；未注册剧本（BMR/S&V 角色未录期间）兜底 TB——
  /// 现阶段 setup 已禁用其余剧本，兜底仅为防御脏数据（如换库残留）。
  static ScriptDefinition of(Script script) =>
      scriptDefinitions[script] ?? scriptDefinitions[Script.troubleBrewing]!;

  /// 按阵营取角色池子集。
  List<Character> byTeam(Team team) =>
      characters.where((c) => c.team == team).toList();

  /// 剧本内外来者增量的**最大可能值**（TB：Baron → 2；无修正角色 → 0）。
  ///
  /// 「或」型角色（Godfather ±1）取其各候选的最大值。
  int get maxOutsiderDelta => characters
      .expand((c) => c.setupOutsiderDeltas)
      .fold(0, (a, b) => a > b ? a : b);

  /// 已声明修正角色下的外来者最大可能增量（#231）。
  ///
  /// [claimedCharacters] 为每玩家最新声明的角色集合（可含 myRole 注入项）。
  /// 未声明任何修正角色 → 0（基础配置）；声明了则取该角色增量候选的最大
  /// 值（隐藏的真修正角色未声明时不可知，返回 0 保持保守——与原 Baron
  /// 语义一致：只有 Baron 已声明才按 base+2 期望）。
  static int claimedOutsiderDelta(Iterable<Character> claimedCharacters) {
    var max = 0;
    for (final c in claimedCharacters) {
      for (final d in c.setupOutsiderDeltas) {
        if (d > max) max = d;
      }
    }
    return max;
  }
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
  // BMR / S&V：角色数据随 #217 录入（现空池，setup 已禁用入口）。
  Script.badMoonRising: ScriptDefinition(
    script: Script.badMoonRising,
    characters: [],
  ),
  Script.sectsAndViolets: ScriptDefinition(
    script: Script.sectsAndViolets,
    characters: [],
  ),
};

/// 当天对应的夜晚步骤（按剧本分派，#232）。
///
/// [script] 经 game.script 传入——这是 game.script 首次业务消费点；
/// 未注册剧本经 [ScriptDefinition.of] 兜底 TB。
List<NightOrderStep> nightStepsForDay(Script script, int dayNumber) =>
    ScriptDefinition.of(script).nightStepsFor(dayNumber);
