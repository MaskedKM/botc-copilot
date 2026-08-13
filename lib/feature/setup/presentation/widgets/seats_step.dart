import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/setup/presentation/providers/setup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 3：输入玩家名 + 拖拽排座位。
class SeatsStep extends ConsumerWidget {
  /// 创建步骤页。
  const SeatsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 只监听长度（行数），不监听名字内容——名字变更由各行自己的
    // controller 管理，避免每次击键重建导致焦点丢失。
    final rowCount =
        ref.watch(setupProvider.select((s) => s.playerNames.length));
    // 仅在合法性翻转时重建（非每次击键），保焦点（#163 P1）。
    final nameError =
        ref.watch(setupProvider.select((s) => s.nameValidationError));
    final notifier = ref.read(setupProvider.notifier);
    final gameColors = context.gameColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('排座位', style: AppTextStyles.title),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            '按实际座位顺时针输入名字，上下拖动调整顺序。1 号位在钟面 12 点方向。'
            '（名字请用常用汉字，生僻字可能显示为系统字体）',
            style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
          ),
        ),
        if (nameError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              nameError,
              style: AppTextStyles.caption
                  .copyWith(color: gameColors.bloodBright),
            ),
          ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            buildDefaultDragHandles: false,
            itemCount: rowCount,
            onReorder: notifier.reorderSeat,
            itemBuilder: (context, index) {
              // key 用 index 保持稳定：击键不重建（不丢焦点）；
              // 拖拽后 ReorderableListView 按新 index 重建各行，
              // _SeatRow.didUpdateWidget 会把最新名字同步进 controller。
              return _SeatRow(
                key: ValueKey('seat-$index'),
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 单个座位行：座位号 + 名字输入框 + 拖拽手柄。
class _SeatRow extends ConsumerStatefulWidget {
  const _SeatRow({required this.index, super.key});

  final int index;

  @override
  ConsumerState<_SeatRow> createState() => _SeatRowState();
}

class _SeatRowState extends ConsumerState<_SeatRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(setupProvider).playerNames[widget.index],
    );
  }

  @override
  void didUpdateWidget(_SeatRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 拖拽换座后同一 key 的行拿到新 index 对应的名字，同步进 controller。
    final name = ref.read(setupProvider).playerNames[widget.index];
    if (_controller.text != name) {
      _controller.text = name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final notifier = ref.read(setupProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${widget.index + 1}',
              style:
                  AppTextStyles.headline.copyWith(color: gameColors.goldBright),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '玩家 ${widget.index + 1} 的名字',
                isDense: true,
              ),
              onChanged: (v) => notifier.setPlayerName(widget.index, v),
            ),
          ),
          ReorderableDragStartListener(
            index: widget.index,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.drag_handle),
            ),
          ),
        ],
      ),
    );
  }
}
