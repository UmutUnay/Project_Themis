import 'package:equatable/equatable.dart';

import '../../../themis_ui_lib.dart';

/// Interface of a config data.
abstract interface class ConfigInterface {
  /// Current config state.
  Map<String, dynamic> get config;

  /// Wheter config was modified.
  bool get modified;

  /// Returns a copy with the key of [item] overriden by [value].
  ConfigInterface withValue(ConfigItem item, dynamic value);

  /// Returns a copy with saved changes.
  ConfigInterface commit();
}

enum Omit { omit }

/// Holds data about key: value pairs.
class ConfigData extends Equatable implements ConfigInterface {
  /// {key: value} map of the config file.
  final Map<String, dynamic> _config;

  /// {key: value} map of the changes to the config file.
  final Map<String, dynamic> _configModifications;

  ConfigData({required Map<String, dynamic> config})
    : _config = config,
      _configModifications = const {},
      _modificationGeneration = 0;

  ConfigData._internal({
    required Map<String, dynamic> config,
    required Map<String, dynamic> configModifications,
    required int modificationGeneration,
  }) : _config = config,
       _configModifications = configModifications,
       _modificationGeneration = modificationGeneration;

  /// Current config state.
  @override
  Map<String, dynamic> get config =>
      {..._config, ..._configModifications}
        ..removeWhere((k, v) => v == Omit.omit);

  /// Generation of the current modification.
  /// This is a required as otherwise map reorderings are invisible.
  final int _modificationGeneration;

  /// Wheter config was modified.
  @override
  bool get modified => _modificationGeneration != 0;

  /// Returns a copy with the key of [item] overriden by [value].
  @override
  ConfigData withValue(ConfigItem item, dynamic value) =>
      _config[item.key] == value
      ? _configModifications.containsKey(item.key)
            ? ConfigData._internal(
                config: _config,
                configModifications: {..._configModifications}
                  ..remove(item.key),
                modificationGeneration: _modificationGeneration + 1,
              )
            : this
      : item.defaultValue == value && item.omitDefault
      ? ConfigData._internal(
          config: _config,
          configModifications: {..._configModifications, item.key: Omit.omit},
          modificationGeneration: _modificationGeneration + 1,
        )
      : value == _configModifications[item.key]
      ? this
      : ConfigData._internal(
          config: _config,
          configModifications: {..._configModifications, item.key: value},
          modificationGeneration: _modificationGeneration + 1,
        );

  /// Returns a copy with saved changes.
  @override
  ConfigData commit() => modified ? ConfigData(config: config) : this;

  @override
  List<Object?> get props => [config, _modificationGeneration];
}
