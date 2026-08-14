import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/elimination_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/elimination_board.dart';
import 'package:botc_copilot/feature/reasoning/presentation/elimination_board_panel.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// widget test 用 provider override，不碰真实 DB（drift stream 会留
// pending timer——AGENTS.md 测试策略）。
Player _player(int id, int seat, String name, {bool alive = true}) => Player(
      id: id,
      gameId: 1,
      name: name,
      seatNumber: seat,
      isAlive: alive,
      abilityUsed: false,
      suspectedDrunk: false,
      deathDay: alive ? null : 1,
      deathCause: alive ? null : DeathCause.nightKill,
    );

void main() {
  final players = [
    for (var i = 1; i <= 7; i++) _player(i, i, 'P$i'),
  ];

  Widget pumpBoard(EliminationBoard? board) => ProviderScope(
        overrides: [
          eliminationBoardProvider(1).overrideWith((ref) => board),
          gamePlayersProvider.overrideWith(
            (ref, gameId) => Stream.value(players),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: EliminationBoardPanel(gameId: 1)),
          ),
        ),
      );

  testWidgets('基础渲染：标题/上下界/候选 chips', (tester) async {
    final board = EliminationEngine.evaluate(
      players: players,
      setup: PlayerSetup.forCount(7),
      confirmedRoles: const {},
      labelFor: (id) => '$id号 P$id',
    );
    await tester.pumpWidget(pumpBoard(board));
    await tester.pump();

    expect(find.text('排除法棋盘（自动演绎）'), findsOneWidget);
    expect(find.textContaining('存活邪恶 2'), findsOneWidget);
    // 7 名候选全部渲染
    for (var i = 1; i <= 7; i++) {
      expect(find.text('$i号 P$i'), findsOneWidget);
    }
    expect(find.textContaining('共 7 名候选'), findsOneWidget);
  });

  testWidgets('board 为 null → 静默不渲染', (tester) async {
    await tester.pumpWidget(pumpBoard(null));
    await tester.pump();
    expect(find.byType(EliminationBoardPanel), findsOneWidget);
    expect(find.text('排除法棋盘（自动演绎）'), findsNothing);
  });

  testWidgets('现任恶魔确认 → 显示确认行，无候选 chips', (tester) async {
    final board = EliminationEngine.evaluate(
      players: players,
      setup: PlayerSetup.forCount(7),
      confirmedRoles: const {},
      successions: [
        DemonInheritance(
          id: 1,
          gameId: 1,
          dayNumber: 2,
          fromPlayerId: 7,
          toPlayerId: 3,
          trigger: SuccessionTrigger.scarletWoman,
          createdAt: DateTime(2026, 8, 14),
        ),
      ],
      labelFor: (id) => '$id号 P$id',
    );
    await tester.pumpWidget(pumpBoard(board));
    await tester.pump();

    expect(find.textContaining('现任恶魔已确认：3号 P3'), findsOneWidget);
    expect(find.textContaining('名候选'), findsNothing);
  });

  testWidgets('弱排除与收缩结论渲染', (tester) async {
    final board = EliminationEngine.evaluate(
      players: players,
      setup: PlayerSetup.forCount(7),
      confirmedRoles: const {
        1: Character.monk,
        2: Character.chef,
        3: Character.empath,
        4: Character.fortuneTeller,
      },
      // 1-4 号需要死亡才是合法揭示：重造玩家表。
      labelFor: (id) => '$id号 P$id',
    );
    // 直接手工构造以精确控制字段（引擎构造需配套死亡状态）。
    final manual = EliminationBoard(
      confirmedGood: const {
        1: [Deduction(source: DeductionSource.deathReveal, description: '死亡揭示为僧侣（镇民）')],
      },
      confirmedEvil: const {
        6: [Deduction(source: DeductionSource.evilCountForcing, description: '收缩')],
        7: [Deduction(source: DeductionSource.evilCountForcing, description: '收缩')],
      },
      knownMinionIds: const {},
      confirmedDemonPlayerId: null,
      confirmedDemonReason: null,
      forcedEvilRemaining: const {6, 7},
      demonCandidates: const [2, 3, 4, 5, 6, 7],
      weakDemonExclusions: const {
        2: [Deduction(source: DeductionSource.fortuneTellerNo, description: '读否')],
      },
      minAliveEvil: 2,
      maxAliveEvil: 2,
      anomalies: const ['确认好人过多：测试'],
    );
    await tester.pumpWidget(pumpBoard(manual));
    await tester.pump();

    expect(
      find.textContaining('计数收缩：6号 P6、7号 P7 即全部存活邪恶'),
      findsOneWidget,
    );
    expect(find.textContaining('被信息弱排除'), findsOneWidget);
    expect(find.textContaining('确认好人过多：测试'), findsOneWidget);
    expect(find.text('确认好人（1）'), findsOneWidget);
    expect(find.text('确认邪恶（2）'), findsOneWidget);
  });

  testWidgets('展开确认好人 → 显示依据', (tester) async {
    final board = EliminationEngine.evaluate(
      players: players,
      setup: PlayerSetup.forCount(7),
      confirmedRoles: const {},
      myPlayerId: 5,
      myRole: Character.empath,
      labelFor: (id) => '$id号 P$id',
    );
    await tester.pumpWidget(pumpBoard(board));
    await tester.pump();

    await tester.tap(find.text('确认好人（1）'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('我的真实角色'), findsOneWidget);
  });
}
