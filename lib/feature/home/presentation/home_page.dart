import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/core/router.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/shared/widgets/loading_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 首页：对局存档列表（issue #9）。
///
/// 展示全部历史对局，支持继续/删除/新建。
class HomePage extends ConsumerWidget {
  /// 创建首页。
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(allGamesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('血染钟楼 · 对局')),
      body: gamesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetryView(
          onRetry: () => ref.invalidate(allGamesProvider),
        ),
        data: (games) {
          if (games.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('还没有对局', style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角开始你的第一局',
                    style: AppTextStyles.caption
                        .copyWith(color: context.gameColors.inkViolet),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) =>
                _GameCard(game: games[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.setup),
        icon: const Icon(Icons.add),
        label: const Text('新建对局'),
      ),
    );
  }
}

class _GameCard extends ConsumerWidget {
  const _GameCard({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameColors = context.gameColors;

    return Dismissible(
      key: ValueKey('game-${game.id}'),
      direction: DismissDirection.endToStart,
      // 删除在 confirmDismiss 内完成——成功才返回 true（卡片消失），失败返回
      // false（卡片复位）+ SnackBar，避免「视觉消失但 DB 行仍在」（#158 home-1）。
      confirmDismiss: (_) => _confirmAndDelete(context, ref),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: gameColors.blood.withValues(alpha: 0.2),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Icon(Icons.delete_outline, color: gameColors.blood),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          minTileHeight: 64,
          title: Text(
            '${game.script.nameCn} · ${game.playerCount} 人局',
            style: AppTextStyles.headline,
          ),
          subtitle: Text(
            '${game.myRole != null ? '我的角色：${game.myRole!.nameCn} · ' : ''}'
            '${game.createdAt.month}/${game.createdAt.day} '
            '${game.createdAt.hour.toString().padLeft(2, '0')}:'
            '${game.createdAt.minute.toString().padLeft(2, '0')}',
            style: AppTextStyles.caption,
          ),
          trailing: _StatusBadge(status: game.status),
          // 已结束对局亦可点进只读复盘（issue #134）。
          onTap: () => context.push(AppRoutes.gameBoard(game.id)),
        ),
      ),
    );
  }

  Future<bool> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除对局'),
        content: const Text('删除后该对局的所有记录将无法恢复，确认删除？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false; // 取消 → 不删除、卡片复位
    try {
      await ref.read(appDatabaseProvider).gamesDao.deleteGame(game.id);
      return true; // 成功 → 卡片消失
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
      }
      return false; // 失败 → 卡片复位（#158 home-1）
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final GameStatus status;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final (label, color) = switch (status) {
      GameStatus.ongoing => ('进行中', gameColors.goldBright),
      GameStatus.goodWin => ('善良获胜', gameColors.trustConfirmedGood),
      GameStatus.evilWin => ('邪恶获胜', gameColors.blood),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}
