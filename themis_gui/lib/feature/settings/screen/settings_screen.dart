/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-24 13:31:55
 * @LastEditTime: 2025-11-25 00:20:29
 * @Description: 
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yaru/yaru.dart';

import '../../../core/misc/constants.dart';
import '../../../core/misc/extensions.dart';
import '../../../core/misc/print_success.dart';
import '../../../core/model/yaru_page_item.dart';
import '../cubit/settings_data.dart';
import '../widgets/exit_confirmation.dart';
import 'about_settings.dart';
import 'client_settings.dart';
import 'install_plugin_settings.dart';

/// GUI settings menu.
class GuiSettings extends StatelessWidget {
  final String? initialPageId;
  const GuiSettings({this.initialPageId, super.key});

  @override
  Widget build(BuildContext context) {
    final tempSettings = TempSettingsCubit(
      BlocProvider.of<SavedSettingsCubit>(context),
    );
    final child = YaruMasterDetailPage(
      appBar: YaruWindowTitleBar(
        title: const Text('Gui Settings'),
        border: BorderSide.none,
        backgroundColor: YaruMasterDetailTheme.of(context).sideBarColor,
        leading: YaruBackButton(
          onPressed: Navigator.of(context).canPop()
              ? null
              : () {
                  context.pushReplacement("/plugins");
                },
        ),
      ),
      initialIndex: initialPageId != null
          ? settingsItems.indexWhere((it) => it.id == initialPageId)
          : null,
      length: settingsItems.length,
      paneLayoutDelegate: YaruFixedPaneDelegate(paneSize: 240),
      tileBuilder: (context, index, selected, availableWidth) => YaruMasterTile(
        leading: settingsItems[index].iconBuilder(context, selected),
        title: Text(settingsItems[index].title),
        subtitle: Text.new.callMaybe(settingsItems[index].subtitle),
        // subtitle: Text.new[settingsItems[index].subtitle],
        // subtitle: settingsItems[index].subtitle?.apply(Text.new),
      ),
      pageBuilder: pageBuilder,
    );
    return BlocProvider.value(
      value: tempSettings,
      child: BlocSelector<TempSettingsCubit, TempSettingsData, bool>(
        selector: (settings) => !settings.settingsChanged,
        builder: (context, state) => PopScope(
          canPop: state,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              showDialog(
                barrierDismissible: true,
                context: context,
                builder: (context) => ExitConfirmationDialog(tempSettings),
              );
            }
          },
          child: child,
        ),
      ),
    );
  }

  Widget pageBuilder(BuildContext context, int index) {
    final cubit = Provider.of<TempSettingsCubit?>(context);
    // context.replace("/settings/${settingsItems[index].id}");
    return YaruDetailPage(
      appBar: YaruWindowTitleBar(
        border: BorderSide.none,
        title:
            settingsItems[index].titleBuilder?.call(context) ??
            Text(settingsItems[index].title),
        actions: [
          SizedBox(width: 8),
          if (cubit != null)
            BlocSelector<TempSettingsCubit, TempSettingsData, bool>(
              bloc: cubit,
              selector: (settings) =>
                  settings.canSaveSettings && settings.settingsChanged,
              builder: (context, state) => OutlinedButton(
                onPressed: state
                    ? () async {
                        final scaffold = ScaffoldMessenger.of(context);
                        final success =
                            await BlocProvider.of<TempSettingsCubit>(
                              context,
                            ).saveSettings();
                        if (context.mounted) {
                          notifySuccess(
                            context,
                            success,
                            successText: "Settings saved.",
                            failureText: "Couldn't save, settings invalid.",
                          );
                        }
                      }
                    : null,
                child: Row(
                  mainAxisSize: .min,
                  spacing: 4,
                  children: [
                    Icon(YaruIcons.floppy, color: state ? saveIconColor : null),
                    Text("Save"),
                  ],
                ),
              ),
            ),
          SizedBox(width: 8),
          if (cubit != null)
            BlocSelector<TempSettingsCubit, TempSettingsData, bool>(
              bloc: cubit,
              selector: (settings) => settings.settingsChanged,
              builder: (context, state) => OutlinedButton(
                onPressed: state
                    ? BlocProvider.of<TempSettingsCubit>(
                        context,
                      ).restoreSettings
                    : null,
                child: Row(
                  mainAxisSize: .min,
                  spacing: 4,
                  children: [
                    Icon(
                      YaruIcons.refresh,
                      color: state ? discardIconColor : null,
                    ),
                    Text("Discard"),
                  ],
                ),
              ),
            ),
          SizedBox(width: 8),
        ],
      ),
      body: settingsItems[index].pageBuilder(context),
      floatingActionButton: settingsItems[index].floatingActionButtonBuilder
          ?.call(context),
    );
  }
}

final settingsItems = <YaruPageItem>[
  YaruPageItem(
    title: "Account",
    id: "account",
    pageBuilder: (context) => ClientSettings(),
    iconBuilder: (context, selected) => selected
        ? const Icon(YaruIcons.user_filled)
        : const Icon(YaruIcons.user),
  ),
  YaruPageItem(
    title: "Install Plugin",
    id: "install",
    pageBuilder: (context) => InstallPluginSettings(),
    iconBuilder: (context, selected) => selected
        ? const Icon(YaruIcons.download_filled)
        : const Icon(YaruIcons.download),
  ),
  YaruPageItem(
    title: "About",
    id: "about",
    pageBuilder: (context) => AboutSettings(),
    iconBuilder: (context, selected) => selected
        ? const Icon(YaruIcons.information_filled)
        : const Icon(YaruIcons.information),
  ),
];
