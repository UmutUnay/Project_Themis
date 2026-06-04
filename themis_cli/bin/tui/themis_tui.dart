import 'dart:io';

import 'package:nocterm/nocterm.dart';

import 'themis_component/themis_plugins_page.dart';
import 'util/widget/navigable_flex.dart';
import 'util/widget/provider.dart';
import 'util/widget/scaffold.dart';
import 'util/widget/stream_builder.dart';
import 'util/theme.dart';

class ThemisTui extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return InheritedProvider<PageTitle>(
      value: PageTitle("Themis TUI"),
      child: Scaffold(child: ThemisPluginsPage()),
    );
  }
}
