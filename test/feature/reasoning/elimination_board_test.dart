import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/reasoning/domain/elimination_board.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

Player _player(
  int id,
  int seat, {
  int? deathDay,
  DeathCause? deathCause,
}) =>
    Player(
      id: id,
      gameId: 1,
      name: 'P$id',
      seatNumber: seat,
      isAlive: deathDay == null,
      abilityUsed: false,
      suspectedDrunk: false,
      deathDay: deathDay,
      deathCause: deathCause ??
          (deathDay == null ? null : DeathCause.nightKill),
    );

InfoDeclaration _infoDecl(
  int playerId,
  Character type,
  String payloadJson, {
  int dayRecordId = 1,
  Reliability reliability = Reliability.unverified,
}) =>
    InfoDeclaration(
      id: playerId,
      playerId: playerId,
      dayRecordId: dayRecordId,
      characterType: type,
      payloadJson: payloadJson,
      reliability: reliability,
      isMine: false,
    );

DemonInheritance _succession(int id, int from, int? to, {int day = 2}) =>
    DemonInheritance(
      id: id,
      gameId: 1,
      dayNumber: day,
      fromPlayerId: from,
      toPlayerId: to,
      trigger: to == null
          ? SuccessionTrigger.suicideByImp
          : SuccessionTrigger.scarletWoman,
      createdAt: DateTime(2026, 8, 14),
    );

