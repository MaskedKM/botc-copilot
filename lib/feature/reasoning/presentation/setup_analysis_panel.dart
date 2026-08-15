import 'package:botc_copilot/core/constants/script_definition.dart';
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
                  // #266②：徽章按实际声明的修正角色命名（TB=男爵，BMR=教父…）
                  '${analysis.modifierClaims.map((c) => c.nameCn).join('、')} 已声明',
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
        // #266②：修正局参照按剧本修正角色派生（describe 含镇民反向补偿），
        // 不再硬编码「Baron 局 +2/-2」。
        for (final m in analysis.scriptModifiers)
          Text(
            '「${m.nameCn}」在场：${describeSetupModifier(m)}',
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
  /// #266①：差额一律与**有效锚点**比较——修正角色已声明时锚点为
  /// expectedWithClaimed（按声明计算），否则为 base / baronOutsiders。
  /// 此前 standard/under 分支与 base+2 硬编码比较，会渲染
  /// 「声明 3 = 标准 1」的字面矛盾句和 0/-1 差额。
  (Color, IconData, String, String) _interpret(GameColors gc) {
    final names =
        analysis.modifierClaims.map((c) => c.nameCn).join('、');
    final scriptNames =
        analysis.scriptModifiers.map((c) => c.nameCn).join('、');
    switch (analysis.deviation) {
      case OutsiderDeviation.standard:
        // 修正角色已声明时的 standard = 与声明锚点吻合（#151 S3 后语义）
        return (
          gc.trustConfirmedGood,
          Icons.check_circle_outline,
          '与标准配置一致',
          analysis.baronClaimed
              ? '声明 ${analysis.claimedOutsiders} = '
                  '「$names」修正后期望 ${analysis.expectedWithClaimed}'
                  '（若声明为真）。'
              : '声明 ${analysis.claimedOutsiders} = 标准 ${analysis.baseOutsiders}。',
        );
      case OutsiderDeviation.baronConsistent:
        final diff = analysis.claimedOutsiders - analysis.baseOutsiders;
        return (
          analysis.baronClaimed ? gc.trustConfirmedGood : gc.goldBright,
          analysis.baronClaimed
              ? Icons.check_circle_outline
              : Icons.lightbulb_outline,
          '与修正局配置一致（+$diff）',
          analysis.baronClaimed
              ? '「$names」已声明且数量吻合（若声明为真）。'
              : '「$scriptNames」可能在场（未声明），或 $diff 人假报外来者。',
        );
      case OutsiderDeviation.partial:
        return (
          gc.goldBright,
          Icons.lightbulb_outline,
          '介于标准与修正配置',
          '差 1：1 人假报外来者，或 1 人隐瞒'
          '（如 Drunk 未显，或「或」型修正角色取 -1）。',
        );
      case OutsiderDeviation.under:
        // #266①：锚点 = 已声明修正角色的期望（此前与 base 比，Baron 局
        // 声明吻合时显示差额 0 甚至 -1）
        final anchor = analysis.baronClaimed
            ? analysis.expectedWithClaimed
            : analysis.baseOutsiders;
        final diff = anchor - analysis.claimedOutsiders;
        return (
          gc.trustSuspect,
          Icons.help_outline,
          '少于期望配置 $diff',
          analysis.baronClaimed
              ? '「$names」已声明——若为真应有 $anchor 个，'
                  '可能外来者未声明 / 假报修正角色。'
              : '可能 Drunk（自以为是镇民）/ 有外来者尚未声明'
                  '（若尚未全部声明，属正常）。',
        );
      case OutsiderDeviation.over:
        final anchor = analysis.baronClaimed
            ? analysis.expectedWithClaimed
            : analysis.baronOutsiders;
        final diff = analysis.claimedOutsiders - anchor;
        return (
          gc.blood,
          Icons.error_outline,
          '超出修正上限 $diff',
          analysis.baronClaimed
              ? '已超出「$names」修正后期望 $anchor——必有人假报外来者。'
              : '必有人假报外来者'
                  '（已超出「$scriptNames」修正后的上限 $anchor）。',
        );
    }
  }
}
