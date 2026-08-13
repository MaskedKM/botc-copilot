import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/dependency_chain_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/dependency_chain.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 信息依赖链可视化（issue #58）。
///
/// 展示每条信息声明的依赖（作者清醒度）与内容引用，并支持沙盒「假设 X
/// 醉」试算——高亮受影响（不可靠）的信息。原则：展示依赖与假设影响，
/// 不判定谁一定是 Drunk。
class DependencyChainPage extends ConsumerWidget {
  /// 创建页面。
  const DependencyChainPage({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  /// 打开页面。
  static void show(BuildContext context, {required int gameId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DependencyChainPage(gameId: gameId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(dependencyNodesProvider(gameId));
    final players =
        ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final sandbox = ref.watch(dependencySandboxProvider(gameId));
    // 同时等声明与玩家流：玩家未就绪时 suspectedDrunk overlay 未生效、
    // 座位号也无法解析，故两者都在加载时显示转圈。
    final loading = ref.watch(
          gameDeclarationsProvider(gameId).select((a) => a.isLoading),
        ) ||
        ref.watch(gamePlayersProvider(gameId).select((a) => a.isLoading));
    final gameColors = context.gameColors;
    final byId = {for (final p in players) p.id: p};

    return Scaffold(
      appBar: AppBar(title: const Text('信息依赖链')),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : nodes.isEmpty
                ? _Empty(gameColors: gameColors)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (sandbox.isNotEmpty)
                        _SandboxBar(
                          assumedSeats: [
                            for (final id in sandbox) _seat(byId, id),
                          ],
                          onReset: () => ref
                              .read(dependencySandboxProvider(gameId).notifier)
                              .reset(),
                          gameColors: gameColors,
                        ),
                      _Legend(gameColors: gameColors),
                      const SizedBox(height: 12),
                      ..._authorSections(nodes, byId, sandbox, ref),
                    ],
                  ),
      ),
    );
  }

  /// 按作者（座位序）分组渲染各节。
  List<Widget> _authorSections(
    List<InfoDependencyNode> nodes,
    Map<int, Player> byId,
    Set<int> sandbox,
    WidgetRef ref,
  ) {
    final authorIds = <int>{
      for (final n in nodes) n.authorId,
    }.toList()
      ..sort((a, b) =>
          (byId[a]?.seatNumber ?? 1 << 30)
              .compareTo(byId[b]?.seatNumber ?? 1 << 30));
    return [
      for (final authorId in authorIds)
        _AuthorSection(
          authorId: authorId,
          authorNodes: nodes.where((n) => n.authorId == authorId).toList(),
          byId: byId,
          sandboxAssumed: sandbox.contains(authorId),
          onToggleAssumeDrunk: () => ref
              .read(dependencySandboxProvider(gameId).notifier)
              .toggleAssumeDrunk(authorId),
        ),
    ];
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.gameColors});

  final GameColors gameColors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree_outlined,
                size: 48, color: gameColors.inkViolet),
            const SizedBox(height: 12),
            Text('暂无信息声明', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text(
              '在玩家详情中录入角色信息后，此处展示信息间的依赖关系，'
              '并支持「假设 X 醉」试算。',
              style:
                  AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SandboxBar extends StatelessWidget {
  const _SandboxBar({
    required this.assumedSeats,
    required this.onReset,
    required this.gameColors,
  });

  final List<String> assumedSeats;
  final VoidCallback onReset;
  final GameColors gameColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: gameColors.blood.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gameColors.blood.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 18, color: gameColors.blood),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '假设中（仅本页试算，不改存档）：${assumedSeats.join('、')} 醉',
              style: AppTextStyles.caption.copyWith(color: gameColors.bloodBright),
            ),
          ),
          TextButton(onPressed: onReset, child: const Text('重置')),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.gameColors});

  final GameColors gameColors;

  @override
  Widget build(BuildContext context) {
    Widget dot(Reliability r) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle,
                size: 10, color: gameColors.ofReliability(r)),
            const SizedBox(width: 4),
            Text(r.nameCn, style: AppTextStyles.caption),
          ],
        );
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        dot(Reliability.verified),
        dot(Reliability.unverified),
        dot(Reliability.possiblyTainted),
        dot(Reliability.invalidated),
      ],
    );
  }
}

class _AuthorSection extends StatelessWidget {
  const _AuthorSection({
    required this.authorId,
    required this.authorNodes,
    required this.byId,
    required this.sandboxAssumed,
    required this.onToggleAssumeDrunk,
  });

