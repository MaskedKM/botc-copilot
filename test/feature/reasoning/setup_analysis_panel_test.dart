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
      abilityUsed: false, suspectedDrunk: false,
      fakeDead: false,
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
  List<Character> modifierClaims = const [],
  List<Character> scriptModifiers = const [Character.baron],
  int expectedWithClaimed = 2,
  int maxOutsiderDelta = 2,
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
      modifierClaims: modifierClaims,
      scriptModifiers: scriptModifiers,
      expectedWithClaimed: expectedWithClaimed,
      maxOutsiderDelta: maxOutsiderDelta,
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
    // #266②：修正局参照行按剧本修正角色派生（男爵 +2/-2）
    expect(find.textContaining('「男爵」在场：+2 外来者、-2 镇民'),
        findsOneWidget);
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
    expect(find.text('介于标准与修正配置'), findsOneWidget);
  });

  testWidgets('over 偏差解读（超出修正上限）', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(deviation: OutsiderDeviation.over, claimed: 5),
    ));
    await tester.pump();
    expect(find.textContaining('超出修正上限 1'), findsOneWidget);
  });

  testWidgets('standard 偏差解读（无修正角色声明）', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(deviation: OutsiderDeviation.standard, claimed: 2),
    ));
    await tester.pump();
    expect(find.text('与标准配置一致'), findsOneWidget);
    expect(find.textContaining('声明 2 = 标准 2'), findsOneWidget);
  });

  // #266①：standard + 修正角色已声明 = 与声明锚点吻合（#151 S3 语义），
  // 不再渲染「声明 3 = 标准 1。但 Baron 已声明」的字面矛盾句。
  testWidgets('standard + 男爵已声明 → 与修正后期望吻合（无矛盾文案）', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(
        deviation: OutsiderDeviation.standard,
        claimed: 4,
        modifierClaims: const [Character.baron],
        expectedWithClaimed: 4,
      ),
    ));
    await tester.pump();
    expect(find.textContaining('声明 4 = 「男爵」修正后期望 4'), findsOneWidget);
    expect(find.textContaining('但 Baron 已声明'), findsNothing); // 假文案不再
    expect(find.text('男爵 已声明'), findsOneWidget); // 徽标按修正角色命名
  });

  // #266①：under 与声明锚点比（男爵已声明、声明 3 → 期望 4 → 差 1），
  // 不再出现「少于标准配置 0/-1」的负差额。
  testWidgets('under + 男爵已声明 → 与修正后期望比较', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(
        deviation: OutsiderDeviation.under,
        claimed: 3,
        modifierClaims: const [Character.baron],
        expectedWithClaimed: 4,
      ),
    ));
    await tester.pump();
    expect(find.text('少于期望配置 1'), findsOneWidget);
    expect(find.textContaining('若为真应有 4 个'), findsOneWidget);
  });

  testWidgets('under 偏差解读 + 尚未声明提示（无修正角色）', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(deviation: OutsiderDeviation.under, claimed: 1),
    ));
    await tester.pump();
    expect(find.textContaining('少于期望配置 1'), findsOneWidget);
    expect(find.textContaining('尚未全部声明'), findsOneWidget);
  });

  testWidgets('baronClaimed → 徽标按修正角色命名（男爵）', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(
        deviation: OutsiderDeviation.baronConsistent,
        claimed: 4,
        modifierClaims: const [Character.baron],
        expectedWithClaimed: 4,
      ),
    ));
    await tester.pump();
    expect(find.text('男爵 已声明'), findsOneWidget);
  });

  testWidgets('baronConsistent + baronClaimed → 软化措辞「若声明为真」', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(
        deviation: OutsiderDeviation.baronConsistent,
        claimed: 4,
        modifierClaims: const [Character.baron],
        expectedWithClaimed: 4,
      ),
    ));
    await tester.pump();
    expect(find.textContaining('若声明为真'), findsOneWidget);
  });

  // #266②：BMR 教父（±1）声明 → 徽章/差额按教父锚点（base+1）。
  testWidgets('BMR 教父已声明 → 徽章 + 参照行走教父', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(
        deviation: OutsiderDeviation.under,
        claimed: 2,
        modifierClaims: const [Character.godfather],
        scriptModifiers: const [Character.godfather],
        expectedWithClaimed: 3, // base 2 + 教父 +1
        maxOutsiderDelta: 1,
      ),
    ));
    await tester.pump();
    expect(find.text('教父 已声明'), findsOneWidget);
    expect(find.textContaining('「教父」在场：±1 外来者'), findsOneWidget);
    expect(find.text('少于期望配置 1'), findsOneWidget); // 3 - 2
  });

  // #266②：S&V 双修正角色参照行（方古 +1 / 亡骨魔 -1）。
  testWidgets('S&V 参照行列出方古与亡骨魔', (tester) async {
    await tester.pumpWidget(buildPanel(
      _analysis(
        deviation: OutsiderDeviation.standard,
        claimed: 2,
        scriptModifiers: const [Character.fanggu, Character.vigormortis],
        expectedWithClaimed: 2,
        maxOutsiderDelta: 1,
      ),
    ));
    await tester.pump();
    expect(find.textContaining('「方古」在场：+1 外来者、-1 镇民'),
        findsOneWidget);
    expect(find.textContaining('「亡骨魔」在场：-1 外来者、+1 镇民'),
        findsOneWidget);
  });
}
