part of "themis_component.dart";

// class Subui extends ThemisComponent<PlainSubuiItem> {
//   const Subui(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: .start,
//       mainAxisSize: .min,
//       spacing: 4,
//       children: [
//         ...BlocProvider.of<ThemisPluginCubit>(
//           context,
//           listen: false,
//         ).state.ui[item.subUiId]!.map((it) => ThemisComponent.fromItem(it)),
//       ],
//     );
//   }
// }

// class SubUiPageButton extends ThemisComponent<SubUiPageButtonItem> {
//   const SubUiPageButton(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     return _ThemisSubUiPageButton(
//       item: item,
//       title: item.title,
//       description: item.description,
//       getConfigCubit: (context) async =>
//           BlocProvider.of<ConfigDataCubit>(context, listen: false),
//     );
//   }
// }

// class ConfigFileList extends ThemisComponent<ConfigTypedSubuiItem> {
//   const ConfigFileList(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     final pluginCubit = BlocProvider.of<ThemisPluginCubit>(
//       context,
//       listen: false,
//     );
//     return StatefulBuilder(
//       builder: (context, setState) => FutureBuilder(
//         future: ThemisClient.instance.getConfigsOfType(
//           pluginCubit.state.brief.pluginId,
//           item.configType,
//         ),
//         builder: (context, snapshot) => snapshot.data == null
//             ? YaruCircularProgressIndicator()
//             : _ThemisSubUiList(
//                 title: item.title,
//                 description: item.description,
//                 itemCount: snapshot.data!.length,
//                 itemBuilder: (index) => FutureBuilder(
//                   future: ThemisClient.instance.getConfig(
//                     snapshot.data![index],
//                   ),
//                   builder: (context, snapshot) => snapshot.data == null
//                       ? YaruCircularProgressIndicator()
//                       : BlocProvider<ConfigDataCubit<ConfigInterface>>(
//                           create: (context) => ConfigFileCubit(
//                             snapshot.data!,
//                             pluginCubit: pluginCubit,
//                           ),
//                           child: Builder(
//                             builder: (context) => _ThemisSubUiListItem(
//                               item: item,
//                               save: () async {
//                                 final scaffold = ScaffoldMessenger.of(context);
//                                 final success =
//                                     await BlocProvider.of<ConfigDataCubit>(
//                                       context,
//                                       listen: false,
//                                     ).saveConfig();
//                                 if (!success) {
//                                   scaffold.showSnackBar(
//                                     SnackBar(
//                                       content: Text(
//                                         "Couldn't save, settings invalid.",
//                                       ),
//                                     ),
//                                   );
//                                 }
//                               },
//                               restore: BlocProvider.of<ConfigDataCubit>(
//                                 context,
//                                 listen: false,
//                               ).resetConfig,
//                               delete: () async {
//                                 final success = await ThemisClient.instance
//                                     .deleteConfig(snapshot.data!.brief);
//                                 if (success) setState(() {});
//                               },
//                               title: snapshot.data!.brief.title,
//                             ),
//                           ),
//                         ),
//                 ),
//                 add: () => showDialog(
//                   barrierDismissible: true,
//                   context: context,
//                   builder: (context) => _NewConfigDialog(
//                     create: (brief) async {
//                       final success = await ThemisClient.instance.createConfig(
//                         brief,
//                       );
//                       if (success) setState(() {});
//                     },
//                     pluginId: pluginCubit.state.brief.pluginId,
//                     configType: item.configType,
//                   ),
//                 ),
//                 refresh: () => setState(() {}),
//               ),
//       ),
//     );
//   }
// }

// class ConfigFilePageButtonList extends ThemisComponent<ConfigTypedSubuiItem> {
//   const ConfigFilePageButtonList(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     final pluginCubit = BlocProvider.of<ThemisPluginCubit>(
//       context,
//       listen: false,
//     );
//     return StatefulBuilder(
//       builder: (context, setState) => FutureBuilder(
//         future: ThemisClient.instance.getConfigsOfType(
//           pluginCubit.state.brief.pluginId,
//           item.configType,
//         ),
//         builder: (context, snapshot) => snapshot.data == null
//             ? YaruCircularProgressIndicator()
//             : _ThemisSubUiList(
//                 title: item.title,
//                 description: item.description,
//                 itemCount: snapshot.data!.length,
//                 itemBuilder: (index) => _ThemisSubUiListPageButton(
//                   item: item,
//                   delete: () async {
//                     final success = await ThemisClient.instance.deleteConfig(
//                       snapshot.data![index],
//                     );
//                     if (success) setState(() {});
//                   },
//                   getConfigCubit: () async => ConfigFileCubit(
//                     await ThemisClient.instance.getConfig(
//                       snapshot.data![index],
//                     ),
//                     pluginCubit: pluginCubit,
//                   ),
//                   title: snapshot.data![index].title,
//                   description: "",
//                 ),
//                 add: () => showDialog(
//                   barrierDismissible: true,
//                   context: context,
//                   builder: (context) => _NewConfigDialog(
//                     create: (brief) async {
//                       final success = await ThemisClient.instance.createConfig(
//                         brief,
//                       );
//                       if (success) setState(() {});
//                     },
//                     pluginId: pluginCubit.state.brief.pluginId,
//                     configType: item.configType,
//                   ),
//                 ),
//                 refresh: () => setState(() {}),
//               ),
//       ),
//     );
//   }
// }

