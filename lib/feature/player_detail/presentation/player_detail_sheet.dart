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

/// 玩家详情底部弹层（issue #7）。
///
/// 内容：角色声明 + 角色自适应信息录入 + 信任度调整。
/// 通过 [show] 弹出。
class PlayerDetailSheet extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final claims =
        ref.watch(playerClaimsProvider(player.id)).valueOrNull ?? [];
    final declared = claims.isEmpty ? null : claims.last.character;
    final day = ref.watch(
      gameBoardProvider(gameId).select((s) => s.currentDay),
    );
    final players =
        ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];

    return DraggableScrollableSheet(
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
                  '${player.seatNumber}号 ${player.name}',
                  style: AppTextStyles.title,
                ),
                const SizedBox(width: 8),
                if (!player.isAlive)
                  Text(
                    '☠ 已死亡',
                    style: AppTextStyles.caption
                        .copyWith(color: context.gameColors.blood),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _RoleClaimSection(
              gameId: gameId,
              player: player,
              day: day,
              claims: claims,
            ),
            const SizedBox(height: 16),
            if (declared != null)
              _InfoInputSection(
                gameId: gameId,
                player: player,
                day: day,
                character: declared,
                players: players,
              )
            else
              Text(
                '先声明角色，再录入该角色的信息。',
                style: AppTextStyles.caption
                    .copyWith(color: context.gameColors.inkViolet),
              ),
            const SizedBox(height: 16),
            _RecordedInfoSection(player: player, currentRole: declared),
            const SizedBox(height: 16),
            _PoisonSection(gameId: gameId, player: player, day: day),
            const SizedBox(height: 16),
            _BehaviorNoteSection(gameId: gameId, player: player, day: day),
            const SizedBox(height: 16),
            _TrustSection(gameId: gameId, player: player, day: day),
          ],
        );
      },
    );
  }
}

/// 角色声明区。
class _RoleClaimSection extends ConsumerWidget {
  const _RoleClaimSection({
    required this.gameId,
    required this.player,
    required this.day,
    required this.claims,
  });

  final int gameId;
  final Player player;
  final int day;
  final List<RoleClaim> claims;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimed = claims.isEmpty ? null : claims.last.character;
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
                selected: claimed == c,
                onSelected: (_) async {
                  final dayRecordId = await ref
                      .read(gameBoardProvider(gameId).notifier)
                      .ensureCurrentDayRecord();
                  await ref
                      .read(playerDetailRepositoryProvider)
                      .claimRole(
                        playerId: player.id,
                        dayRecordId: dayRecordId,
                        character: c,
                      );
                },
              ),
          ],
        ),
        // 新手模式：显示当前声明角色的能力描述（issue #41）
        if (claimed != null)
          HelpTooltip(
            level: helpLevel,
            icon: Icons.auto_stories_outlined,
            text: '${claimed.nameCn}：${claimed.ability}',
          ),
      ],
    );
  }
}

/// 信息录入区（按角色自适应）。
class _InfoInputSection extends ConsumerWidget {
  const _InfoInputSection({
    required this.gameId,
    required this.player,
    required this.day,
    required this.character,
    required this.players,
  });

  final int gameId;
  final Player player;
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
                  playerId: player.id,
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
  const _RecordedInfoSection({required this.player, required this.currentRole});

  final Player player;

  /// 当前声明角色（claims.last）；null = 尚未声明，回退为显示全部。
  final Character? currentRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final declarations =
        ref.watch(playerDeclarationsProvider(player.id)).valueOrNull ?? [];
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

/// 信任度调整区（5 档滑块，实时反映到圆环色环）。
class _TrustSection extends ConsumerWidget {
  const _TrustSection({
    required this.gameId,
    required this.player,
    required this.day,
  });

  final int gameId;
  final Player player;
  final int day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(latestTrustLevelsProvider(gameId)).valueOrNull ??
        const <int, TrustLevel>{};
    final current = levels[player.id] ?? TrustLevel.unknown;
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
                onSelected: (_) =>
                    ref.read(playerDetailRepositoryProvider).setTrustLevel(
                          gameId: gameId,
                          playerId: player.id,
                          day: day,
                          level: level,
                        ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 醉/毒标记区（issue #35）。
class _PoisonSection extends ConsumerWidget {
  const _PoisonSection({
    required this.gameId,
    required this.player,
    required this.day,
  });

  final int gameId;
  final Player player;
  final int day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses =
        ref.watch(gamePoisonStatusesProvider(gameId)).valueOrNull ?? [];
    final marked = statuses.any(
      (p) => p.playerId == player.id && p.dayNumber == day && p.isActive,
    );
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
          onChanged: (_) {
            ref.read(poisonRepositoryProvider).toggleStatus(
                  gameId: gameId,
                  playerId: player.id,
                  dayNumber: day,
                );
          },
        ),
      ],
    );
  }
}

/// 行为备注区（issue #36）。
class _BehaviorNoteSection extends ConsumerStatefulWidget {
  const _BehaviorNoteSection({
    required this.gameId,
    required this.player,
    required this.day,
  });

  final int gameId;
  final Player player;
  final int day;

  @override
  ConsumerState<_BehaviorNoteSection> createState() =>
      _BehaviorNoteSectionState();
}

class _BehaviorNoteSectionState
    extends ConsumerState<_BehaviorNoteSection> {
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
          playerId: widget.player.id,
          dayNumber: widget.day,
          note: note,
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final todayNotes = ref
            .watch(playerDayNotesProvider((widget.player.id, widget.day)))
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
