/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-17 16:08:36
 * @LastEditTime: 2026-03-08 12:37:03
 * @Description: 
 */

import 'dart:convert';

import 'package:dio/dio.dart';

import '../misc/extensions.dart';
import '../model/client_data.dart';
import '../model/plugin_data/backup_data.dart';
import '../model/plugin_data/config_data.dart';
import '../model/plugin_data/config_file_data.dart';
import '../model/themis_item/themis_item.dart';
import '../model/plugin_data/themis_plugin_data.dart';
import 'demo_item.dart';

/// The default address of the http server on localhost.
const String themisLocalhostAddress = "http://127.0.0.1:5000";

/// Service to facilitate communication with the Themis system.
abstract class ThemisClient {
  static ThemisClient? _instance;
  static ThemisClient get instance => _instance!;

  /// Tries to ininialize the instance with the default client.
  // static Future<bool> platform() async {
  //   // if (_instance == null && !kIsWeb && Platform.isLinux) {
  //   //   await trySetInstance(DBusThemisClient());
  //   // }
  //   // if (_instance == null) return trySetInstance(HttpThemisClient());
  //   if (_instance == null) return trySetInstance(TestThemisClient.demo());
  //   return true;
  // }

  /// Sets [client] as instance if it works.
  static Future<bool> trySetInstance(ThemisClient client) async {
    if (await client.validate()) {
      _instance = client;
      return true;
    }
    return false;
  }

  final String authToken;

  ThemisClient(this.authToken);

  factory ThemisClient.fromData(
    ClientData data,
    String authToken,
    TestThemisClient Function() getTestClient,
  ) => switch (data.type) {
    ClientType.http =>
      data.address != ""
          ? HttpThemisClient(authToken, data.address)
          : HttpThemisClient(authToken),
    ClientType.test => getTestClient(),
    _ => TestThemisClient.demo(),
  };

  /// Serializable form.
  ClientData get data;

  /// Returns wheter the connection is valid.
  Future<bool> validate();

  /// Ping the server to make sure it works.
  Future<bool> ping();

  /// Logs in and returns the auth token. Does not save the token.
  Future<String> login(String username, String password);

  /// Retrieves the list of available plugins.
  Future<List<ThemisPluginBrief>> getPlugins();

  /// Test if the plugin is installed and works.
  Future<bool> testPlugin(String pluginId);

  /// Restart the plugin to apply settings.
  Future<bool> restartPlugin(String pluginId);

  /// Install plugin from a file on the server.
  Future<bool> installLocalPlugin(String binaryPath);

  /// Get the plugin ui.
  /// The return is a map of uiIds to lists of [ThemisItem]s.
  /// The id 'main' is expected to contain only the [MainItem] and the only [MainItem].
  Future<Map<String, List<ThemisItem>>> getUi(String pluginId);

  /// Get the list of config types from the plugin with the given id.
  Future<List<ConfigTypeBrief>> getConfigTypes(String pluginId);

  /// Get the list of configs of given type that belong to the plugin with given id.
  Future<List<ConfigFileBrief>> getConfigsOfType(
    String pluginId,
    String configType,
  );

  /// Get the list of configs of given type that belong to the plugin with given id.
  Future<List<ConfigFileBrief>> getAllConfigBriefs(String pluginId);

  /// Get the plugin config json with given id from the plugin with the given id.
  /// The return is a flat key: value map.
  Future<ConfigFileData> getConfig(ConfigFileBrief brief);

  /// Set the updated config.
  Future<bool> setConfig<T>(
    String pluginId,
    String configId,
    Map<String, dynamic> value,
  );

  /// Creates a new config file.
  Future<bool> createConfig(ConfigFileBrief brief);

  /// Deletes a config file.
  Future<bool> deleteConfig(ConfigFileBrief brief);

  /// Creates a new backup.
  Future<bool> createBackup(String pluginId);

  /// Gets the list of backups.
  Future<List<BackupData>> getBackups(String pluginId);

  /// Restores a backup.
  Future<bool> restoreBackup(String pluginId, String backupId);

