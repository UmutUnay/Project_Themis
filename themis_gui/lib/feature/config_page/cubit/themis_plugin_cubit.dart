/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-12-05 21:55:22
 * @LastEditTime: 2026-03-08 11:31:57
 * @Description: 
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

/// Manages the state of a plugin (but not its configs).
class ThemisPluginCubit extends Cubit<ThemisPluginData> {
  ThemisPluginCubit(super.initialState);

  /// Changes the auto restart setting.
  void setAutoRestart(bool value) => emit(state.copyWith(autoRestart: value));

  /// Changes showResetToDefaultButtons setting.
  void setShowResetToDefault(bool value) =>
      emit(state.copyWith(showResetToDefaultButtons: value));

  // /// Replaces the Ui main item.
  // void replaceRoot(MainItem main) => emit(state.copyWith(ui: main));

  // /// Replaces the item with [item.id] with [item]. Returns success.
  // bool replaceItem(ThemisItem item) {
  //   final editor = ThemisTreeEditor(state.ui);
  //   final result = editor.replaceItem(item);
  //   emit(state.copyWith(ui: editor.root));
  //   return result;
  // }

  // /// Adds [item] as a child of the [NestedItem] at [id]. Returns success.
  // bool addItem(String id, ThemisItem item, [int index = -1]) {
  //   final editor = ThemisTreeEditor(state.ui);
  //   final result = editor.addItem(id, item, index);
  //   emit(state.copyWith(ui: editor.root));
  //   return result;
  // }

  // /// Remove item with [id] from the tree. Returns success.
  // bool removeItem(String id) {
  //   final editor = ThemisTreeEditor(state.ui);
  //   final result = editor.removeItem(id);
  //   emit(state.copyWith(ui: editor.root));
  //   return result;
  // }
}
