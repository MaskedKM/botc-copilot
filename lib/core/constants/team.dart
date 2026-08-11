/// 角色阵营。
enum Team {
  /// 镇民（善良）。
  townsfolk(nameCn: '镇民', isGood: true),

  /// 外来者（善良）。
  outsider(nameCn: '外来者', isGood: true),

  /// 爪牙（邪恶）。
  minion(nameCn: '爪牙', isGood: false),

  /// 恶魔（邪恶）。
  demon(nameCn: '恶魔', isGood: false);

  const Team({required this.nameCn, required this.isGood});

  /// 中文名。
  final String nameCn;

  /// 是否善良阵营。
  final bool isGood;
}
