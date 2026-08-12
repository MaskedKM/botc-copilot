import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/data/poison_repository.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/data/behavior_note_repository.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/player_detail/presentation/player_detail_sheet.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 不碰 DB 的假仓库（widget test 禁令：FakeAsync 区域不能跑真实数据库 IO）。
class _FakePlayerDetailRepository implements PlayerDetailRepository {
  Character? claimedRole;
  TrustLevel? trustLevel;
  int claimCalls = 0;
  int trustCalls = 0;
  bool? lastDeclareIsMine;
  int declareCalls = 0;
  int drunkCalls = 0;
  bool? lastSuspectedDrunk;

  @override
  Future<int> claimRole({
    required int playerId,
    required int dayRecordId,
    required Character character,
  }) async {
    claimCalls++;
    claimedRole = character;
    return 1;
  }

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
    declareCalls++;
    lastDeclareIsMine = isMine;
    return 1;
  }

  @override
  Future<int> setTrustLevel({
    required int gameId,
    required int playerId,
    required int day,
    required TrustLevel level,
  }) async {
    trustCalls++;
    trustLevel = level;
    return 1;
  }

  @override
  Future<void> deleteDeclaration(int id) async {}

  @override
  Future<int> setSuspectedDrunk(int playerId, {required bool suspected}) async {
    drunkCalls++;
    lastSuspectedDrunk = suspected;
    return 1;
  }
}

class _FakePoisonRepository implements PoisonRepository {
  int toggleCalls = 0;

  @override
  Future<void> toggleStatus({
    required int gameId,
    required int playerId,
    required int dayNumber,
    PoisonSource source = PoisonSource.poisoner,
  }) async {
    toggleCalls++;
  }

  @override
  Future<bool> isTainted({
    required int gameId,
    required int playerId,
    required int dayNumber,
  }) async =>
      false;
}

/// 不碰 DB 的 GameBoardNotifier（currentDay 固定 1，dayRecordId 固定 1）。
class _FakeGameBoardNotifier extends GameBoardNotifier {
  _FakeGameBoardNotifier(super.ref, super.gameId);

  @override
  Future<int> ensureCurrentDayRecord() async => 1;
}

