/// 剧本（决定角色池与配置表）。
enum Script {
  /// Trouble Brewing 暗流涌动（基础剧本）。
  troubleBrewing(nameCn: '暗流涌动', nameEn: 'Trouble Brewing', abbr: 'TB'),

  /// Bad Moon Rising 黯月初升（官方中文名，#217 数据录入时勘正）。
  badMoonRising(nameCn: '黯月初升', nameEn: 'Bad Moon Rising', abbr: 'BMR'),

  /// Sects & Violets 灾祸滋生（官方中文名，#217 数据录入时勘正）。
  sectsAndViolets(
    nameCn: '灾祸滋生',
    nameEn: 'Sects & Violets',
    abbr: 'S&V',
  );

  const Script({
    required this.nameCn,
    required this.nameEn,
    required this.abbr,
  });

  /// 中文名。
  final String nameCn;

  /// 英文名。
  final String nameEn;

  /// 常用缩写。
  final String abbr;
}
