
import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/player_detail/domain/info_payload_formatter.dart';
import 'package:botc_copilot/shared/reliability.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 已录入信息回显区（issue #68：按当前声明角色分组）。
///
/// 当前声明角色的信息列在「已录入信息」；换声明后旧角色的信息归入
/// 「改口历史」，弱化显示但不丢失——既避免新旧角色信息混在一起，
/// 又保留改口轨迹供复盘。
class RecordedInfoSection extends ConsumerStatefulWidget {
  const RecordedInfoSection({
    required this.gameId,
    required this.playerId,
    required this.currentRole,
    required this.authorSuspectedDrunk,
    this.readOnly = false,
  });

  /// 对局 id（用于解析目标玩家 db id → 座位号，#145；解析 dayRecordId → 天数，#71）。
  final int gameId;

  final int playerId;

  /// 当前声明角色（草稿或来源值）；null = 尚未声明，回退为显示全部。
  final Character? currentRole;

  /// 该玩家是否被疑醉（整局 overlay 叠加到信息可靠性圆点，#109）。
  final bool authorSuspectedDrunk;

  /// 只读（复盘）：不显示删除按钮。
  final bool readOnly;

  @override
  ConsumerState<RecordedInfoSection> createState() =>
      RecordedInfoSectionState();
}

class RecordedInfoSectionState extends ConsumerState<RecordedInfoSection> {
  /// 是否展开当前角色的全部信息（默认仅最近 5 条，#71）。
  bool _showAllCurrent = false;

  /// 是否展开改口历史（其他角色）的全部信息（#71）。
  bool _showAllHistory = false;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final declarations =
        ref.watch(playerDeclarationsProvider(widget.playerId)).valueOrNull ??
            [];
    if (declarations.isEmpty) return const SizedBox.shrink();

    // 解析 payload 内目标玩家 db id → 座位号（#145）。
    final players = ref
            .watch(gamePlayersProvider(widget.gameId))
            .valueOrNull ??
        const <Player>[];
    final playersById = {for (final p in players) p.id: p};
    String seatLabel(int id) {
      final p = playersById[id];
      return p != null ? '${p.seatNumber}号' : '$id 号';
    }

    // 解析 dayRecordId → 第 N 天（信息声明无 dayNumber 列，#71）。
    final dayRecords =
        ref.watch(gameDayRecordsProvider(widget.gameId)).valueOrNull ??
            const <DayRecord>[];
    final dayNumberOf = {for (final d in dayRecords) d.id: d.dayNumber};
    int? dayOf(InfoDeclaration d) => dayNumberOf[d.dayRecordId];

    Future<void> Function()? deleteFor(InfoDeclaration d) => widget.readOnly
        ? null
        : () => confirmDeleteDeclaration(context, ref, d.id);

    final current = widget.currentRole == null
        ? declarations
        : declarations
            .where((d) => d.characterType == widget.currentRole)
            .toList();
    final history = widget.currentRole == null
        ? const <InfoDeclaration>[]
        : declarations
            .where((d) => d.characterType != widget.currentRole)
            .toList();