// /// Confirmation dialog for GUI settings reset.
// class _NewConfigDialog extends StatelessWidget {
//   final void Function(ConfigFileBrief brief) create;
//   final String pluginId;
//   final String configType;
//   const _NewConfigDialog({
//     required this.create,
//     required this.pluginId,
//     required this.configType,
//     super.key,
//   });

//   @override
//   Component build(BuildContext context) {
//     var name = "";
//     return AlertDialog(
//       titlePadding: EdgeInsets.zero,
//       title: YaruDialogTitleBar(title: Text("Creating new config")),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text("Config Type"),
//           TextFormField(initialValue: configType, enabled: false),
//           Text("Config Name"),
//           TextFormField(
//             decoration: InputDecoration(hintText: "Config Name"),
//             onChanged: (value) => name = value,
//           ),
//         ],
//       ),
//       actions: [
//         OutlinedButton(
//           style: ButtonStyle(
//             backgroundColor: WidgetStatePropertyAll(
//               ColorScheme.of(context).primary,
//             ),
//           ),
//           onPressed: () {
//             create(
//               ConfigFileBrief(
//                 pluginId: pluginId,
//                 configId: "$configType-${Uuid().v4()}",
//                 configType: configType,
//                 title: name,
//               ),
//             );
//             Navigator.of(context).pop();
//           },
//           child: Text("Create"),
//         ),
//         OutlinedButton(
//           onPressed: Navigator.of(context).pop,
//           child: Text("Cancel"),
//         ),
//       ],
//     );
//   }
// }

// class MutableList<S>
//     extends
//         ConfigThemisWidget<
//           List<Map<String, dynamic>>,
//           S,
//           MutableConfigItem<S>
//         > {
//   const MutableList(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     final cubit = BlocProvider.of<ConfigDataCubit>(context, listen: false);
//     return BlocSelector<
//       ConfigDataCubit,
//       ConfigInterface,
//       List<Map<String, dynamic>>
//     >(
//       bloc: cubit,
//       selector: (state) =>
//           item.deserializeValue(state.config[item.key] ?? item.defaultValue),
//       builder: (context, state) => _ThemisSubUiList(
//         title: item.title,
//         description: item.description,
//         itemCount: state.length,
//         itemBuilder: (index) =>
//             BlocProvider<ConfigDataCubit<ConfigInterface>>.value(
//               value: cubit.getChild(item, index),
//               child: _ThemisSubUiListItem(
//                 item: item,
//                 up: index > 0
//                     ? () => cubit.swapChildren(item, index - 1, index)
//                     : null,
//                 down: index < state.length - 1
//                     ? () => cubit.swapChildren(item, index, index + 1)
//                     : null,
//                 save: () async {
//                   final scaffold = ScaffoldMessenger.of(context);
//                   final success = await cubit
//                       .getChild(item, index)
//                       .saveConfig();
//                   if (!success) {
//                     scaffold.showSnackBar(
//                       SnackBar(
//                         content: Text("Couldn't save, settings invalid."),
//                       ),
//                     );
//                   }
//                 },
//                 restore: cubit.getChild(item, index).resetConfig,
//                 delete: () => cubit.deleteChild(item, index),
//               ),
//             ),
//         add: item.canAddNew(state) ? (() => cubit.addChild(item)) : null,
//         resetToDefault: resetToDefault,
//       ),
//     );
//   }
// }

// /// Displays an editable list.
// class _ThemisSubUiList extends StatelessWidget {
//   final String title;
//   final String description;
//   final int itemCount;
//   final Widget Function(int index) itemBuilder;
//   final VoidCallback? add;
//   final VoidCallback? refresh;
//   final void Function(BuildContext context)? resetToDefault;
//   const _ThemisSubUiList({
//     required this.title,
//     required this.description,
//     required this.itemCount,
//     required this.itemBuilder,
//     required this.add,
//     this.refresh,
//     this.resetToDefault,
//     super.key,
//   });

