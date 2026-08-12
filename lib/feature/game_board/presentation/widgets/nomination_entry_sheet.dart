import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/data/nomination_repository.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/day_panels.dart';
import 'package:botc_copilot/feature/player_detail/data/ability_repository.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/latest_claim.dart';
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
  _VoteMode _voteMode = _VoteMode.quick;
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
    final claims =
        ref.watch(gameClaimsProvider(widget.gameId)).valueOrNull ?? [];

    final alivePlayers = players.where((p) => p.isAlive).toList();
    final forCount = NominationRules.countFor(
      _votes.entries
          .map((e) => VoteEntry(playerId: e.key, vote: e.value))
          .toList(),
    );
    final canSubmit = _nominatorId != null &&
        _nomineeId != null &&
        !_submitting &&
        // 快录允许空投票（= 全反对）；详细至少录 1 票（issue #84）
        (_voteMode == _VoteMode.quick || _votes.isNotEmpty);

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

            // 被提名者（官方允许自我提名——Virgin 自证战术；含死人，标 ☠ 区分）
            const Text('被提名者', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final p in players)
                  ChoiceChip(
                    label: Text(
                      '${p.seatNumber}号 ${p.name}'
                      '${p.isAlive ? '' : ' ☠'}'
                      '${p.id == _nominatorId ? '（自）' : ''}',
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
              Row(
                children: [
                  const Expanded(
                    child: Text('投票', style: AppTextStyles.headline),
                  ),
                  // 模式切换（issue #84）
                  SegmentedButton<_VoteMode>(
                    segments: const [
                      ButtonSegment(
                        value: _VoteMode.quick,
                        icon: Icon(Icons.bolt, size: 16),
                        label: Text('快录'),
                      ),
                      ButtonSegment(
                        value: _VoteMode.full,
                        icon: Icon(Icons.list, size: 16),
                        label: Text('详细'),
                      ),
                    ],
                    selected: {_voteMode},
                    onSelectionChanged: (s) =>
                        setState(() => _voteMode = s.first),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _voteMode == _VoteMode.quick
                    ? '点选赞成者，未点者提交时记为反对'
                        '（官方：举手=赞成，不举=非赞成）'
                    : '逐人三选（死票 / 弃权场景）',
                style: AppTextStyles.caption
                    .copyWith(color: gameColors.inkViolet),
              ),
              const SizedBox(height: 8),
              if (_voteMode == _VoteMode.quick)
                _QuickVoteGrid(
                  players: players,
                  votes: _votes,
                  allNominations: allNominations,
                  onToggle: (id, selected) => setState(() {
                    if (selected) {
                      _votes[id] = Vote.forVote;
                    } else {
                      _votes.remove(id);
                    }
                  }),
                )
              else
                for (final p in players)
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
              const SizedBox(height: 8),
              Text(
                _voteMode == _VoteMode.quick
                    ? '赞成 $forCount / 阈值 ${NominationRules.threshold(alivePlayers.length)}'
                        '（其余 ${players.length - forCount} 人按反对）'
                    : '赞成 $forCount / 阈值 ${NominationRules.threshold(alivePlayers.length)}'
                        ' · 已录 ${_votes.length}/${players.length}',
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
                        claims: claims,
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
    required List<RoleClaim> claims,
    required int day,
  }) async {
    // 详细模式漏录二次确认（issue #84）
    if (_voteMode == _VoteMode.full && _votes.length < players.length) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('尚有未录投票'),
          content: Text(
            '还有 ${players.length - _votes.length} 人未录，未录者不计为赞成。'
            '确认提交？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('返回补录'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认提交'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final dayRecordId = await ref
        .read(gameBoardProvider(widget.gameId).notifier)
        .ensureCurrentDayRecord();

    // 快录模式：未点者补记为反对（官方：不举=非赞成）；详细模式只存已录票（issue #84）
    final votes = _voteMode == _VoteMode.quick
        ? NominationRules.fillQuickVotes(recorded: _votes, players: players)
        : [
            for (final entry in _votes.entries)
              VoteEntry(
                playerId: entry.key,
                vote: entry.value,
                isDeadVote: !players
                        .firstWhere((p) => p.id == entry.key)
                        .isAlive &&
                    entry.value == Vote.forVote,
              ),
          ];

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
      // Virgin 触发场景提示（issue #54 收尾）
      await _maybeVirginTrigger(claims: claims, players: players);
      navigator.pop();
    }
  }

  /// 命中 Virgin 触发场景时弹窗，交用户确认（醉/毒是否触发由人判断）。
  Future<void> _maybeVirginTrigger({
    required List<RoleClaim> claims,
    required List<Player> players,
  }) async {
    // 注入「我的真实身份」（issue #107）：我是 Virgin 被提名 / 我是镇民提名
    // Virgin 时，场景能正确识别。
    final game = ref.read(gameByIdProvider(widget.gameId)).valueOrNull;
    final latestClaim = latestClaimWithSelf(
      claims,
      myPlayerId: game?.myPlayerId,
      myRole: game?.myRole,
    );
    final virginId = NominationRules.virginTriggerScenario(
      nominatorId: _nominatorId!,
      nomineeId: _nomineeId!,
      latestClaim: latestClaim,
      playersById: {for (final p in players) p.id: p},
    );
    if (virginId == null) return;
    final nominator = players.firstWhere((p) => p.id == _nominatorId);
    final nominee = players.firstWhere((p) => p.id == _nomineeId);

    final action = await showDialog<_VirginAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('处女能力可能触发'),
        content: Text(
          '${nominee.seatNumber}号 ${nominee.name}（声明处女）首次被镇民 '
          '${nominator.seatNumber}号 ${nominator.name} 提名。\n'
          '官方规则：若处女未被毒/醉，提名者立即被处决；若被毒/醉则不触发'
          '（且不消耗能力），请选「不处理」。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _VirginAction.dismiss),
            child: const Text('不处理'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _VirginAction.execute),
            child: Text('处决 ${nominator.name}'),
          ),
        ],
      ),
    );

    switch (action) {
      case _VirginAction.execute:
        await ref
            .read(abilityRepositoryProvider)
            .setAbilityUsed(virginId, used: true);
        final suggestion = await ref
            .read(gameBoardProvider(widget.gameId).notifier)
            .recordExecution(_nominatorId!);
        if (suggestion != null && context.mounted) {
          await handleEndSuggestion(
            context,
            ref,
            widget.gameId,
            suggestion,
          );
        }
      case _VirginAction.dismiss:
      case null:
        break;
    }
  }
}

