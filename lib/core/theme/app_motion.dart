/// 动效时长 token（docs/UI-STYLE.md §七）。
///
/// 原则：动效表达状态，不表演。常规过渡 150-250ms；
/// 签名时刻（昼夜更替/死亡熄灭/处决扫针）允许 300-600ms 一次性动画。
abstract final class AppMotion {
  /// 快速反馈（按钮按下、chip 选中）。
  static const Duration fast = Duration(milliseconds: 150);

  /// 常规过渡（面板展开、tab 切换、信任度颜色过渡）。
  static const Duration normal = Duration(milliseconds: 250);

  /// 签名：处决确认（血红环扫过座位）。
  static const Duration execution = Duration(milliseconds: 300);

  /// 签名：死亡（蜡烛熄灭，节点压暗）。
  static const Duration death = Duration(milliseconds: 400);

  /// 签名：昼夜更替（日月图标弧线旋转）。
  static const Duration dayNight = Duration(milliseconds: 600);
}
