import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/data/poison_repository.dart';
import 'package:botc_copilot/feature/player_detail/data/behavior_note_repository.dart';
import 'package:botc_copilot/shared/widgets/help_tooltip.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/player_detail/domain/info_payload_formatter.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/info_input_factory.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 玩家详情底部弹层（issue #7 / #69）。
///
/// 角色声明 / 信任度 / 醉毒标记采用**草稿→保存**模式：编辑只更新本地
/// 草稿，点底部「保存」一次性提交，避免误点污染 RoleClaim / TrustLog
/// 历史。信息录入与行为备注保留各自的提交语义（已有表单提交）。
///
/// 通过 [show] 弹出。
class PlayerDetailSheet extends ConsumerStatefulWidget {
  /// 创建玩家详情弹层。
  const PlayerDetailSheet({
    required this.gameId,
    required this.player,
    super.key,
  });

  /// 对局 id。
  final int gameId;

  /// 目标玩家。
  final Player player;

  /// 弹出玩家详情。
  static Future<void> show(
    BuildContext context, {
    required int gameId,
    required Player player,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PlayerDetailSheet(gameId: gameId, player: player),
      ),
    );
  }

  @override
  ConsumerState<PlayerDetailSheet> createState() => _PlayerDetailSheetState();
}

class _PlayerDetailSheetState extends ConsumerState<PlayerDetailSheet> {
  // 草稿字段：未「触动」前显示来源值，触动后显示草稿值。
  bool _roleTouched = false;
  Character? _draftRole;
  bool _trustTouched = false;
  TrustLevel _draftTrust = TrustLevel.unknown;
  bool _poisonTouched = false;
  bool _draftPoison = false;

  bool _saving = false;

  /// 是否存在未保存的修改。
  bool _isDirty({
    required Character? initialRole,
    required TrustLevel initialTrust,
    required bool initialPoison,
  }) =>
      (_roleTouched && _draftRole != initialRole) ||
      (_trustTouched && _draftTrust != initialTrust) ||
      (_poisonTouched && _draftPoison != initialPoison);

  /// 提交所有草稿变更到 DB，完成后关闭。
  Future<void> _save({
    required Character? initialRole,
    required TrustLevel initialTrust,
    required bool initialPoison,
    required int day,
  }) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(playerDetailRepositoryProvider);
      final poisonRepo = ref.read(poisonRepositoryProvider);
      final notifier = ref.read(gameBoardProvider(widget.gameId).notifier);

