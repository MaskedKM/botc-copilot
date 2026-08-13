import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/data/poison_repository.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/feature/game_board/presentation/succession_handler.dart';
import 'package:botc_copilot/feature/player_detail/data/ability_repository.dart';
import 'package:botc_copilot/feature/player_detail/data/behavior_note_repository.dart';
import 'package:botc_copilot/shared/widgets/help_tooltip.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/player_detail/domain/info_payload_formatter.dart';
import 'package:botc_copilot/feature/player_detail/domain/next_unclaimed_player.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/info_input_factory.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/shared/game_private.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/shared/reliability.dart';
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
    this.enableChain = false,
    super.key,
  });

  /// 对局 id。
  final int gameId;

  /// 目标玩家。
  final Player player;

  /// 是否启用「保存并下一位」首夜队列（#134）。圆环点按开启；矛盾列表等
  /// 查看入口关闭。仅非己、进行中时实际显示该按钮。
  final bool enableChain;

  /// 弹出玩家详情；返回值 = 「保存并下一位」时下一个待开玩家，否则 null。
  static Future<Player?> show(
    BuildContext context, {
    required int gameId,
    required Player player,
    bool enableChain = false,
  }) {
    return showModalBottomSheet<Player?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PlayerDetailSheet(
          gameId: gameId,
          player: player,
          enableChain: enableChain,
        ),
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
  bool _drunkTouched = false;
  bool _draftDrunk = false;

  /// 草稿声明是否已随信息提交自动落库（#134 解耦）。
  ///
  /// 信息提交会先写声明；此标记让 `_isDirty`/`_save` 的角色块跳过，避免
  /// 声明流刷新前（pre-refresh 窗口）重复插入声明。
  bool _claimAutoCommitted = false;

  bool _saving = false;

  /// 信息提交前确保草稿声明已落库（#134 解耦）。
  ///
  /// 非己玩家选了角色 chip 但尚未保存时直接录信息会造成「孤儿信息」——
  /// 该信息关联的角色没有对应声明。此处先写声明再录信息，杜绝孤儿。
  Future<void> _commitDraftClaim() async {
    if (!_roleTouched || _draftRole == null || _claimAutoCommitted) return;
    final claims = ref
            .read(playerClaimsProvider(widget.player.id))
            .valueOrNull ??
        const <RoleClaim>[];
    final saved = claims.isEmpty ? null : claims.last.character;
    if (_draftRole == saved) {
      // 草稿与已存声明一致，仅标记，避免重复写
      if (mounted) setState(() => _claimAutoCommitted = true);
      return;
    }
    final notifier = ref.read(gameBoardProvider(widget.gameId).notifier);
    final dayRecordId = await notifier.ensureCurrentDayRecord();
    await ref.read(playerDetailRepositoryProvider).claimRole(
          playerId: widget.player.id,
          dayRecordId: dayRecordId,
          character: _draftRole!,
        );
    if (mounted) setState(() => _claimAutoCommitted = true);
  }

  /// 是否存在未保存的修改。
  bool _isDirty({
    required Character? initialRole,
    required TrustLevel initialTrust,
    required bool initialPoison,
    required bool initialDrunk,
  }) =>
      (_roleTouched &&
              !_claimAutoCommitted &&
              _draftRole != initialRole) ||
      (_trustTouched && _draftTrust != initialTrust) ||
      (_poisonTouched && _draftPoison != initialPoison) ||
      (_drunkTouched && _draftDrunk != initialDrunk);

  /// 提交所有草稿变更到 DB（不关闭弹层）。_save / _saveAndNext 共用。
  Future<void> _commitChanges({
    required Character? initialRole,
    required TrustLevel initialTrust,
    required bool initialPoison,
    required bool initialDrunk,
    required int day,
  }) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(playerDetailRepositoryProvider);
      final poisonRepo = ref.read(poisonRepositoryProvider);
      final notifier = ref.read(gameBoardProvider(widget.gameId).notifier);

      // 角色声明（仅当改了且选了角色；已随信息自动落库则跳过，#134）
      if (_roleTouched &&
          !_claimAutoCommitted &&
          _draftRole != null &&
          _draftRole != initialRole) {
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
      // 毒（按天，toggleStatus：草稿与初始不同时翻转一次即到位）
      if (_poisonTouched && _draftPoison != initialPoison) {
        await poisonRepo.toggleStatus(
          gameId: widget.gameId,
          playerId: widget.player.id,
          dayNumber: day,
        );
      }
      // 疑似醉汉（整局身份，#109）
      if (_drunkTouched && _draftDrunk != initialDrunk) {
        await repo.setSuspectedDrunk(
          widget.player.id,
          suspected: _draftDrunk,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 保存并关闭弹层。
  Future<void> _save({
    required Character? initialRole,
    required TrustLevel initialTrust,
    required bool initialPoison,
    required bool initialDrunk,
    required int day,
  }) async {
    await _commitChanges(
      initialRole: initialRole,
      initialTrust: initialTrust,
      initialPoison: initialPoison,
      initialDrunk: initialDrunk,
      day: day,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存')),
      );
      Navigator.of(context).pop(null);
    }
  }

  /// 保存并打开下一个未声明的玩家（首夜队列加速器，#134）。
  Future<void> _saveAndNext({
    required Character? initialRole,
    required TrustLevel initialTrust,
    required bool initialPoison,
    required bool initialDrunk,
    required int day,
    required Player next,
  }) async {
    await _commitChanges(
      initialRole: initialRole,
      initialTrust: initialTrust,
      initialPoison: initialPoison,
      initialDrunk: initialDrunk,
      day: day,
    );
    if (!mounted) return;
    // 把下一个玩家作为弹层返回值；调用方循环打开（_openDetailChain）。
    Navigator.of(context).pop(next);
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

    // 我座位识别（issue #105）：setup 已选定「我的座位 + 真实角色」，
    // 点自己座位时应以真实角色（myRole）驱动信息/能力录入，不要求重复声明。
    final game = ref.watch(gameByIdProvider(widget.gameId)).valueOrNull;
    final isMe = game?.myPlayerId == widget.player.id;
    final myRole = game?.myRole;
    // 结束局只读复盘：禁所有编辑，保留数据展示（#134）。
    final readOnly = game?.status != GameStatus.ongoing;
    final effectiveRole = isMe ? myRole : initialRole;

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
    // 疑似醉汉（整局身份，#109）：取已保存值（players 流为最新）
    final initialDrunk = players
            .where((p) => p.id == playerId)
            .firstOrNull
            ?.suspectedDrunk ??
        false;

    // 显示值：触动后取草稿，否则取来源值。
    final displayRole = _roleTouched ? _draftRole : initialRole;
    final displayTrust = _trustTouched ? _draftTrust : initialTrust;
    final displayPoison = _poisonTouched ? _draftPoison : initialPoison;
    final displayDrunk = _drunkTouched ? _draftDrunk : initialDrunk;

    final dirty = _isDirty(
      initialRole: initialRole,
      initialTrust: initialTrust,
      initialPoison: initialPoison,
      initialDrunk: initialDrunk,
    );

    // 「保存并下一位」仅在 enableChain 且非己、进行中时显示（#134）。
    // gameClaimsProvider 的 watch 收敛到 [_NextPlayerButton] 内，避免非链式
    // 场景（默认弹层）触发该 provider（widget test 不覆写它，会建真实 DB）。
    final chainEnabled = widget.enableChain && !isMe && !readOnly;

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
                          .copyWith(color: context.gameColors.bloodBright),
                    ),
                ],
              ),
              // 我座位：标识真实角色（私密，区别于公开声明，#105）+ 换座入口（#86/#131）
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '这是我 · 真实角色：${myRole?.nameCn ?? '未设置'}',
                          style: AppTextStyles.caption.copyWith(
                            color: context.gameColors.goldBright,
                          ),
                        ),
                      ),
                      if (game?.status == GameStatus.ongoing)
                        TextButton.icon(
                          onPressed: () => _changeSeatDialog(
                            context,
                            ref,
                            game!,
                            players,
                          ),
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: const Text('换座'),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // 角色声明区（我座位跳过：真实角色已知，不要求重复声明，#105）
              if (!isMe)
                _RoleClaimSection(
                  gameId: widget.gameId,
                  selected: displayRole,
                  readOnly: readOnly,
                  onSelect: (c) => setState(() {
                    _roleTouched = true;
                    _draftRole = c;
                    // 改草稿后重置：允许新角色随信息提交重新自动落库（#134）
                    _claimAutoCommitted = false;
                  }),
                ),
              // 一次性能力（仅进行中可记录动作）：我座位按真实角色，他人按声明角色
              if (!readOnly &&
                  effectiveRole != null &&
                  (effectiveRole == Character.virgin ||
                      effectiveRole == Character.slayer ||
                      effectiveRole == Character.saint)) ...[
                const SizedBox(height: 16),
                _AbilitySection(
                  gameId: widget.gameId,
                  playerId: playerId,
                  day: day,
                  character: effectiveRole,
                  players: players,
                ),
              ],
              const SizedBox(height: 16),
              // 信息录入（#134 解耦，仅进行中）：我座位按真实角色；他人按**草稿**
              // 角色（选 chip 即刻出现录入区），提交时自动落库声明，免去
              // 「保存→关→重开」。我座位仍 isMine=true（#105）。复盘只读时不显示。
              if (!readOnly)
                if (isMe ? myRole != null : displayRole != null)
                  _InfoInputSection(
                    gameId: widget.gameId,
                    playerId: playerId,
                    day: day,
                    character: isMe ? myRole! : displayRole!,
                    players: players,
                    isMine: isMe,
                    onEnsureClaim: _commitDraftClaim,
                  )
                else if (isMe)
                  Text(
                    '开局未设置角色，无法录入信息。',
                    style: AppTextStyles.caption
                        .copyWith(color: context.gameColors.inkViolet),
                  )
                else
                  Text(
                    '先声明角色，再录入该角色的信息。',
                    style: AppTextStyles.caption
                        .copyWith(color: context.gameColors.inkViolet),
                  ),
              const SizedBox(height: 16),
              // 分组按有效角色（我座位=myRole；草稿不改分组，避免误导）。
              // 可靠性圆点叠加整局「疑似醉汉」overlay（#109）。
              _RecordedInfoSection(
                gameId: widget.gameId,
                playerId: playerId,
                currentRole: effectiveRole,
                authorSuspectedDrunk: initialDrunk,
                readOnly: readOnly,
              ),
              // 恶魔私密爪牙名单（7+ 人局，我=恶魔，#108/#131 迁入）
              if (isMe &&
                  myRole == Character.imp &&
                  (game?.playerCount ?? 0) >= 7) ...[
                const SizedBox(height: 16),
                _MyMinionsSection(game: game!, players: players, readOnly: readOnly),
              ],
              const SizedBox(height: 16),
              _PoisonSection(
                day: day,
                marked: displayPoison,
                readOnly: readOnly,
                onChanged: (v) => setState(() {
                  _poisonTouched = true;
                  _draftPoison = v;
                }),
              ),
              const SizedBox(height: 16),
              _DrunkSuspicionSection(
                marked: displayDrunk,
                readOnly: readOnly,
                onChanged: (v) => setState(() {
                  _drunkTouched = true;
                  _draftDrunk = v;
                }),
              ),
              const SizedBox(height: 16),
              _BehaviorNoteSection(
                gameId: widget.gameId,
                playerId: playerId,
                day: day,
                readOnly: readOnly,
              ),
              const SizedBox(height: 16),
              _TrustSection(
                current: displayTrust,
                readOnly: readOnly,
                onSelect: (l) => setState(() {
                  _trustTouched = true;
                  _draftTrust = l;
                }),
              ),
              // 保存按钮仅进行中显示（复盘只读，#134）
              if (!readOnly) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (dirty && !_saving)
                            ? () => _save(
                                  initialRole: initialRole,
                                  initialTrust: initialTrust,
                                  initialPoison: initialPoison,
                                  initialDrunk: initialDrunk,
                                  day: day,
                                )
                            : null,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? '保存中…' : '保存'),
                      ),
                    ),
                    // 保存并下一位（首夜队列加速器，#134）：保存当前并自动
                    // 跳到下一个未声明玩家。无未声明者时禁用。
                    if (chainEnabled) ...[
                      const SizedBox(width: 8),
                      _NextPlayerButton(
                        gameId: widget.gameId,
                        playerId: playerId,
                        myPlayerId: game?.myPlayerId,
                        players: players,
                        saving: _saving,
                        onNext: (next) => _saveAndNext(
                          initialRole: initialRole,
                          initialTrust: initialTrust,
                          initialPoison: initialPoison,
                          initialDrunk: initialDrunk,
                          day: day,
                          next: next,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 「保存并下一位」按钮（#134 首夜队列加速器）。
///
/// 独立 ConsumerWidget——仅在此按钮渲染时才 watch [gameClaimsProvider]，避免
/// 非链式弹层（默认入口）触发该 provider（widget test 不覆写它会建真实 DB）。
class _NextPlayerButton extends ConsumerWidget {
  const _NextPlayerButton({
    required this.gameId,
    required this.playerId,
    required this.myPlayerId,
    required this.players,
    required this.saving,
    required this.onNext,
  });

  final int gameId;
  final int playerId;
  final int? myPlayerId;
  final List<Player> players;
  final bool saving;
  final void Function(Player next) onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allClaims =
        ref.watch(gameClaimsProvider(gameId)).valueOrNull ??
            const <RoleClaim>[];
    final next = nextUnclaimedPlayer(
      players: players,
      claimedPlayerIds: allClaims.map((c) => c.playerId).toSet(),
      fromPlayerId: playerId,
      myPlayerId: myPlayerId,
    );
    return FilledButton.icon(
      onPressed: (next != null && !saving) ? () => onNext(next) : null,
      icon: const Icon(Icons.skip_next),
      label: const Text('下一位'),
    );
  }
}

/// 角色声明区（草稿：onSelect 只更新草稿，不写 DB）。
class _RoleClaimSection extends ConsumerWidget {
  const _RoleClaimSection({
    required this.gameId,
    required this.selected,
    required this.onSelect,
    this.readOnly = false,
  });

  final int gameId;
  final Character? selected;
  final void Function(Character) onSelect;

  /// 只读（复盘）：chip 不可选。
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helpLevel = ref.watch(gameHelpLevelProvider(gameId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('角色声明', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        // 按阵营分组（与开局选角 role_step 一致，#160 P0）：首夜为 5-15 人
        // 逐一声明是最高频操作，平铺 22 chip 线性扫描 + 相邻易误点。
        for (final team in const [
          Team.townsfolk,
          Team.outsider,
          Team.minion,
          Team.demon,
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              team.nameCn,
              style: AppTextStyles.caption.copyWith(
                color: team.isGood
                    ? context.gameColors.goldBright
                    : context.gameColors.blood,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in Character.byTeam(team))
                ChoiceChip(
                  label: Text(c.nameCn),
                  selected: selected == c,
                  onSelected: readOnly ? null : (_) => onSelect(c),
                ),
            ],
          ),
        ],
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
  final Future<void> Function() onEnsureClaim;

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
          actingPlayerId: playerId,
          onSubmit: (payload) async {
            // 先落库草稿声明（非己且选了 chip 时），再录信息（#134）
            await onEnsureClaim();
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
  const _RecordedInfoSection({
    required this.gameId,
    required this.playerId,
    required this.currentRole,
    required this.authorSuspectedDrunk,
    this.readOnly = false,
  });

  /// 对局 id（用于解析目标玩家 db id → 座位号，#145）。
  final int gameId;

  final int playerId;

  /// 当前声明角色（草稿或来源值）；null = 尚未声明，回退为显示全部。
  final Character? currentRole;

  /// 该玩家是否被疑醉（整局 overlay 叠加到信息可靠性圆点，#109）。
  final bool authorSuspectedDrunk;

  /// 只读（复盘）：不显示删除按钮。
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final declarations =
        ref.watch(playerDeclarationsProvider(playerId)).valueOrNull ?? [];
    if (declarations.isEmpty) return const SizedBox.shrink();

    // 解析 payload 内目标玩家 db id → 座位号（#145）。playerId 是 db id，
    // 必须经 playersById 映射为座位号展示，否则多局后 db id > 座位数即错乱。
    final players =
        ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? const <Player>[];
    final playersById = {for (final p in players) p.id: p};
    String seatLabel(int id) {
      final p = playersById[id];
      return p != null ? '${p.seatNumber}号' : '$id 号';
    }

    Future<void> Function()? deleteFor(InfoDeclaration d) => readOnly
        ? null
        : () => _confirmDeleteDeclaration(context, ref, d.id);

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
            _InfoRow(
              decl: decl,
              labelFor: seatLabel,
              authorSuspectedDrunk: authorSuspectedDrunk,
              onDelete: deleteFor(decl),
            ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '改口历史（其他角色）',
            style: AppTextStyles.caption
                .copyWith(color: context.gameColors.inkViolet),
          ),
          const SizedBox(height: 4),
          for (final decl in history.reversed.take(5))
            _InfoRow(
              decl: decl,
              dimmed: true,
              labelFor: seatLabel,
              authorSuspectedDrunk: authorSuspectedDrunk,
              onDelete: deleteFor(decl),
            ),
        ],
      ],
    );
  }
}

/// 单条已录入信息行。
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.decl,
    required this.labelFor,
    this.dimmed = false,
    this.authorSuspectedDrunk = false,
    this.onDelete,
  });

  final InfoDeclaration decl;

  /// 目标玩家 db id → 座位号展示（#145）。
  final String Function(int playerId) labelFor;

  /// 弱化显示（改口历史）：删除线 + 灰色。
  final bool dimmed;

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
              iconSize: 18,
              visualDensity: VisualDensity.compact,
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

