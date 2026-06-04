import 'dart:async';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

/// Lists installed plugins.
class ListPluginsCommand extends Command {
  @override
  String get description => "Lists installed plugins.";

  @override
  String get name => "list_plugins";

  @override
  String get category => "Retrieve";

  @override
  FutureOr<dynamic>? run() async {
    final plugins = await ThemisClient.instance.getPlugins();
    final maxIndexWidth = (log(plugins.length) * log10e).truncate();
    final maxTitleWidth = plugins
        .map((e) => e.title.length)
        .reduce((a, b) => max(a, b));
    for (var (i, plugin) in plugins.indexed) {
      print(
        "${i.toString().padRight(maxIndexWidth)}: ${plugin.title.padRight(maxTitleWidth)} [id=${plugin.pluginId} v=${plugin.pluginVersion}]",
      );
      print("    ${plugin.subtitle}");
    }
  }
}

class ListConfigFilesCommand extends Command {
  @override
  String get description => "Lists config files of a plugin.";

  @override
  String get name => "list_files";

  @override
  String get category => "Retrieve";

  ListConfigFilesCommand() {
    argParser.addOption(
      "pluginId",
      abbr: "p",
      help: "Id of the plugin of interest.",
      mandatory: true,
    );
  }

  @override
  FutureOr<dynamic>? run() async {
    final briefs = await ThemisClient.instance.getAllConfigBriefs(
      argResults!.option("pluginId")!,
    );
    final Map<String, List<ConfigFileBrief>> typedBriefs = {};
    for (var brief in briefs) {
      if (!typedBriefs.containsKey(brief.configType)) {
        typedBriefs[brief.configType] = [];
      }
      typedBriefs[brief.configType]!.add(brief);
    }
    final maxIndexWidth = (log(briefs.length) * log10e).truncate();
    final maxTitleWidth = briefs
        .map((e) => e.title.length)
        .reduce((a, b) => max(a, b));
    var i = 0;
    for (var MapEntry(key: type, value: briefs) in typedBriefs.entries) {
      print("$type:");
      for (var brief in briefs) {
        print(
          "    ${i.toString().padRight(maxIndexWidth)}: ${brief.title.padRight(maxTitleWidth)} [id=${brief.configId}]",
        );
        i++;
      }
    }
  }
}
