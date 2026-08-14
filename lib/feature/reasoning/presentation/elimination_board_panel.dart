import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/presentation/player_detail_sheet.dart';
import 'package:botc_copilot/feature/reasoning/data/elimination_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/elimination_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 排除法棋盘面板（issue #214）：自动演绎的候选收敛视图。
///
/// 与手动 `_DemonPoolSection`（信任度标记）互补——本面板展示**依据驱动**
/// 的结论：确认好人/邪恶（可展开看依据）、现任恶魔（若已知）、计数收缩、
/// 弱排除标注。原则：给候选与依据，身份判断由用户裁决。
class EliminationBoardPanel extends ConsumerWidget {
  /// 创建面板。
  const EliminationBoardPanel({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(eliminationBoardProvider(gameId));
    // 基础流未就绪：静默不占位（dashboard 自身已有加载态）。
    if (board == null) return const SizedBox.shrink();
    final players =
        ref.watch(gamePlayersProvider(gameId)).valueOrNull ??
            const <Player>[];
    final playersById = {for (final p in players) p.id: p};
    final gameColors = context.gameColors;

    String label(int id) {
      final p = playersById[id];
      return p == null ? '?' : '${p.seatNumber}号 ${p.name}';
    }

    // 座位序排序（#214 review F1）：候选由引擎排好，其余集合按座位统一，
    // 避免换座后按 db id 乱序。
    int bySeat(int a, int b) => (playersById[a]?.seatNumber ?? 1 << 30)
        .compareTo(playersById[b]?.seatNumber ?? 1 << 30);
    final weakOnly = board.weakDemonExclusions.keys.toList()..sort(bySeat);
    final forcedSorted = board.forcedEvilRemaining.toList()..sort(bySeat);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: gameColors.goldBright.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: gameColors.goldBright.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('排除法棋盘（自动演绎）', style: AppTextStyles.headline),
          const SizedBox(height: 4),
          Text(
            '存活邪恶 ${board.minAliveEvil}'
            '${board.maxAliveEvil != board.minAliveEvil ? '–${board.maxAliveEvil}' : ''} 人'
            ' · 依据自动收敛，身份判断由你裁决',
            style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
          ),
          const SizedBox(height: 8),
          if (board.confirmedDemonPlayerId case final demon?)
            _DemonKnownRow(
              label: label(demon),
              reason: board.confirmedDemonReason?.description ?? '',
              gameColors: gameColors,
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final id in board.demonCandidates)
                  ActionChip(
                    avatar: Icon(
                      board.weakDemonExclusions.containsKey(id)
                          ? Icons.visibility_off_outlined
                          : Icons.help_outline,
                      size: 14,
                      color: board.weakDemonExclusions.containsKey(id)
                          ? gameColors.inkViolet
                          : gameColors.goldBright,
                    ),
                    label: Text(label(id)),
                    onPressed: () {
                      final p = playersById[id];
                      if (p != null) {
                        PlayerDetailSheet.show(context, gameId: gameId, player: p);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              board.demonCandidates.isEmpty
                  ? '无恶魔候选（全部存活玩家已确认好人或已知爪牙）'
                  : '共 ${board.demonCandidates.length} 名候选'
                      '${weakOnly.isEmpty ? '' : '；${weakOnly.map(label).join('、')} 被信息弱排除（若真则非恶魔）'}',
              style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
            ),
          ],
          if (board.forcedEvilRemaining.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ForcedEvilBox(
              labels: [for (final id in forcedSorted) label(id)],
              gameColors: gameColors,
            ),
          ],
          if (board.anomalies.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final a in board.anomalies)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber,
                        size: 14, color: gameColors.blood),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        a,
                        style: AppTextStyles.caption
                            .copyWith(color: gameColors.bloodBright),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          _ReasonsTile(
            title: '确认好人（${board.confirmedGood.length}）',
            reasons: board.confirmedGood,
            label: label,
            sortWith: bySeat,
            color: gameColors.trustConfirmedGood,
            gameColors: gameColors,
          ),
          _ReasonsTile(
            title: '确认邪恶（${board.confirmedEvil.length}）',
            reasons: board.confirmedEvil,
            label: label,
            sortWith: bySeat,
            color: gameColors.blood,
            gameColors: gameColors,
          ),
        ],
      ),
    );
  }
}

/// 现任恶魔已知行（传承/myRole 确认）。
class _DemonKnownRow extends StatelessWidget {
  const _DemonKnownRow({
    required this.label,
    required this.reason,
    required this.gameColors,
  });

  final String label;
  final String reason;
  final GameColors gameColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: gameColors.blood.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: gameColors.blood.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 16, color: gameColors.blood),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '现任恶魔已确认：$label。$reason',
              style: AppTextStyles.body
                  .copyWith(color: gameColors.bloodBright),
            ),
          ),
        ],
      ),
    );
  }
}

/// 计数收缩结论框（确定性）。
class _ForcedEvilBox extends StatelessWidget {
  const _ForcedEvilBox({
    required this.labels,
    required this.gameColors,
  });

  final List<String> labels;
  final GameColors gameColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: gameColors.blood.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: gameColors.blood.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.compress, size: 16, color: gameColors.blood),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '计数收缩：${labels.join('、')} 即全部存活邪恶（未确认的死者均为邪恶）',
              style: AppTextStyles.body
                  .copyWith(color: gameColors.bloodBright),
            ),
          ),
        ],
      ),
    );
  }
}

/// 确认列表（可展开看依据）。
class _ReasonsTile extends StatelessWidget {
  const _ReasonsTile({
    required this.title,
    required this.reasons,
    required this.label,
    required this.sortWith,
    required this.color,
    required this.gameColors,
  });

  final String title;
  final Map<int, List<Deduction>> reasons;
  final String Function(int) label;

  /// 座位序比较器（保证换座后展示顺序稳定）。
  final int Function(int, int) sortWith;
  final Color color;
  final GameColors gameColors;

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) return const SizedBox.shrink();
    final sortedEntries = reasons.keys.toList()..sort(sortWith);
    return ExpansionTile(
      dense: true,
      tilePadding: EdgeInsets.zero,
      iconColor: color,
      title: Text(title, style: AppTextStyles.body.copyWith(color: color)),
      childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
      children: [
        for (final pid in sortedEntries)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label(pid), style: AppTextStyles.body),
                for (final d in reasons[pid]!)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      '· ${d.source.nameCn}：${d.description}',
                      style: AppTextStyles.caption
                          .copyWith(color: gameColors.inkViolet),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
