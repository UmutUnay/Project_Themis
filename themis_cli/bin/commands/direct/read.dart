import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

/// Prints the raw contents of a config file.
class ReadCommand extends Command {
  @override
  String get description => "Prints the raw contents of a config file.";

  @override
  String get name => "read";

  @override
  String get category => "Retrieve";

  ReadCommand() {
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
    print(json.encode(configData.config));
  }
}
