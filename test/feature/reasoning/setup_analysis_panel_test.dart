import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/setup_analysis_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/outsider_analysis.dart';
import 'package:botc_copilot/feature/reasoning/presentation/setup_analysis_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// widget test 用 provider override，不碰真实 DB（drift stream 在 widget test
// 留 pending timer，见 AGENTS.md 测试策略）。
Player _player(int id, int seat, String name) => Player(
      id: id,
      gameId: 1,
      name: name,
      seatNumber: seat,
      isAlive: true,
      abilityUsed: false,
    );

const _outsiderChars = [
  Character.butler,
  Character.saint,
  Character.drunk,
  Character.recluse,
];

OutsiderCountAnalysis _analysis({
  required OutsiderDeviation deviation,
  required int claimed,
  bool baronClaimed = false,
}) =>
    OutsiderCountAnalysis(
      playerCount: 9,
      townsfolk: 5,
      baseOutsiders: 2,
      minions: 1,
      demons: 1,
      claimedOutsiders: claimed,
      deviation: deviation,
      // claimers 与 claimed 数量一致（避免 fixture 不真实）；第 2 个标死亡确认
      claimers: [
        for (var i = 0; i < claimed; i++)
          OutsiderClaimer(
            playerId: i + 1,
            character: _outsiderChars[i % _outsiderChars.length],
            confirmed: i == 1,
          ),
      ],
      baronClaimed: baronClaimed,
    );

Widget buildPanel(OutsiderCountAnalysis analysis) {
  final players = [
    _player(1, 1, 'A'),
    _player(2, 2, 'B'),
    _player(3, 3, 'C'),
    _player(4, 4, 'D'),
    _player(5, 5, 'E'),
  ];
  return ProviderScope(
    overrides: [
      setupAnalysisProvider(1).overrideWith((ref) => analysis),
      gamePlayersProvider.overrideWith(
        (ref, gameId) => Stream.value(players),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: SetupAnalysisPanel(gameId: 1))),
    ),
  );
}

void main() {
  testWidgets('渲染配置行 + 声明数 + claimer chips（含确认标记）', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(deviation: OutsiderDeviation.partial, claimed: 3),
    ));
    await tester.pump();

    // 配置行
    expect(find.textContaining('9 人局'), findsOneWidget);
    expect(find.textContaining('外来者2'), findsOneWidget);
    expect(find.textContaining('Baron 局：外来者4'), findsOneWidget);
    // 声明数
    expect(find.textContaining('已声明外来者 3 人'), findsOneWidget);
    // claimer chips：含角色名 + 确认标记
    expect(find.textContaining('管家'), findsOneWidget); // butler
    expect(find.textContaining('圣徒'), findsOneWidget); // saint
    expect(find.textContaining('✓'), findsOneWidget); // 死亡揭示标记
  });

  testWidgets('partial 偏差解读', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(deviation: OutsiderDeviation.partial, claimed: 3),
    ));
    await tester.pump();
    expect(find.text('介于标准与 Baron 配置'), findsOneWidget);
  });

  testWidgets('over 偏差解读（即便 Baron 也超出）', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(deviation: OutsiderDeviation.over, claimed: 5),
    ));
    await tester.pump();
    expect(find.textContaining('即便 Baron 在场也超出'), findsOneWidget);
  });

  testWidgets('standard 偏差解读（无 Baron）', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(deviation: OutsiderDeviation.standard, claimed: 2),
    ));
    await tester.pump();
    expect(find.text('与标准配置一致'), findsOneWidget);
  });

  testWidgets('standard + baronClaimed → 张力提示（review R1）', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(
        deviation: OutsiderDeviation.standard,
        claimed: 2,
        baronClaimed: true,
      ),
    ));
    await tester.pump();
    // Baron 已声明却只 base 个 → 文本应提示与 Baron 配置不符
    expect(find.textContaining('但 Baron 已声明'), findsOneWidget);
    expect(find.text('Baron 已声明'), findsOneWidget); // 徽标
  });

  testWidgets('under 偏差解读 + 尚未声明提示', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(deviation: OutsiderDeviation.under, claimed: 1),
    ));
    await tester.pump();
    expect(find.textContaining('少于标准配置 1'), findsOneWidget);
    expect(find.textContaining('尚未全部声明'), findsOneWidget);
  });

  testWidgets('baronClaimed → 显示「Baron 已声明」徽标', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(
        deviation: OutsiderDeviation.baronConsistent,
        claimed: 4,
        baronClaimed: true,
      ),
    ));
    await tester.pump();
    expect(find.text('Baron 已声明'), findsOneWidget);
  });

  testWidgets('baronConsistent + baronClaimed → 软化措辞「若声明为真」', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(
        deviation: OutsiderDeviation.baronConsistent,
        claimed: 4,
        baronClaimed: true,
      ),
    ));
    await tester.pump();
    expect(find.textContaining('若声明为真'), findsOneWidget);
  });
}
