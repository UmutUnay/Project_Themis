/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2026-03-08 11:19:53
 * @LastEditTime: 2026-03-08 12:34:21
 * @Description: 
 */

import 'package:equatable/equatable.dart';

import '../../../themis_ui_lib.dart';
import 'config_data.dart';

/// Holds identifying and textual information about a config file type.
class ConfigTypeBrief extends Equatable {
  /// Id of the plugin this config file belongs to.
  final String pluginId;

  /// Id of the config type.
  final String configType;

  /// Title of the config type.
  final String title;

  const ConfigTypeBrief({
    required this.pluginId,
    required this.configType,
    required this.title,
  });

  ConfigTypeBrief.fromJson(Map<String, dynamic> jmap)
    : pluginId = jmap['pluginId'],
      configType = jmap['configType'],
      title = jmap['title'];

  ConfigTypeBrief.fromFileBrief(ConfigFileBrief brief)
    : pluginId = brief.pluginId,
      configType = brief.configType,
      title = brief.configType;

  Map<String, dynamic> toJson() => {
    'pluginId': pluginId,
    'configType': configType,
    'title': title,
  };

  ConfigTypeBrief copyWith({
    String? pluginId,
    String? configType,
    String? title,
  }) => ConfigTypeBrief(
    pluginId: pluginId ?? this.pluginId,
    configType: configType ?? this.configType,
    title: title ?? this.title,
  );

  @override
  List<Object?> get props => [pluginId, configType];
}

/// Holds identifying and textual information about a config file.
class ConfigFileBrief extends Equatable {
  /// Id of the plugin this config file belongs to.
  final String pluginId;

  /// Id of the config file.
  final String configId;

  /// Type of the config file.
  final String configType;

  /// Title of the config file.
  final String title;

  const ConfigFileBrief({
    required this.pluginId,
    required this.configId,
    required this.configType,
    required this.title,
  });

  ConfigFileBrief.fromJson(Map<String, dynamic> jmap)
    : pluginId = jmap['pluginId'],
      configId = jmap['configId'],
      configType = jmap['configType'],
      title = jmap['title'];

  Map<String, dynamic> toJson() => {
    'pluginId': pluginId,
    'configId': configId,
    'configType': configType,
    'title': title,
  };

  ConfigFileBrief copyWith({
    String? pluginId,
    String? configId,
    String? configType,
    String? title,
  }) => ConfigFileBrief(
    pluginId: pluginId ?? this.pluginId,
    configId: configId ?? this.configId,
    configType: configType ?? this.configType,
    title: title ?? this.title,
  );

  @override
  List<Object?> get props => [pluginId, configId, configType];
}

/// Holds data about a config file.
class ConfigFileData extends Equatable implements ConfigInterface {
  /// Textual information about the config file.
  final ConfigFileBrief brief;

  /// Config data from the file.
  final ConfigData data;

  ConfigFileData({required this.brief, required this.data});

  /// Current config state.
  @override
  late final Map<String, dynamic> config = data.config;

  /// Wheter config was modified.
  @override
  bool get modified => data.modified;

  /// Returns a copy with the key of [item] overriden by [value].
  @override
  ConfigFileData withValue(ConfigItem item, dynamic value) =>
      ConfigFileData(brief: brief, data: data.withValue(item, value));

  /// Returns a copy with saved changes.
  @override
  ConfigFileData commit() => ConfigFileData(brief: brief, data: data.commit());

  @override
  List<Object?> get props => [brief, data];
}
