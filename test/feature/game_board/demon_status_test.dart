import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/domain/demon_status.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// DemonStatusResolver 矩阵（#208 design v2）。
///
/// 官方语义：人头邪恶胜前提「恶魔活到只剩 2 人」；恶魔死亡 → SW 检查 →
/// 无 SW 按死亡方式：处决/白天击杀仅 SW 可继承（善良胜）；夜死自杀
/// starpass 强制传存活爪牙（无爪牙可传 → 善良胜）。
void main() {
  // 7 人：id = 座位号，默认全员存活。
  List<Player> ps({
    Set<int> dead = const {},
    Map<int, DeathCause> causes = const {},
  }) =>
      [
        for (var i = 1; i <= 7; i++)
          Player(
            id: i,
            gameId: 1,
            name: '玩家$i',
            seatNumber: i,
            isAlive: !dead.contains(i),
            abilityUsed: false,
            suspectedDrunk: false,
            fakeDead: false,
            deathDay: dead.contains(i) ? 2 : null,
            deathCause: causes[i],
          ),
      ];

  // 揭示声明（id 升序语义由调用方保证，测试内直接构造）。
  RoleClaim reveal(int id, int playerId, Character c) => RoleClaim(
        id: id,
        playerId: playerId,
        dayRecordId: 1,
        character: c,
        claimType: ClaimType.revealedOnDeath,
      );

  DemonInheritance inh(int id, int from, int? to) => DemonInheritance(
        id: id,
        gameId: 1,
        dayNumber: 2,
        fromPlayerId: from,
        toPlayerId: to,
        trigger: SuccessionTrigger.suicideByImp,
        createdAt: DateTime(2026, 8, 14),
      );

  DemonStatus resolve({
    required List<Player> players,
    Character? myRole,
    int? myPlayerId,
    List<RoleClaim> claims = const [],
    List<DemonInheritance> inheritances = const [],
    Set<int> aliveMinionCandidates = const {},
  }) =>
      DemonStatusResolver.resolve(
        players: players,
        myRole: myRole,
        myPlayerId: myPlayerId,
        claims: claims,
        inheritances: inheritances,
        aliveMinionCandidates: aliveMinionCandidates,
      );

  group('优先级 1-2：我的恶魔 / 传承继承人', () {
    test('我是恶魔且存活 → alive', () {
      expect(
        resolve(
          players: ps(),
          myRole: Character.imp,
          myPlayerId: 3,
        ),
        DemonStatus.alive,
      );
    });

    test('我是恶魔但已死（无传承无揭示）→ 按我的死因分流：处决 → dead',
        () {
      expect(
        resolve(
          players: ps(dead: {3}, causes: {3: DeathCause.execution}),
          myRole: Character.imp,
          myPlayerId: 3,
        ),
        DemonStatus.dead,
      );
    });

    test('我是恶魔夜死（自杀）且有存活爪牙候选 → alive（starpass 强制）',
        () {
      expect(
        resolve(
          players: ps(dead: {3}, causes: {3: DeathCause.nightKill}),
          myRole: Character.imp,
          myPlayerId: 3,
          aliveMinionCandidates: {5},
        ),
        DemonStatus.alive,
      );
    });

    test('我是恶魔夜死且无爪牙候选 → dead（无爪牙可传）', () {
      expect(
        resolve(
          players: ps(dead: {3}, causes: {3: DeathCause.nightKill}),
          myRole: Character.imp,
          myPlayerId: 3,
        ),
        DemonStatus.dead,
      );
    });

    test('最近传承继承人存活 → alive', () {
      expect(
        resolve(
          players: ps(dead: {3}),
          inheritances: [inh(1, 3, 5)],
        ),
        DemonStatus.alive,
      );
    });

    test('继承人已死且无更新传承 → dead（传承记录本身即恶魔事实）', () {
      expect(
        resolve(
          players: ps(dead: {3, 5}),
          inheritances: [inh(1, 3, 5)],
        ),
        DemonStatus.dead,
      );
    });

    test('多代传承：旧继承人死、新继承人活 → alive（取最新）', () {
      expect(
        resolve(
          players: ps(dead: {3, 5}),
          inheritances: [inh(1, 3, 5), inh(2, 5, 6)],
        ),
        DemonStatus.alive,
      );
    });

    test('继承人未知（null）的传承 = 传承已发生 → alive（恶魔身份未知）',
        () {
      expect(
        resolve(
          players: ps(dead: {3}, causes: {3: DeathCause.execution}),
          inheritances: [inh(1, 3, null)],
          claims: [reveal(1, 3, Character.imp)],
        ),
        DemonStatus.alive,
      );
    });
  });

  group('优先级 3：死亡揭示按死因分流（v2 核心）', () {
    test('揭示恶魔死于处决 → dead（此路径仅 SW 可继承）', () {
      expect(
        resolve(
          players: ps(dead: {3}, causes: {3: DeathCause.execution}),
          claims: [reveal(1, 3, Character.imp)],
        ),
        DemonStatus.dead,
      );
    });

    test('揭示恶魔死于 Slayer（other）→ dead', () {
      expect(
        resolve(
          players: ps(dead: {3}, causes: {3: DeathCause.other}),
          claims: [reveal(1, 3, Character.imp)],
        ),
        DemonStatus.dead,
      );
    });

    test('揭示恶魔夜死 + 有存活爪牙候选 → alive（starpass 强制推断）', () {
      expect(
        resolve(
          players: ps(dead: {3}, causes: {3: DeathCause.nightKill}),
          claims: [reveal(1, 3, Character.imp)],
          aliveMinionCandidates: {6},
        ),
        DemonStatus.alive,
      );
    });

    test('揭示恶魔夜死 + 无爪牙候选 → dead', () {
      expect(
        resolve(
          players: ps(dead: {3}, causes: {3: DeathCause.nightKill}),
          claims: [reveal(1, 3, Character.imp)],
        ),
        DemonStatus.dead,
      );
    });

    test('揭示非恶魔（爪牙）不参与判定 → unknown', () {
      expect(
        resolve(
          players: ps(dead: {3}, causes: {3: DeathCause.execution}),
          claims: [reveal(1, 3, Character.poisoner)],
        ),
        DemonStatus.unknown,
      );
    });

    test('旧数据无死因 → unknown（保守，走人头候选）', () {
      expect(
        resolve(
          players: ps(dead: {3}),
          claims: [reveal(1, 3, Character.imp)],
        ),
        DemonStatus.unknown,
      );
    });
  });

  group('优先级 4：无信息', () {
    test('无任何恶魔线索 → unknown（维持现状 EvilWinCandidate）', () {
      expect(resolve(players: ps()), DemonStatus.unknown);
    });

    test('好人 myRole 不影响判定 → unknown', () {
      expect(
        resolve(players: ps(), myRole: Character.empath, myPlayerId: 2),
        DemonStatus.unknown,
      );
    });
  });
}
