/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-17 16:06:50
 * @LastEditTime: 2026-03-08 12:35:04
 * @Description: 
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';
import 'package:yaru/yaru.dart';

import '../../../core/misc/extensions.dart';
import '../cubit/config_file_cubit.dart';
import '../cubit/themis_plugin_cubit.dart';
import '../widgets/themis_widget.dart';

/// Plugins screen.
class ThemisPluginsPage extends StatefulWidget {
  const ThemisPluginsPage({super.key});

  @override
  State<ThemisPluginsPage> createState() => _ThemisPluginsPageState();
}

class _ThemisPluginsPageState extends State<ThemisPluginsPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ThemisPluginBrief>>(
      future: ThemisClient.instance.getPlugins(),
      initialData: [],
      builder: (context, snapshot) => YaruMasterDetailPage(
        appBar: YaruWindowTitleBar(
          title: const Text('Plugins'),
          border: BorderSide.none,
          backgroundColor: YaruMasterDetailTheme.of(context).sideBarColor,
          actions: [
            SizedBox(width: 8),
            Material(
              type: .transparency,
              child: YaruIconButton(
                icon: Icon(YaruIcons.settings),
                onPressed: () => context.push('/settings'),
              ),
            ),
            SizedBox(width: 8),
          ],
          leading: Navigator.of(context).canPop()
              ? const YaruBackButton()
              : null,
        ),
        length: snapshot.data!.length,
        paneLayoutDelegate: YaruFixedPaneDelegate(paneSize: 240),
        tileBuilder: (context, index, selected, availableWidth) =>
            YaruMasterTile(
              title: Text(snapshot.data![index].title),
              subtitle: Text.new.callMaybe(snapshot.data![index].subtitle),
            ),
        pageBuilder: (context, index) =>
            ThemisPluginPage(snapshot.data![index]),
        onSelected: (value) {},
        emptyBuilder: (context) => YaruDetailPage(
          appBar: YaruWindowTitleBar(
            title: const Text('Plugins'),
            border: BorderSide.none,
            backgroundColor: YaruMasterDetailTheme.of(context).sideBarColor,
            actions: [
              SizedBox(width: 8),
              Material(
                type: .transparency,
                child: YaruIconButton(
                  icon: Icon(YaruIcons.settings),
                  onPressed: () => context.push('/settings'),
                ),
              ),
              SizedBox(width: 8),
            ],
            leading: Navigator.of(context).canPop()
                ? const YaruBackButton()
                : null,
          ),
          body: Center(child: Text("You don't have any plugins installed.")),
        ),
      ),
    );
  }
}

class ThemisPluginPage extends StatelessWidget {
  final ThemisPluginBrief brief;
  const ThemisPluginPage(this.brief, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemisPluginData>(
      future: ThemisClient.instance.getData(brief),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          final main = data.ui['main']!.first;
          return BlocProvider(
            create: (_) => ThemisPluginCubit(data),
            child: FutureBuilder<ConfigFileData?>(
              future: ThemisClient.instance.getConfig(data.mainConfigBrief),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final data = snapshot.data!;
                  return BlocProvider<ConfigDataCubit<ConfigInterface>>(
                    create: (_) => ConfigFileCubit(
                      data,
                      pluginCubit: Provider.of<ThemisPluginCubit>(
                        context,
                        listen: false,
                      ),
                    ),
                    child: ThemisWidget.fromItem(main),
                  );
                }
                return Center();
              },
            ),
          );
        }
        return Center();
      },
    );
  }
}
