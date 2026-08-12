import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/setup/data/setup_repository.dart';
import 'package:botc_copilot/feature/setup/domain/setup_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 开局设置仓库 Provider。
final setupRepositoryProvider = Provider<SetupRepository>(
  (ref) => SetupRepository(ref.watch(appDatabaseProvider)),
);

/// 开局设置向导状态 Provider。
final setupProvider =
    StateNotifierProvider<SetupNotifier, SetupState>(SetupNotifier.new);

/// 开局设置向导状态管理。
class SetupNotifier extends StateNotifier<SetupState> {
  /// 创建 notifier。
  SetupNotifier(this._ref) : super(SetupState());

  final Ref _ref;

  /// 选择剧本。
  void selectScript(Script script) {
    state = state.copyWith(script: script);
  }

  /// 调整玩家数（保留已输入的名字，多余截断、不足补字母）。
  void setPlayerCount(int count) {
    final names = List<String>.of(state.playerNames);
    if (names.length > count) {
      names.removeRange(count, names.length);
    } else {
      for (var i = names.length; i < count; i++) {
        names.add(String.fromCharCode(65 + i));
      }
    }
    // ≤6 人局恶魔无 Bluff（官方规则）→ 清空已选残留，避免污染小局排除法
    final bluffs = count < 7 ? const <Character>[] : state.demonBluffs;
    state = state.copyWith(
      playerCount: count,
      playerNames: names,
      // 人数减少后原座位号越界 → 清除，避免残留指向错误的人
      mySeat: (state.mySeat != null && state.mySeat! > count)
          ? () => null
          : null,
      demonBluffs: bluffs,
    );
  }

  /// 设置某座位的玩家名（[index] 从 0 开始）。
  void setPlayerName(int index, String name) {
    final names = List<String>.of(state.playerNames);
    names[index] = name;
    state = state.copyWith(playerNames: names);
  }

  /// 拖拽换座（ReorderableListView 语义：newIndex 为移除后插入位）。
  ///
  /// 若已选「我的座位」，座位号跟随同一名玩家移动（用户选的是
  /// 「我」这个人，不是固定号码）。
  void reorderSeat(int oldIndex, int newIndex) {
    final names = List<String>.of(state.playerNames);
    final myName =
        state.mySeat != null ? names[state.mySeat! - 1] : null;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    final name = names.removeAt(oldIndex);
    names.insert(target, name);
    final newSeat = myName != null ? names.indexOf(myName) + 1 : null;
    state = state.copyWith(
      playerNames: names,
      mySeat: newSeat != null && newSeat != state.mySeat
          ? () => newSeat
          : null,
    );
  }

  /// 选择我的角色。
  void selectRole(Character role) {
    // 换了角色则清空 Bluff（防止非恶魔角色残留 Bluff 数据）
    state = state.copyWith(
      myRole: role,
      demonBluffs: role.team == Team.demon ? state.demonBluffs : const [],
    );
  }

  /// 切换 Bluff 角色选中态（最多 3 个）。
  void toggleBluff(Character role) {
    final bluffs = List<Character>.of(state.demonBluffs);
    if (bluffs.contains(role)) {
      bluffs.remove(role);
    } else if (bluffs.length < 3) {
      bluffs.add(role);
    }
    state = state.copyWith(demonBluffs: bluffs);
  }

  /// 选择我的座位号（1-based；传 null 清除选择）。
  void selectMySeat(int? seat) {
    state = state.copyWith(mySeat: () => seat);
  }

  /// 下一步。
  void nextStep() {
    if (state.canProceed && state.step < SetupState.totalSteps - 1) {
      state = state.copyWith(step: state.step + 1);
    }
  }

  /// 上一步。
  void previousStep() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  /// 提交：创建对局 + 玩家，返回新对局 id。
  ///
  /// 成功后重置向导状态，避免下次进入 setup 看到上一局残留。
  Future<int> submit() async {
    if (!state.canProceed || state.myRole == null) {
      throw StateError('设置未完成，无法提交');
    }
    state = state.copyWith(submitting: true);
    try {
      final gameId = await _ref.read(setupRepositoryProvider).createGame(
            script: state.script,
            names: state.playerNames,
            myRole: state.myRole!,
            demonBluffs: state.demonBluffs,
            mySeat: state.mySeat,
          );
      // 异步间隙中页面可能已跳转、notifier 已 dispose，需 mounted 守卫。
      if (mounted) state = SetupState();
      return gameId;
    } finally {
      if (mounted) {
        state = state.copyWith(submitting: false);
      }
    }
  }
}
