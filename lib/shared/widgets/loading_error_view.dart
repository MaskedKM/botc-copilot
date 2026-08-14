import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:flutter/material.dart';

/// 加载占位（spinner + 文案，#138）。
///
/// 替代裸 `CircularProgressIndicator`——加载态给用户明确反馈而非「转圈
/// 不知在等什么」。
class LoadingView extends StatelessWidget {
  /// 创建加载占位。
  const LoadingView({this.message = '加载中…', super.key});

  /// 文案（默认「加载中…」）。
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.caption
                .copyWith(color: context.gameColors.inkViolet),
          ),
        ],
      ),
    );
  }
}

/// 错误占位（图标 + 文案 + 重试，#138）。
///
/// 流错误原先被 `.valueOrNull ?? []` 静默吞为「空数据」，用户看到的是
/// 「无记录」而非「出错了」。此组件显式提示并提供重试（典型实现：
/// `ref.invalidate(provider)`）。
class ErrorRetryView extends StatelessWidget {
  /// 创建错误占位。
  const ErrorRetryView({this.message = '加载失败，请重试', this.onRetry, super.key});

  /// 错误文案。
  final String message;

  /// 重试回调（null 时不显示重试按钮）。
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 32, color: gameColors.blood),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: gameColors.inkViolet),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
            ),
          ],
        ],
      ),
    );
  }
}
