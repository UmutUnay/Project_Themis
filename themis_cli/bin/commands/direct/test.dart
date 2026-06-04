import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

/// Sends test message to the plugin.
class TestCommand extends Command {
  @override
  String get description => "Sends test message to the plugin.";

  @override
  String get name => "test";

  @override
  String get category => "Management";

  TestCommand() {
    argParser.addOption(
      "pluginId",
      abbr: "p",
      help: "Id of the plugin of interest.",
      mandatory: true,
    );
  }

  @override
  FutureOr<dynamic>? run() async {
    await ThemisClient.instance.testPlugin(argResults!.option("pluginId")!);
  }
}
