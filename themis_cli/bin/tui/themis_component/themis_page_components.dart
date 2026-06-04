part of "themis_component.dart";

/// Page that nests items.
class ThemisSubpage extends ThemisComponent<NestedItem> {
  const ThemisSubpage(super.item, {super.key});

  @override
  Component build(BuildContext context) {
    final size = InheritedProvider.of<Size>(context)!;
    return _ThemisBlankpage(
      child: NavigableScope(
        initialFocus: 0,
        unselectOnEscape: true,
        builder: (context, selected, select, focused, focus) {
          final pluginActions = [];
          return DoublePanePage(
            leftPaneRatio: 0.4,
            maxLeftPaneWidth: 60,
            leftPane: Pane(
              title: "Selected Item",
              body: Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: BoxBorder(bottom: BorderSide()),
                    ),
                    child: Column(
                      children: [Text(item.title), Text(item.description)],
                    ),
                  ),
                  Text(item.items[focused].title),
                ],
              ),
            ),
            rightPane: Pane(
              title: item.title,
              selected: selected == null,
              body: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: .horizontal,
                    child: Builder(
                      builder: (context) {
                        final size = InheritedProvider.of<Size>(context)!;
                        return NavigableGrid(
                          mainAxisDirection: .horizontal,
                          crossAxisCount: (size.height.toInt() - 4) ~/ 8,
                          mainAxisExtent: size.width / 2 - 4,
                          crossAxisAlignment: .center,
                          children: [
                            ...item.items.map(
                              (it) => ThemisComponent.fromItem(it),
                            ),
                          ],
                          onSelected: select,
                          onFocused: focus,
                          isFocused: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A blank configuration page.
class _ThemisBlankpage extends StatelessComponent {
  final Component child;
  const _ThemisBlankpage({required this.child, super.key});

  @override
  Component build(BuildContext context) {
    final cubit = InheritedProvider.of<ConfigDataCubit>(context, listen: false);
    final pluginCubit = InheritedProvider.of<ThemisPluginCubit>(
      context,
      listen: false,
    );
    // BlocProvider doesn't accept nullable type
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        switch (event) {
          case KeyboardEvent(logicalKey: .keyS, isControlPressed: true):
            if (cubit != null && cubit.state.modified) {
              Future.microtask(() async {
                final success = await cubit.saveConfig();
                if (!success) {
                  Navigator.of(context).showDialog(
                    builder: (context) {
                      Future.microtask(() => Navigator.of(context).pop());
                      return Text("Couldn't save, settings invalid.");
                    },
                  );
                }
              });
              return true;
            }
            return false;
          default:
            return false;
        }
      },
      child: Column(
        crossAxisAlignment: .center,
        children: [
          Row(
            children: [
              Row(
                children: [
                  // if (pluginCubit != null)
                  //   Selector<ThemisPluginCubit, bool>(
                  //     provided: pluginCubit,
                  //     selector: (provided) =>
                  //         provided.state.showResetToDefaultButtons,
                  //     builder: (context, state) => GestureDetector(
                  //       onTap: () => InheritedProvider.of<ThemisPluginCubit>(
                  //         context,
                  //         listen: false,
                  //       )!.setShowResetToDefault(!state),
                  //       // style: ButtonStyle(
                  //       //   backgroundColor: WidgetStatePropertyAll(
                  //       //     state
                  //       //         ? ColorScheme.of(context).secondaryContainer
                  //       //         : null,
                  //       //   ),
                  //       //   padding: WidgetStatePropertyAll(
                  //       //     .symmetric(horizontal: 8, vertical: 16),
                  //       //   ),
                  //       // ),
                  //       child: Text("R"),
                  //     ),
                  //   ),
                  // if (pluginCubit != null) SizedBox(width: 1),
                  // Tooltip(
                  //   message: "Restart system",
                  //   child: OutlinedButton(
                  //     onPressed: () => ThemisClient.instance.restartPlugin(
                  //       Provider.of<ThemisPluginCubit>(
                  //         context,
                  //         listen: false,
                  //       ).state.brief.pluginId,
                  //     ),
                  //     style: ButtonStyle(
                  //       padding: WidgetStatePropertyAll(
                  //         .symmetric(horizontal: 8, vertical: 16),
                  //       ),
                  //     ),
                  //     child: Icon(Icons.restart_alt),
                  //   ),
                  // ),
                  // SizedBox(width: 8),
                  // if (pluginCubit != null)
                  //   Tooltip(
                  //     message: "Restart on save",
                  //     child:
                  //         BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
                  //           bloc: pluginCubit,
                  //           selector: (state) => state.autoRestart,
                  //           builder: (context, state) => OutlinedButton(
                  //             onPressed: () => Provider.of<ThemisPluginCubit>(
                  //               context,
                  //               listen: false,
                  //             ).setAutoRestart(!state),
                  //             style: ButtonStyle(
                  //               backgroundColor: WidgetStatePropertyAll(
                  //                 state
                  //                     ? ColorScheme.of(context).secondaryContainer
                  //                     : null,
                  //               ),
                  //               padding: WidgetStatePropertyAll(
                  //                 .symmetric(horizontal: 8, vertical: 16),
                  //               ),
                  //             ),
                  //             child: Icon(
                  //               Icons.motion_photos_auto,
                  //               color: state
                  //                   ? ColorScheme.of(context).primary
                  //                   : null,
                  //             ),
                  //           ),
                  //         ),
                  //   ),
                  // if (pluginCubit != null) SizedBox(width: 8),
                  // if (cubit != null)
                  //   BlocSelector<ConfigDataCubit, ConfigInterface, bool>(
                  //     bloc: cubit,
                  //     selector: (state) => state.modified,
                  //     builder: (context, state) => Row(
                  //       spacing: 8,
                  //       children: [
                  //         Tooltip(
                  //           message: "Save",
                  //           child: OutlinedButton(
                  //             onPressed: state
                  //                 ? () async {
                  //                     final scaffold = ScaffoldMessenger.of(
                  //                       context,
                  //                     );
                  //                     final success = await cubit.saveConfig();
                  //                     if (!success) {
                  //                       scaffold.showSnackBar(
                  //                         SnackBar(
                  //                           content: Text(
                  //                             "Couldn't save, settings invalid.",
                  //                           ),
                  //                         ),
                  //                       );
                  //                     }
                  //                   }
                  //                 : null,
                  //             style: ButtonStyle(
                  //               padding: WidgetStatePropertyAll(
                  //                 .symmetric(horizontal: 8, vertical: 16),
                  //               ),
                  //             ),
                  //             child: Icon(
                  //               YaruIcons.floppy,
                  //               color: state
                  //                   ? saveIconColor
                  //                   : Theme.of(context).disabledColor,
                  //             ),
                  //           ),
                  //         ),
                  //         Tooltip(
                  //           message: "Discard",
                  //           child: OutlinedButton(
                  //             onPressed: state ? cubit.resetConfig : null,
                  //             style: ButtonStyle(
                  //               padding: WidgetStatePropertyAll(
                  //                 .symmetric(horizontal: 8, vertical: 16),
                  //               ),
                  //             ),
                  //             child: Icon(
                  //               YaruIcons.refresh,
                  //               color: state
                  //                   ? discardIconColor
                  //                   : Theme.of(context).disabledColor,
                  //             ),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // SizedBox(width: 8),
                ],
              ),
            ],
          ),
          Selector<ThemisPluginCubit, ThemisPluginData>(
            selector: (provided) => provided.state,
            builder: (context, state) => SingleChildScrollView(child: child),
          ),
        ],
      ),
    );
  }
}