/// 投票录入模式（issue #84）。
enum _VoteMode {
  /// 快录：点选赞成，未点者提交时记为反对。
  quick,

  /// 详细：逐人三选（赞成 / 反对 / 弃权）。
  full,
}

/// Virgin 触发弹窗的选项。
enum _VirginAction { dismiss, execute }

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

/// 快录模式：点选=赞成，未点提交时记为反对（issue #84）。
class _QuickVoteGrid extends StatelessWidget {
  const _QuickVoteGrid({
    required this.players,
    required this.votes,
    required this.allNominations,
    required this.onToggle,
  });

  final List<Player> players;
  final Map<int, Vote> votes;
  final List<Nomination> allNominations;
  final void Function(int playerId, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [for (final p in players) _chip(p, gameColors)],
    );
  }

  Widget _chip(Player p, GameColors gameColors) {
    final used = NominationRules.deadVoteUsed(allNominations, p.id);
    final blocked = !p.isAlive && used;
    return ChoiceChip(
      label: Text(
        '${p.seatNumber}号 ${p.name}'
        '${p.isAlive ? '' : (used ? ' ·死票已用' : ' ·死票')}',
      ),
      selected: votes[p.id] == Vote.forVote,
      selectedColor: gameColors.trustConfirmedGood,
      onSelected: blocked ? null : (sel) => onToggle(p.id, sel),
    );
  }
}