      // 角色声明（仅当改了且选了角色）
      if (_roleTouched && _draftRole != null && _draftRole != initialRole) {
        final dayRecordId = await notifier.ensureCurrentDayRecord();
        await repo.claimRole(
          playerId: widget.player.id,
          dayRecordId: dayRecordId,
          character: _draftRole!,
        );
      }
      // 信任度
      if (_trustTouched && _draftTrust != initialTrust) {
        await repo.setTrustLevel(
          gameId: widget.gameId,
          playerId: widget.player.id,
          day: day,
          level: _draftTrust,
        );
      }
      // 醉/毒（toggleStatus：草稿与初始不同时翻转一次即到位）
      if (_poisonTouched && _draftPoison != initialPoison) {
        await poisonRepo.toggleStatus(
          gameId: widget.gameId,
          playerId: widget.player.id,
          dayNumber: day,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存')),
      );
      Navigator.of(context).pop();
    }
  }

  /// 有未保存修改时弹「丢弃修改？」确认；无修改直接关闭。
  Future<void> _confirmDiscardIfDirty({required bool dirty}) async {
    if (!dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('丢弃修改？'),
        content: const Text('你有未保存的修改，确定要关闭吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('丢弃'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerId = widget.player.id;
    final claims =
        ref.watch(playerClaimsProvider(playerId)).valueOrNull ??
            const <RoleClaim>[];
    final initialRole = claims.isEmpty ? null : claims.last.character;

    final day = ref.watch(
      gameBoardProvider(widget.gameId).select((s) => s.currentDay),
    );
    final players =
        ref.watch(gamePlayersProvider(widget.gameId)).valueOrNull ?? [];

    final trustMap =
        ref.watch(latestTrustLevelsProvider(widget.gameId)).valueOrNull ??
            const <int, TrustLevel>{};
    final initialTrust = trustMap[playerId] ?? TrustLevel.unknown;

    final statuses =
        ref.watch(gamePoisonStatusesProvider(widget.gameId)).valueOrNull ??
            const <PoisonStatus>[];
    final initialPoison = statuses.any(
      (p) => p.playerId == playerId && p.dayNumber == day && p.isActive,
    );

    // 显示值：触动后取草稿，否则取来源值。
    final displayRole = _roleTouched ? _draftRole : initialRole;
    final displayTrust = _trustTouched ? _draftTrust : initialTrust;
    final displayPoison = _poisonTouched ? _draftPoison : initialPoison;

    final dirty = _isDirty(
      initialRole: initialRole,
      initialTrust: initialTrust,
      initialPoison: initialPoison,
    );

    return PopScope(
      // 有未保存修改时阻止直接返回 / 下拉关闭，改走确认。
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscardIfDirty(dirty: dirty);
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // 头部：座位号 + 名字 + 存活状态
              Row(
                children: [
                  Text(
                    '${widget.player.seatNumber}号 ${widget.player.name}',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(width: 8),
                  if (!widget.player.isAlive)
                    Text(
                      '☠ 已死亡',
                      style: AppTextStyles.caption
                          .copyWith(color: context.gameColors.blood),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _RoleClaimSection(
                gameId: widget.gameId,
                selected: displayRole,
                onSelect: (c) => setState(() {
                  _roleTouched = true;
                  _draftRole = c;
                }),
              ),
              const SizedBox(height: 16),
              if (displayRole != null)
                _InfoInputSection(
                  gameId: widget.gameId,
                  playerId: playerId,
                  day: day,
                  character: displayRole,
                  players: players,
                )
              else
                Text(
                  '先声明角色，再录入该角色的信息。',
                  style: AppTextStyles.caption
                      .copyWith(color: context.gameColors.inkViolet),
                ),
              const SizedBox(height: 16),
              _RecordedInfoSection(
                playerId: playerId,
                currentRole: displayRole,
              ),
              const SizedBox(height: 16),
              _PoisonSection(
                day: day,
                marked: displayPoison,
                onChanged: (v) => setState(() {
                  _poisonTouched = true;
                  _draftPoison = v;
                }),
              ),
              const SizedBox(height: 16),
              _BehaviorNoteSection(
                gameId: widget.gameId,
                playerId: playerId,
                day: day,
              ),
              const SizedBox(height: 16),
              _TrustSection(
                current: displayTrust,
                onSelect: (l) => setState(() {
                  _trustTouched = true;
                  _draftTrust = l;
                }),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: (dirty && !_saving)
                    ? () => _save(
                          initialRole: initialRole,
                          initialTrust: initialTrust,
                          initialPoison: initialPoison,
                          day: day,
                        )
                    : null,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? '保存中…' : '保存'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 角色声明区（草稿：onSelect 只更新草稿，不写 DB）。
class _RoleClaimSection extends ConsumerWidget {
  const _RoleClaimSection({
    required this.gameId,
    required this.selected,
    required this.onSelect,
  });

  final int gameId;
  final Character? selected;
  final void Function(Character) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helpLevel = ref.watch(gameHelpLevelProvider(gameId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('角色声明', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in Character.values)
              ChoiceChip(
                label: Text(c.nameCn),
                selected: selected == c,
                onSelected: (_) => onSelect(c),
              ),
          ],
        ),
        // 新手模式：显示当前声明角色的能力描述（issue #41）
        if (selected != null)
          HelpTooltip(
            level: helpLevel,
            icon: Icons.auto_stories_outlined,
            text: '${selected!.nameCn}：${selected!.ability}',
          ),
      ],
    );
  }
}

/// 信息录入区（按角色自适应；保留自身表单提交语义，立即写 DB）。
class _InfoInputSection extends ConsumerWidget {
  const _InfoInputSection({
    required this.gameId,
    required this.playerId,
    required this.day,
    required this.character,
    required this.players,
  });

  final int gameId;
  final int playerId;
  final int day;
  final Character character;
  final List<Player> players;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${character.nameCn} 的信息', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        InfoInputFactory.build(
          character: character,
          players: players,
          onSubmit: (payload) async {
            final notifier = ref.read(gameBoardProvider(gameId).notifier);
            final dayRecordId = await notifier.ensureCurrentDayRecord();
            await ref.read(playerDetailRepositoryProvider).declareInfo(
                  playerId: playerId,
                  dayRecordId: dayRecordId,
                  character: character,
                  payload: payload,
                  gameId: gameId,
                  dayNumber: ref.read(gameBoardProvider(gameId)).currentDay,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('信息已记录')),
              );
            }
          },
        ),
      ],
    );
  }
}

/// 已录入信息回显区（issue #68：按当前声明角色分组）。
///
/// 当前声明角色的信息列在「已录入信息」；换声明后旧角色的信息归入
/// 「改口历史」，弱化显示但不丢失——既避免新旧角色信息混在一起，
/// 又保留改口轨迹供复盘。
class _RecordedInfoSection extends ConsumerWidget {
  const _RecordedInfoSection({required this.playerId, required this.currentRole});

