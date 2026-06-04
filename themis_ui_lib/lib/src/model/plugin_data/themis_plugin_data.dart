/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-12-16 23:27:02
 * @LastEditTime: 2026-03-08 12:33:03
 * @Description: 
 */

import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../themis_item/themis_item.dart';
import 'config_file_data.dart';

/// Brief textual information about the plugin.
/// Two plugins are grouped if their ids and versions match.
class ThemisPluginBrief extends Equatable {
  /// Plugin identifier.
  final String pluginId;

  /// Version of the plugin.
  final String pluginVersion;

  /// Title to display on the main tab.
  final String title;

  /// Subtitle to display on the main tab.
  final String subtitle;

  const ThemisPluginBrief({
    required this.pluginId,
    required this.pluginVersion,
    required this.title,
    required this.subtitle,
  });

  ThemisPluginBrief.fromJson(Map<String, dynamic> jmap)
    : pluginId = jmap['pluginId'],
      pluginVersion = jmap['pluginVersion'],
      title = jmap['title'],
      subtitle = jmap['subtitle'];

  String encode() => json.encode({
    'pluginId': pluginId,
    'pluginVersion': pluginVersion,
    'title': title,
    'subtitle': subtitle,
  });

  @override
  List<Object?> get props => [pluginId, pluginVersion];
}

/// Class that holds data received from a plugin.
class ThemisPluginData extends Equatable {
  /// Textual information about the plugin.
  final ThemisPluginBrief brief;

  /// Ui subtrees by their ids.
  /// The id 'main' is expected to contain only the [MainItem] and the only [MainItem].
  final Map<String, List<ThemisItem>> ui;

  /// Textual information about the main config file of the plugin.
  final ConfigFileBrief mainConfigBrief;

  /// Wheter to auto restart on save.
  final bool autoRestart;

  /// Wheter to show reset to default buttons.
  /// // TODO: Separation of concerns: This isn't a plugin setting.
  final bool showResetToDefaultButtons;

  const ThemisPluginData({
    required this.brief,
    required this.ui,
    required this.mainConfigBrief,
    required this.autoRestart,
    required this.showResetToDefaultButtons,
  });

  // Copies the object with given fields changed.
  ThemisPluginData copyWith({
    ThemisPluginBrief? brief,
    Map<String, List<ThemisItem>>? ui,
    ConfigFileBrief? mainConfigBrief,
    bool? autoRestart,
    bool? showResetToDefaultButtons,
  }) => ThemisPluginData(
    brief: brief ?? this.brief,
    ui: ui ?? this.ui,
    mainConfigBrief: mainConfigBrief ?? this.mainConfigBrief,
    autoRestart: autoRestart ?? this.autoRestart,
    showResetToDefaultButtons:
        showResetToDefaultButtons ?? this.showResetToDefaultButtons,
  );

  @override
  List<Object?> get props => [
    brief,
    ui,
    mainConfigBrief,
    autoRestart,
    showResetToDefaultButtons,
  ];
}
