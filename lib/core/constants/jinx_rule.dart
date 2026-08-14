import 'package:botc_copilot/core/constants/character.dart';

/// Jinx（角色对冲突消解规则，#233 引入实体）。
///
/// 官方全局机制：新角色须与所有已有角色兼容，冲突由官方 Jinx 列表消解；
/// 自定义剧本混编多剧本角色时全量生效（含**同剧本内**角色对，如 S&V 的
/// Magician/Legion）。script tool 据剧本角色组合自动标注适用 Jinx——
/// App 侧由 [ScriptDefinition.applicableJinxes] 按角色池推导。
class JinxRule {
  /// 创建 Jinx 规则。
  const JinxRule({required this.a, required this.b, required this.text});

  /// 角色对（无序：a/b 仅为书写顺序）。
  final Character a;
  final Character b;

  /// 官方消解规则文本（中文转述，已核官方 Wiki / Jinx 更新公告）。
  final String text;

  /// 是否涉及某角色。
  bool involves(Character c) => c == a || c == b;
}

/// 全局 Jinx 注册表（官方数据；跨剧本混编全量生效）。
///
/// 当前仅含 #233 验收所需锚点对；BMR/S&V 其余 Jinx 随 #217 录入。
const jinxRules = <JinxRule>[
  // 官方现行文本（wiki.bloodontheclocktower.com/Magician，Jinx 更新后）。
  JinxRule(
    a: Character.magician,
    b: Character.legion,
    text: '若魔术师在场，恶魔信息步骤中军团分批唤醒：每批得知哪些玩家是'
        '好人，但不知道有多少名邪恶玩家。',
  ),
];
