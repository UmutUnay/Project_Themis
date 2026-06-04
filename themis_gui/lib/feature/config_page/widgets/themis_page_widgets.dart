part of "themis_widget.dart";

/// Page that nests items.
class ThemisSubpage extends ThemisWidget<NestedItem> {
  const ThemisSubpage(super.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return _ThemisBlankpage(
      title: item.title,
      child: Column(
        spacing: 8,
        children: [
          SizedBox(height: 24),
          DefaultTextStyle(
            style: Theme.of(context).textTheme.titleLarge!,
            child: Text(item.title),
          ),
          if (item.description != "")
            DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!,
              child: Text(item.description),
            ),
          SizedBox(height: 24),
          Wrap(
            direction: .horizontal,
            alignment: .center,
            crossAxisAlignment: .center,
            children: [...item.items.map((it) => ThemisWidget.fromItem(it))],
          ),
        ],
      ),
    );
  }
}

/// A blank configuration page.
class _ThemisBlankpage extends StatelessWidget {
  final String title;
  final Widget child;
  const _ThemisBlankpage({required this.title, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = Provider.of<ConfigDataCubit?>(context, listen: false);
    final pluginCubit = Provider.of<ThemisPluginCubit?>(context, listen: false);
    final settings = BlocProvider.of<SavedSettingsCubit>(
      context,
      listen: false,
    );
    // BlocProvider doesn't accept nullable type
    return CallbackShortcuts(
      bindings: {
        SingleActivator(.keyS, control: true): () async {
          if (cubit != null && cubit.state.modified) {
            final success = await cubit.saveConfig();
            if (context.mounted) {
              notifySuccess(
                context,
                success,
                successText: "Settings saved.",
                failureText: "Couldn't save, config invalid.",
              );
            }
          }
        },
      },
      child: YaruDetailPage(
        appBar: YaruWindowTitleBar(
          border: BorderSide.none,
          leading: Navigator.of(context).canPop()
              ? const YaruBackButton()
              : null,
          title: Text(title),
          actions: [
            if (settings.state.debugData.showTestButton)
              Tooltip(
                message: "Send test message",
                child: OutlinedButton(
                  onPressed: () async {
                    final result = await ThemisClient.instance.testPlugin(
                      Provider.of<ThemisPluginCubit>(
                        context,
                        listen: false,
                      ).state.brief.pluginId,
                    );
                    if (context.mounted) {
                      notifySuccess(
                        context,
                        result,
                        successText: "Ping successful.",
                        failureText: "Ping unsuccessful.",
                      );
                    }
                  },
                  style: ButtonStyle(
                    padding: WidgetStatePropertyAll(
                      .symmetric(horizontal: 8, vertical: 16),
                    ),
                  ),
                  child: Icon(Icons.message_outlined),
                ),
              ),
            if (settings.state.debugData.showTestButton) SizedBox(width: 8),
            if (pluginCubit != null)
              Tooltip(
                message: "Show reset to default buttons",
                child: BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
                  bloc: pluginCubit,
                  selector: (state) => state.showResetToDefaultButtons,
                  builder: (context, state) => OutlinedButton(
                    onPressed: () => Provider.of<ThemisPluginCubit>(
                      context,
                      listen: false,
                    ).setShowResetToDefault(!state),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        state
                            ? ColorScheme.of(context).secondaryContainer
                            : null,
                      ),
                      padding: WidgetStatePropertyAll(
                        .symmetric(horizontal: 8, vertical: 16),
                      ),
                    ),
                    child: Icon(
                      state ? Icons.visibility : Icons.visibility_off,
                      color: state ? ColorScheme.of(context).primary : null,
                    ),
                  ),
                ),
              ),
            if (pluginCubit != null) SizedBox(width: 8),
            Tooltip(
              message: "Backup options",
              child: OutlinedButton(
                onPressed: () => showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (context) =>
                      _BackupDialog(brief: pluginCubit!.state.brief),
                ),
                style: ButtonStyle(
                  padding: WidgetStatePropertyAll(
                    .symmetric(horizontal: 8, vertical: 16),
                  ),
                ),
                child: Icon(Icons.backup),
              ),
            ),
            if (pluginCubit != null) SizedBox(width: 8),
            Tooltip(
              message: "Restart system",
              child: OutlinedButton(
                onPressed: () async {
                  final success = await ThemisClient.instance.restartPlugin(
                    Provider.of<ThemisPluginCubit>(
                      context,
                      listen: false,
                    ).state.brief.pluginId,
                  );
                  if (context.mounted) {
                    notifySuccess(
                      context,
                      success,
                      successText: "System restarted.",
                      failureText: "Restart unsuccessful.",
                    );
                  }
                },
                style: ButtonStyle(
                  padding: WidgetStatePropertyAll(
                    .symmetric(horizontal: 8, vertical: 16),
                  ),
                ),
                child: Icon(Icons.restart_alt),
              ),
            ),
            SizedBox(width: 8),
            if (pluginCubit != null)
              Tooltip(
                message: "Restart on save",
                child: BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
                  bloc: pluginCubit,
                  selector: (state) => state.autoRestart,
                  builder: (context, state) => OutlinedButton(
                    onPressed: () => Provider.of<ThemisPluginCubit>(
                      context,
                      listen: false,
                    ).setAutoRestart(!state),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        state
                            ? ColorScheme.of(context).secondaryContainer
                            : null,
                      ),
                      padding: WidgetStatePropertyAll(
                        .symmetric(horizontal: 8, vertical: 16),
                      ),
                    ),
                    child: Icon(
                      Icons.motion_photos_auto,
                      color: state ? ColorScheme.of(context).primary : null,
                    ),
                  ),
                ),
              ),
            if (pluginCubit != null) SizedBox(width: 8),
            if (cubit != null)
              BlocSelector<ConfigDataCubit, ConfigInterface, bool>(
                bloc: cubit,
                selector: (state) => state.modified,
                builder: (context, state) => Row(
                  spacing: 8,
                  children: [
                    Tooltip(
                      message: "Save",
                      child: OutlinedButton(
                        onPressed: state
                            ? () async {
                                final success = await cubit.saveConfig();
                                if (context.mounted) {
                                  notifySuccess(
                                    context,
                                    success,
                                    successText: "Settings saved.",
                                    failureText:
                                        "Couldn't save, config invalid.",
                                  );
                                }
                              }
                            : null,
                        style: ButtonStyle(
                          padding: WidgetStatePropertyAll(
                            .symmetric(horizontal: 8, vertical: 16),
                          ),
                        ),
                        child: Icon(
                          YaruIcons.floppy,
                          color: state
                              ? saveIconColor
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: "Discard",
                      child: OutlinedButton(
                        onPressed: state ? cubit.resetConfig : null,
                        style: ButtonStyle(
                          padding: WidgetStatePropertyAll(
                            .symmetric(horizontal: 8, vertical: 16),
                          ),
                        ),
                        child: Icon(
                          YaruIcons.refresh,
                          color: state
                              ? discardIconColor
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(width: 8),
          ],
        ),
        body: SizedBox(
          width: 10000,
          child: BlocBuilder<ThemisPluginCubit, ThemisPluginData>(
            builder: (context, state) => SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }
}

/// Confirmation dialog for GUI settings reset.
class _BackupDialog extends StatelessWidget {
  final ThemisPluginBrief brief;
  const _BackupDialog({required this.brief, super.key});

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        title: YaruDialogTitleBar(title: Text("Backups of ${brief.title}")),
        actions: [
          OutlinedButton(
            onPressed: () async {
              final success = await ThemisClient.instance.createBackup(
                brief.pluginId,
              );
              if (context.mounted) {
                notifySuccess(
                  context,
                  success,
                  successText: "Backup created.",
                  failureText: "Backup creation failed.",
                );
                setState(() {});
              }
            },
            child: Text("Create Backup"),
          ),
        ],
        content: SingleChildScrollView(
          child: FutureBuilder<List<BackupData>>(
            future: ThemisClient.instance.getBackups(brief.pluginId),
            initialData: [],
            builder: (context, snapshot) => Column(
              spacing: 4,
              children: snapshot.data!
                  .map(
                    (e) => YaruSection(
                      padding: .symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        spacing: 8,
                        children: [
                          Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              Text("Id"),
                              DefaultTextStyle(
                                style: TextStyle(
                                  fontFamily:
                                      'IBMPlexMono', // Style doesn't work!
                                  fontSize: Theme.of(
                                    context,
                                  ).textTheme.bodySmall!.fontSize,
                                ),
                                child: Text(e.id),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              Text("Path"),
                              DefaultTextStyle(
                                style: TextStyle(
                                  fontFamily:
                                      'IBMPlexMono', // Style doesn't work!
                                  fontSize: Theme.of(
                                    context,
                                  ).textTheme.bodySmall!.fontSize,
                                ),
                                child: Text(e.path),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  final success = await ThemisClient.instance
                                      .restoreBackup(brief.pluginId, e.id);
                                  if (context.mounted) {
                                    notifySuccess(
                                      context,
                                      success,
                                      successText:
                                          "Backup restored. Please reload the page immediately.",
                                      failureText: "Backup restoration failed.",
                                      indefinite: success,
                                    );
                                    setState(() {});
                                  }
                                },
                                child: Text("Restore (overwrite)"),
                              ),
                              // OutlinedButton(
                              //   style: ButtonStyle(
                              //     backgroundColor: WidgetStatePropertyAll(
                              //       deleteIconColor,
                              //     ),
                              //   ),
                              //   onPressed: () async {
                              //     final success = await ThemisClient.instance
                              //         .restoreBackup(brief.pluginId, e.id);
                              //     if (context.mounted) {
                              //       notifySuccess(
                              //         context,
                              //         success,
                              //         successText: "Backup deleted.",
                              //         failureText: "Backup deletion failed.",
                              //       );
                              //       setState(() {});
                              //     }
                              //   },
                              //   child: Text("Delete"),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
