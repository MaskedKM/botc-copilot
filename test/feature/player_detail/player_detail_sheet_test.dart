import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
import 'package:botc_copilot/feature/game_board/data/poison_repository.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/data/behavior_note_repository.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/player_detail/presentation/player_detail_sheet.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 不碰 DB 的假仓库（widget test 禁令：FakeAsync 区域不能跑真实数据库 IO）。
class _FakePlayerDetailRepository implements PlayerDetailRepository {
  Character? claimedRole;
  TrustLevel? trustLevel;
  int claimCalls = 0;
  int trustCalls = 0;

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
  }) async =>
      1;

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
      ..trustCalls = 0;
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
  Widget buildSheet() {
    return ProviderScope(
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

  testWidgets('保存一次性提交角色/信任度/醉毒草稿', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(buildSheet());
    await tester.pump();

    await tester.tap(find.text('共情者')); // 角色草稿
    await tester.pump();
    await tester.tap(find.text('确信好人')); // 信任度草稿
    await tester.pump();
    await tester.tap(find.byType(SwitchListTile)); // 醉毒草稿
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
}
