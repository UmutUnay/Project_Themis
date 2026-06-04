import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';
import '../../printing/misc.dart';
import '../../printing/confirmation.dart';

/// Deletes a config file.
class DeleteCommand extends Command {
  @override
  String get description => "Deletes a config file.";

  @override
  String get name => "delete";

  @override
  String get category => "Modify";

  DeleteCommand() {
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
        help: "Id of the file to delete.",
        mandatory: true,
      );
  }

  @override
  FutureOr<dynamic>? run() async {
    final pluginId = argResults!.option("pluginId")!;
    final configId = argResults!.option("configId")!;
    final success = await ThemisClient.instance.deleteConfig(
      ConfigFileBrief(
        pluginId: pluginId,
        configId: configId,
        configType: "",
        title: "",
      ),
    );
    printSuccess(success);
  }
}
