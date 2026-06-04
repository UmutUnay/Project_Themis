import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

/// Restarts the system managed by a plugin.
class RestartCommand extends Command {
  @override
  String get description => "Restarts the system managed by a plugin.";

  @override
  String get name => "restart";

  @override
  String get category => "Management";

  RestartCommand() {
    argParser.addOption(
      "pluginId",
      abbr: "p",
      help: "Id of the plugin of interest.",
      mandatory: true,
    );
  }

  @override
  FutureOr<dynamic>? run() async {
    await ThemisClient.instance.restartPlugin(argResults!.option("pluginId")!);
  }
}