/// 信任度调整区（草稿：onSelect 只更新草稿，不写 DB）。
class _TrustSection extends StatelessWidget {
  const _TrustSection({
    required this.current,
    required this.onSelect,
    this.readOnly = false,
  });

  final TrustLevel current;
  final void Function(TrustLevel) onSelect;

  /// 只读（复盘）：chip 不可选。
  final bool readOnly;

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
                onSelected: readOnly ? null : (_) => onSelect(level),
              ),
          ],
        ),
      ],
    );
  }
}

/// 毒标记区（按天，仅「毒」；草稿：onChanged 只更新草稿，不写 DB）。
///
/// 醉汉是整局身份，不在此处——见 [_DrunkSuspicionSection]（#109）。
class _PoisonSection extends StatelessWidget {
  const _PoisonSection({
    required this.day,
    required this.marked,
    required this.onChanged,
    this.readOnly = false,
  });

  final int day;
  final bool marked;
  final void Function(bool) onChanged;

  /// 只读（复盘）：开关不可拨。
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('毒状态（按天）', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(
            '标记为可能被毒（第 $day 天）',
            style: AppTextStyles.body,
          ),
          subtitle: Text(
            '官方：毒当夜 + 次日白天生效、黄昏解除。被毒者「无能力」，'
            '其获得的信息可能为假，可靠性自动降为「可能被污染」。',
            style: AppTextStyles.caption
                .copyWith(color: gameColors.inkViolet),
          ),
          value: marked,
          activeTrackColor: gameColors.inkViolet,
          onChanged: readOnly ? null : onChanged,
        ),
      ],
    );
  }
}

