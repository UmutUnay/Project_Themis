import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

/// Prints the contents of a config file in human readable format.
class PrintCommand extends Command {
  @override
  String get description =>
      "Prints the contents of a config file in human readable format.";

  @override
  String get name => "print";

  @override
  String get category => "Retrieve";

  PrintCommand() {
    argParser
      ..addOption(
        "pluginId",
        abbr: "p",
        help: "Id of the plugin of interest.",
        mandatory: true,
      )
      ..addOption(
        "configId",
        abbr: "c",
        help: "Id of the config file to read.",
        mandatory: true,
      );
  }

  @override
  FutureOr<dynamic>? run() async {
    final configData = await ThemisClient.instance.getConfig(
      ConfigFileBrief(
        pluginId: argResults!.option("pluginId")!,
        configId: argResults!.option("configId")!,
        configType: "",
        title: "",
      ),
    );
    final data = configData.config;
    final maxIndexWidth = (log(data.length) * log10e).truncate();
    final maxKeyWidth = data.keys
        .map((e) => e.length)
        .reduce((a, b) => max(a, b));
    for (var (i, MapEntry(:key, :value)) in data.entries.indexed) {
      print(
        "${i.toString().padRight(maxIndexWidth)} - ${key.padRight(maxKeyWidth)}: ${json.encode(value)}",
      );
    }
  }
}
