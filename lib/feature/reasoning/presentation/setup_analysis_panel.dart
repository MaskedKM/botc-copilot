import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/setup_analysis_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/outsider_analysis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 配置分析面板（issue #59）：外来者计数「配置 vs 声明」实时对比 + 偏差解读。
///
/// 嵌入 [ReasoningDashboard] 的 ListView，故用 Column（不可再套 ListView）。
/// 偏差判定见 [analyzeOutsiderCount]；本面板仅做展示，不做身份结论。
class SetupAnalysisPanel extends ConsumerWidget {
  /// 创建面板。
  const SetupAnalysisPanel({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(setupAnalysisProvider(gameId));
    final gameColors = context.gameColors;
    if (analysis == null) return const SizedBox.shrink(); // 游戏未加载

    final players =
        ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final nameOf = _nameOf(players);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.balance, size: 18, color: gameColors.goldBright),
            const SizedBox(width: 8),
            Text('配置分析', style: AppTextStyles.headline),
            if (analysis.baronClaimed) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: gameColors.goldBright.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Baron 已声明',
                  style: AppTextStyles.caption
                      .copyWith(color: gameColors.goldBright),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // 标准配置
        Text(
          '${analysis.playerCount} 人局  '
          '镇民${analysis.townsfolk} · 外来者${analysis.baseOutsiders} · '
          '爪牙${analysis.minions} · 恶魔${analysis.demons}',
          style: AppTextStyles.body,
        ),
        Text(
          'Baron 局：外来者${analysis.baronOutsiders} · '
          '镇民${analysis.townsfolk - 2}',
          style:
              AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
        ),
        const SizedBox(height: 10),
        // 已声明外来者
        Text(
          '已声明外来者 ${analysis.claimedOutsiders} 人',
          style: AppTextStyles.label,
        ),
        const SizedBox(height: 4),
        if (analysis.claimers.isEmpty)
          Text(
            '尚无外来者声明',
            style: AppTextStyles.caption
                .copyWith(color: gameColors.inkViolet),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final c in analysis.claimers)
                Chip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(
                    '${nameOf(c.playerId)} ${c.character.nameCn}'
                    '${c.confirmed ? ' ✓' : ''}',
                    style: AppTextStyles.caption,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 10),
        // 偏差解读（按 case 着色）
        _DeviationBanner(analysis: analysis),
      ],
    );
  }

  /// 玩家 id → 'N号 名字' 取名器。
  String Function(int) _nameOf(List<Player> players) {
    final byId = {for (final p in players) p.id: p};
    return (int id) {
      final p = byId[id];
      return p != null ? '${p.seatNumber}号 ${p.name}' : '?';
    };
  }
}

/// 偏差解读横幅：按 [OutsiderDeviation] 着色 + 标题 + 详情。
class _DeviationBanner extends StatelessWidget {
  const _DeviationBanner({required this.analysis});

  final OutsiderCountAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final (color, icon, title, detail) = _interpret(gameColors);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(detail, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 按 case 映射（颜色, 图标, 标题, 详情）。
  ///
  /// Baron 信号影响配色（review R1）：claimed==base+2 且 Baron 已声明 →
  /// 解决态（绿）；claimed==base 但 Baron 已声明 → 与 Baron 配置不符（黄）。
  (Color, IconData, String, String) _interpret(GameColors gc) {
    switch (analysis.deviation) {
      case OutsiderDeviation.standard:
        return (
          analysis.baronClaimed ? gc.goldBright : gc.trustConfirmedGood,
          analysis.baronClaimed
              ? Icons.lightbulb_outline
              : Icons.check_circle_outline,
          '与标准配置一致',
          analysis.baronClaimed
              ? '声明 ${analysis.claimedOutsiders} = 标准 ${analysis.baseOutsiders}。'
                  '但 Baron 已声明——若为真应有 ${analysis.baronOutsiders} 个，'
                  '可能外来者未声明 / 假 Baron。'
              : '声明 ${analysis.claimedOutsiders} = 标准 ${analysis.baseOutsiders}。',
        );
      case OutsiderDeviation.baronConsistent:
        final diff = analysis.claimedOutsiders - analysis.baseOutsiders;
        return (
          analysis.baronClaimed ? gc.trustConfirmedGood : gc.goldBright,
          analysis.baronClaimed
              ? Icons.check_circle_outline
              : Icons.lightbulb_outline,
          '与 Baron 局配置一致（+$diff）',
          analysis.baronClaimed
              ? 'Baron 已声明且数量吻合（若声明为真）。'
              : 'Baron 可能在场（未声明），或 $diff 人假报外来者。',
        );
      case OutsiderDeviation.partial:
        return (
          gc.goldBright,
          Icons.lightbulb_outline,
          '介于标准与 Baron 配置',
          '差 1：1 人假报外来者，或 1 人隐瞒（如 Drunk 未显）。',
        );
      case OutsiderDeviation.under:
        final diff = analysis.baseOutsiders - analysis.claimedOutsiders;
        return (
          gc.trustSuspect,
          Icons.help_outline,
          '少于标准配置 $diff',
          '可能 Drunk（自以为是镇民）/ 有外来者尚未声明'
          '（若尚未全部声明，属正常）。',
        );
      case OutsiderDeviation.over:
        final diff = analysis.claimedOutsiders - analysis.baronOutsiders;
        return (
          gc.blood,
          Icons.error_outline,
          '即便 Baron 在场也超出 $diff',
          '必有人假报外来者（已超出 Baron 修正后的上限）。',
        );
    }
  }
}