/// 疑似醉汉标记区（整局身份推测，#109；草稿：onChanged 只更新草稿）。
///
/// 官方：醉汉是整局身份（从头到尾醉酒、自己不知道、信息为假），与按天的毒
/// 不同。一次标记全局长效，该玩家所有信息（历史 + 未来）按可能不可靠处理。
class _DrunkSuspicionSection extends StatelessWidget {
  const _DrunkSuspicionSection({
    required this.marked,
    required this.onChanged,
    this.readOnly = false,
  });

  final bool marked;
  final void Function(bool) onChanged;

  /// 只读（复盘）：开关不可拨。
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('疑似醉汉（整局）', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(
            '怀疑是醉汉',
            style: AppTextStyles.body,
          ),
          subtitle: Text(
            '官方：醉汉是整局身份，其所有信息都为假（自己不知道）。'
            '标记后该玩家全部信息（历史 + 未来）按可能不可靠处理。',
            style: AppTextStyles.caption
                .copyWith(color: gameColors.inkViolet),
          ),
          value: marked,
          activeTrackColor: gameColors.inkViolet,
          onChanged: readOnly ? null : onChanged,
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
    this.readOnly = false,
  });

  final int gameId;
  final int playerId;
  final int day;

  /// 只读（复盘）：隐藏输入框，仅展示已存备注。
  final bool readOnly;

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
    // #164：await 后须 mounted 守卫，否则关闭 sheet 致 dispose → .clear() 崩。
    if (!mounted) return;
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
                  if (!widget.readOnly)
                    IconButton(
                      tooltip: '删除备注',
                      iconSize: 16,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, color: gameColors.inkViolet),
                      onPressed: () =>
                          _confirmDeleteNote(context, ref, n.id),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 删除信息声明的二次确认（误录纠错，issue #83）。
