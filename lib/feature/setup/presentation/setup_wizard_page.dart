import 'package:botc_copilot/core/router.dart';
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/setup/domain/setup_state.dart';
import 'package:botc_copilot/feature/setup/presentation/providers/setup_provider.dart';
import 'package:botc_copilot/feature/setup/presentation/widgets/confirm_step.dart';
import 'package:botc_copilot/feature/setup/presentation/widgets/player_count_step.dart';
import 'package:botc_copilot/feature/setup/presentation/widgets/role_step.dart';
import 'package:botc_copilot/feature/setup/presentation/widgets/script_step.dart';
import 'package:botc_copilot/feature/setup/presentation/widgets/seats_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 开局设置向导（issue #4）。
///
/// 五步：选剧本 → 选人数 → 排座位 → 选角色 → 确认开局。
/// 目标：玩家坐下后 2 分钟内完成。
class SetupWizardPage extends ConsumerStatefulWidget {
  /// 创建设置向导页。
  const SetupWizardPage({super.key});

  @override
  ConsumerState<SetupWizardPage> createState() => _SetupWizardPageState();
}

class _SetupWizardPageState extends ConsumerState<SetupWizardPage> {
  static const _steps = [
    ScriptStep(),
    PlayerCountStep(),
    SeatsStep(),
    RoleStep(),
    ConfirmStep(),
  ];

  Future<void> _onNext() async {
    final notifier = ref.read(setupProvider.notifier);
    final state = ref.read(setupProvider);
    if (state.step < SetupState.totalSteps - 1) {
      notifier.nextStep();
      return;
    }
    // 最后一步：提交并跳转对局主界面。
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await notifier.submit();
      router.go(AppRoutes.gameBoard);
    } on Exception {
      messenger.showSnackBar(const SnackBar(content: Text('创建对局失败，请重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(setupProvider.select((s) => s.step));
    final canProceed = ref.watch(setupProvider.select((s) => s.canProceed));
    final submitting =
        ref.watch(setupProvider.select((s) => s.submitting));
    final isLast = step == SetupState.totalSteps - 1;
    final gameColors = context.gameColors;

    return Scaffold(
      appBar: AppBar(title: const Text('开局设置')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (var i = 0; i < SetupState.totalSteps; i++) ...[
                    _StepDot(index: i, current: step),
                    if (i < SetupState.totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 0.5,
                          color: i < step
                              ? gameColors.goldBright
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Expanded(child: IndexedStack(index: step, children: _steps)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (step > 0)
                    TextButton(
                      onPressed: () =>
                          ref.read(setupProvider.notifier).previousStep(),
                      child: const Text('上一步'),
                    )
                  else
                    const SizedBox(width: 80),
                  const Spacer(),
                  FilledButton(
                    onPressed: canProceed && !submitting ? _onNext : null,
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLast ? '开始对局' : '下一步'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.current});

  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final reached = index <= current;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? gameColors.goldBright : Colors.transparent,
        border: Border.all(
          color: reached
              ? gameColors.goldBright
              : Theme.of(context).colorScheme.outline,
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${index + 1}',
        style: AppTextStyles.caption.copyWith(
          color: reached ? AppColors.textOnGold : AppColors.textSecondary,
        ),
      ),
    );
  }
}
