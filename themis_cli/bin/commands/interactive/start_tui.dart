import 'dart:async';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:nocterm/nocterm.dart';
import 'package:themis_cli/tui/themis_tui.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

/// Opens the interactive tui.
class StartTuiCommand extends Command {
  @override
  String get description => "Opens the interactive tui.";

  @override
  String get name => "tui";

  @override
  String get category => "Interactive";

  @override
  bool get hidden => true;

  @override
  FutureOr<dynamic>? run() async {
    await runApp(ThemisTui());
  }
}
