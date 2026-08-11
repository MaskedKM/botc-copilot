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
    final names = ref.watch(setupProvider.select((s) => s.playerNames));
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
            '按实际座位顺时针输入名字，上下拖动调整顺序。1 号位在钟面 12 点方向。',
            style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            buildDefaultDragHandles: false,
            itemCount: names.length,
            onReorder: notifier.reorderSeat,
            itemBuilder: (context, index) {
              return Padding(
                key: ValueKey('seat-$index-${names[index]}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.headline
                            .copyWith(color: gameColors.goldBright),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: names[index],
                        decoration: InputDecoration(
                          hintText: '玩家 ${index + 1} 的名字',
                          isDense: true,
                        ),
                        onChanged: (v) => notifier.setPlayerName(index, v),
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
