import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

/// Prints the value stored at a key of a config file.
class GetCommand extends Command {
  @override
  String get description =>
      "Prints the value stored at a key of a config file.";

  @override
  String get name => "get";

  @override
  String get category => "Retrieve";

  GetCommand() {
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
      )
      ..addOption("key", abbr: "k", help: "Key to get.", mandatory: true);
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
    print(json.encode(configData.config[argResults!.option("key")!]));
  }
}
