import 'dart:io';
import 'dart:math';

import 'package:nocterm/nocterm.dart';

import 'provider.dart';
import 'stream_builder.dart';
import '../theme.dart';

class Scaffold extends StatelessComponent {
  final Component child;

  Scaffold({required this.child, super.key});

  @override
  Component build(BuildContext context) {
    return Navigator(
      home: Builder(
        builder: (context) => KeyboardListener(
          autofocus: true,
          onKeyEvent: (key) {
            switch (key) {
              case LogicalKey.keyQ:
                exit(0);
              default:
                return false;
            }
          },
          child: TuiTheme(
            data: themisTheme,
            child: ColoredBox(
              color: themisTheme.background,
              child: StreamBuilder(
                stream: TerminalBinding.instance.terminal.backend.resizeStream!,
                initialData: TerminalBinding.instance.terminal.size,
                builder: (context, data) =>
                    InheritedProvider(value: data!, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension type PageTitle(String title) {
  PageTitle push(String node) => PageTitle("$title > $node");
  double helpWidth(BuildContext context) =>
      InheritedProvider.of<Size>(context, listen: false)!.width -
      3 -
      title.length;
}

extension PushThemisPageExtension on NavigatorState {
  Future<T?> pushThemisPage<T>(Component child, String title) {
    final pageTitle = InheritedProvider.of<PageTitle>(context, listen: false)!;
    return pushComponent<T>(
      InheritedProvider<PageTitle>(
        value: pageTitle.push(title),
        child: Scaffold(child: child),
      ),
    );
  }
}
