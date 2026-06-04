import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

import 'commands/direct/create.dart';
import 'commands/direct/delete.dart';
import 'commands/direct/get.dart';
import 'commands/direct/install_plugin.dart';
import 'commands/direct/list.dart';
import 'commands/direct/print.dart';
import 'commands/direct/read.dart';
import 'commands/direct/restart.dart';
import 'commands/direct/set.dart';
import 'commands/direct/test.dart';
import 'commands/direct/write.dart';
import 'commands/interactive/start_tui.dart';

const String version = '0.0.1';

void addParams(ArgParser parser) => parser
  ..addFlag(
    "dev",
    help: "Use te test client for development purposes.",
    hide: true,
  )
  ..addOption(
    "server",
    abbr: "s",
    help: "The address of themis http api server.",
    valueHelp: "http://...",
    defaultsTo: themisLocalhostAddress,
  )
  ..addOption("auth", help: "Auth token for the server.", hide: true)
  ..addOption("username", help: "Username to login to the server.", hide: true)
  ..addOption("password", help: "Password to login to the server.", hide: true)
  ..addFlag("version", negatable: false, help: "Print the tool version.");

void main(List<String> arguments) async {
  final runner =
      CommandRunner("themis_cli", "Command line interface for Project Themis")
        ..addCommand(ListPluginsCommand())
        ..addCommand(ListConfigFilesCommand())
        ..addCommand(PrintCommand())
        ..addCommand(ReadCommand())
        ..addCommand(GetCommand())
        ..addCommand(SetCommand())
        ..addCommand(WriteCommand())
        ..addCommand(CreateCommand())
        ..addCommand(DeleteCommand())
        ..addCommand(RestartCommand())
        ..addCommand(InstallLocalPluginCommand())
        ..addCommand(TestCommand())
        ..addCommand(StartTuiCommand());
  addParams(runner.argParser);
  try {
    final ArgResults results = runner.parse(arguments);
    if (results.flag("version")) {
      print("themis_cli version: $version");
      return;
    }
    ThemisClient client;
    if (results.flag("dev")) {
      client = TestThemisClient.demo();
    } else {
      var auth = results.option("auth");
      client = HttpThemisClient(auth ?? "", results.option("server")!);
      // if (auth == null) {
      //   final username = results.option("username");
      //   final password = results.option("password");
      //   if (username == null || password == null) {
      //     throw UsageException(
      //       "Either auth token or username & password is required.",
      //       runner.usage,
      //     );
      //   }
      //   auth = await client.login(username, password);
      //   client = HttpThemisClient(auth, results.option("server")!);
      // }
    }
    await ThemisClient.trySetInstance(client);
    await runner.runCommand(results);
  } on FormatException catch (e) {
    print(e.message);
    print('');
    print(runner.usage);
  } on UsageException catch (e) {
    print(e);
  }
}