  /// Gets the collection of plugin data.
  Future<ThemisPluginData> getData(ThemisPluginBrief brief) async {
    final ui = await getUi(brief.pluginId);
    final configBrief = (await getConfigsOfType(
      brief.pluginId,
      (ui['main']!.first as MainItem).configType,
    )).first;
    return ThemisPluginData(
      brief: brief,
      ui: ui,
      mainConfigBrief: configBrief,
      autoRestart: false,
      showResetToDefaultButtons: false,
    );
  }
}

/// The Themis client implemented as an http api client.
class HttpThemisClient extends ThemisClient {
  final String serverAddress;
  HttpThemisClient(
    super.authToken, [
    this.serverAddress = themisLocalhostAddress,
  ]);

  @override
  ClientData get data => ClientData(ClientType.http, serverAddress);

  @override
  Future<bool> validate() async => (await ping()) != false;

  // @override
  // Future<String?> sendCommand(ThemisCommand command) async {
  //   try {
  //     Response response;
  //     if (command.isSetter) {
  //       response = await Dio().put(
  //         "$serverAddress/${command.pluginId}/${command.method}",
  //         data: command.argument,
  //       );
  //     } else {
  //       response = await Dio().get(
  //         "$serverAddress/${command.pluginId}/${command.method}",
  //       );
  //     }
  //     return response.data;
  //   } on DioException {
  //     return null;
  //   }
  // }

