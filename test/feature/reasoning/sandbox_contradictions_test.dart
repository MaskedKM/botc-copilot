import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/dependency_chain_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/contradiction.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 沙箱假设下的本地矛盾试算（#211 Part2 方案3）。
///
/// 核心断言：同一条 Empath 矛盾，基线报出、「假设作者醉」后消失——
/// 与依赖链视图同一假设语义（公理4 醉=毒=信息可能为假），且不动存档。
void main() {
  late ProviderContainer container;

  final players = [
    for (var i = 1; i <= 3; i++)
      Player(
        id: i,
        gameId: 1,
        name: '玩家$i',
        seatNumber: i,
        isAlive: true,
        abilityUsed: false,
        suspectedDrunk: false,
        fakeDead: false,
      ),
  ];

  RoleClaim claim(int id, int seat, Character c) => RoleClaim(
        id: id,
        playerId: seat,
        dayRecordId: 10,
        character: c,
        claimType: ClaimType.firstClaim,
      );

  final claims = [
    claim(1, 2, Character.empath), // 2 号 Empath，邻座 1/3
    claim(2, 1, Character.chef),
    claim(3, 3, Character.monk),
  ];
  final declarations = [
    InfoDeclaration(
      id: 1,
      playerId: 2,
      dayRecordId: 10,
      characterType: Character.empath,
      payloadJson: '{"value": 1}', // 邻座都声明好人 → 矛盾
      reliability: Reliability.unverified,
      isMine: false,
    ),
  ];

  setUp(() {
    container = ProviderContainer(
      overrides: [
        gameClaimsProvider(1).overrideWith((ref) => Stream.value(claims)),
        gameAllDeclarationsProvider(1)
            .overrideWith((ref) => Stream.value(declarations)),
        gameAllDaysProvider(1).overrideWith(
          (ref) => Stream.value([
            DayRecord(
              id: 10,
              gameId: 1,
              dayNumber: 2,
              nightDeathPlayerIds: null,
              // nightConfirmed=true：同时触发规则5 noDeathNight——它不受醉
              // 影响，正好用作「假设醉只消醉敏感矛盾」的对照。
              nightConfirmed: true,
              dayExecutionPlayerId: null,
              dayConfirmed: false,
              notes: '',
            ),
          ]),
        ),
        gamePlayersProvider(1)
            .overrideWith((ref) => Stream.value(players)),
        gameByIdProvider(1).overrideWith((ref) => Stream.value(null)),
      ],
    );
  });

  tearDown(() => container.dispose());

  /// 轮询直到 [ok]（流 provider 需真实事件循环周期落地）。
  Future<T> until<T>(T Function() read, bool Function(T) ok) async {
    for (var i = 0; i < 50; i++) {
      final v = read();
      if (ok(v)) return v;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('provider 未达到期望状态');
  }


  test('空假设短路：sandboxContradictions 返回空（页面隐藏卡片）', () {
    expect(
      container.read(sandboxContradictionsProvider(1)).contradictions,
      isEmpty,
    );
  });

  test('基线报 Empath 矛盾；假设作者醉后消失（两视图一致）', () async {
    final baseline = await until(
      () => container.read(contradictionsProvider(1)),
      (r) => !r.failed && r.contradictions.isNotEmpty,
    );
    // empathMismatch（醉敏感）+ noDeathNight（不受醉影响）
    expect(
      baseline.contradictions
          .map((c) => c.type)
          .contains(ContradictionType.empathMismatch),
      isTrue,
    );

    // 假设 2 号（Empath 作者）醉——不写存档，仅沙箱。共享流已由上面的
    // 基线轮询落地；空沙箱时 sandbox provider 短路返回空，无需预热。
    container
        .read(dependencySandboxProvider(1).notifier)
        .toggleAssumeDrunk(2);

    final assumed = await until(
      () => container.read(sandboxContradictionsProvider(1)),
      // 消失的是醉敏感的 empathMismatch；noDeathNight 保留
      (r) =>
          !r.failed &&
          !r.contradictions
              .any((c) => c.type == ContradictionType.empathMismatch),
    );
    expect(
      assumed.contradictions
          .map((c) => c.type)
          .contains(ContradictionType.noDeathNight),
      isTrue,
    );
  });

  test('假设无关玩家醉 → 矛盾保留（不误消）', () async {
    container
        .read(dependencySandboxProvider(1).notifier)
        .toggleAssumeDrunk(1);
    final assumed = await until(
      () => container.read(sandboxContradictionsProvider(1)),
      (r) => r.contradictions
          .any((c) => c.type == ContradictionType.empathMismatch),
    );
    expect(
      assumed.contradictions
          .map((c) => c.type)
          .contains(ContradictionType.empathMismatch),
      isTrue,
    );
  });

  test('沙箱不动存档：玩家 suspectedDrunk 保持 false', () async {
    container
        .read(dependencySandboxProvider(1).notifier)
        .toggleAssumeDrunk(2);
    await until(
      () => container.read(sandboxContradictionsProvider(1)),
      (r) => !r.failed && r.contradictions.isEmpty,
    );
    // provider 纯读——players 流本就是内存 fixture，断言其未被篡改。
    expect(players[1].suspectedDrunk, isFalse);
  });
}