void main() {
  final game = Game(
    id: 1,
    script: Script.troubleBrewing,
    playerCount: 7,
    status: GameStatus.ongoing,
    createdAt: DateTime(2026, 8, 12),
    helpLevel: HelpLevel.expert, // 关掉 HelpTooltip，减少干扰
    myRole: Character.empath,
  );

  final me = Player(
    id: 1,
    gameId: 1,
    name: 'A',
    seatNumber: 1,
    isAlive: true,
    abilityUsed: false, suspectedDrunk: false,
    deathDay: null,
    deathCause: null,
  );

  final detailRepo = _FakePlayerDetailRepository();
  final poisonRepo = _FakePoisonRepository();

  setUp(() {
    detailRepo
      ..claimedRole = null
      ..trustLevel = null
      ..claimCalls = 0
      ..trustCalls = 0
      ..declareCalls = 0
      ..lastDeclareIsMine = null
      ..drunkCalls = 0
      ..lastSuspectedDrunk = null;
    poisonRepo.toggleCalls = 0;
  });

  /// 放大测试表面：弹层内容是一个长 ListView（懒构建），
  /// 默认 800×600 下底部保存按钮不在树中。
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// 默认：无声明 / 无信任记录 / 无毒标记。
  /// [myPlayerId] 模拟「我的座位」（issue #105）：设为 me.id 时点自己座位
  /// 应识别「这是我」并以真实角色录入。
  /// [myRole] 覆盖我的真实角色（默认沿用顶层 game 的 empath）。
  /// [suspectedDrunk] 模拟玩家已被标「疑似醉汉」（#109，测 overlay 显示）。
  /// [declarations] 覆盖已录入信息（默认空）。
  Widget buildSheet({
    int? myPlayerId,
    Character? myRole,
    bool suspectedDrunk = false,
    List<InfoDeclaration> declarations = const [],
  }) {
    final g = game.copyWith(
      myPlayerId: Value(myPlayerId),
      myRole: Value(myRole ?? game.myRole),
    );
    return ProviderScope(
      overrides: [
        gameByIdProvider(1).overrideWith((ref) => Stream.value(g)),
        gamePlayersProvider(1).overrideWith(
          (ref) => Stream.value([me.copyWith(suspectedDrunk: suspectedDrunk)]),
        ),
        gameBoardProvider(1)
            .overrideWith((ref) => _FakeGameBoardNotifier(ref, 1)),
        playerClaimsProvider(1)
            .overrideWith((ref) => Stream.value(const <RoleClaim>[])),
        playerDeclarationsProvider(1)
            .overrideWith((ref) => Stream.value(declarations)),
        latestTrustLevelsProvider(1)
            .overrideWith((ref) => Stream.value(const <int, TrustLevel>{})),
        gamePoisonStatusesProvider(1)
            .overrideWith((ref) => Stream.value(const <PoisonStatus>[])),
        playerDayNotesProvider((1, 1))
            .overrideWith((ref) => Stream.value(const <BehaviorNote>[])),
        playerDetailRepositoryProvider.overrideWithValue(detailRepo),
        poisonRepositoryProvider.overrideWithValue(poisonRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: PlayerDetailSheet(gameId: 1, player: me)),
      ),
    );
  }

  testWidgets('草稿改动不立即写库，保存按钮随 dirty 启用', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(buildSheet());
    await tester.pump();

    // 初始无修改 → 保存禁用
    final saveBefore = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveBefore.onPressed, isNull);

    // 选一个角色（草稿）→ 不写库，按钮启用
    await tester.tap(find.text('共情者'));
    await tester.pump();
    expect(detailRepo.claimCalls, 0);

    final saveAfter = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveAfter.onPressed, isNotNull);
  });

  testWidgets('保存一次性提交角色/信任度/毒草稿', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(buildSheet());
    await tester.pump();

    await tester.tap(find.text('共情者')); // 角色草稿
    await tester.pump();
    await tester.tap(find.text('确信好人')); // 信任度草稿
    await tester.pump();
    await tester.tap(find.text('标记为可能被毒（第 1 天）')); // 毒草稿（#109 拆分）
    await tester.pump();

    // 草稿阶段均不写库
    expect(detailRepo.claimCalls, 0);
    expect(detailRepo.trustCalls, 0);
    expect(poisonRepo.toggleCalls, 0);

    await tester.tap(find.text('保存'));
    await tester.pump(); // _save 的 async 间隙
    await tester.pump(); // SnackBar 出现

    expect(detailRepo.claimCalls, 1);
    expect(detailRepo.claimedRole, Character.empath);
    expect(detailRepo.trustCalls, 1);
    expect(detailRepo.trustLevel, TrustLevel.confirmedGood);
    expect(poisonRepo.toggleCalls, 1);
    expect(find.text('已保存'), findsOneWidget);
  });

  testWidgets('未保存修改时返回 → 弹丢弃确认', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameByIdProvider(1).overrideWith((ref) => Stream.value(game)),
          gamePlayersProvider(1)
              .overrideWith((ref) => Stream.value([me])),
          gameBoardProvider(1)
              .overrideWith((ref) => _FakeGameBoardNotifier(ref, 1)),
          playerClaimsProvider(1)
              .overrideWith((ref) => Stream.value(const <RoleClaim>[])),
          playerDeclarationsProvider(1)
              .overrideWith((ref) => Stream.value(const <InfoDeclaration>[])),
          latestTrustLevelsProvider(1).overrideWith(
            (ref) => Stream.value(const <int, TrustLevel>{}),
          ),
          gamePoisonStatusesProvider(1)
              .overrideWith((ref) => Stream.value(const <PoisonStatus>[])),
          playerDayNotesProvider((1, 1))
              .overrideWith((ref) => Stream.value(const <BehaviorNote>[])),
          playerDetailRepositoryProvider.overrideWithValue(detailRepo),
          poisonRepositoryProvider.overrideWithValue(poisonRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () =>
                    PlayerDetailSheet.show(context, gameId: 1, player: me),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // 弹层动画

    // 做一处草稿修改
    await tester.tap(find.text('共情者'));
    await tester.pump();

    // 系统返回 → PopScope 拦截 → 丢弃确认 dialog
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('丢弃修改？'), findsOneWidget);

    // 确认丢弃 → 弹层关闭，且不写库
    await tester.tap(find.text('丢弃'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('丢弃修改？'), findsNothing);
    expect(detailRepo.claimCalls, 0);
  });

  // issue #105：点自己座位应识别「这是我」，以真实角色直接录入信息。
  testWidgets('我座位：识别这是我，直接以真实角色录入（无需声明）', (tester) async {
    useTallSurface(tester);
    // myPlayerId = me.id → 点 me 座位 = 点自己
    await tester.pumpWidget(buildSheet(myPlayerId: me.id));
    await tester.pump();

    // 头部标识真实角色（私密）
    expect(find.text('这是我 · 真实角色：共情者'), findsOneWidget);
    // 信息区直接出现（无需先声明角色）——核心修复点
    expect(find.text('共情者 的信息'), findsOneWidget);
    // 角色声明区对我座位隐藏（不要求重复声明）
    expect(find.text('角色声明'), findsNothing);
  });

  testWidgets('我座位录入信息传 isMine=true', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(buildSheet(myPlayerId: me.id));
    await tester.pump();

    // Empath 数字输入的「记录」按钮（默认值 0）
    await tester.tap(find.text('记录'));
    await tester.pump(); // declareInfo async 间隙
    await tester.pump();

    expect(detailRepo.declareCalls, 1);
    expect(detailRepo.lastDeclareIsMine, isTrue);
    expect(find.text('我的信息已记录'), findsOneWidget);
  });

  testWidgets('我座位：一次性能力按真实角色显示（myRole=slayer）', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(buildSheet(myPlayerId: me.id, myRole: Character.slayer));
    await tester.pump();

    // 能力区按真实角色（猎杀者）显示，无需公开声明
    expect(find.text('一次性能力 · 猎杀者'), findsOneWidget);
  });

  testWidgets('他人座位行为不变：仍要求先声明角色', (tester) async {
    useTallSurface(tester);
    // myPlayerId=null → me 不是「我」
    await tester.pumpWidget(buildSheet());
    await tester.pump();

    expect(find.text('这是我 · 真实角色：共情者'), findsNothing);
    expect(find.text('角色声明'), findsOneWidget);
    // 未声明时不显示信息录入区
    expect(find.text('共情者 的信息'), findsNothing);
    expect(find.text('先声明角色，再录入该角色的信息。'), findsOneWidget);
  });

  testWidgets('疑似醉汉整局开关：草稿→保存提交 setSuspectedDrunk（#109）',
      (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(buildSheet());
    await tester.pump();

    // 两个 SwitchListTile（毒 + 醉）都应出现，文案区分
    expect(find.text('标记为可能被毒（第 1 天）'), findsOneWidget);
    expect(find.text('怀疑是醉汉'), findsOneWidget);

    // 草稿阶段不写库
    expect(detailRepo.drunkCalls, 0);

    await tester.tap(find.text('怀疑是醉汉'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump();

    expect(detailRepo.drunkCalls, 1);
    expect(detailRepo.lastSuspectedDrunk, isTrue);
  });

  testWidgets('疑似醉汉 → 信息圆点叠加为被污染色（#109 overlay）',
      (tester) async {
    useTallSurface(tester);
    final decl = InfoDeclaration(
      id: 1,
      playerId: me.id,
      dayRecordId: 1,
      characterType: Character.chef,
      payloadJson: '{"value": 1}',
      reliability: Reliability.unverified,
      isMine: false,
    );
    // 被疑醉：圆点应取 reliabilityTainted 色（overlay 把 unverified 升级为 tainted）
    await tester.pumpWidget(
      buildSheet(suspectedDrunk: true, declarations: [decl]),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(); // 等 gamePlayers / declarations 流产出
    final gc = Theme.of(tester.element(find.byIcon(Icons.circle)))
        .extension<GameColors>()!;
    final dot = tester.widget<Icon>(find.byIcon(Icons.circle));
    expect(dot.color, gc.reliabilityTainted);
    // 与未验证色不同（紫 vs 橙），overlay 可视
    expect(gc.reliabilityUnverified, isNot(gc.reliabilityTainted));
  });
}