  final int authorId;
  final List<InfoDependencyNode> authorNodes;
  final Map<int, Player> byId;
  final bool sandboxAssumed;
  final VoidCallback onToggleAssumeDrunk;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final author = byId[authorId];
    final persistedDrunk = author?.suspectedDrunk ?? false;
    // 作者当前是否被视为醉（持久 ∪ 沙盒）
    final authorDrunk = persistedDrunk || sandboxAssumed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: authorDrunk
            ? gameColors.reliabilityTainted.withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: authorDrunk
              ? gameColors.reliabilityTainted.withValues(alpha: 0.5)
              : gameColors.inkViolet.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _seatName(byId, authorId),
                  style: AppTextStyles.body,
                ),
              ),
              if (persistedDrunk)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '疑似醉（存档）',
                    style: AppTextStyles.caption
                        .copyWith(color: gameColors.reliabilityTainted),
                  ),
                ),
              FilterChip(
                label: const Text('假设醉'),
                selected: sandboxAssumed,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onToggleAssumeDrunk(),
              ),
            ],
          ),
          if (authorDrunk) ...[
            const SizedBox(height: 4),
            Text(
              '作者信息可能失效（醉/毒）',
              style: AppTextStyles.caption
                  .copyWith(color: gameColors.reliabilityTainted),
            ),
          ],
          const SizedBox(height: 8),
          for (final n in authorNodes) _NodeRow(node: n, byId: byId),
        ],
      ),
    );
  }
}

class _NodeRow extends StatelessWidget {
  const _NodeRow({required this.node, required this.byId});

  final InfoDependencyNode node;
  final Map<int, Player> byId;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    return InkWell(
      onTap: () => _showNodeDetail(context, node, byId, gameColors),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.circle,
                size: 12,
                color: gameColors.ofReliability(node.effectiveReliability),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('第${node.dayNumber}天 · ${node.summary}',
                      style: AppTextStyles.body),
                  if (node.references.playerIds.isNotEmpty ||
                      node.references.character != null) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final pid in node.references.playerIds)
                          _refChip('→ ${_seat(byId, pid)}', gameColors),
                        if (node.references.character != null)
                          _refChip(
                            '→ ${node.references.character!.nameCn}',
                            gameColors,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _refChip(String text, GameColors gameColors) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: gameColors.inkViolet.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(text, style: AppTextStyles.caption.copyWith(fontSize: 10)),
  );
}

void _showNodeDetail(
  BuildContext context,
  InfoDependencyNode node,
  Map<int, Player> byId,
  GameColors gameColors,
) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('${node.characterType.nameCn} · 第${node.dayNumber}天'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('作者：${_seatName(byId, node.authorId)}',
              style: AppTextStyles.body),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.circle,
                  size: 12,
                  color: gameColors.ofReliability(node.effectiveReliability)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  node.storedReliability != node.effectiveReliability
                      ? '可靠性：${node.storedReliability.nameCn} → ${node.effectiveReliability.nameCn}'
                      : '可靠性：${node.effectiveReliability.nameCn}',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 信息状态以 isTainted 为准（作者清醒但存档被毒时信息仍不可靠），
          // 作者清醒度单独列出，避免「作者清醒 → 信息可用」的矛盾表述。
          Text(
            node.isTainted ? '信息可能不可靠' : '信息可用',
            style: AppTextStyles.caption.copyWith(
              color: node.isTainted
                  ? gameColors.reliabilityTainted
                  : gameColors.trustConfirmedGood,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '作者：${node.authorAssumedDrunk ? '可能醉/毒' : '清醒'}',
            style: AppTextStyles.caption.copyWith(
              color: node.authorAssumedDrunk
                  ? gameColors.reliabilityTainted
                  : gameColors.inkViolet,
            ),
          ),
          if (node.references.playerIds.isNotEmpty ||
              node.references.character != null) ...[
            const SizedBox(height: 8),
            if (node.references.playerIds.isNotEmpty)
              Text(
                '引用玩家：${node.references.playerIds.map((id) => _seat(byId, id)).join('、')}',
                style: AppTextStyles.caption,
              ),
            if (node.references.character != null)
              Text(
                '引用角色：${node.references.character!.nameCn}',
                style: AppTextStyles.caption,
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

String _seat(Map<int, Player> byId, int id) {
  final p = byId[id];
  return p == null ? '$id 号' : '${p.seatNumber}号';
}

String _seatName(Map<int, Player> byId, int id) {
  final p = byId[id];
  return p == null ? '$id 号' : '${p.seatNumber}号 ${p.name}';
}
