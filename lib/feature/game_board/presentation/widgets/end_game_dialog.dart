import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';

/// 对局结束确认 dialog（issue #37）。
///
/// 四种入口：
/// - [showEvilCandidate]：存活 ≤ 2 时提示"邪恶获胜？"
/// - [showGoodWinCandidate]：存活 ≤ 2 且恶魔确认已死无继时提示"善良获胜？"
///   （issue #208）
/// - [showDemonCheck]：处决后确认"被处决者是恶魔吗？"，可录入死亡揭示角色
/// - [showMayorCheck]：3 人存活且无人被处决时确认市长是否在场（issue #88）
abstract final class EndGameDialog {
  /// 存活 ≤ 2 提示。返回 true=确认邪恶获胜，false/null=继续游戏。
  static Future<bool?> showEvilCandidate(
    BuildContext context, {
    required int aliveCount,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('存活人数告急', style: AppTextStyles.title),
        content: Text(
          '场上仅剩 $aliveCount 名存活玩家。\n按官方规则，仅剩 2 人时邪恶阵营获胜。',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续游戏'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.gameColors.blood,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('邪恶获胜'),
          ),
        ],
      ),
    );
  }

  /// 恶魔已死无存活继承人 + 存活 ≤ 2（issue #208）。
  ///
  /// 官方前提「恶魔活到只剩 2 人」不成立——按记录恶魔已死且无传承，
  /// 应提示善良胜。返回 true=确认善良获胜，false/null=继续游戏（认知
  /// 极限兜底：SW 自动继承等未记录事件由用户裁决）。
  static Future<bool?> showGoodWinCandidate(
    BuildContext context, {
    required int aliveCount,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恶魔已死？', style: AppTextStyles.title),
        content: Text(
          '场上仅剩 $aliveCount 名存活玩家，且记录显示恶魔已死亡、'
          '无存活继承人。\n按官方规则，人头邪恶胜的前提是恶魔活到最后——'
          '此时应为善良阵营获胜。',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续游戏'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.gameColors.trustConfirmedGood,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('善良获胜'),
          ),
        ],
      ),
    );
  }

  /// 市长胜利确认（issue #88）：3 人存活且当日无人被处决。
  /// 返回 true=善良获胜，null/false=继续。
  static Future<bool?> showMayorCheck(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('市长可能获胜', style: AppTextStyles.title),
        content: Text(
          '场上仅剩 3 名存活玩家且今日无人被处决。\n'
          '官方规则：若有市长存活且未被毒 / 醉在场，善良阵营获胜。',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续游戏'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.gameColors.trustConfirmedGood,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('善良获胜'),
          ),
        ],
      ),
    );
  }

  /// 处决后确认。返回 [GameEndResult]；null = 取消。
  static Future<GameEndResult?> showDemonCheck(
    BuildContext context, {
    required String executedName,
    Script script = Script.troubleBrewing,
  }) {
    Character? revealed;
    return showDialog<GameEndResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('$executedName 被处决', style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('他是恶魔吗？', style: AppTextStyles.body),
              const SizedBox(height: 12),
              DropdownButtonFormField<Character>(
                initialValue: revealed,
                decoration: const InputDecoration(
                  labelText: '揭示的角色（可选）',
                  isDense: true,
                ),
                items: [
                  for (final c in ScriptDefinition.of(script).characters)
                    DropdownMenuItem(value: c, child: Text(c.nameCn)),
                ],
                onChanged: (c) => setState(() => revealed = c),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                GameEndResult(goodWin: false, revealedRole: revealed),
              ),
              child: const Text('不是，继续'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.gameColors.trustConfirmedGood,
              ),
              onPressed: () => Navigator.pop(
                context,
                GameEndResult(goodWin: true, revealedRole: revealed),
              ),
              child: const Text('是恶魔，善良获胜'),
            ),
          ],
        ),
      ),
    );
  }

  /// 恶魔死亡传承确认（issue #89）。
  ///
  /// 三路径（自杀/处决/Slayer）统一对话框：用户裁决是否传承、选继承人
  /// （新恶魔），或判恶魔真死 → 善良胜。[heirCandidates] 为存活爪牙候选
  /// （我是恶魔=私密爪牙名单，好人=声明爪牙）。[allowDeathReveal] 为真时
  /// 显示死亡揭示角色下拉（处决/Slayer 路径）。
  static Future<SuccessionResult?> showSuccessionCheck(
    BuildContext context, {
    required DemonSuccessionCandidate candidate,
    required List<({int playerId, String name})> heirCandidates,
    bool allowDeathReveal = false,
    Character? initialRevealedRole,
    Script script = Script.troubleBrewing,
  }) {
    // SW 满足时默认选 SW；否则 null（「继承人未知」项）。
    int? selectedHeir =
        candidate.scarletWomanEligible ? candidate.scarletWomanPlayerId : null;
    Character? revealed = initialRevealedRole;
    return showDialog<SuccessionResult>(
      context: context,
      // 恶魔已落库死亡，必须裁决（传承/善良胜），不可 dismiss 悬空——
      // 尤其 Slayer 路径 abilityUsed 已置 true，dismiss 后无法重入。
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${candidate.demonName}（恶魔）死亡',
              style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (candidate.scarletWomanEligible)
                Text(
                  '绯红女在场（死前 ${candidate.aliveCountAfter + 1} 存活 ≥5），'
                  '按规则自动继承为新恶魔。'
                  '${candidate.scarletWomanTainted ? '\n⚠ SW 被标毒/醉，按规则可能不触发，由你裁决。' : ''}',
                  style: AppTextStyles.body,
                )
              else
                Text(
                  'Imp 自杀传位：选一名存活爪牙继承为新恶魔（游戏继续）。\n'
                  '若恶魔已无爪牙可传，可判善良胜。',
                  style: AppTextStyles.body,
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: selectedHeir,
                decoration: const InputDecoration(
                  labelText: '继承人（新恶魔）',
                  isDense: true,
                ),
                items: [
                  for (final heir in heirCandidates)
                    DropdownMenuItem<int?>(
                      value: heir.playerId,
                      child: Text(heir.name),
                    ),
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('继承人未知（暂不指定）'),
                  ),
                ],
                onChanged: (v) => setState(() => selectedHeir = v),
              ),
              if (allowDeathReveal) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<Character>(
                  initialValue: revealed,
                  decoration: const InputDecoration(
                    labelText: '揭示的角色（可选）',
                    isDense: true,
                  ),
                  items: [
                    for (final c in ScriptDefinition.of(script).characters)
                      DropdownMenuItem(value: c, child: Text(c.nameCn)),
                  ],
                  onChanged: (c) => setState(() => revealed = c),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                SuccessionResult(occurred: false, revealedRole: revealed),
              ),
              child: const Text('恶魔已死，善良获胜'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.gameColors.blood,
              ),
              onPressed: () => Navigator.pop(
                context,
                SuccessionResult(
                  occurred: true,
                  toPlayerId: selectedHeir,
                  // 处决/Slayer 传承必经 SW（规则）；自杀按继承人判定。
                  trigger: candidate.way == DeathWay.suicide
                      ? (selectedHeir == candidate.scarletWomanPlayerId
                          ? SuccessionTrigger.scarletWoman
                          : SuccessionTrigger.suicideByImp)
                      : SuccessionTrigger.scarletWoman,
                  revealedRole: revealed,
                ),
              ),
              child: const Text('传承，游戏继续'),
            ),
          ],
        ),
      ),
    );
  }
}
