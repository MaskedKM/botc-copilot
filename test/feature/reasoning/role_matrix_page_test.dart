import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/presentation/role_matrix_page.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// #138 drill-down：角色矩阵行头可点（直达玩家详情）。
  testWidgets('行头为可点 drill-down 目标（#138）', (tester) async {
    final game = Game(
      id: 1,
      script: Script.troubleBrewing,
      playerCount: 7,
      status: GameStatus.ongoing,
      createdAt: DateTime(2026, 8, 12),
      myRole: Character.empath,
      helpLevel: HelpLevel.expert,
    );
    final players = [
      Player(
        id: 1,
        gameId: 1,
        name: 'A',
        seatNumber: 1,
        isAlive: true,
        abilityUsed: false,
        suspectedDrunk: false,
        deathDay: null,
        deathCause: null,
      ),
      Player(
        id: 2,
        gameId: 1,
        name: 'B',
        seatNumber: 2,
        isAlive: true,
        abilityUsed: false,
        suspectedDrunk: false,
        deathDay: null,
        deathCause: null,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameByIdProvider(1).overrideWith((ref) => Stream.value(game)),
          gamePlayersProvider(1)
              .overrideWith((ref) => Stream.value(players)),
          gameClaimsProvider(1)
              .overrideWith((ref) => Stream.value(const <RoleClaim>[])),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const RoleMatrixPage(gameId: 1),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 行头「1A」渲染，且被 GestureDetector 包裹（drill-down 已接线）。
    final header = find.text('1A');
    expect(header, findsOneWidget);
    final gd = tester.widget<GestureDetector>(
      find.ancestor(of: header, matching: find.byType(GestureDetector)),
    );
    expect(gd.onTap, isNotNull);
  });
}
