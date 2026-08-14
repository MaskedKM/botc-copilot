import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/ghost_vote_tracker.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 纯参数 widget，无需 provider override（AGENTS.md：widget test 不碰 DB）。
Player _p(int id, int seat, String name, {bool alive = false}) => Player(
      id: id,
      gameId: 1,
      name: name,
      seatNumber: seat,
      isAlive: alive,
      abilityUsed: false,
      suspectedDrunk: false,
      deathDay: alive ? null : 2,
      deathCause: alive ? null : DeathCause.nightKill,
    );

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('无死亡玩家 → 静默不渲染', (tester) async {
    await tester.pumpWidget(
      wrap(const GhostVoteTracker(deadPlayers: [], allNominations: [])),
    );
    await tester.pump();
    expect(find.textContaining('死票追踪'), findsNothing);
  });

  testWidgets('死票未用/已用分组展示（座位序）', (tester) async {
    // 座位倒挂：id3→座位1、id1→座位7，展示须按座位序。
    final nomination = Nomination(
      id: 1,
      gameId: 1,
      dayRecordId: 1,
      nominatorPlayerId: 5,
      nomineePlayerId: 4,
      voteResultJson:
          '[{"playerId":1,"vote":"forVote","isDeadVote":true}]',
      passed: false,
    );
    await tester.pumpWidget(
      wrap(GhostVoteTracker(
        deadPlayers: [_p(1, 7, 'A'), _p(3, 1, 'C')],
        allNominations: [nomination],
      )),
    );
    await tester.pump();
    expect(find.textContaining('死票追踪'), findsOneWidget);
    // 未用：C（座位1）；已用：A（座位7）
    expect(find.textContaining('尚有死票未用：1号'), findsOneWidget);
    expect(find.textContaining('已用完：7号'), findsOneWidget);
    expect(find.byType(Chip), findsOneWidget);
  });

  testWidgets('全部用完 → 提示用尽', (tester) async {
    final nomination = Nomination(
      id: 1,
      gameId: 1,
      dayRecordId: 1,
      nominatorPlayerId: 5,
      nomineePlayerId: 4,
      voteResultJson:
          '[{"playerId":2,"vote":"forVote","isDeadVote":true}]',
      passed: false,
    );
    await tester.pumpWidget(
      wrap(GhostVoteTracker(
        deadPlayers: [_p(2, 2, 'B')],
        allNominations: [nomination],
      )),
    );
    await tester.pump();
    expect(find.textContaining('均已用完'), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
  });
}
