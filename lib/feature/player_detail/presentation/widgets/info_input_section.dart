
import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/player_detail/data/ability_repository.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/info_input_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 信息录入区（按角色自适应；保留自身表单提交语义，立即写 DB）。
class InfoInputSection extends ConsumerWidget {
  const InfoInputSection({
    required this.gameId,
    required this.playerId,
    required this.day,
    required this.character,
    required this.players,
    required this.onEnsureClaim,
    this.isMine = false,
  });

  final int gameId;
  final int playerId;
  final int day;
  final Character character;
  final List<Player> players;

  /// 是否录入「我的」信息（我座位以真实角色录入，写入 isMine=true，#105）。
  final bool isMine;

  /// 提交信息前回调：确保草稿声明已落库（#134 解耦，杜绝孤儿信息）。
  final Future<bool> Function() onEnsureClaim;

  /// 我的角色今晚是否被唤醒（#243：官方夜序 + 掘墓条件）。
  bool _wakesTonight(Script script, WidgetRef ref) {
    final steps = nightStepsForDay(script, day);
    // S&V 日间私密询问型：不在夜序（白天行动），但所得同属「我的私有
    // 信息」（私下询问说书人），不过滤。区别于 Gossip（公开声明，无私有
    // 信息可录）——公开内容走他人声明入口。
    const dayPrivateInfo = {Character.savant, Character.artist};
    if (dayPrivateInfo.contains(character)) return true;
    final inOrder = steps.any((s) => s.character == character);
    if (!inOrder) return false;
    if (character == Character.undertaker) {
      // 官方：掘墓人每夜*得知**今日**被处决者的角色——夜 N 跟在昼 N-1
      // 后，须前一天有处决。
      final days =
          ref.watch(gameDayRecordsProvider(gameId)).valueOrNull ?? [];
      return days.any((d) =>
          d.dayNumber == day - 1 && d.dayExecutionPlayerId != null);
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final script = ref.watch(
          gameByIdProvider(gameId).select((g) => g.valueOrNull?.script),
        ) ??
        Script.troubleBrewing;
    // #243 单一入口：我的座位 = 当夜私有知识，按官方夜序过滤（首夜信息角色
    // 仅首夜、僧侣/掘墓/渡鸦第 2 夜起；掘墓另需前一天有处决）。渡鸦不卡
    // 存活（被唤醒者自知死亡，死亡标记黎明才落）。他人表单**不过滤**——
    // 白天复述 / bluff 均合法，时序问题交给矛盾引擎。
    if (isMine && !_wakesTonight(script, ref)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${character.nameCn} 的信息', style: AppTextStyles.headline),
          const SizedBox(height: 8),
          Text(
            '按夜序，「${character.nameCn}」第 $day 夜不被唤醒，'
            '今夜无私有信息可录。他人今晚的公开声明可次日在此录入。',
            style: AppTextStyles.caption.copyWith(
              color: context.gameColors.inkViolet,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${character.nameCn} 的信息', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        InfoInputFactory.build(
          character: character,
          players: players,
          script: script,
          actingPlayerId: playerId,
          // #285：掘墓人预填「最近一次被处决者」（夜 N 报昼 N-1 的处决；
          // 隔日补报取更早处决时用户可改选）。其余角色无预填。
          initialPlayerId: character == Character.undertaker
              ? _latestExecutedPlayerId(ref, gameId, day)
              : null,
          onSubmit: (payload) async {
            // 先落库草稿声明（非己且选了 chip 时），再录信息（#134）。
            // 声明写失败则中止——避免信息无对应声明成孤儿（#164 B9 review）。
            final claimOk = await onEnsureClaim();
            if (!claimOk) return;
            final notifier = ref.read(gameBoardProvider(gameId).notifier);
            final dayRecordId = await notifier.ensureCurrentDayRecord();
            await ref.read(playerDetailRepositoryProvider).declareInfo(
                  playerId: playerId,
                  dayRecordId: dayRecordId,
                  character: character,
                  payload: payload,
                  isMine: isMine,
                  gameId: gameId,
                  dayNumber: ref.read(gameBoardProvider(gameId)).currentDay,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isMine ? '我的信息已记录' : '信息已记录')),
              );
            }
            // 教授复活联动（#217 增量4D，仅我的声明=事实）：教授不知是否
            // 成功，复活与否由用户按公开信息裁决；能力总是消耗（公理4）。
            if (isMine && character == Character.professor) {
              final targetId = payload['playerId'];
              final target = targetId is int
                  ? players.where((p) => p.id == targetId).firstOrNull
                  : null;
              if (target != null && context.mounted) {
                final resurrected = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('教授复活'),
                    content: Text(
                      '${target.seatNumber}号 ${target.name} 是否回到场上？\n'
                      '官方：教授不会得知复活是否成功——按公开信息裁决；'
                      '能力已消耗（醉/毒时使用也不返还）。',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('未复活'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('已复活'),
                      ),
                    ],
                  ),
                );
                if (resurrected != null) {
                  await ref.read(abilityRepositoryProvider).recordProfessorResurrect(
                        professorId: playerId,
                        targetId: target.id,
                        resurrected: resurrected,
                        day: day,
                      );
                }
              }
            }
          },
        ),
      ],
    );
  }
}


/// 声明日（[day]）之前最近一次处决的玩家 id（无则 null，#285）。
int? _latestExecutedPlayerId(WidgetRef ref, int gameId, int day) {
  final days =
      ref.watch(gameDayRecordsProvider(gameId)).valueOrNull ?? [];
  DayRecord? latest;
  for (final d in days) {
    if (d.dayNumber >= day) break;
    if (d.dayExecutionPlayerId != null) latest = d;
  }
  return latest?.dayExecutionPlayerId;
}
