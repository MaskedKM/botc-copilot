import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/contradiction.dart';
import 'package:botc_copilot/feature/reasoning/presentation/contradiction_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Player _p(int id, int seat, String name) => Player(
      id: id,
      gameId: 1,
      name: name,
      seatNumber: seat,
      isAlive: true,
      abilityUsed: false,
      suspectedDrunk: false,
      fakeDead: false,
      deathDay: null,
      deathCause: null,
    );

void main() {
  /// #270⑤：源流未就绪的半加载帧须显示加载态，不能闪「未发现矛盾标记」。
  testWidgets('源流未就绪 → 加载态而非「未发现矛盾」（#270⑤）', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 全部源流空（永不出数据）→ isLoading 恒真，模拟半加载窗口
          gameClaimsProvider(1).overrideWith((ref) => const Stream.empty()),
          gameAllDeclarationsProvider(1)
              .overrideWith((ref) => const Stream.empty()),
          gameAllDaysProvider(1).overrideWith((ref) => const Stream.empty()),
          gameSuccessionsProvider(1)
              .overrideWith((ref) => const Stream.empty()),
          gamePlayersProvider(1).overrideWith((ref) => const Stream.empty()),
          gameByIdProvider(1).overrideWith((ref) => const Stream.empty()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SingleChildScrollView(child: ContradictionPanel(gameId: 1)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('未发现矛盾标记'), findsNothing);
  });

  /// #138 drill-down：矛盾 tile 展开后渲染可点玩家 chip（直达玩家详情）。
  testWidgets('矛盾 tile 展开后显示涉及玩家的可点 chip（#138）', (tester) async {
    final players = [_p(1, 1, 'A'), _p(2, 2, 'B')];
    final contradiction = Contradiction(
      type: ContradictionType.duplicateRoleClaim,
      playerIds: const [1, 2],
      description: '1号 A、2号 B 均指向 厨师。',
      severity: ContradictionSeverity.warning,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contradictionsProvider(1)
              .overrideWith((ref) => ContradictionResult([contradiction])),
          gamePlayersProvider(1).overrideWith((ref) => Stream.value(players)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SingleChildScrollView(child: ContradictionPanel(gameId: 1)),
          ),
        ),
      ),
    );
    await tester.pump();

    // 展开矛盾 tile
    await tester.tap(find.text('角色重复声明'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // 展开动画

    // 两位涉及玩家均渲染为 ActionChip
    expect(find.text('1号 A'), findsOneWidget);
    expect(find.text('2号 B'), findsOneWidget);
  });

  testWidgets('无 playerIds 的矛盾（如无人死亡夜晚）不渲染 chip', (tester) async {
    final contradiction = Contradiction(
      type: ContradictionType.noDeathNight,
      playerIds: const [],
      description: '第 2 天夜晚无人死亡。',
      severity: ContradictionSeverity.info,
      dayNumber: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contradictionsProvider(1)
              .overrideWith((ref) => ContradictionResult([contradiction])),
          gamePlayersProvider(1)
              .overrideWith((ref) => Stream.value(const <Player>[])),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SingleChildScrollView(child: ContradictionPanel(gameId: 1)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('无人死亡夜晚'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 无 chip（ActionChip 不在树中）
    expect(find.byType(ActionChip), findsNothing);
  });

  // #211：引擎异常兜底后须展示降级横幅，而非「未发现矛盾」的空成功。
  testWidgets('引擎 failed 时展示降级横幅而非空成功（#211）', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contradictionsProvider(1)
              .overrideWith((ref) => const ContradictionResult([], failed: true)),
          gamePlayersProvider(1)
              .overrideWith((ref) => Stream.value(const <Player>[])),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SingleChildScrollView(child: ContradictionPanel(gameId: 1)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('推理引擎暂不可用，矛盾检测已暂停。请重启或反馈问题。'),
        findsOneWidget);
    // 不应误显示「未发现矛盾标记」
    expect(find.text('未发现矛盾标记'), findsNothing);
  });
}