Future<void> _confirmDeleteDeclaration(
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

/// 删除行为备注的二次确认（#138 破坏操作加确认）。
Future<void> _confirmDeleteNote(
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
///
/// App 追踪玩家**声明**角色的能力状态，并提供录入动作，不代替裁决隐藏
/// 信息（是否真为恶魔、是否真被毒由用户确认）。
class _AbilitySection extends ConsumerStatefulWidget {
  const _AbilitySection({
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
  ConsumerState<_AbilitySection> createState() => _AbilitySectionState();
}

class _AbilitySectionState extends ConsumerState<_AbilitySection> {
  int? _targetId;
  bool _targetIsDemon = false;
  bool _wasPoisoned = false;
  bool _submitting = false;

  Player? get _live => widget.players
      .where((p) => p.id == widget.playerId)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final used = _live?.abilityUsed ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('一次性能力 · ${widget.character.nameCn}',
            style: AppTextStyles.headline),
        const SizedBox(height: 8),
        switch (widget.character) {
          Character.virgin => _buildVirgin(used, gameColors),
          Character.slayer => _buildSlayer(used, gameColors),
          Character.saint => _buildSaint(gameColors),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  /// Virgin：追踪能力消耗。
  ///
  /// 官方规则（Wiki · Virgin · Summary）：首次被提名后处女即失去能力，
  /// **即使提名者未死、即使处女当时被毒/醉**。被毒/醉时能力不触发
  /// （提名者不被处决），但能力仍已消耗——清醒后再被提名不再触发。
  Widget _buildVirgin(bool used, GameColors gameColors) {
    // Virgin 能力被动触发（首次被提名消耗），此开关是历史记录而非「发动能力」——
    // 死者亦可补录消耗状态。仅 Slayer 主动击杀需门控死者（#154 R-2）。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('能力已消耗'),
          value: used,
          activeTrackColor: gameColors.inkViolet,
          onChanged: (v) async {
            await ref
                .read(abilityRepositoryProvider)
                .setAbilityUsed(widget.playerId, used: v);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(v ? '处女能力已标记消耗' : '处女能力已恢复'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        Text(
          '官方规则：处女首次被镇民提名时，提名者立即被处决（当天提名结束）。'
          '被非镇民提名不触发，但能力仍失去。'
          '被毒/醉时被提名不触发（无人被处决），但能力同样已消耗——'
          '清醒后再被提名不再触发。',
          style: AppTextStyles.caption
              .copyWith(color: gameColors.inkViolet),
        ),
      ],
    );
  }

  /// Saint：提示（被处决时善良立即战败，处决流程会有提示）。
  Widget _buildSaint(GameColors gameColors) {
    return Text(
      '圣徒被处决时，善良方立即战败。处决此人时 App 会提示「邪恶获胜」。',
      style: AppTextStyles.caption.copyWith(color: gameColors.bloodBright),
    );
  }

  /// Slayer：一次性猜测录入。
  Widget _buildSlayer(bool used, GameColors gameColors) {
    if (used) {
      return Text(
        '已使用（一次性，不可再用）。即使当时被毒/醉，能力也已永久消耗。',
        style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
      );
    }
    // 官方规则：死亡玩家不能发动角色能力（#154 R-2）。
    if (!(_live?.isAlive ?? true)) {
      return Text(
        '已死亡，能力不可用（死者不能发动能力）。',
        style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
      );
    }
    final candidates = widget.players
        .where((p) => p.id != widget.playerId && p.isAlive)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('猜测目标是恶魔', style: AppTextStyles.body),
        const SizedBox(height: 4),
        DropdownButton<int>(
          value: _targetId,
          hint: const Text('选择目标'),
          isExpanded: true,
          items: [
            for (final p in candidates)
              DropdownMenuItem(
                value: p.id,
                child: Text('${p.seatNumber}号 ${p.name}'),
              ),
          ],
          onChanged: (v) => setState(() => _targetId = v),
        ),
        CheckboxListTile(
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('目标是恶魔'),
          value: _targetIsDemon,
          onChanged: (v) => setState(() => _targetIsDemon = v ?? false),
        ),
        CheckboxListTile(
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('我此刻被毒/醉'),
          subtitle: const Text('被毒/醉时能力仍永久消耗，但不击杀'),
          value: _wasPoisoned,
          onChanged: (v) => setState(() => _wasPoisoned = v ?? false),
        ),
        FilledButton(
          onPressed: (_targetId != null && !_submitting) ? _submitSlayer : null,
          child: Text(_submitting ? '处理中…' : '使用 Slayer 猜测'),
        ),
      ],
    );
  }

  Future<void> _submitSlayer() async {
    setState(() => _submitting = true);
    final result = await ref.read(abilityRepositoryProvider).recordSlayerGuess(
          slayerId: widget.playerId,
          targetId: _targetId!,
          targetIsDemon: _targetIsDemon,
          wasPoisoned: _wasPoisoned,
          day: widget.day,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    // recordSlayerGuess 仅在 targetIsDemon && !wasPoisoned 时返回 killed。
    if (result == SlayerGuessResult.killed) {
      // 击中恶魔 → 查 SW 传承（在场则不终局），否则善良胜（issue #89）
      final notifier = ref.read(gameBoardProvider(widget.gameId).notifier);
      final succ = await notifier.checkDemonDeath(
        _targetId!,
        way: DeathWay.slayer,
      );
      if (!mounted) return;
      if (succ is DemonSuccessionCandidate) {
        await handleSuccession(context, ref, widget.gameId, succ);
      } else {
        await notifier.endGame(goodWin: true, revealedPlayerId: _targetId);
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('未击杀（目标非恶魔 或 你被毒/醉），能力已永久消耗'),
      ),
    );
  }
}

/// 更换我的座位（issue #86）：选座 → 二次确认 → 写 myPlayerId。
///
/// 从 MyInfoSheet 迁入（#131 统一入口）。
Future<void> _changeSeatDialog(
  BuildContext context,
  WidgetRef ref,
  Game game,
  List<Player> players,
) async {
  var picked = game.myPlayerId;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('更换我的座位'),
        content: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in players)
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: picked == p.id,
                onSelected: (_) => setState(() => picked = p.id),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed:
                picked == null ? null : () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    ),
  );
  final id = picked;
  if (confirmed == true && id != null && id != game.myPlayerId) {
    await ref
        .read(appDatabaseProvider)
        .gamesDao
        .updateMyPlayerId(game.id, id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已更换座位')),
      );
    }
  }
}