  @override
  Future<bool> ping() async {
    try {
      await getPlugins();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> login(String username, String password) async {
    var result = await Dio().post<String>(
      "$serverAddress/login",
      data: {'username': username, 'password': password},
    );
    return result.data ?? "";
  }

  @override
  Future<List<ThemisPluginBrief>> getPlugins() async {
    var result = await Dio().get<String>("$serverAddress/themis/plugins");
    final jmaps = List<Map<String, dynamic>>.from(json.decode(result.data!));
    return jmaps.map((jmap) => ThemisPluginBrief.fromJson(jmap)).toList();
  }

  @override
  Future<bool> testPlugin(String pluginId) async {
    var result = await Dio().get<String>(
      "$serverAddress/themis/plugins/$pluginId/test",
    );
    return result.statusCode == 200;
  }

  @override
  Future<bool> restartPlugin(String pluginId) async {
    var result = await Dio().put<String>(
      "$serverAddress/themis/plugins/$pluginId/restart",
      data: json.encode(true),
    );
    return result.statusCode == 200;
  }

  @override
  Future<bool> installLocalPlugin(String binaryPath) async {
    var result = await Dio().post<String>(
      "$serverAddress/themis/plugins/local_install",
      data: json.encode({'path': binaryPath}),
    );
    return result.statusCode == 200;
  }

  @override
  Future<Map<String, List<ThemisItem>>> getUi(String pluginId) async {
    var result = await Dio().get<String>(
      "$serverAddress/themis/plugins/$pluginId/ui",
    );
    return (json.decode(result.data!) as Map).map(
      (k, v) =>
          MapEntry(k, (v as List).map((e) => ThemisItem.json(e)).toList()),
    );
  }

  @override
  Future<List<ConfigTypeBrief>> getConfigTypes(String pluginId) async {
    var result = await Dio().get<String>(
      "$serverAddress/themis/plugins/$pluginId/config",
    );
    final jmaps = List<Map<String, dynamic>>.from(json.decode(result.data!));
    return jmaps
        .map(
          (jmap) =>
              ConfigTypeBrief.fromFileBrief(ConfigFileBrief.fromJson(jmap)),
        )
        .toList();
  }

  @override
  Future<List<ConfigFileBrief>> getConfigsOfType(
    String pluginId,
    String configType,
  ) async {
    var result = await Dio().get<String>(
      "$serverAddress/themis/plugins/$pluginId/config",
    );
    final jmaps = List<Map<String, dynamic>>.from(json.decode(result.data!));
    return jmaps
        .map((jmap) => ConfigFileBrief.fromJson(jmap))
        .where((e) => e.configType == configType)
        .toList();
  }

  @override
  Future<List<ConfigFileBrief>> getAllConfigBriefs(String pluginId) async {
    var result = await Dio().get<String>(
      "$serverAddress/themis/plugins/$pluginId/config",
    );
    final jmaps = List<Map<String, dynamic>>.from(json.decode(result.data!));
    return jmaps.map((jmap) => ConfigFileBrief.fromJson(jmap)).toList();
  }

  @override
  Future<ConfigFileData> getConfig(ConfigFileBrief brief) async {
    var result = await Dio().get<String>(
      "$serverAddress/themis/plugins/${brief.pluginId}/config/${brief.configId}",
    );
    return ConfigFileData(
      brief: brief,
      data: ConfigData(config: json.decode(result.data!)),
    );
  }

  @override
  Future<bool> setConfig<T>(
    String pluginId,
    String configId,
    Map<String, dynamic> value,
  ) async {
    var result = await Dio().post<String>(
      "$serverAddress/themis/plugins/$pluginId/config/$configId",
      data: json.encode(value),
    );
    return result.statusCode == 200;
  }

  @override
  Future<bool> createConfig(ConfigFileBrief brief) async {
    var result = await Dio().put<String>(
      "$serverAddress/themis/plugins/${brief.pluginId}/config/${brief.configId}",
      data: json.encode(brief.toJson()),
    );
    return result.statusCode == 200;
  }

  @override
  Future<bool> deleteConfig(ConfigFileBrief brief) async {
    var result = await Dio().delete<String>(
      "$serverAddress/themis/plugins/${brief.pluginId}/config/${brief.configId}",
    );
    return result.statusCode == 200;
  }

  @override
  Future<bool> createBackup(String pluginId) async {
    var result = await Dio().get<String>(
      "$serverAddress/themis/plugins/$pluginId/save",
    );
    return result.statusCode == 200;
  }

  @override
  Future<List<BackupData>> getBackups(String pluginId) async {
    var result = await Dio().get<String>(
      "$serverAddress/themis/plugins/$pluginId/load_list",
    );
    final jmaps = List<Map<String, dynamic>>.from(json.decode(result.data!));
    return jmaps.map((jmap) => BackupData.fromJson(jmap)).toList();
  }

  @override
  Future<bool> restoreBackup(String pluginId, String backupId) async {
    var result = await Dio().get<String>(
      "$serverAddress/themis/plugins/$pluginId/load/$backupId",
    );
    return result.statusCode == 200;
  }
}

/// The Themis client implemented as a local mock server.
class TestThemisClient extends ThemisClient {
  /// Plugin briefs for the dummy plugins.
  final List<String> pluginBriefs;

  /// Plugin config ui jsons.
  final Map<String, String> pluginUis;

  /// Plugin config briefs per type.
  final Map<String, String> pluginConfigBriefs;

  /// Plugin config json lists.
  final Map<String, Map<String, String>> pluginConfigFiles;

  /// Plugin backup briefs.
  final Map<String, String> backups;

  TestThemisClient.saved(
    ThemisPluginBrief testBrief,
    Map<String, List<ThemisItem>> testItem,
    List<ConfigFileBrief> testConfigBriefs,
    Map<String, Map<String, dynamic>> testConfig,
    List<BackupData> testBackup,
  ) : pluginBriefs = [testBrief.encode(), demoBrief.encode()],
      pluginUis = {
        testBrief.pluginId: testItem.encode(),
        demoBrief.pluginId: demoItem.encode(),
      },
      pluginConfigBriefs = {
        testBrief.pluginId: json.encode(
          testConfigBriefs.map((e) => e.toJson()).toList(),
        ),
        demoBrief.pluginId: json.encode(
          demoConfigBriefs.map((e) => e.toJson()).toList(),
        ),
      },
      pluginConfigFiles = {
        testBrief.pluginId: testConfig.map(
          (k, v) => MapEntry(k, json.encode(v)),
        ),
        demoBrief.pluginId: demoConfig.map(
          (k, v) => MapEntry(k, json.encode(v)),
        ),
      },
      backups = {
        testBrief.pluginId: json.encode(
          testBackup.map((e) => e.toJson()).toList(),
        ),
        demoBrief.pluginId: json.encode(
          demoBackup.map((e) => e.toJson()).toList(),
        ),
      },
      super("");

  TestThemisClient.demo()
    : pluginBriefs = [demoBrief.encode()],
      pluginUis = {demoBrief.pluginId: demoItem.encode()},
      pluginConfigBriefs = {
        demoBrief.pluginId: json.encode(
          demoConfigBriefs.map((e) => e.toJson()).toList(),
        ),
      },
      pluginConfigFiles = {
        demoBrief.pluginId: demoConfig.map(
          (k, v) => MapEntry(k, json.encode(v)),
        ),
      },
      backups = {
        demoBrief.pluginId: json.encode(
          demoBackup.map((e) => e.toJson()).toList(),
        ),
      },
      super("");

  @override
  ClientData get data => ClientData(ClientType.test);

  @override
  Future<bool> validate() async => true;

  @override
  Future<bool> ping() async => true;

  @override
  Future<String> login(String username, String password) async => "success";

  @override
  Future<List<ThemisPluginBrief>> getPlugins() async => pluginBriefs
      .map((e) => ThemisPluginBrief.fromJson(json.decode(e)))
      .toList();

  @override
  Future<bool> testPlugin(String pluginId) async => true;

  @override
  Future<bool> restartPlugin(String pluginId) async => true;

  @override
  Future<bool> installLocalPlugin(String binaryPath) async => true;

  @override
  Future<Map<String, List<ThemisItem>>> getUi(String pluginId) async =>
      (json.decode(pluginUis[pluginId]!) as Map).map(
        (k, v) =>
            MapEntry(k, (v as List).map((e) => ThemisItem.json(e)).toList()),
      );

  @override
  Future<List<ConfigTypeBrief>> getConfigTypes(String pluginId) async {
    final jmaps = List<Map<String, dynamic>>.from(
      json.decode(pluginConfigBriefs[pluginId]!),
    );
    return jmaps
        .map(
          (jmap) =>
              ConfigTypeBrief.fromFileBrief(ConfigFileBrief.fromJson(jmap)),
        )
        .toList();
  }

  @override
  Future<List<ConfigFileBrief>> getConfigsOfType(
    String pluginId,
    String configType,
  ) async {
    final jmaps = List<Map<String, dynamic>>.from(
      json.decode(pluginConfigBriefs[pluginId]!),
    );
    return jmaps
        .map((jmap) => ConfigFileBrief.fromJson(jmap))
        .where((e) => e.configType == configType)
        .toList();
  }

  @override
  Future<List<ConfigFileBrief>> getAllConfigBriefs(String pluginId) async {
    final jmaps = List<Map<String, dynamic>>.from(
      json.decode(pluginConfigBriefs[pluginId]!),
    );
    return jmaps.map((jmap) => ConfigFileBrief.fromJson(jmap)).toList();
  }

  @override
  Future<ConfigFileData> getConfig(ConfigFileBrief brief) async =>
      ConfigFileData(
        brief: brief,
        data: ConfigData(
          config: json.decode(
            pluginConfigFiles[brief.pluginId]![brief.configId]!,
          ),
        ),
      );

  @override
  Future<bool> setConfig<T>(
    String pluginId,
    String configId,
    Map<String, dynamic> value,
  ) async {
    // testConfig[configId] = value;
    return true;
  }

  @override
  Future<bool> createConfig(ConfigFileBrief brief) async {
    // testConfigTypes[brief.configType]!.add((brief.configId, brief.title));
    // testConfig[brief.configId] =
    //     testConfig[testConfigTypes[brief.configType]!.first.$1]!;
    return true;
  }

  @override
  Future<bool> deleteConfig(ConfigFileBrief brief) async {
    // testConfigTypes[brief.configType]!.removeWhere(
    //   (e) => e.$1 == brief.configId,
    // );
    // testConfig.remove(brief.configId);
    return true;
  }

  @override
  Future<bool> createBackup(String pluginId) async {
    return false;
  }

  @override
  Future<List<BackupData>> getBackups(String pluginId) async {
    final jmaps = List<Map<String, dynamic>>.from(
      json.decode(backups[pluginId]!),
    );
    return jmaps.map((jmap) => BackupData.fromJson(jmap)).toList();
  }

  @override
  Future<bool> restoreBackup(String pluginId, String backupId) async {
    return false;
  }
}
