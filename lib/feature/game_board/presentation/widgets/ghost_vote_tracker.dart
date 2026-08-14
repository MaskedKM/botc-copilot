import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:flutter/material.dart';

/// 幽灵票（死票）追踪面板（issue #216 功能2）。
///
/// 官方规则：死亡玩家仅剩 **1 票**（死票/幽灵票），投出即耗尽、此后
/// 不可再投。「谁还没用死票」是白天博弈的关键信息，原先要玩家自己数。
///
/// 纯参数 widget（无 provider 依赖）：[deadPlayers] 全部死亡玩家，
/// [allNominations] 全局提名（含往日），内部用
/// [NominationRules.deadVoteUsed] 判定已用。死亡玩家为空时静默不渲染。
class GhostVoteTracker extends StatelessWidget {
  /// 创建追踪面板。
  const GhostVoteTracker({
    required this.deadPlayers,
    required this.allNominations,
    super.key,
  });

  /// 全部死亡玩家（任意死因）。
  final List<Player> deadPlayers;

  /// 全局提名（`gameNominationsProvider` 结果，含往日）。
  final List<Nomination> allNominations;

  @override
  Widget build(BuildContext context) {
    if (deadPlayers.isEmpty) return const SizedBox.shrink();
    final gameColors = context.gameColors;

    // 座位序展示（id 序≠座位序，#145 教训）。
    final sorted = [...deadPlayers]
      ..sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
    final unused = sorted
        .where((p) => !NominationRules.deadVoteUsed(allNominations, p.id))
        .toList();
    final used = sorted
        .where((p) => NominationRules.deadVoteUsed(allNominations, p.id))
        .toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: gameColors.goldBright.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gameColors.goldBright.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_vote_outlined,
                  size: 16, color: gameColors.goldBright),
              const SizedBox(width: 6),
              Text(
                '死票追踪（死亡玩家仅 1 票）',
                style:
                    AppTextStyles.body.copyWith(color: gameColors.goldBright),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (unused.isEmpty)
            Text(
              '所有死亡玩家的死票均已用完。',
              style: AppTextStyles.caption
                  .copyWith(color: gameColors.inkViolet),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final p in unused)
                  Chip(
                    label: Text('${p.seatNumber}号 ${p.name}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '尚有死票未用：${unused.map((p) => '${p.seatNumber}号').join('、')}'
              '${used.isEmpty ? '' : '（已用完：${used.map((p) => '${p.seatNumber}号').join('、')}）'}',
              style:
                  AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
            ),
          ],
        ],
      ),
    );
  }
}
