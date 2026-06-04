import 'package:nocterm/nocterm.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

import '../cubit/config_file_cubit.dart';
import '../cubit/themis_plugin_cubit.dart';
import '../util/widget/double_pane_page.dart';
import '../util/widget/future_builder.dart';
import '../util/widget/navigable_flex.dart';
import '../util/widget/provider.dart';
import '../util/widget/scaffold.dart';
import 'themis_component.dart';

class ThemisPluginsPage extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return FutureBuilder<List<ThemisPluginBrief>>(
      future: ThemisClient.instance.getPlugins(),
      initialData: [],
      builder: (context, data) => NavigableScope(
        initialFocus: 0,
        unselectOnEscape: true,
        builder: (context, selected, select, focused, focus) {
          final actions = [
            Action("Open UI", () {
              Navigator.of(context).pushThemisPage(
                ThemisPluginPage(data![focused]),
                data[focused].title,
              );
            }),
            Action("List Config Files", () {}),
            Action("Create Config File", () {}),
            Action("Restart", () {}),
            Action("Send Debug Message", () {}),
          ];
          return DoublePanePage(
            leftPaneRatio: 0.4,
            maxLeftPaneWidth: 80,
            leftPane: Pane(
              title: data![focused].title,
              body: Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: BoxBorder(bottom: BorderSide()),
                    ),
                    child: Row(
                      mainAxisAlignment: .spaceEvenly,
                      children: [
                        Row(
                          children: [
                            Text(
                              "id ",
                              style: TextStyle(
                                color: TuiTheme.of(context).secondary,
                              ),
                            ),
                            Text(data[focused].pluginId),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "v ",
                              style: TextStyle(
                                color: TuiTheme.of(context).secondary,
                              ),
                            ),
                            Text(data[focused].pluginVersion),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(data[focused].subtitle),
                  SizedBox(height: 2),
                  Pane(
                    title: "Actions",
                    body: NavigableColumn(
                      onSelected: (selected) {
                        actions[selected].onSelected();
                        return true;
                      },
                      isFocused: selected != null,
                      spacing: 1,
                      children: actions
                          .map((action) => Text(action.name))
                          .toList(),
                    ),
                  ).buildPane(context),
                ],
              ),
            ),
            rightPane: Pane(
              title: "Plugins",
              selected: selected == null,
              body: InheritedProvider(
                value: true,
                child: NavigableColumn(
                  mainAxisSize: .min,
                  children: data
                      .map((brief) => Column(children: [Text(brief.title)]))
                      .toList(),
                  onSelected: select,
                  onFocused: focus,
                  isFocused: selected == null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Action {
  final String name;
  final VoidCallback onSelected;

  const Action(this.name, this.onSelected);
}

class ThemisPluginPage extends StatelessComponent {
  final ThemisPluginBrief brief;
  const ThemisPluginPage(this.brief, {super.key});

  @override
  Component build(BuildContext context) {
    return FutureBuilder<ThemisPluginData?>(
      future: ThemisClient.instance.getData(brief),
      builder: (context, data) {
        if (data != null) {
          final main = data.ui['main']!.first;
          return ChangeNotifierProvider(
            changeNotifier: ThemisPluginCubit(data),
            child: FutureBuilder<ConfigFileData?>(
              future: ThemisClient.instance.getConfig(data.mainConfigBrief),
              initialData: null,
              builder: (context, data) {
                if (data != null) {
                  return ChangeNotifierProvider<
                    ConfigDataCubit<ConfigInterface>
                  >(
                    changeNotifier: ConfigFileCubit(
                      data,
                      pluginCubit: InheritedProvider.of<ThemisPluginCubit>(
                        context,
                        listen: false,
                      )!,
                    ),
                    child: ThemisComponent.fromItem(main),
                  );
                }
                return SizedBox();
              },
            ),
          );
        }
        return SizedBox();
      },
    );
  }
}
