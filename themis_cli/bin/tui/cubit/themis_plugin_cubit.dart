/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-12-05 21:55:22
 * @LastEditTime: 2026-03-08 11:31:57
 * @Description: 
 */

import 'package:themis_ui_lib/themis_ui_lib.dart';

import '../util/cubit.dart';

/// Manages the state of a plugin (but not its configs).
class ThemisPluginCubit extends Cubit<ThemisPluginData> {
  ThemisPluginCubit(super.initialState);

  /// Changes the auto restart setting.
  void setAutoRestart(bool value) => emit(state.copyWith(autoRestart: value));

  /// Changes showResetToDefaultButtons setting.
  void setShowResetToDefault(bool value) =>
      emit(state.copyWith(showResetToDefaultButtons: value));
}
