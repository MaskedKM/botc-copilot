import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/presentation/player_detail_sheet.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/contradiction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 矛盾列表面板（issue #38）：推理 Tab 内容。
///
/// 原则：默认折叠，不干扰推理体验；只标记不一致，绝不输出身份结论。
class ContradictionPanel extends ConsumerWidget {
  /// 创建面板。
  const ContradictionPanel({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contradictions = ref.watch(contradictionsProvider(gameId));
    final gameColors = context.gameColors;
    // 矛盾 tile drill-down（#138）：playerIds → 玩家详情。
    final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ??
        const <Player>[];
    final playersById = {for (final p in players) p.id: p};

    // 注意：用 Column 而非 ListView——本面板被 ReasoningDashboard 的
    // ListView 内嵌，再开一层 ListView 会无界高度。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('矛盾检测', style: AppTextStyles.headline),
            const SizedBox(width: 8),
            if (contradictions.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: gameColors.blood.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${contradictions.length}',
                  style: AppTextStyles.caption
                      .copyWith(color: gameColors.bloodBright),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '只标记数据不一致，身份判断由你来做。',
          style:
              AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
        ),
        const SizedBox(height: 12),
        if (contradictions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '未发现矛盾标记',
                style: AppTextStyles.caption
                    .copyWith(color: gameColors.inkViolet),
              ),
            ),
          )
        else
          ...contradictions.map(
            (c) => _ContradictionTile(
              contradiction: c,
              gameId: gameId,
              playersById: playersById,
            ),
          ),
      ],
    );
  }
}

class _ContradictionTile extends StatelessWidget {
  const _ContradictionTile({
    required this.contradiction,
    required this.gameId,
    required this.playersById,
  });

  final Contradiction contradiction;

  /// 对局 id（drill-down 打开玩家详情，#138）。
  final int gameId;

  /// 涉及玩家的 id → Player 映射（drill-down 解析）。
  final Map<int, Player> playersById;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final isWarning =
        contradiction.severity == ContradictionSeverity.warning;
    final color = isWarning ? gameColors.blood : gameColors.inkViolet;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        dense: true,
        leading: Icon(
          isWarning ? Icons.warning_amber : Icons.info_outline,
          size: 18,
          color: color,
        ),
        title: Text(
          contradiction.type.nameCn,
          style: AppTextStyles.body.copyWith(color: color),
        ),
        subtitle: contradiction.dayNumber != null
            ? Text(
                '第 ${contradiction.dayNumber} 天',
                style: AppTextStyles.caption,
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contradiction.description,
                    style: AppTextStyles.body,
                  ),
                  // drill-down（#138）：点玩家 chip 直达玩家详情。
                  if (contradiction.playerIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final pid in contradiction.playerIds)
                          if (playersById[pid] case final p?)
                            ActionChip(
                              avatar: const Icon(
                                Icons.person_outline,
                                size: 16,
                              ),
                              label: Text('${p.seatNumber}号 ${p.name}'),
                              onPressed: () => PlayerDetailSheet.show(
                                context,
                                gameId: gameId,
                                player: p,
                              ),
                            ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