//   @override
//   Component build(BuildContext context) {
//     return YaruBorderContainer(
//       margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
//       constraints: .loose(Size(548, 800)),
//       child: AnimatedSize(
//         alignment: .topCenter,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeInOutCirc,
//         child: Column(
//           crossAxisAlignment: .start,
//           mainAxisSize: .min,
//           spacing: 4,
//           children: [
//             Row(
//               children: [
//                 DefaultTextStyle(
//                   style: Theme.of(context).textTheme.titleSmall!,
//                   child: Text(title),
//                 ),
//                 Spacer(),
//                 if (resetToDefault != null)
//                   BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
//                     selector: (state) => state.showResetToDefaultButtons,
//                     builder: (context, state) => state
//                         ? Flexible(
//                             child: Tooltip(
//                               message: "Reset to default",
//                               child: TextButton(
//                                 style: controlButtonStyle,
//                                 onPressed: () => resetToDefault!(context),
//                                 child: Icon(
//                                   YaruIcons.minus,
//                                   color: ColorScheme.of(context).onSurface,
//                                 ),
//                               ),
//                             ),
//                           )
//                         : Flexible(child: SizedBox(height: 32)),
//                   ),
//                 if (refresh != null)
//                   Tooltip(
//                     message: "Refresh file list",
//                     child: OutlinedButton(
//                       style: controlButtonStyle,
//                       onPressed: refresh,
//                       child: Icon(YaruIcons.refresh, color: discardIconColor),
//                     ),
//                   ),
//               ],
//             ),
//             if (description != "")
//               DefaultTextStyle(
//                 style: Theme.of(context).textTheme.bodyMedium!,
//                 child: Text(description),
//               ),
//             Flexible(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: itemCount + 1,
//                 itemBuilder: (context, index) => index == itemCount
//                     ? Padding(
//                         padding: .symmetric(horizontal: 24, vertical: 8),
//                         child: ListTile(
//                           title: Row(
//                             mainAxisAlignment: .center,
//                             spacing: 4,
//                             children: [
//                               Icon(YaruIcons.plus),
//                               Text("Add new item"),
//                             ],
//                           ),
//                           minTileHeight: 32,
//                           shape: RoundedRectangleBorder(
//                             side: BorderSide(
//                               color: Theme.of(context).dividerColor,
//                             ),
//                             borderRadius: .circular(kYaruContainerRadius),
//                           ),
//                           enabled: add != null,
//                           onTap: add,
//                         ),
//                       )
//                     : itemBuilder(index),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// An editable list item.
// class _ThemisSubUiListItem extends StatelessWidget {
//   final SubUiItem item;
//   final VoidCallback? up;
//   final VoidCallback? down;
//   final VoidCallback? save;
//   final VoidCallback? restore;
//   final VoidCallback? delete;
//   final String? title;

//   const _ThemisSubUiListItem({
//     required this.item,
//     this.up,
//     this.down,
//     this.save,
//     this.restore,
//     this.delete,
//     this.title,
//     super.key,
//   });

//   @override
//   Component build(BuildContext context) {
//     return YaruBorderContainer(
//       margin: .symmetric(vertical: 8),
//       child: Column(
//         children: [
//           YaruBorderContainer(
//             padding: .symmetric(horizontal: 12, vertical: 8),
//             child: Row(
//               children: [
//                 if (up != null || down != null)
//                   Row(
//                     spacing: 8,
//                     children: [
//                       Tooltip(
//                         message: "Move up",
//                         child: OutlinedButton(
//                           style: controlButtonStyle,
//                           onPressed: up,
//                           child: Icon(YaruIcons.pan_up),
//                         ),
//                       ),
//                       Tooltip(
//                         message: "Move down",
//                         child: OutlinedButton(
//                           style: controlButtonStyle,
//                           onPressed: down,
//                           child: Icon(YaruIcons.pan_down),
//                         ),
//                       ),
//                     ],
//                   ),
//                 if (title != null)
//                   Text(title!, style: TextTheme.of(context).titleSmall),
//                 Spacer(),
//                 BlocSelector<ConfigDataCubit, ConfigInterface, bool>(
//                   selector: (state) => state.modified,
//                   builder: (context, state) => Row(
//                     spacing: 8,
//                     children: [
//                       Tooltip(
//                         message: "Save",
//                         child: OutlinedButton(
//                           style: controlButtonStyle,
//                           onPressed: state ? save : null,
//                           child: Icon(
//                             YaruIcons.floppy,
//                             color: state
//                                 ? saveIconColor
//                                 : Theme.of(context).disabledColor,
//                           ),
//                         ),
//                       ),
//                       Tooltip(
//                         message: "Discard",
//                         child: OutlinedButton(
//                           style: controlButtonStyle,
//                           onPressed: state ? restore : null,
//                           child: Icon(
//                             YaruIcons.refresh,
//                             color: state
//                                 ? discardIconColor
//                                 : Theme.of(context).disabledColor,
//                           ),
//                         ),
//                       ),
//                       Tooltip(
//                         message: "Delete",
//                         child: OutlinedButton(
//                           style: controlButtonStyle,
//                           onPressed: delete,
//                           child: Icon(YaruIcons.trash, color: deleteIconColor),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: .symmetric(vertical: 8),
//             child: Column(
//               crossAxisAlignment: .start,
//               mainAxisSize: .min,
//               spacing: 4,
//               children: [
//                 ...BlocProvider.of<ThemisPluginCubit>(context, listen: false)
//                     .state
//                     .ui[item.subUiId]!
//                     .map((it) => ThemisComponent.fromItem(it)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// A list item that opens a new page with the contents when clicked.
// class _ThemisSubUiListPageButton extends StatelessWidget {
//   final SubUiItem item;
//   final VoidCallback? delete;
//   final Future<ConfigFileCubit> Function() getConfigCubit;
//   final String title;
//   final String description;

