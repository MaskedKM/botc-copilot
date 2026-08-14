
import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/data/poison_repository.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/role_claim_section.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/info_input_section.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/recorded_info_section.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/status_sections.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/behavior_note_section.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/ability_section.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/player_detail_misc.dart';

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
  bool _fakeTouched = false;
  bool _draftFake = false;

  /// 草稿声明是否已随信息提交自动落库（#134 解耦）。
  ///
  /// 信息提交会先写声明；此标记让 `_isDirty`/`_save` 的角色块跳过，避免
  /// 声明流刷新前（pre-refresh 窗口）重复插入声明。
  bool _claimAutoCommitted = false;

  bool _saving = false;

  /// 行为备注草稿是否有未提交文本（PopScope 守卫，#160 #5）。
  bool _noteDraftDirty = false;

  /// 信息提交前确保草稿声明已落库（#134 解耦）。
  ///
  /// 非己玩家选了角色 chip 但尚未保存时直接录信息会造成「孤儿信息」——
  /// 该信息关联的角色没有对应声明。此处先写声明再录信息，杜绝孤儿。
  /// 提交草稿声明。返回 false=写失败（调用方应中止后续信息写入，避免孤儿信息，#164 B9）。
  Future<bool> _commitDraftClaim() async {
    if (!_roleTouched || _draftRole == null || _claimAutoCommitted) return true;
    final claims = ref
            .read(playerClaimsProvider(widget.player.id))
            .valueOrNull ??
        const <RoleClaim>[];
    final saved = claims.isEmpty ? null : claims.last.character;
    if (_draftRole == saved) {
      // 草稿与已存声明一致，仅标记，避免重复写
      if (mounted) setState(() => _claimAutoCommitted = true);
      return true;
    }
    final notifier = ref.read(gameBoardProvider(widget.gameId).notifier);
    try {
      final dayRecordId = await notifier.ensureCurrentDayRecord();
      await ref.read(playerDetailRepositoryProvider).claimRole(
            playerId: widget.player.id,
            dayRecordId: dayRecordId,
            character: _draftRole!,
          );
      if (mounted) setState(() => _claimAutoCommitted = true);
      return true;
    } on Object {
      // #164 B9：声明写失败提示，不标记 committed（下次重试）。
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('声明保存失败，请重试')));
      }
      return false;
    }
  }

  /// 撤销最新声明（误声明纠错，#160 #11；与信息/备注/提名可删对称）。
  Future<void> _undoLatestClaim(RoleClaim latest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('撤销声明'),
        content: Text(
          '撤销 ${widget.player.seatNumber}号 ${widget.player.name} 的'
          '「${latest.character.nameCn}」声明？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('撤销'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(appDatabaseProvider).roleClaimsDao.deleteClaim(latest.id);
      if (mounted) {
        // 重置草稿：撤销后回到「未声明」状态（chips 无选中）。
        setState(() {
          _roleTouched = false;
          _draftRole = null;
          _claimAutoCommitted = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已撤销声明')));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('撤销失败，请重试')));
      }
    }
  }

  /// 是否存在未保存的修改。
  ///
  /// 信任度 / 毒 / 疑似醉汉已即时落库（#138），不计脏——仅角色声明草稿
  /// 与行为备注草稿参与 PopScope 守卫。
  bool _isDirty({
    required Character? initialRole,
    required TrustLevel initialTrust,
    required bool initialPoison,
    required bool initialDrunk,
  }) =>
      (_roleTouched &&
          !_claimAutoCommitted &&
          _draftRole != initialRole) ||
      _noteDraftDirty; // 行为备注草稿（#160 #5）

  /// 提交所有草稿变更到 DB（不关闭弹层）。_save / _saveAndNext 共用。
  Future<bool> _commitChanges({
    required Character? initialRole,
    required TrustLevel initialTrust,
    required bool initialPoison,
    required bool initialDrunk,
    required int day,
  }) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(playerDetailRepositoryProvider);
      final notifier = ref.read(gameBoardProvider(widget.gameId).notifier);

      // 角色声明（仅当改了且选了角色；已随信息自动落库则跳过，#134）。
      // 信任度 / 毒 / 疑似醉汉已改为即时落库（#138），此处只提交声明。
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
      return true;
    } on Object {
      // #164 B9：fire-and-forget 写失败兜底——提示用户而非静默吞异常。
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
      return false;
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
    final ok = await _commitChanges(
      initialRole: initialRole,
      initialTrust: initialTrust,
      initialPoison: initialPoison,
      initialDrunk: initialDrunk,
      day: day,
    );
    if (!ok) return; // 失败已提示，不弹「已保存」、不关 sheet
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
    final ok = await _commitChanges(
      initialRole: initialRole,
      initialTrust: initialTrust,
      initialPoison: initialPoison,
      initialDrunk: initialDrunk,
      day: day,
    );
    if (!ok || !mounted) return;
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
    // gameClaimsProvider 的 watch 收敛到 [NextPlayerButton] 内，避免非链式
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
                          onPressed: () => changeSeatDialog(
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
                RoleClaimSection(
                  gameId: widget.gameId,
                  selected: displayRole,
                  readOnly: readOnly,
                  onSelect: (c) => setState(() {
                    _roleTouched = true;
                    _draftRole = c;
                    // 改草稿后重置：允许新角色随信息提交重新自动落库（#134）
                    _claimAutoCommitted = false;
                  }),
                  onUndo: !readOnly && claims.isNotEmpty
                      ? () => _undoLatestClaim(claims.last)
                      : null,
                ),
              // 一次性能力（仅进行中可记录动作）：我座位按真实角色，他人按声明角色
              if (!readOnly &&
                  effectiveRole != null &&
                  (effectiveRole == Character.virgin ||
                      effectiveRole == Character.slayer ||
                      effectiveRole == Character.saint)) ...[
                const SizedBox(height: 16),
                AbilitySection(
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
                  InfoInputSection(
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
              RecordedInfoSection(
                gameId: widget.gameId,
                playerId: playerId,
                currentRole: effectiveRole,
                // #156 BUG-C：用 displayDrunk（含草稿）而非 initialDrunk（保存值），
                // 拨醉汉开关后可靠性圆点即时联动，无需保存。
                authorSuspectedDrunk: displayDrunk,
                readOnly: readOnly,
              ),
              // 恶魔私密爪牙名单（7+ 人局，我=恶魔，#108/#131 迁入）
              if (isMe &&
                  myRole == Character.imp &&
                  (game?.playerCount ?? 0) >= 7) ...[
                const SizedBox(height: 16),
                MyMinionsSection(game: game!, players: players, readOnly: readOnly),
              ],
              const SizedBox(height: 16),
              PoisonSection(
                day: day,
                marked: displayPoison,
                readOnly: readOnly,
                // #138：毒标记即时落库（与信息/备注一致），不再等「保存」。
                onChanged: (v) async {
                  setState(() {
                    _poisonTouched = true;
                    _draftPoison = v;
                  });
                  try {
                    await ref.read(poisonRepositoryProvider).toggleStatus(
                          gameId: widget.gameId,
                          playerId: widget.player.id,
                          dayNumber: day,
                        );
                  } on Object {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('保存失败，请重试')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              DrunkSuspicionSection(
                marked: displayDrunk,
                readOnly: readOnly,
                // #138：疑似醉汉即时落库（整局身份），不再等「保存」。
                onChanged: (v) async {
                  setState(() {
                    _drunkTouched = true;
                    _draftDrunk = v;
                  });
                  try {
                    await ref
                        .read(playerDetailRepositoryProvider)
                        .setSuspectedDrunk(widget.player.id, suspected: v);
                  } on Object {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('保存失败，请重试')),
                      );
                    }
                  }
                },
              ),
              // 僵怖假死（#217 增量4B）：仅 BMR 对局显示；即时落库。
              if ((game?.script ?? Script.troubleBrewing) ==
                  Script.badMoonRising) ...[
                const SizedBox(height: 16),
                FakeDeathSection(
                  marked: _fakeTouched
                      ? _draftFake
                      : (widget.player.fakeDead),
                  readOnly: readOnly,
                  onChanged: (v) async {
                    setState(() {
                      _fakeTouched = true;
                      _draftFake = v;
                    });
                    try {
                      await ref
                          .read(playerDetailRepositoryProvider)
                          .setFakeDead(widget.player.id, fake: v);
                    } on Object {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('保存失败，请重试')),
                        );
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
              BehaviorNoteSection(
                gameId: widget.gameId,
                playerId: playerId,
                day: day,
                readOnly: readOnly,
                onDraftChanged: (hasDraft) {
                  // 仅在脏状态翻转时 setState（非每次击键），保焦点（#160 #5）。
                  if (hasDraft != _noteDraftDirty) {
                    setState(() => _noteDraftDirty = hasDraft);
                  }
                },
              ),
              const SizedBox(height: 16),
              TrustSection(
                current: displayTrust,
                readOnly: readOnly,
                // #138：信任度即时落库（与信息/备注一致），不再等「保存」。
                onSelect: (l) async {
                  setState(() {
                    _trustTouched = true;
                    _draftTrust = l;
                  });
                  try {
                    await ref.read(playerDetailRepositoryProvider).setTrustLevel(
                          gameId: widget.gameId,
                          playerId: widget.player.id,
                          day: day,
                          level: l,
                        );
                  } on Object {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('保存失败，请重试')),
                      );
                    }
                  }
                },
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
                      NextPlayerButton(
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
