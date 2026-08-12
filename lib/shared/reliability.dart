import 'package:botc_copilot/shared/models/enums.dart';

/// 计算信息声明的**有效**可靠性（issue #109）。
///
/// 在存档 [Reliability]（按天的毒，#122）之上叠加整局「疑似醉汉」overlay：
/// 醉汉是整局身份（官方：从头到尾醉酒、信息为假），故作者被疑醉时其全部
/// 信息（历史 + 未来）按可能不可靠处理。
///
/// - `invalidated` 不被覆盖（更强判定）。
/// - 存档已 `possiblyTainted` 或作者疑似醉汉 → `possiblyTainted`。
/// - 否则保持存档值。
Reliability effectiveReliability(
  Reliability stored,
  bool authorSuspectedDrunk,
) {
  if (stored == Reliability.invalidated) return Reliability.invalidated;
  if (stored == Reliability.possiblyTainted || authorSuspectedDrunk) {
    return Reliability.possiblyTainted;
  }
  return stored;
}