//   const _ThemisSubUiListPageButton({
//     required this.item,
//     this.delete,
//     required this.getConfigCubit,
//     required this.title,
//     required this.description,
//     super.key,
//   });

//   @override
//   Component build(BuildContext context) {
//     return YaruBorderContainer(
//       margin: .symmetric(vertical: 8),
//       child: Column(
//         children: [
//           YaruBorderContainer(
//             padding: .symmetric(horizontal: 12, vertical: 8),
//             child: Row(
//               children: [
//                 Text(title, style: TextTheme.of(context).titleSmall),
//                 Spacer(),
//                 Tooltip(
//                   message: "Delete",
//                   child: OutlinedButton(
//                     style: controlButtonStyle,
//                     onPressed: delete,
//                     child: Icon(YaruIcons.trash, color: deleteIconColor),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _ThemisSubUiPageButton(
//             item: item,
//             title: title,
//             description: description,
//             getConfigCubit: (_) => getConfigCubit(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ThemisSubUiPageButton extends StatelessWidget {
//   final SubUiItem item;
//   final String title;
//   final String description;
//   final Future<ConfigDataCubit> Function(BuildContext context) getConfigCubit;

//   const _ThemisSubUiPageButton({
//     required this.item,
//     required this.title,
//     required this.description,
//     required this.getConfigCubit,
//     super.key,
//   });
//   @override
//   Component build(BuildContext context) {
//     return Padding(
//       padding: .symmetric(vertical: 8),
//       child: SizedBox(
//         width: 500,
//         child: ListTile(
//           title: DefaultTextStyle(
//             style: Theme.of(context).textTheme.titleSmall!,
//             child: Text(title),
//           ),
//           subtitle: description == ""
//               ? null
//               : Padding(
//                   padding: EdgeInsets.symmetric(vertical: 4),
//                   child: DefaultTextStyle(
//                     style: Theme.of(context).textTheme.bodySmall!,
//                     child: Text(description),
//                   ),
//                 ),
//           trailing: Icon(YaruIcons.go_next),
//           onTap: () {
//             final pluginCubit = BlocProvider.of<ThemisPluginCubit>(
//               context,
//               listen: false,
//             );
//             final configCubit = getConfigCubit(context);
//             Navigator.of(context).push(
//               CupertinoPageRoute(
//                 builder: (context) => FutureBuilder(
//                   future: configCubit,
//                   builder: (context, snapshot) => snapshot.data == null
//                       ? YaruCircularProgressIndicator()
//                       : BlocProvider<ThemisPluginCubit>.value(
//                           value: pluginCubit,
//                           child: BlocProvider<ConfigDataCubit>.value(
//                             value: snapshot.data!,
//                             child: _ThemisBlankpage(
//                               title: item.title,
//                               child: Column(
//                                 spacing: 8,
//                                 children: [
//                                   SizedBox(height: 24),
//                                   DefaultTextStyle(
//                                     style: Theme.of(
//                                       context,
//                                     ).textTheme.titleLarge!,
//                                     child: Text(title),
//                                   ),
//                                   if (description != "")
//                                     DefaultTextStyle(
//                                       style: Theme.of(
//                                         context,
//                                       ).textTheme.bodyMedium!,
//                                       child: Text(description),
//                                     ),
//                                   SizedBox(height: 24),
//                                   Wrap(
//                                     direction: .horizontal,
//                                     alignment: .center,
//                                     crossAxisAlignment: .center,
//                                     children: [
//                                       ...pluginCubit.state.ui[item.subUiId]!
//                                           .map(
//                                             (it) =>
//                                                 ThemisComponent.fromItem(it),
//                                           ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
