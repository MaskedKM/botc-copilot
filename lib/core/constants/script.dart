/// 剧本（决定角色池与配置表）。
enum Script {
  /// Trouble Brewing 暗流涌动（基础剧本）。
  troubleBrewing(nameCn: '暗流涌动', nameEn: 'Trouble Brewing', abbr: 'TB'),

  /// Bad Moon Rising 血月升起。
  badMoonRising(nameCn: '血月升起', nameEn: 'Bad Moon Rising', abbr: 'BMR'),

  /// Sects & Violets 紫罗兰教派。
  sectsAndViolets(
    nameCn: '紫罗兰教派',
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
