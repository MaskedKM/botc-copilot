/// 跨 feature 共享的领域枚举（Drift 表与 UI 共用）。

/// 对局状态。
enum GameStatus {
  /// 进行中。
  ongoing('进行中'),

  /// 善良阵营获胜。
  goodWin('善良获胜'),

  /// 邪恶阵营获胜。
  evilWin('邪恶获胜');

  const GameStatus(this.nameCn);

  /// 中文显示名。
  final String nameCn;
}

/// 死亡原因。
enum DeathCause {
  /// 夜晚被杀。
  nightKill('夜晚死亡'),

  /// 白天被处决。
  execution('处决'),

  /// 其他（技能、规则等）。
  other('其他');

  const DeathCause(this.nameCn);

  /// 中文显示名。
  final String nameCn;
}

/// 角色声明类型。
enum ClaimType {
  /// 首次声明。
  firstClaim('首次声明'),

  /// 改口（变更声明）。
  changed('改口'),

  /// 死亡时揭示。
  revealedOnDeath('死亡揭示'),

  /// 我的真实身份（助手视角，合成注入、不持久化；issue #107）。
  myRole('真实角色（我）');

  const ClaimType(this.nameCn);

  /// 中文显示名。
  final String nameCn;
}

/// 信息可靠性（醉/毒追踪）。
enum Reliability {
  /// 已验证（如被掘墓人确认）。
  verified('已验证'),

  /// 待验证。
  unverified('待验证'),

  /// 可能被醉/毒污染。
  possiblyTainted('可能污染'),

  /// 已失效。
  invalidated('已失效');

  const Reliability(this.nameCn);

  /// 中文显示名。
  final String nameCn;
}

/// 信任度等级。
enum TrustLevel {
  /// 确信好人。
  confirmedGood('确信好人'),

  /// 偏向好人。
  likelyGood('偏好'),

  /// 未知。
  unknown('未知'),

  /// 有嫌疑。
  suspect('嫌疑'),

  /// 恶魔候选。
  demonCandidate('恶魔候选');

  const TrustLevel(this.nameCn);

  /// 中文显示名。
  final String nameCn;
}

/// 帮助层级（issue #41）：控制规则提示的展开程度。
enum HelpLevel {
  /// 新手：规则提示默认展开。
  beginner('新手'),

  /// 普通：规则提示折叠但可点开。
  normal('普通'),

  /// 老手：零干扰，只显示最核心信息。
  expert('老手');

  const HelpLevel(this.nameCn);

  /// 中文显示名。
  final String nameCn;
}

/// 毒来源（仅按天的「毒」；醉汉是整局身份，见 Players.suspectedDrunk，issue #109）。
enum PoisonSource {
  /// 投毒者。
  poisoner('投毒'),

  /// 其他来源（自定义剧本的非 Poisoner 毒源）。
  other('其他');

  const PoisonSource(this.nameCn);

  /// 中文显示名。
  final String nameCn;
}
