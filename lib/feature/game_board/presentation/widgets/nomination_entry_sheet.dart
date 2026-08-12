import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/data/nomination_repository.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/shared/widgets/help_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 提名录入弹层：选提名者 → 选被提名者 → 逐人投票。
class NominationEntrySheet extends ConsumerStatefulWidget {
  /// 创建录入弹层。
  const NominationEntrySheet({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  /// 弹出录入。
  static Future<void> show(BuildContext context, {required int gameId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: NominationEntrySheet(gameId: gameId),
      ),
    );
  }

  @override
  ConsumerState<NominationEntrySheet> createState() =>
      _NominationEntrySheetState();
}

class _NominationEntrySheetState
    extends ConsumerState<NominationEntrySheet> {
  int? _nominatorId;
  int? _nomineeId;
  final Map<int, Vote> _votes = {};
  bool _submitting = false;
  final TextEditingController _defenseController = TextEditingController();

  @override
  void dispose() {
    _defenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final players =
        ref.watch(gamePlayersProvider(widget.gameId)).valueOrNull ?? [];
    final day = ref.watch(
      gameBoardProvider(widget.gameId).select((s) => s.currentDay),
    );
    final todayNominations = ref
            .watch(dayNominationsProvider((widget.gameId, day)))
            .valueOrNull ??
        [];
    final allNominations =
        ref.watch(gameNominationsProvider(widget.gameId)).valueOrNull ?? [];

    final alivePlayers = players.where((p) => p.isAlive).toList();
    final canSubmit = _nominatorId != null &&
        _nomineeId != null &&
        _votes.isNotEmpty &&
        !_submitting;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('记录提名', style: AppTextStyles.title),
            const SizedBox(height: 16),

            // 提名者
            const Text('提名者', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final p in alivePlayers)
                  ChoiceChip(
                    label: Text('${p.seatNumber}号 ${p.name}'),
                    selected: _nominatorId == p.id,
                    onSelected: NominationRules.hasNominatedToday(
                      todayNominations,
                      p.id,
                    )
                        ? null // 已提名过 → 禁用
                        : (_) => setState(() => _nominatorId = p.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 被提名者（含死人——官方规则死人可被提名；标 ☠ 区分）
            const Text('被提名者', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final p in players)
                  if (p.id != _nominatorId)
                    ChoiceChip(
                      label: Text(
                        '${p.seatNumber}号 ${p.name}'
                        '${p.isAlive ? '' : ' ☠'}',
                      ),
                      selected: _nomineeId == p.id,
                      onSelected: NominationRules.hasBeenNominatedToday(
                        todayNominations,
                        p.id,
                      )
                          ? null // 已被提名过 → 禁用
                          : (_) => setState(() => _nomineeId = p.id),
                    ),
              ],
            ),
            const SizedBox(height: 16),

            // 逐人投票
            if (_nomineeId != null) ...[
              const Text('投票', style: AppTextStyles.headline),
              const SizedBox(height: 8),
              for (final p in players) ...[
                _VoteRow(
                  player: p,
                  vote: _votes[p.id],
                  deadVoteUsed:
                      NominationRules.deadVoteUsed(allNominations, p.id),
                  onChanged: (v) => setState(() {
                    if (v == null) {
                      _votes.remove(p.id);
                    } else {
                      _votes[p.id] = v;
                    }
                  }),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '当前赞成 ${NominationRules.countFor(_votes.entries.map((e) => VoteEntry(playerId: e.key, vote: e.value)).toList())} 票'
                '（处决阈值 ${NominationRules.threshold(alivePlayers.length)} 票）',
                style: AppTextStyles.caption
                    .copyWith(color: gameColors.goldBright),
              ),
              const SizedBox(height: 16),
              // 被提名者辩护（可选，issue #56）
              const Text('辩护记录（可选）', style: AppTextStyles.headline),
              const SizedBox(height: 4),
              Text(
                '记录被提名者的辩护 / 反指控 / 透露的信息。',
                style: AppTextStyles.caption
                    .copyWith(color: gameColors.inkViolet),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _defenseController,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: '如：我绝不是恶魔，X 号昨晚的行为更可疑…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            // 新手提示：提名/投票规则（issue #41）
            HelpTooltip(
              level: ref.watch(gameHelpLevelProvider(widget.gameId)),
              text: '提名规则：每人每天最多提名 1 次、被提名 1 次。'
                  '死亡玩家全程只有 1 张死票（投赞成即消耗）。'
                  '赞成票达到存活人数一半即上处决台，平票无人处决。',
            ),
            const SizedBox(height: 16),

            FilledButton(
              onPressed: canSubmit
                  ? () => _submit(
                        todayNominations: todayNominations,
                        allNominations: allNominations,
                        players: players,
                        day: day,
                      )
                  : null,
              child: Text(_submitting ? '记录中…' : '提交提名'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit({
    required List<Nomination> todayNominations,
    required List<Nomination> allNominations,
    required List<Player> players,
    required int day,
  }) async {
    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final dayRecordId = await ref
        .read(gameBoardProvider(widget.gameId).notifier)
        .ensureCurrentDayRecord();

    // 死票标记：死亡玩家投赞成 = 消耗死票（反对/弃权不消耗）
    final votes = _votes.entries.map((e) {
      final player = players.firstWhere((p) => p.id == e.key);
      return VoteEntry(
        playerId: e.key,
        vote: e.value,
        isDeadVote: !player.isAlive && e.value == Vote.forVote,
      );
    }).toList();

    final error =
        await ref.read(nominationRepositoryProvider).addNomination(
              gameId: widget.gameId,
              dayRecordId: dayRecordId,
              nominatorId: _nominatorId!,
              nomineeId: _nomineeId!,
              votes: votes,
              players: players,
              todayNominations: todayNominations,
              allNominations: allNominations,
              defenseText: _defenseController.text,
            );

    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      setState(() => _submitting = false);
    } else {
      navigator.pop();
    }
  }
}

/// 单个玩家的投票行。
class _VoteRow extends StatelessWidget {
  const _VoteRow({
    required this.player,
    required this.vote,
    required this.deadVoteUsed,
    required this.onChanged,
  });

  final Player player;
  final Vote? vote;
  final bool deadVoteUsed;
  final ValueChanged<Vote?> onChanged;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final isDead = !player.isAlive;
    final deadVoteBlocked = isDead && deadVoteUsed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '${player.seatNumber}号 ${player.name}',
              style: AppTextStyles.body.copyWith(
                color: isDead ? AppColors.textDisabled : null,
              ),
            ),
          ),
          if (isDead)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                deadVoteUsed ? '死票已用' : '死票',
                style: AppTextStyles.caption.copyWith(
                  color: deadVoteBlocked
                      ? AppColors.textDisabled
                      : gameColors.blood,
                ),
              ),
            ),
          _voteButton('赞成', Vote.forVote, gameColors.trustConfirmedGood,
              disabled: deadVoteBlocked),
          const SizedBox(width: 4),
          _voteButton('反对', Vote.against, gameColors.blood),
          const SizedBox(width: 4),
          _voteButton('弃权', Vote.abstain, gameColors.inkViolet),
        ],
      ),
    );
  }

  Widget _voteButton(String label, Vote value, Color color,
      {bool disabled = false}) {
    final selected = vote == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color,
      visualDensity: VisualDensity.compact,
      onSelected: disabled
          ? null
          : (_) => onChanged(selected ? null : value),
    );
  }
}
