import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';
import '../../printing/misc.dart';
import '../../printing/confirmation.dart';

/// Sets a key of an existing config file to the given value.
class SetCommand extends Command {
  @override
  String get description =>
      "Sets a key of an existing config file to the given value.";

  @override
  String get name => "set";

  @override
  String get category => "Modify";

  SetCommand() {
    argParser
      ..addOption(
        "pluginId",
        abbr: "p",
        help: "Id of the plugin of interest",
        mandatory: true,
      )
      ..addOption(
        "configId",
        abbr: "c",
        help: "Id of the config file to write.",
        mandatory: true,
      )
      ..addOption(
        "key",
        abbr: "k",
        help: "Key to set. String.",
        valueHelp: "\"my_key\"",
        mandatory: true,
      )
      ..addOption(
        "value",
        abbr: "v",
        help: "Value to set. Json value.",
        valueHelp: "\"\\\"my_string_value\\\"\"",
      )
      ..addOption(
        "source",
        help: "Path of a file containing the raw json value to set.",
      )
      ..addFlag("force", abbr: "f", help: "Don't ask for confirmation.");
  }

  @override
  FutureOr<dynamic>? run() async {
    final pluginId = argResults!.option("pluginId")!;
    final configId = argResults!.option("configId")!;
    final key = argResults!.option("key")!;
    var value = argResults!.option("value");
    final path = argResults!.option("source");

    if (value != null) {
      value = json.decode(value);
    } else if (path != null) {
      final file = File(path);
      final fileContents = file.readAsStringSync();
      value = json.decode(fileContents);
    } else {
      throw UsageException("Write called without value or source.", usage);
    }

    var configData = await ThemisClient.instance.getConfig(
      ConfigFileBrief(
        pluginId: argResults!.option("pluginId")!,
        configId: argResults!.option("configId")!,
        configType: "",
        title: "",
      ),
    );
    if (!configData.config.containsKey(key)) {
      print(
        "Warning: The key ${json.encode(key)} wasn't found in the config file.",
      );
    }
    final go =
        argResults!.flag("force") ||
        askConfirmation(
          "Set key ${json.encode(key)} of $configId from $pluginId to ${json.encode(value)}?",
          false,
        );
    if (go) {
      final success = await ThemisClient.instance.setConfig(
        pluginId,
        configId,
        configData.config..[key] = value,
      );
      printSuccess(success);
    }
  }
}
