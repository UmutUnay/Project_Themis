import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

/// Installs the plugin found at a path on the server.
class InstallLocalPluginCommand extends Command {
  @override
  String get description =>
      """Installs the plugin found at a path on the server.
      The file isn't transferred between this computer and the server, it needs to be on the server already.""";

  @override
  String get name => "install_local";

  @override
  String get category => "Management";

  InstallLocalPluginCommand() {
    argParser
      ..addOption(
        "path",
        abbr: "p",
        help: "Path of the plugin to install on the server.",
        mandatory: true,
      )
      ..addFlag(
        "relative",
        abbr: "r",
        help:
            "Convert relative path to absolute. Only relevant if the server is running on this computer.",
      );
  }

  @override
  FutureOr<dynamic>? run() async {
    var path = argResults!.option("path")!;
    final relative = argResults!.flag("relative");
    if (relative) path = File(path).absolute.path;
    await ThemisClient.instance.installLocalPlugin(path);
  }
}
