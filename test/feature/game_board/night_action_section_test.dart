import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/night_action_section.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 不碰 DB 的假仓库（widget test 禁令）。
class _FakePlayerDetailRepository implements PlayerDetailRepository {
  int? lastPlayerId;
  Character? lastCharacter;
  bool? lastIsMine;
  Map<String, Object?>? lastPayload;

  @override
  Future<int> declareInfo({
    required int playerId,
    required int dayRecordId,
    required Character character,
    required Map<String, Object?> payload,
    bool isMine = false,
    int? dayNumber,
    int? gameId,
  }) async {
    lastPlayerId = playerId;
    lastCharacter = character;
    lastIsMine = isMine;
    lastPayload = payload;
    return 1;
  }

  @override
  Future<int> claimRole({
    required int playerId,
    required int dayRecordId,
    required Character character,
  }) async =>
      1;

  @override
  Future<int> setTrustLevel({
    required int gameId,
    required int playerId,
    required int day,
    required TrustLevel level,
  }) async =>
      1;

  @override
  Future<void> deleteDeclaration(int id) async {}

  @override
  Future<int> setSuspectedDrunk(int playerId, {required bool suspected}) async => 1;
}

class _FakeGameBoardNotifier extends GameBoardNotifier {
  _FakeGameBoardNotifier(super.ref, super.gameId) {
    // 第 2 天（后续夜，Monk 在夜序中）
    state = state.copyWith(currentDay: 2);
  }

  @override
  Future<int> ensureCurrentDayRecord() async => 1;

  @override
  Future<void> restoreState() async {
    // 跳过 DB IO（widget test 不碰真实 DB，#154 ISSUE-3）；保留构造设的 currentDay。
    state = state.copyWith(initialized: true);
  }
}

void main() {
  final players = [
    for (var i = 1; i <= 7; i++)
      Player(
        id: i,
        gameId: 1,
        name: '玩家$i',
        seatNumber: i,
        isAlive: true,
        abilityUsed: false, suspectedDrunk: false,
      ),
  ];

  late _FakePlayerDetailRepository repo;

  setUp(() => repo = _FakePlayerDetailRepository());

  /// 放大测试表面：列表懒构建，需容纳全部条目。
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget buildSection({
    required List<RoleClaim> claims,
    Character? myRole,
    int? myPlayerId,
    List<Player>? playersOverride,
  }) {
    final game = Game(
      id: 1,
      script: Script.troubleBrewing,
      playerCount: 7,
      status: GameStatus.ongoing,
      createdAt: DateTime(2026, 8, 12),
      helpLevel: HelpLevel.expert,
      myRole: myRole,
      myPlayerId: myPlayerId,
    );
    return ProviderScope(
      overrides: [
        gameByIdProvider(1).overrideWith((ref) => Stream.value(game)),
        gamePlayersProvider(1)
            .overrideWith((ref) => Stream.value(playersOverride ?? players)),
        gameBoardProvider(1)
            .overrideWith((ref) => _FakeGameBoardNotifier(ref, 1)),
        gameClaimsProvider(1).overrideWith((ref) => Stream.value(claims)),
        playerDetailRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SingleChildScrollView(child: NightActionSection(gameId: 1)),
        ),
      ),
    );
  }

  RoleClaim claim(int playerId, Character c) => RoleClaim(
        id: playerId,
        playerId: playerId,
        dayRecordId: 1,
        character: c,
        claimType: ClaimType.firstClaim,
      );

  testWidgets('他人声明 Monk → 录入入口出现，记录写 isMine=false', (tester) async {
    useTallSurface(tester);
    // 我是 1 号士兵（非夜行动者）；3 号声明僧侣
    await tester.pumpWidget(buildSection(
      claims: [claim(3, Character.monk)],
      myRole: Character.soldier,
      myPlayerId: 1,
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('僧侣（3号 玩家3）'), findsOneWidget);
    expect(find.text('夜间行动'), findsOneWidget);

    // Monk 不能选自己（3号）→ 候选无「3号 玩家3」；选 4 号保护
    await tester.tap(find.text('4号 玩家4'));
    await tester.pump();
    await tester.tap(find.text('记录'));
    await tester.pump();

    expect(repo.lastPlayerId, 3);
    expect(repo.lastCharacter, Character.monk);
    expect(repo.lastIsMine, isFalse);
    expect(repo.lastPayload, {'playerId': 4});
  });

  testWidgets('我座位 myRole=poisoner → 录入写 isMine=true 且标「我」',
      (tester) async {
    useTallSurface(tester);
    // 我是 5 号投毒者（无公开声明，走 myRole 注入）
    await tester.pumpWidget(buildSection(
      claims: const [],
      myRole: Character.poisoner,
      myPlayerId: 5,
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('投毒者（5号 玩家5 · 我）'), findsOneWidget);

    // Poisoner 可选任何人 → 选 2 号下毒
    await tester.tap(find.text('2号 玩家2'));
    await tester.pump();
    await tester.tap(find.text('记录'));
    await tester.pump();

    expect(repo.lastPlayerId, 5);
    expect(repo.lastCharacter, Character.poisoner);
    expect(repo.lastIsMine, isTrue);
    expect(repo.lastPayload, {'playerId': 2});
  });

  testWidgets('夜序聚合：投毒者条目在僧侣之前', (tester) async {
    useTallSurface(tester);
    // 5 号声明投毒者、3 号声明僧侣；后续夜序 Poisoner → Monk
    await tester.pumpWidget(buildSection(
      claims: [claim(5, Character.poisoner), claim(3, Character.monk)],
      myRole: Character.soldier,
      myPlayerId: 1,
    ));
    await tester.pumpAndSettle();

    final poisonerCenter = tester.getCenter(find.textContaining('投毒者（5号'));
    final monkCenter = tester.getCenter(find.textContaining('僧侣（3号'));
    // 投毒者在上（dy 更小）
    expect(poisonerCenter.dy, lessThan(monkCenter.dy));
  });

  testWidgets('无夜行动者声明 → 区段隐藏', (tester) async {
    useTallSurface(tester);
    // 仅声明士兵（非夜行动者）
    await tester.pumpWidget(buildSection(
      claims: [claim(2, Character.soldier)],
      myRole: Character.soldier,
      myPlayerId: 1,
    ));
    await tester.pumpAndSettle();

    expect(find.text('夜间行动'), findsNothing);
  });

  testWidgets('前夜已死亡的声称者不出现（死人不再行动）', (tester) async {
    useTallSurface(tester);
    // 3 号声明僧侣，但第 1 夜已死（currentDay=2）→ 不应出现
    final withDead = [
      for (final p in players)
        p.id == 3
            ? Player(
                id: 3,
                gameId: 1,
                name: '玩家3',
                seatNumber: 3,
                isAlive: false,
                abilityUsed: false, suspectedDrunk: false,
                deathDay: 1,
                deathCause: DeathCause.nightKill,
              )
            : p,
    ];
    await tester.pumpWidget(buildSection(
      claims: [claim(3, Character.monk)],
      myRole: Character.soldier,
      myPlayerId: 1,
      playersOverride: withDead,
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('僧侣（3号'), findsNothing);
    expect(find.text('夜间行动'), findsNothing);
  });
}
