import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/timeline/data/timeline_provider.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/feature/timeline/domain/timeline_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 每日事件流时间线（issue #8）。
///
/// 按天分组展示：夜晚死亡 / 角色声明 / 信息声明 / 处决 / 掘墓人信息。
class TimelinePage extends ConsumerWidget {
  /// 创建时间线页。
  const TimelinePage({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineProvider(gameId));
    final game = ref.watch(gameByIdProvider(gameId)).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('事件时间线')),
      body: timelineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (days) {
          final hasEvents = days.any((d) => d.events.isNotEmpty);
          if (!hasEvents) {
            return Center(
              child: Text(
                '还没有记录。回到对局页记录第一天的事件。',
                style: AppTextStyles.caption
                    .copyWith(color: context.gameColors.inkViolet),
              ),
            );
          }
          final ended = game != null && game.status != GameStatus.ongoing;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length + (ended ? 1 : 0),
            itemBuilder: (context, index) {
              if (ended && index == days.length) {
                // 对局结束标记
                final gameColors = context.gameColors;
                final goodWin = game.status == GameStatus.goodWin;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 18,
                        color: goodWin
                            ? gameColors.trustConfirmedGood
                            : gameColors.blood,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '对局结束 · ${game.status.nameCn}',
                        style: AppTextStyles.headline.copyWith(
                          color: goodWin
                              ? gameColors.trustConfirmedGood
                              : gameColors.blood,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _DaySection(day: days[index]);
            },
          );
        },
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day});

  final TimelineDay day;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 天标题 + 金色刻度线
        Row(
          children: [
            Text(
              '第 ${day.dayNumber} 天',
              style: AppTextStyles.title
                  .copyWith(color: gameColors.goldBright),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Divider(height: 0.5)),
          ],
        ),
        const SizedBox(height: 8),
        for (final event in day.events) _EventTile(event: event),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final (icon, color) = switch (event.type) {
      TimelineEventType.nightDeath =>
        (Icons.nights_stay, gameColors.inkViolet),
      TimelineEventType.execution => (Icons.gavel, gameColors.blood),
      TimelineEventType.undertakerResult =>
        (Icons.badge, gameColors.goldBright),
      TimelineEventType.roleClaim =>
        (Icons.record_voice_over, gameColors.trustLikelyGood),
      TimelineEventType.infoDeclaration =>
        (Icons.chat_bubble_outline, gameColors.goldBright),
      TimelineEventType.poisonMarked =>
        (Icons.science_outlined, gameColors.inkViolet),
      TimelineEventType.behaviorNote =>
        (Icons.edit_note, gameColors.inkViolet),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(event.summary, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
