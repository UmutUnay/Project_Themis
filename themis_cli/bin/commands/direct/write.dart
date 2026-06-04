import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';
import '../../printing/misc.dart';
import '../../printing/confirmation.dart';

/// Overwrites an existing config file with the contents of the given file.
class WriteCommand extends Command {
  @override
  String get description =>
      "Overwrites an existing config file with the contents of the given file.";

  @override
  String get name => "write";

  @override
  String get category => "Modify";

  WriteCommand() {
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
        "source",
        help: "Path to the source file to overwrite with.",
        mandatory: true,
      )
      ..addOption("force", abbr: "f", help: "Don't ask for confirmation.");
  }

  @override
  FutureOr<dynamic>? run() async {
    final pluginId = argResults!.option("pluginId")!;
    final configId = argResults!.option("configId")!;
    final path = argResults!.option("source")!;
    final file = File(path);
    final go =
        argResults!.flag("force") ||
        askConfirmation(
          "Overwrite $configId from $pluginId with the contents of ${file.absolute.path}?",
          false,
        );
    if (go) {
      final fileContents = file.readAsStringSync();
      final fileConfig = json.decode(fileContents);
      final success = await ThemisClient.instance.setConfig(
        pluginId,
        configId,
        fileConfig,
      );
      printSuccess(success);
    }
  }
}
