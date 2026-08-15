import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/shared/game_private.dart';
import 'package:botc_copilot/core/constants/script.dart';
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
    final script = ref.watch(
          gameByIdProvider(gameId).select((g) => g.valueOrNull?.script),
        ) ??
        Script.troubleBrewing;
    final scriptRulesSupported =
        contradictionRulesFor(script).isNotEmpty;
    final result = ref.watch(contradictionsProvider(gameId));
    final contradictions = result.contradictions;
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
        if (result.failed)
          _DegradedBanner(gameColors: gameColors)
        else if (result.loading)
          // #270⑤：源流半加载帧显示加载态，不渲染「未发现矛盾标记」
          // （loading 由 provider 统一计算，避免面板直连六个源流）。
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else ...[
          // #281：漏录不静默失效——提示横幅。#270⑤ 复核：改加法（原 else-if
          // 链会把其余矛盾 tile 全部遮掉，漏录 Bluff 不应隐藏其他检测）。
          if (_bluffsMissing(ref, gameId))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: gameColors.bloodBright),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '你是恶魔但 Bluff 未录入（3 个不在场好人角色）——'
                      'Bluff 声明检测暂不可用，可在你的座位详情补录。',
                      style: AppTextStyles.caption
                          .copyWith(color: gameColors.bloodBright),
                    ),
                  ),
                ],
              ),
            ),
          if (contradictions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  // #262：规则未注册的剧本不能自信地宣称「无矛盾」——
                  // 三官方剧本均有通用公理规则，此分支留给未来自定义剧本。
                  scriptRulesSupported
                      ? '未发现矛盾标记'
                      : '该剧本的推理规则尚未支持，暂不进行矛盾检测',
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

/// 引擎异常降级横幅（issue #211）。
///
/// detect() 抛异常兜底后展示——明确告知「推理引擎暂不可用」而非空成功，
/// 避免用户误以为「无矛盾」。只在 release 下真正兜底时出现（debug 下异常
/// 会经 debugPrint 输出，仍同样展示横幅以便发现）。
class _DegradedBanner extends StatelessWidget {
  const _DegradedBanner({required this.gameColors});

  final GameColors gameColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: gameColors.blood.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gameColors.blood.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: gameColors.blood),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '推理引擎暂不可用，矛盾检测已暂停。请重启或反馈问题。',
              style: AppTextStyles.caption
                  .copyWith(color: gameColors.bloodBright),
            ),
          ),
        ],
      ),
    );
  }
}


/// 恶魔 7+ 局 Bluff 是否漏录（#281 提示用）。
bool _bluffsMissing(WidgetRef ref, int gameId) {
  final game = ref.watch(gameByIdProvider(gameId)).valueOrNull;
  return game != null &&
      game.myRole != null &&
      game.myRole!.team == Team.demon &&
      game.playerCount >= 7 &&
      demonBluffsOf(game).isEmpty;
}
