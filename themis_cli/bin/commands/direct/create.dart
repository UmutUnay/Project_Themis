import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';
import '../../printing/misc.dart';
import '../../printing/confirmation.dart';

/// Creates a new config file.
class CreateCommand extends Command {
  @override
  String get description => "Creates a new config file.";

  @override
  String get name => "create";

  @override
  String get category => "Modify";

  CreateCommand() {
    argParser
      ..addOption(
        "pluginId",
        abbr: "p",
        help: "Id of the plugin of interest",
        mandatory: true,
      )
      ..addOption(
        "configType",
        abbr: "t",
        help: "Type of the config file to create.",
        mandatory: true,
      )
      ..addOption(
        "configId",
        abbr: "c",
        help:
            "Id suggestion for the new config file. Can be ignored by the plugin.",
        mandatory: true,
      )
      ..addOption(
        "title",
        help: "File title to show on the ui.",
        mandatory: true,
      );
  }

  @override
  FutureOr<dynamic>? run() async {
    final pluginId = argResults!.option("pluginId")!;
    final configType = argResults!.option("configType")!;
    final configId = argResults!.option("configId")!;
    final title = argResults!.option("title")!;
    final success = await ThemisClient.instance.createConfig(
      ConfigFileBrief(
        pluginId: pluginId,
        configId: configId,
        configType: configType,
        title: title,
      ),
    );
    printSuccess(success);
  }
}
