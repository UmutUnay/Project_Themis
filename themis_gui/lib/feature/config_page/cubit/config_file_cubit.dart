/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2026-03-08 11:18:20
 * @LastEditTime: 2026-03-08 12:27:54
 * @Description: 
 */

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

import 'themis_plugin_cubit.dart';

/// A cubit that manages the state of a configuration.
abstract class ConfigDataCubit<C extends ConfigInterface> extends Cubit<C> {
  ConfigDataCubit(super.initialState);

  /// Cached SubconfigCubits under this cubit.
  final Map<String, List<SubconfigCubit>> _children = {};

  /// Get child belonging to [item.key] at [index]. Create it if it doesn't exist.
  SubconfigCubit getChild(MutableConfigItem item, int index) {
    if (!_children.containsKey(item.key)) {
      final count = item
          .deserializeValue(state.config[item.key] ?? item.defaultValue)
          .length;
      _children[item.key] = [
        for (int index = 0; index < count; index++)
          SubconfigCubit(parent: this, item: item, index: index),
      ];
    }
    final sublist = _children[item.key]!;
    return sublist[index];
  }

  /// Wheter the configuration was modified at any level.
  bool get modified =>
      state.modified ||
      _children.values.any((sublist) => sublist.any((child) => child.modified));

  /// Adds a new child and corresponding value under [item.key].
  void addChild(MutableConfigItem item) {
    final oldValue = item.deserializeValue(
      state.config[item.key] ?? item.defaultValue,
    );
    oldValue.add(item.templateValue);
    emit(state.withValue(item, item.serializeValue(oldValue)) as C);
    if (!_children.containsKey(item.key)) _children[item.key] = [];
    _children[item.key]!.add(
      SubconfigCubit(
        parent: this,
        item: item,
        index: _children[item.key]!.length,
      ),
    );
  }

  /// Swaps the children and values under [item.key] at the given indicies.
  /// They are assumed to exist.
  void swapChildren(MutableConfigItem item, int index1, int index2) {
    final child1 = _children[item.key]![index1];
    _children[item.key]!.swap(index1, index2);
    _children[item.key]![index1].index = index1;
    _children[item.key]![index2].index = index2;

    final oldValue = child1.item.deserializeValue(
      state.config[item.key] ?? item.defaultValue,
    );
    oldValue.swap(index1, index2);
    emit(state.withValue(item, child1.item.serializeValue(oldValue)) as C);
  }

  /// Deletes the children and value under [item.key] at [index].
  /// It is assumed to exist.
  void deleteChild(MutableConfigItem item, int index) {
    final child = _children[item.key]!.removeAt(index);
    for (var i = 0; i < _children[item.key]!.length; i++) {
      _children[item.key]![i].index = i;
    }

    final oldValue = child.item.deserializeValue(
      state.config[item.key] ?? item.defaultValue,
    );
    oldValue.removeAt(index);
    final newValue = child.item.serializeValue(oldValue);
    child.close();
    emit(state.withValue(item, newValue) as C);
  }

  /// Clears the children cache.
  void purgeChildren() {
    for (var sublist in _children.values) {
      for (var child in sublist) {
        child.close();
      }
    }
    _children.clear();
  }

  @override
  Future<void> close() {
    purgeChildren();
    return super.close();
  }

  /// Set the [key] of item to [value].
  /// Returns false if item not found, otherwise true.
  bool setKey<V>(ConfigItem item, V value) {
    emit(state.withValue(item, value) as C);
    return true;
  }

  /// Saves the config. Call the super in the beginning and fail if it returns false.
  @mustCallSuper
  Future<bool> saveConfig() async {
    bool result = true;
    for (var sublist in _children.values) {
      for (var child in sublist) {
        result &= await child.saveConfig();
      }
    }
    return result;
  }

  /// Resets cubit to initial state. Call the super first
  @mustCallSuper
  Future<void> resetConfig() async => purgeChildren();
}

/// Manages the state of a config file.
class ConfigFileCubit extends ConfigDataCubit<ConfigFileData> {
  final ThemisPluginCubit pluginCubit;

  ConfigFileCubit(super.initialState, {required this.pluginCubit});

  /// Saves the config to the server.
  @override
  Future<bool> saveConfig() async {
    bool result = await super.saveConfig();
    if (result) {
      result = await ThemisClient.instance.setConfig(
        state.brief.pluginId,
        state.brief.configId,
        state.config,
      );
    }
    if (result) {
      emit(state.commit());
      if (pluginCubit.state.autoRestart) {
        await ThemisClient.instance.restartPlugin(state.brief.configId);
      }
    }
    return result;
  }

  /// Resets cubit to server's state.
  @override
  Future<void> resetConfig() async {
    await super.resetConfig();
    emit(await ThemisClient.instance.getConfig(state.brief));
  }
}

/// Manages the state of a subconfig found at a key of the parent.
class SubconfigCubit<S> extends ConfigDataCubit<ConfigData> {
  /// The source of the subconfig.
  final ConfigDataCubit parent;

  /// The item subconfig belongs to. It is expected to be a [List<Map<String, T>>]
  final MutableConfigItem item;

  /// Index of the subconfig in the list.
  int index;

  SubconfigCubit({
    required this.parent,
    required this.item,
    required this.index,
  }) : super(
         ConfigData(
           config: item.deserializeValue(
             parent.state.config[item.key] ?? item.defaultValue,
           )[index],
         ),
       );

  /// Saves the config to the parent.
  @override
  Future<bool> saveConfig() async {
    bool result = await super.saveConfig();
    if (result) {
      List<Map<String, dynamic>> newValue = [
        ...item.deserializeValue(
          parent.state.config[item.key] ?? item.defaultValue,
        ),
      ]..[index] = state.config;
      result = item.validate(newValue);
      if (result) {
        result = parent.setKey(item, item.serializeValue(newValue));
      }
    }
    if (result) emit(state.commit());
    return result;
  }

  /// Resets the subconfig to what's in the parent.
  @override
  Future<void> resetConfig() async {
    await super.resetConfig();
    emit(
      ConfigData(
        config: item.deserializeValue(
          parent.state.config[item.key] ?? item.defaultValue,
        )[index],
      ),
    );
  }
}