/// 恶魔私密爪牙名单（issue #108）。
///
/// 官方：7+ 人局恶魔首夜得知爪牙是谁。多选玩家（排除自己），即时写入
/// `Games.myMinionIdsJson`。私密——不进公开推理，仅角色矩阵对我私密展示。
///
/// 从 MyInfoSheet 迁入（#131 统一入口）。
class _MyMinionsSection extends ConsumerWidget {
  const _MyMinionsSection({
    required this.game,
    required this.players,
    this.readOnly = false,
  });

  final Game game;

  /// 全部玩家（用于候选）。
  final List<Player> players;

  /// 只读（复盘）：chip 不可选。
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameColors = context.gameColors;
    final selected = minionIdsOf(game);
    final expected = PlayerSetup.forCount(game.playerCount).minions;
    // 候选：除我以外的玩家
    final candidates =
        players.where((p) => p.id != game.myPlayerId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '我的爪牙（私密，${game.playerCount} 人局应有 $expected 个）',
          style: AppTextStyles.headline.copyWith(color: gameColors.bloodBright),
        ),
        const SizedBox(height: 4),
        Text(
          '官方：7+ 人局恶魔首夜得知爪牙。仅你可见，不影响公开推理。',
          style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in candidates)
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: selected.contains(p.id),
                onSelected: readOnly
                    ? null
                    : (_) async {
                        final next = Set<int>.of(selected);
                        final isAdd = !next.contains(p.id);
                        if (isAdd) {
                          next.add(p.id);
                        } else {
                          next.remove(p.id);
                        }
                        await ref
                            .read(appDatabaseProvider)
                            .gamesDao
                            .updateMyMinionIds(
                              game.id,
                              jsonEncode(next.toList()),
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${isAdd ? "已加入" : "已移除"} '
                              '${p.seatNumber}号 ${p.name}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
              ),
          ],
        ),
      ],
    );
  }
}
