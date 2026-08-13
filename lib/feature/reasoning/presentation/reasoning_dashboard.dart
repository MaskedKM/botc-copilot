import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/presentation/player_detail_sheet.dart';
import 'package:botc_copilot/feature/reasoning/presentation/character_reference_page.dart';
import 'package:botc_copilot/feature/reasoning/presentation/contradiction_panel.dart';
import 'package:botc_copilot/feature/reasoning/presentation/dependency_chain_page.dart';
import 'package:botc_copilot/feature/reasoning/presentation/role_matrix_page.dart';
import 'package:botc_copilot/feature/reasoning/presentation/setup_analysis_panel.dart';
import 'package:botc_copilot/feature/reasoning/presentation/voting_analysis_page.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 推理面板（issue #39）：信任度分组 + 恶魔候选池 + 矛盾检测。
///
/// 原则：只展示数据分组，不自动判定身份。
class ReasoningDashboard extends ConsumerStatefulWidget {
  /// 创建面板。
  const ReasoningDashboard({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  ConsumerState<ReasoningDashboard> createState() =>
      _ReasoningDashboardState();
}

class _ReasoningDashboardState extends ConsumerState<ReasoningDashboard> {
  /// 信任度分组是否只看存活玩家（PR #50 review S2）。
  bool _aliveOnly = false;

  @override
  Widget build(BuildContext context) {
    final players =
        ref.watch(gamePlayersProvider(widget.gameId)).valueOrNull ?? [];
    final trustLevels =
        ref.watch(latestTrustLevelsProvider(widget.gameId)).valueOrNull ??
            {};
    final gameColors = context.gameColors;

    // 按信任度分组（可选只看存活）
    final grouped =
        _aliveOnly ? players.where((p) => p.isAlive).toList() : players;
    final groups = <TrustLevel, List<Player>>{
      for (final level in TrustLevel.values) level: [],
    };
    for (final p in grouped) {
      groups[trustLevels[p.id] ?? TrustLevel.unknown]!.add(p);
    }
    // 恶魔候选池 = 存活 且 未被标记为确信好人/偏好
    final demonPool = players
        .where(
          (p) =>
              p.isAlive &&
              (trustLevels[p.id] ?? TrustLevel.unknown) !=
                  TrustLevel.confirmedGood &&
              (trustLevels[p.id] ?? TrustLevel.unknown) !=
                  TrustLevel.likelyGood,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 恶魔候选池（置顶，核心视图）
        _DemonPoolSection(pool: demonPool, total: players.length),
        const SizedBox(height: 8),
        // 声明矩阵 + 角色参考入口（issue #40 / #60）
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.grid_on, size: 16),
                label: const Text('声明矩阵'),
                onPressed: () =>
                    RoleMatrixPage.show(context, gameId: widget.gameId),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.menu_book, size: 16),
                label: const Text('角色参考'),
                onPressed: () => CharacterReferencePage.show(
                  context,
                  gameId: widget.gameId,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 投票分析（issue #57）+ 信息依赖链（issue #58）
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.how_to_vote_outlined, size: 16),
                label: const Text('投票分析'),
                onPressed: () =>
                    VotingAnalysisPage.show(context, gameId: widget.gameId),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.account_tree_outlined, size: 16),
                label: const Text('依赖链'),
                onPressed: () => DependencyChainPage.show(
                  context,
                  gameId: widget.gameId,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 配置分析：外来者计数 配置 vs 声明（issue #59）
        SetupAnalysisPanel(gameId: widget.gameId),
        const SizedBox(height: 16),
        // 信任度分组
        Row(
          children: [
            Text('信任度分组', style: AppTextStyles.headline),
            const Spacer(),
            FilterChip(
              label: const Text('只看存活'),
              selected: _aliveOnly,
              visualDensity: VisualDensity.compact,
              onSelected: (v) => setState(() => _aliveOnly = v),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '在玩家详情中调整信任度，此处实时同步。',
          style:
              AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
        ),
        const SizedBox(height: 8),
        for (final level in TrustLevel.values)
          if (groups[level]!.isNotEmpty)
            _TrustGroupTile(
              level: level,
              players: groups[level]!,
              gameId: widget.gameId,
            ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        // 矛盾检测（issue #38 面板内嵌）
        ContradictionPanel(gameId: widget.gameId),
      ],
    );
  }
}

class _DemonPoolSection extends StatelessWidget {
  const _DemonPoolSection({required this.pool, required this.total});

  final List<Player> pool;
  final int total;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final highlight = pool.length <= 2;
    final color = highlight ? gameColors.blood : gameColors.goldBright;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                '恶魔候选池（未标记好人）',
                style: AppTextStyles.headline.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (pool.isEmpty)
            Text(
              '所有存活玩家都已标记为好人',
              style: AppTextStyles.caption
                  .copyWith(color: gameColors.inkViolet),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final p in pool)
                  Chip(
                    label: Text('${p.seatNumber}号 ${p.name}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              highlight
                  ? '仅剩 ${pool.length} 人未标记——值得重点推理'
                  : '共 ${pool.length} 人。标记确信好人可缩小范围。',
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrustGroupTile extends ConsumerWidget {
  const _TrustGroupTile({
    required this.level,
    required this.players,
    required this.gameId,
  });

  final TrustLevel level;
  final List<Player> players;
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameColors = context.gameColors;
    final color = gameColors.ofTrustLevel(level);
    // #81：对局结束后玩家详情只读（不可打开写入）
    final ongoing = ref.watch(isGameOngoingProvider(gameId));

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  '${level.nameCn}（${players.length}）',
                  style: AppTextStyles.body.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final p in players)
                  InkWell(
                    onTap: ongoing
                        ? () => PlayerDetailSheet.show(
                            context,
                            gameId: gameId,
                            player: p,
                          )
                        : null,
                    child: Chip(
                      label: Text(
                        '${p.seatNumber}号 ${p.name}'
                        '${p.isAlive ? '' : ' ☠'}',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