void main() {
  // 7 人局：TF=5 / 外=0 / 爪=1 / 恶=1（E=2）。
  final setup = PlayerSetup.forCount(7);
  String label(int id) => '$id号';

  EliminationBoard evaluate({
    required Map<int, Player> players,
    Map<int, Character> confirmedRoles = const {},
    List<DemonInheritance> successions = const [],
    Set<int> privateMinionIds = const {},
    List<InfoDeclaration> declarations = const [],
    Map<int, int> dayRecordToDayNumber = const {},
    int? myPlayerId,
    Character? myRole,
  }) =>
      EliminationEngine.evaluate(
        players: players.values.toList(),
        setup: setup,
        confirmedRoles: confirmedRoles,
        successions: successions,
        privateMinionIds: privateMinionIds,
        declarations: declarations,
        dayRecordToDayNumber: dayRecordToDayNumber,
        myPlayerId: myPlayerId,
        myRole: myRole,
        labelFor: label,
      );

  group('确认层', () {
    test('死亡揭示善良 → confirmedGood（含 Drunk/Recluse 等外来者）', () {
      final board = evaluate(
        players: {
          for (var i = 1; i <= 7; i++)
            i: _player(i, i, deathDay: i == 1 ? 2 : null),
        },
        confirmedRoles: {1: Character.saint},
      );
      expect(board.confirmedGood.containsKey(1), isTrue);
      expect(
        board.confirmedGood[1]!.first.source,
        DeductionSource.deathReveal,
      );
    });

    test('死亡揭示爪牙/恶魔 → confirmedEvil，死者不进候选', () {
      final board = evaluate(
        players: {
          for (var i = 1; i <= 7; i++)
            i: _player(i, i, deathDay: i <= 2 ? 2 : null),
        },
        confirmedRoles: {1: Character.poisoner, 2: Character.imp},
      );
      expect(board.confirmedEvil.keys, containsAll([1, 2]));
      expect(board.knownMinionIds, {1});
      expect(board.demonCandidates, isNot(contains(1)));
      expect(board.demonCandidates, isNot(contains(2)));
    });

    test('myRole 善良 → 确认好人（即便实为 Drunk 也是外来者·善良）', () {
      final board = evaluate(
        players: {for (var i = 1; i <= 7; i++) i: _player(i, i)},
        myPlayerId: 5,
        myRole: Character.empath, // 可能实为 Drunk
      );
      expect(board.confirmedGood.containsKey(5), isTrue);
      expect(board.confirmedGood[5]!.first.description, contains('Drunk'));
      expect(board.demonCandidates, isNot(contains(5)));
    });

    test('myRole 爪牙 → 确认邪恶 + 已知爪牙，排除出恶魔候选', () {
      final board = evaluate(
        players: {for (var i = 1; i <= 7; i++) i: _player(i, i)},
        myPlayerId: 3,
        myRole: Character.poisoner,
      );
      expect(board.confirmedEvil.containsKey(3), isTrue);
      expect(board.knownMinionIds, contains(3));
      expect(board.demonCandidates, isNot(contains(3)));
    });

    test('myRole 恶魔 → confirmedDemon = 我', () {
      final board = evaluate(
        players: {for (var i = 1; i <= 7; i++) i: _player(i, i)},
        myPlayerId: 3,
        myRole: Character.imp,
      );
      expect(board.confirmedDemonPlayerId, 3);
      expect(board.demonCandidates, isNot(contains(3)));
    });

    test('恶魔私密爪牙名单 → 确认邪恶 + 已知爪牙（7+ 局官方）', () {
      final board = evaluate(
        players: {for (var i = 1; i <= 7; i++) i: _player(i, i)},
        myPlayerId: 6,
        myRole: Character.imp,
        privateMinionIds: {2, 4},
      );
      expect(board.confirmedEvil.keys, containsAll([2, 4, 6]));
      expect(board.knownMinionIds, containsAll([2, 4]));
      expect(board.demonCandidates, containsAll([1, 3, 5, 7]));
      expect(board.demonCandidates, hasLength(4));
    });

    test('传承记录 → confirmedDemon = 继承人', () {
      final board = evaluate(
        players: {
          for (var i = 1; i <= 7; i++)
            i: _player(i, i, deathDay: i == 1 ? 2 : null),
        },
        successions: [_succession(1, 1, 4)],
      );
      expect(board.confirmedDemonPlayerId, 4);
      expect(
        board.confirmedDemonReason!.source,
        DeductionSource.succession,
      );
      expect(board.demonCandidates, isNot(contains(4)));
    });

    test('最新传承继承人未知 → 不确认恶魔', () {
      final board = evaluate(
        players: {
          for (var i = 1; i <= 7; i++)
            i: _player(i, i, deathDay: i == 1 ? 2 : null),
        },
        successions: [_succession(1, 1, null)],
      );
      expect(board.confirmedDemonPlayerId, isNull);
    });

    test('最新传承目标已死 → 不确认现任恶魔（review F2）', () {
      // 4 号曾继承恶魔但随后死亡——其恶魔死亡必有后续传承/善良胜；
      // 最新记录仍指向死者说明后续未录入，现任恶魔实际未知。
      final board = evaluate(
        players: {
          1: _player(1, 1, deathDay: 2),
          4: _player(4, 4, deathDay: 4),
          for (var i in [2, 3, 5, 6, 7]) i: _player(i, i),
        },
        successions: [_succession(1, 1, 4)],
      );
      expect(board.confirmedDemonPlayerId, isNull);
      // 死目标不在候选（已死），其余存活照常
      expect(board.demonCandidates, isNot(contains(4)));
    });

    test('传承记录无序传入 → 按 id 取最新（review F3）', () {
      final board = evaluate(
        players: {
          1: _player(1, 1, deathDay: 2),
          5: _player(5, 5, deathDay: 4), // 第 4 天 5 号（新恶魔）也死了
          for (var i in [2, 3, 4, 6, 7]) i: _player(i, i),
        },
        successions: [
          _succession(2, 5, 6, day: 4), // id 大 = 最新：6 号现任
          _succession(1, 1, 5, day: 2),
        ],
      );
      expect(board.confirmedDemonPlayerId, 6);
    });

    test('已确认死亡邪恶超过配置 → anomaly（review F4）', () {
      final board = evaluate(
        players: {
          for (var i = 1; i <= 3; i++)
            i: _player(i, i, deathDay: 2), // 3 个揭示邪恶死者 > E=2
          for (var i = 4; i <= 7; i++) i: _player(i, i),
        },
        confirmedRoles: {
          1: Character.poisoner,
          2: Character.scarletWoman,
          3: Character.imp,
        },
      );
      expect(board.maxAliveEvil, -1);
      expect(
        board.anomalies.any((a) => a.contains('超过配置邪恶总数')),
        isTrue,
      );
    });

    test('善恶双确认 → anomaly 提示核对', () {
      final board = evaluate(
        players: {
          for (var i = 1; i <= 7; i++)
            i: _player(i, i, deathDay: i == 2 ? 3 : null),
        },
        confirmedRoles: {2: Character.poisoner},
        myPlayerId: 2,
        myRole: Character.monk, // 冲突：又确认善良
      );
      expect(
        board.anomalies.any((a) => a.contains('同时有善良与邪恶')),
        isTrue,
      );
    });
  });

  group('邪恶计数收缩（#214 核心）', () {
    test('终局场景：揭示善良的死者不占邪恶槽 → 剩余存活即邪恶', () {
      // 7 人局 E=2。1-4 号死且全部揭示善良；我（5 号）存活确认善良
      // → 可能邪恶的死者 = 0 → 存活邪恶下界 = 2 == 存活未确认（6、7）。
      final board = evaluate(
        players: {
          for (var i = 1; i <= 4; i++) i: _player(i, i, deathDay: 2),
          for (var i = 5; i <= 7; i++) i: _player(i, i),
        },
        confirmedRoles: {
          1: Character.monk,
          2: Character.chef,
          3: Character.empath,
          4: Character.fortuneTeller,
        },
        myPlayerId: 5,
        myRole: Character.slayer,
      );
      expect(board.forcedEvilRemaining, {6, 7});
      expect(board.confirmedEvil.keys, containsAll([6, 7]));
      expect(
        board.confirmedEvil[6]!
            .any((d) => d.source == DeductionSource.evilCountForcing),
        isTrue,
      );
      expect(board.demonCandidates, containsAll([6, 7]));
      expect(board.anomalies, isEmpty);
    });

    test('收缩依据文案：未确认死者均为邪恶（review F1 方向修正）', () {
      final board = evaluate(
        players: {
          for (var i = 1; i <= 4; i++) i: _player(i, i, deathDay: 2),
          for (var i = 5; i <= 7; i++) i: _player(i, i),
        },
        confirmedRoles: {
          1: Character.monk,
          2: Character.chef,
          3: Character.empath,
          4: Character.fortuneTeller,
        },
        myPlayerId: 5,
        myRole: Character.slayer,
      );
      final forcing = board.confirmedEvil[6]!
          .firstWhere((d) => d.source == DeductionSource.evilCountForcing);
      // 数学结论：等式迫使「邪恶死亡数 = 可能邪恶的死亡数」→ 未确认死者全为邪恶
      expect(forcing.description, contains('均为邪恶'));
      expect(forcing.description, isNot(contains('均为善良')));
    });

    test('未揭示死者可能占邪恶槽：下界按「可能邪恶的死者」计', () {
      // 1 号死未揭示（可能邪恶）→ minAliveEvil = 1；
      // 对照：揭示善良的死者不占槽（上例 minAliveEvil = 2）。
      final board = evaluate(
        players: {
          1: _player(1, 1, deathDay: 2),
          for (var i = 2; i <= 7; i++) i: _player(i, i),
        },
      );
      expect(board.minAliveEvil, 1);
      expect(board.maxAliveEvil, 2);

      final revealedGoodDead = evaluate(
        players: {
          1: _player(1, 1, deathDay: 2),
          for (var i = 2; i <= 7; i++) i: _player(i, i),
        },
        confirmedRoles: {1: Character.monk},
      );
      expect(revealedGoodDead.minAliveEvil, 2);
    });

    test('确认好人过多（others < minAliveEvil）→ anomaly', () {
      // 构造：6 人存活确认好人（数学边界验证，现实来源见终局用例）。
      final board = EliminationEngine.evaluate(
        players: {for (var i = 1; i <= 7; i++) i: _player(i, i)}.values.toList(),
        setup: setup,
        confirmedRoles: {
          1: Character.monk,
          2: Character.chef,
          3: Character.empath,
          4: Character.fortuneTeller,
          5: Character.undertaker,
          6: Character.virgin,
        },
        labelFor: (id) => '$id号',
      );
      expect(board.forcedEvilRemaining, isEmpty);
      expect(board.anomalies, isNotEmpty);
      expect(board.anomalies.first, contains('确认好人过多'));
    });

    test('全邪恶已死（揭示爪牙+恶魔）→ 下上界均 0，不 forcing', () {
      final board = evaluate(
        players: {
          1: _player(1, 1, deathDay: 2),
          2: _player(2, 2, deathDay: 2),
          for (var i = 3; i <= 7; i++) i: _player(i, i),
        },
        confirmedRoles: {1: Character.poisoner, 2: Character.imp},
      );
      expect(board.minAliveEvil, 0);
      expect(board.maxAliveEvil, 0);
      expect(board.forcedEvilRemaining, isEmpty);
      // 引擎不做终局判定：候选照常输出
      expect(board.demonCandidates, isNotEmpty);
    });

    test('存活数少于存活邪恶上界 → anomaly', () {
      final board = evaluate(
        players: {
          1: _player(1, 1, deathDay: 2),
          2: _player(2, 2, deathDay: 2),
          3: _player(3, 3, deathDay: 2),
          4: _player(4, 4, deathDay: 2),
          5: _player(5, 5, deathDay: 2),
          6: _player(6, 6, deathDay: 2),
          // 仅 7 号存活（1 人）< maxAliveEvil（E2 - 0 揭示邪恶死者 = 2）
          7: _player(7, 7),
        },
      );
      expect(board.anomalies.any((a) => a.contains('少于存活邪恶上界')), isTrue);
    });
  });

  group('弱排除层（FT 读「否」/ Empath 读 0）', () {
    test('FT 读「否」→ pair 弱排除（若真则无恶魔），不移出候选', () {
      final board = evaluate(
        players: {for (var i = 1; i <= 7; i++) i: _player(i, i)},
        declarations: [
          _infoDecl(
            3,
            Character.fortuneTeller,
            '{"playerIds": [1, 2], "answer": false}',
          ),
        ],
        dayRecordToDayNumber: {1: 1},
      );
      expect(board.weakDemonExclusions.keys, containsAll([1, 2]));
      expect(
        board.weakDemonExclusions[1]!.first.source,
        DeductionSource.fortuneTellerNo,
      );
      expect(board.demonCandidates, containsAll([1, 2]));
    });

    test('FT 读「是」/ 醉毒 → 不弱排除', () {
      final board = evaluate(
        players: {for (var i = 1; i <= 7; i++) i: _player(i, i)},
        declarations: [
          _infoDecl(
            3,
            Character.fortuneTeller,
            '{"playerIds": [1, 2], "answer": true}',
          ),
          _infoDecl(
            4,
            Character.fortuneTeller,
            '{"playerIds": [5, 6], "answer": false}',
            reliability: Reliability.possiblyTainted,
          ),
        ],
        dayRecordToDayNumber: {1: 1},
      );
      expect(board.weakDemonExclusions, isEmpty);
    });

    test('传承继承人在 FT「否」pair 内 → 豁免（读数时效）', () {
      final board = evaluate(
        players: {
          for (var i = 1; i <= 7; i++)
            i: _player(i, i, deathDay: i == 7 ? 2 : null),
        },
        successions: [_succession(1, 7, 1)], // 1 号成为新恶魔
        declarations: [
          _infoDecl(
            3,
            Character.fortuneTeller,
            '{"playerIds": [1, 2], "answer": false}',
          ),
        ],
        dayRecordToDayNumber: {1: 1},
      );
      // 1 号是传承继承人（现任恶魔）→ 豁免弱排除；2 号照常
      expect(board.weakDemonExclusions.keys, [2]);
      expect(board.confirmedDemonPlayerId, 1);
    });

    test('Empath 读 0 → 邻座弱排除；当夜被杀者不算邻座（#78）', () {
      final board = evaluate(
        players: {
          // 1 号第 2 天当夜被杀 → 第 2 天读取时已收缩出邻座
          1: _player(1, 1, deathDay: 2, deathCause: DeathCause.nightKill),
          for (var i = 2; i <= 7; i++) i: _player(i, i),
        },
        declarations: [
          _infoDecl(2, Character.empath, '{"value": 0}', dayRecordId: 10),
        ],
        dayRecordToDayNumber: {10: 2},
      );
      // 2 号（座位2）当时邻座 = 3 号与 7 号（1 号已收缩）
      expect(board.weakDemonExclusions.keys, containsAll([3, 7]));
      expect(board.weakDemonExclusions.keys, isNot(contains(1)));
    });

    test('Empath 弱排除目标若非候选（确认好人）→ 不记录', () {
      final board = evaluate(
        players: {for (var i = 1; i <= 7; i++) i: _player(i, i)},
        declarations: [
          _infoDecl(2, Character.empath, '{"value": 0}', dayRecordId: 10),
        ],
        dayRecordToDayNumber: {10: 2},
        myPlayerId: 3,
        myRole: Character.monk, // 3 号确认好人 → 非候选
      );
      // 2 号邻座 = 1、3；3 号非候选 → 仅 1 号记录
      expect(board.weakDemonExclusions.keys, [1]);
    });
  });

  test('候选按座位号排序', () {
    final board = evaluate(
      players: {
        for (var i = 1; i <= 7; i++) i: _player(i, 8 - i), // 座位倒序
      },
    );
    expect(board.demonCandidates, [7, 6, 5, 4, 3, 2, 1]);
  });
}
