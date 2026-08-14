
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/player_detail/data/behavior_note_repository.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/recorded_info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 行为备注区（issue #36；保留自身提交语义，立即写 DB）。
class BehaviorNoteSection extends ConsumerStatefulWidget {
  const BehaviorNoteSection({
    required this.gameId,
    required this.playerId,
    required this.day,
    this.readOnly = false,
    this.onDraftChanged,
  });

  final int gameId;
  final int playerId;
  final int day;

  /// 只读（复盘）：隐藏输入框，仅展示已存备注。
  final bool readOnly;

  /// 草稿脏状态变化（有未提交文本=true），供父级 PopScope 守卫（#160 #5）。
  final void Function(bool hasDraft)? onDraftChanged;

  @override
  ConsumerState<BehaviorNoteSection> createState() =>
      BehaviorNoteSectionState();
}

class BehaviorNoteSectionState extends ConsumerState<BehaviorNoteSection> {
  final _controller = TextEditingController();

  /// 是否展开历史备注（其他天，#71）。
  bool _showHistory = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = _controller.text.trim();
    if (note.isEmpty) return;
    await ref.read(behaviorNoteRepositoryProvider).addNote(
          gameId: widget.gameId,
          playerId: widget.playerId,
          dayNumber: widget.day,
          note: note,
        );
    // #164：await 后须 mounted 守卫，否则关闭 sheet 致 dispose → .clear() 崩。
    if (!mounted) return;
    _controller.clear();
    widget.onDraftChanged?.call(false); // 提交后草稿清空（#160 #5）
  }

  /// 单条备注行（今日 / 历史共用，#71）。
  Widget _noteRow(BuildContext context, BehaviorNote n) {
    final gameColors = context.gameColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('· ', style: AppTextStyles.body),
          Expanded(
            child: Text(n.note, style: AppTextStyles.body),
          ),
          if (!widget.readOnly)
            IconButton(
              tooltip: '删除备注',
              iconSize: 20,
              // #165 A2：去 compact 恢复 ≥44dp 命中区。
              icon: Icon(Icons.close, color: gameColors.inkViolet),
              onPressed: () => confirmDeleteNote(context, ref, n.id),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 拉取该玩家全部备注：今日单独展示，其余按天分组折叠为历史（#71）。
    final allNotes = ref
            .watch(playerBehaviorNotesProvider(widget.playerId))
            .valueOrNull ??
        [];
    final todayNotes =
        allNotes.where((n) => n.dayNumber == widget.day).toList();
    final historyNotes =
        allNotes.where((n) => n.dayNumber != widget.day).toList();
    // 历史按天倒序分组（最近的天在前），天内保持录入顺序（DAO 已按 createdAt 升序）。
    final historyByDay = <int, List<BehaviorNote>>{};
    for (final n in historyNotes) {
      historyByDay.putIfAbsent(n.dayNumber, () => []).add(n);
    }
    final historyDays = historyByDay.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final gameColors = context.gameColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('行为备注（第 ${widget.day} 天）', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        if (!widget.readOnly)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: '如：投票时犹豫 / 主动带票冲 X号',
                    isDense: true,
                  ),
                  inputFormatters: [LengthLimitingTextInputFormatter(500)],
                  onChanged: (v) =>
                      widget.onDraftChanged?.call(v.trim().isNotEmpty),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              IconButton(
                tooltip: '添加备注',
                icon: const Icon(Icons.add),
                onPressed: _submit,
              ),
            ],
          ),
        if (!widget.readOnly) const SizedBox(height: 8),
        if (todayNotes.isEmpty)
          Text(
            '暂无备注',
            style: AppTextStyles.caption
                .copyWith(color: gameColors.inkViolet),
          )
        else
          for (final n in todayNotes) _noteRow(context, n),
        if (historyNotes.isNotEmpty) ...[
          const SizedBox(height: 8),
          HistoryExpandToggle(
            expanded: _showHistory,
            count: historyNotes.length,
            collapsedLabel: '查看历史（共 ${historyNotes.length} 条）',
            onTap: () => setState(() => _showHistory = !_showHistory),
          ),
          if (_showHistory)
            for (final day in historyDays) ...[
              const SizedBox(height: 4),
              Text(
                '第 $day 天',
                style: AppTextStyles.caption
                    .copyWith(color: gameColors.inkViolet),
              ),
              for (final n in historyByDay[day]!) _noteRow(context, n),
            ],
        ],
      ],
    );
  }
}

/// 删除行为备注的二次确认（#138 破坏操作加确认）。
Future<void> confirmDeleteNote(
  BuildContext context,
  WidgetRef ref,
  int noteId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('删除这条备注？'),
      content: const Text('该操作不可撤销。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: AppTheme.dangerButtonStyle,
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    await ref.read(behaviorNoteRepositoryProvider).deleteNote(noteId);
  }
}