    // 默认仅展示最近 5 条；展开后显示全部（#71）。
    final currentShown =
        _showAllCurrent ? current.reversed : current.reversed.take(5);
    final historyShown =
        _showAllHistory ? history.reversed : history.reversed.take(5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('已录入信息', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        if (current.isEmpty)
          Text(
            widget.currentRole == null
                ? '暂无'
                : '尚无 ${widget.currentRole!.nameCn} 的信息',
            style: AppTextStyles.caption
                .copyWith(color: context.gameColors.inkViolet),
          )
        else ...[
          for (final decl in currentShown)
            InfoRow(
              decl: decl,
              labelFor: seatLabel,
              dayNumber: dayOf(decl),
              authorSuspectedDrunk: widget.authorSuspectedDrunk,
              onDelete: deleteFor(decl),
            ),
          if (current.length > 5)
            HistoryExpandToggle(
              expanded: _showAllCurrent,
              count: current.length,
              onTap: () =>
                  setState(() => _showAllCurrent = !_showAllCurrent),
            ),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '改口历史（其他角色）',
            style: AppTextStyles.caption
                .copyWith(color: context.gameColors.inkViolet),
          ),
          const SizedBox(height: 4),
          for (final decl in historyShown)
            InfoRow(
              decl: decl,
              dimmed: true,
              labelFor: seatLabel,
              dayNumber: dayOf(decl),
              authorSuspectedDrunk: widget.authorSuspectedDrunk,
              onDelete: deleteFor(decl),
            ),
          if (history.length > 5)
            HistoryExpandToggle(
              expanded: _showAllHistory,
              count: history.length,
              onTap: () =>
                  setState(() => _showAllHistory = !_showAllHistory),
            ),
        ],
      ],
    );
  }
}

/// 「查看全部 / 收起」切换按钮（信息/备注历史展开，#71）。
class HistoryExpandToggle extends StatelessWidget {
  const HistoryExpandToggle({
    required this.expanded,
    required this.count,
    required this.onTap,
    this.collapsedLabel,
  });

  final bool expanded;
  final int count;
  final VoidCallback onTap;

  /// 折叠态完整文案（默认「查看全部」；备注历史用「查看历史」，#71）。
  final String? collapsedLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18),
        label: Text(
          expanded ? '收起' : (collapsedLabel ?? '查看全部（共 $count 条）'),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(0, 32),
          foregroundColor: context.gameColors.inkViolet,
          textStyle: AppTextStyles.caption,
        ),
      ),
    );
  }
}

/// 单条已录入信息行。
class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.decl,
    required this.labelFor,
    this.dimmed = false,
    this.dayNumber,
    this.authorSuspectedDrunk = false,
    this.onDelete,
  });

  final InfoDeclaration decl;

  /// 目标玩家 db id → 座位号展示（#145）。
  final String Function(int playerId) labelFor;

  /// 弱化显示（改口历史）：删除线 + 灰色。
  final bool dimmed;

  /// 该条信息所属天数（由 dayRecordId 解析，#71）；null = 无法解析则不显示。
  final int? dayNumber;

  /// 作者是否被疑醉（整局 overlay 叠加可靠性圆点，#109）。
  final bool authorSuspectedDrunk;

  /// 删除回调（非 null 时显示删除按钮，issue #83 误录纠错）。
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // a11y：可靠性圆点需语义标签（#135），不能只靠颜色。
          Semantics(
            label: '可靠性：${effectiveReliability(decl.reliability, authorSuspectedDrunk).nameCn}',
            child: Icon(
              Icons.circle,
              size: 6,
              color: context.gameColors.ofReliability(
                effectiveReliability(decl.reliability, authorSuspectedDrunk),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (dayNumber != null) ...[
            Text(
              '第$dayNumber天',
              style: AppTextStyles.caption
                  .copyWith(color: context.gameColors.inkViolet),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              InfoPayloadFormatter.summarize(decl, labelFor: labelFor),
              style: dimmed
                  ? AppTextStyles.body.copyWith(
                      color: context.gameColors.inkViolet,
                      decoration: TextDecoration.lineThrough,
                    )
                  : AppTextStyles.body,
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: '删除这条信息',
              iconSize: 20,
              // #165 A2：去 compact 恢复 ≥44dp 命中区。
              icon: Icon(
                Icons.close,
                color: context.gameColors.inkViolet,
              ),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

/// 删除信息声明的二次确认（误录纠错，issue #83）。
Future<void> confirmDeleteDeclaration(
  BuildContext context,
  WidgetRef ref,
  int declarationId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('删除这条信息？'),
      content: const Text('删除后该信息不再出现在玩家详情与推理输入中。'
          '该操作不可撤销。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    await ref
        .read(playerDetailRepositoryProvider)
        .deleteDeclaration(declarationId);
  }
}