  final int playerId;

  /// 当前声明角色（草稿或来源值）；null = 尚未声明，回退为显示全部。
  final Character? currentRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final declarations =
        ref.watch(playerDeclarationsProvider(playerId)).valueOrNull ?? [];
    if (declarations.isEmpty) return const SizedBox.shrink();

    final current = currentRole == null
        ? declarations
        : declarations.where((d) => d.characterType == currentRole).toList();
    final history = currentRole == null
        ? const <InfoDeclaration>[]
        : declarations.where((d) => d.characterType != currentRole).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('已录入信息', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        if (current.isEmpty)
          Text(
            currentRole == null ? '暂无' : '尚无 ${currentRole!.nameCn} 的信息',
            style: AppTextStyles.caption
                .copyWith(color: context.gameColors.inkViolet),
          )
        else
          for (final decl in current.reversed.take(5))
            _InfoRow(decl: decl),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '改口历史（其他角色）',
            style: AppTextStyles.caption
                .copyWith(color: context.gameColors.inkViolet),
          ),
          const SizedBox(height: 4),
          for (final decl in history.reversed.take(5))
            _InfoRow(decl: decl, dimmed: true),
        ],
      ],
    );
  }
}

/// 单条已录入信息行。
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.decl, this.dimmed = false});

  final InfoDeclaration decl;

  /// 弱化显示（改口历史）：删除线 + 灰色。
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: context.gameColors.ofReliability(decl.reliability),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              InfoPayloadFormatter.summarize(decl),
              style: dimmed
                  ? AppTextStyles.body.copyWith(
                      color: context.gameColors.inkViolet,
                      decoration: TextDecoration.lineThrough,
                    )
                  : AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}

/// 信任度调整区（草稿：onSelect 只更新草稿，不写 DB）。
class _TrustSection extends StatelessWidget {
  const _TrustSection({required this.current, required this.onSelect});

  final TrustLevel current;
  final void Function(TrustLevel) onSelect;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('信任度', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final level in TrustLevel.values)
              ChoiceChip(
                label: Text(level.nameCn),
                selected: current == level,
                selectedColor: gameColors.ofTrustLevel(level),
                labelStyle: AppTextStyles.label.copyWith(
                  color: current == level
                      ? AppColors.textOnGold
                      : AppColors.textPrimary,
                ),
                onSelected: (_) => onSelect(level),
              ),
          ],
        ),
      ],
    );
  }
}

/// 醉/毒标记区（草稿：onChanged 只更新草稿，不写 DB）。
class _PoisonSection extends StatelessWidget {
  const _PoisonSection({
    required this.day,
    required this.marked,
    required this.onChanged,
  });

  final int day;
  final bool marked;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('醉/毒状态', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(
            '标记为可能被毒/醉（第 $day 天）',
            style: AppTextStyles.body,
          ),
          subtitle: Text(
            '醉/毒时玩家「无能力」，其获得的信息可能为假。'
            '录入信息时若当天有此标记，可靠性自动降为「可能被污染」。',
            style: AppTextStyles.caption
                .copyWith(color: gameColors.inkViolet),
          ),
          value: marked,
          activeTrackColor: gameColors.inkViolet,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// 行为备注区（issue #36；保留自身提交语义，立即写 DB）。
class _BehaviorNoteSection extends ConsumerStatefulWidget {
  const _BehaviorNoteSection({
    required this.gameId,
    required this.playerId,
    required this.day,
  });

  final int gameId;
  final int playerId;
  final int day;

  @override
  ConsumerState<_BehaviorNoteSection> createState() =>
      _BehaviorNoteSectionState();
}

class _BehaviorNoteSectionState extends ConsumerState<_BehaviorNoteSection> {
  final _controller = TextEditingController();

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
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final todayNotes = ref
            .watch(playerDayNotesProvider((widget.playerId, widget.day)))
            .valueOrNull ??
        [];
    final gameColors = context.gameColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('行为备注（第 ${widget.day} 天）', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '如：投票时犹豫 / 主动带票冲 X号',
                  isDense: true,
                ),
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
        const SizedBox(height: 8),
        if (todayNotes.isEmpty)
          Text(
            '暂无备注',
            style: AppTextStyles.caption
                .copyWith(color: gameColors.inkViolet),
          )
        else
          ...todayNotes.map(
            (n) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('· ', style: AppTextStyles.body),
                  Expanded(
                    child: Text(n.note, style: AppTextStyles.body),
                  ),
                  IconButton(
                    tooltip: '删除备注',
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close, color: gameColors.inkViolet),
                    onPressed: () => ref
                        .read(behaviorNoteRepositoryProvider)
                        .deleteNote(n.id),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
