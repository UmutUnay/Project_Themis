/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-12-05 21:44:01
 * @LastEditTime: 2026-03-08 13:16:55
 * @Description: 
 */

import 'package:collection/collection.dart';
import 'package:nocterm/nocterm.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';
import '../cubit/config_file_cubit.dart';
import '../cubit/themis_plugin_cubit.dart';
import '../util/widget/double_pane_page.dart';
import '../util/widget/navigable_flex.dart';
import '../util/widget/provider.dart';
import '../util/widget/scaffold.dart';

part "themis_component_abstract.dart";
part "themis_subui_components.dart";
part "themis_page_components.dart";

class SectionThemisWidget extends ThemisComponent<SectionItem> {
  const SectionThemisWidget(super.item, {super.key});

  @override
  Component build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    mainAxisSize: .min,
    children: [
      if (item.description != "") Text(item.description),
      SizedBox(height: 4),
      ...item.items.map((it) => ThemisComponent.fromItem(it)),
    ],
  );
}

// class PageButtonThemisWidget extends ThemisComponent<PageButtonItem> {
//   const PageButtonThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 8),
//       child: SizedBox(
//         width: 500,
//         child: ListTile(
//           title: DefaultTextStyle(
//             style: Theme.of(context).textTheme.titleSmall!,
//             child: Text(item.title),
//           ),
//           subtitle: Padding(
//             padding: EdgeInsets.symmetric(vertical: 4),
//             child: DefaultTextStyle(
//               style: Theme.of(context).textTheme.bodySmall!,
//               child: Text(item.description),
//             ),
//           ),
//           trailing: Icon(YaruIcons.go_next),
//           onTap: () {
//             final pluginCubit = BlocProvider.of<ThemisPluginCubit>(
//               context,
//               listen: false,
//             );
//             final configCubit = BlocProvider.of<ConfigDataCubit>(
//               context,
//               listen: false,
//             );
//             Navigator.of(context).push(
//               CupertinoPageRoute(
//                 builder: (context) => BlocProvider<ThemisPluginCubit>.value(
//                   value: pluginCubit,
//                   child: BlocProvider<ConfigDataCubit>.value(
//                     value: configCubit,
//                     child: ThemisSubpage(item),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class ChildSelectorThemisWidget extends ThemisComponent<ItemSelectorItem> {
//   const ChildSelectorThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     int? currentIndex;
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       child: SizedBox(
//         width: 500,
//         child: AnimatedSize(
//           alignment: .topCenter,
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeInOutCirc,
//           child: StatefulBuilder(
//             builder: (context, setState) => Column(
//               crossAxisAlignment: .start,
//               mainAxisSize: .min,
//               spacing: 8,
//               children: [
//                 Row(
//                   crossAxisAlignment: .center,
//                   mainAxisAlignment: .spaceBetween,
//                   spacing: 4,
//                   children: [
//                     Column(
//                       crossAxisAlignment: .start,
//                       children: [
//                         DefaultTextStyle(
//                           style: Theme.of(context).textTheme.titleSmall!,
//                           child: Text(item.title),
//                         ),
//                         if (item.description != "")
//                           DefaultTextStyle(
//                             style: Theme.of(context).textTheme.bodySmall!,
//                             child: Text(item.description),
//                           ),
//                       ],
//                     ),
//                     Row(
//                       mainAxisSize: .min,
//                       spacing: 4,
//                       children: [
//                         DropdownMenu(
//                           dropdownMenuEntries: item.keys
//                               .mapIndexed(
//                                 (i, option) => DropdownMenuEntry(
//                                   value: i,
//                                   label: option,
//                                   style: ButtonStyle(
//                                     textStyle: WidgetStatePropertyAll(
//                                       TextStyle(
//                                         fontFamily:
//                                             'IBMPlexMono', // Style works here!??
//                                         fontSize: Theme.of(
//                                           context,
//                                         ).textTheme.bodySmall!.fontSize,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               )
//                               .toList(),
//                           textStyle: TextStyle(
//                             fontFamily: 'IBMPlexMono', // Style doesn't work!
//                             fontSize: Theme.of(
//                               context,
//                             ).textTheme.bodySmall!.fontSize,
//                           ),
//                           enableFilter: true,
//                           initialSelection: currentIndex,
//                           onSelected: (value) =>
//                               setState(() => currentIndex = value),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 if (currentIndex != null)
//                   ThemisComponent.fromItem(item.items[currentIndex!]),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class InfoThemisWidget extends ThemisComponent<InfoItem> {
//   const InfoThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) => Padding(
//     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//     child: SizedBox(
//       width: item.info.length > 1000 ? 800 : 500,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         spacing: 4,
//         children: [
//           DefaultTextStyle(
//             style: Theme.of(context).textTheme.titleSmall!,
//             child: Text(item.title),
//           ),
//           if (item.description != "")
//             DefaultTextStyle(
//               style: Theme.of(context).textTheme.bodySmall!,
//               child: Text(item.description),
//             ),
//           YaruBorderContainer(
//             color: ColorScheme.of(context).primaryContainer,
//             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             child: DefaultTextStyle(
//               style: TextStyle(
//                 fontFamily: 'IBMPlexMono',
//                 fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
//                 color: Theme.of(context).textTheme.bodySmall!.color,
//               ),
//               child: SelectableText(item.info),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// class KeyedInfoThemisWidget extends ThemisComponent<KeyedInfoItem> {
//   const KeyedInfoThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) =>
//       BlocSelector<ConfigDataCubit, ConfigInterface, String>(
//         selector: (state) => state.config[item.key] ?? item.defaultValue,
//         builder: (context, state) => Padding(
//           padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//           child: SizedBox(
//             width: state.length > 1000 ? 800 : 500,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               spacing: 4,
//               children: [
//                 DefaultTextStyle(
//                   style: Theme.of(context).textTheme.titleSmall!,
//                   child: Text(item.title),
//                 ),
//                 if (item.description != "")
//                   DefaultTextStyle(
//                     style: Theme.of(context).textTheme.bodySmall!,
//                     child: Text(item.description),
//                   ),
//                 YaruBorderContainer(
//                   color: ColorScheme.of(context).primaryContainer,
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   child: DefaultTextStyle(
//                     style: TextStyle(
//                       fontFamily: 'IBMPlexMono',
//                       fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
//                       color: Theme.of(context).textTheme.bodySmall!.color,
//                     ),
//                     child: SelectableText(state),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
// }

// class SwitchThemisWidget<S> extends ConfigThemisWidget<bool, S, SwitchItem<S>> {
//   const SwitchThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     return BlocSelector<ConfigDataCubit, ConfigInterface, bool>(
//       selector: (state) =>
//           item.deserializeValue(state.config[item.key] ?? item.defaultValue),
//       builder: (context, state) => Padding(
//         padding: EdgeInsets.symmetric(horizontal: 8),
//         child: SizedBox(
//           width: 500,
//           child: ListTile(
//             title: DefaultTextStyle(
//               style: Theme.of(context).textTheme.titleSmall!,
//               child: Text(item.title),
//             ),
//             subtitle: item.description == ""
//                 ? null
//                 : Padding(
//                     padding: EdgeInsets.symmetric(vertical: 4),
//                     child: DefaultTextStyle(
//                       style: Theme.of(context).textTheme.bodySmall!,
//                       child: Text(item.description),
//                     ),
//                   ),
//             onTap: () => setValue(context, !state),
//             trailing: Row(
//               mainAxisSize: .min,
//               spacing: 4,
//               children: [
//                 YaruSwitch(
//                   value: state,
//                   onChanged: (value) => setValue(context, value),
//                 ),
//                 BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
//                   selector: (state) => state.showResetToDefaultButtons,
//                   builder: (context, state) => state
//                       ? Flexible(
//                           child: Tooltip(
//                             message: "Reset to default",
//                             child: TextButton(
//                               style: controlButtonStyle,
//                               onPressed: () => resetToDefault(context),
//                               child: Icon(
//                                 YaruIcons.minus,
//                                 color: ColorScheme.of(context).onSurface,
//                               ),
//                             ),
//                           ),
//                         )
//                       : Flexible(child: SizedBox(height: 32)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class ButtonThemisWidget extends ConfigThemisWidget<bool, bool, ButtonItem> {
//   const ButtonThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     return BlocSelector<ConfigDataCubit, ConfigInterface, bool>(
//       selector: (state) =>
//           item.deserializeValue(state.config[item.key] ?? item.defaultValue),
//       builder: (context, state) => Padding(
//         padding: EdgeInsets.symmetric(horizontal: 8),
//         child: SizedBox(
//           width: 500,
//           child: ListTile(
//             title: DefaultTextStyle(
//               style: Theme.of(context).textTheme.titleSmall!,
//               child: Text(item.title),
//             ),
//             subtitle: item.description == ""
//                 ? null
//                 : Padding(
//                     padding: EdgeInsets.symmetric(vertical: 4),
//                     child: DefaultTextStyle(
//                       style: Theme.of(context).textTheme.bodySmall!,
//                       child: Text(item.description),
//                     ),
//                   ),
//             onTap: () => setValue(context, !state),
//             trailing: Icon(state ? YaruIcons.ok_filled : YaruIcons.ok),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class TextThemisWidget extends ConfigThemisWidget<String, String, TextItem> {
//   const TextThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     final textController = TextEditingController();
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       child: SizedBox(
//         width: 500,
//         child: BlocSelector<ConfigDataCubit, ConfigInterface, String>(
//           selector: (state) => item.deserializeValue(
//             state.config[item.key] ?? item.defaultValue,
//           ),
//           builder: (context, state) {
//             textController.text = state;
//             return Column(
//               crossAxisAlignment: .start,
//               spacing: 8,
//               children: [
//                 Row(
//                   spacing: 4,
//                   mainAxisAlignment: .spaceBetween,
//                   children: [
//                     DefaultTextStyle(
//                       style: Theme.of(context).textTheme.titleSmall!,
//                       child: Text(item.title),
//                     ),
//                     BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
//                       selector: (state) => state.showResetToDefaultButtons,
//                       builder: (context, state) => state
//                           ? Flexible(
//                               child: Tooltip(
//                                 message: "Reset to default",
//                                 child: TextButton(
//                                   style: controlButtonStyle,
//                                   onPressed: () => resetToDefault(context),
//                                   child: Icon(
//                                     YaruIcons.minus,
//                                     color: ColorScheme.of(context).onSurface,
//                                   ),
//                                 ),
//                               ),
//                             )
//                           : Flexible(child: SizedBox(height: 32)),
//                     ),
//                   ],
//                 ),
//                 if (item.description != "")
//                   DefaultTextStyle(
//                     style: Theme.of(context).textTheme.bodySmall!,
//                     child: Text(item.description),
//                   ),
//                 DefaultTextStyle(
//                   style: TextStyle(
//                     fontFamily: 'IBMPlexMono', // Style doesn't work!
//                     fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
//                   ),
//                   child: TextFormField(
//                     controller: textController,
//                     maxLines: null,
//                     style: TextStyle(
//                       fontFamily: 'IBMPlexMono', // Style doesn't work!
//                       fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
//                     ),
//                     onChanged: (value) => setValue(context, value),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class ShortTextThemisWidget
//     extends ConfigThemisWidget<String, String, TextItem> {
//   const ShortTextThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     final textController = TextEditingController();
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       child: SizedBox(
//         width: 500,
//         child: BlocSelector<ConfigDataCubit, ConfigInterface, String>(
//           selector: (state) => item.deserializeValue(
//             state.config[item.key] ?? item.defaultValue,
//           ),
//           builder: (context, state) {
//             textController.text = state;
//             return Row(
//               crossAxisAlignment: .center,
//               mainAxisAlignment: .spaceBetween,
//               spacing: 4,
//               children: [
//                 Column(
//                   crossAxisAlignment: .start,
//                   children: [
//                     DefaultTextStyle(
//                       style: Theme.of(context).textTheme.titleSmall!,
//                       child: Text(item.title),
//                     ),
//                     if (item.description != "")
//                       DefaultTextStyle(
//                         style: Theme.of(context).textTheme.bodySmall!,
//                         child: Text(item.description),
//                       ),
//                   ],
//                 ),
//                 Flexible(
//                   child: Row(
//                     mainAxisSize: .min,
//                     spacing: 4,
//                     children: [
//                       Expanded(
//                         child: DefaultTextStyle(
//                           style: TextStyle(
//                             fontFamily: 'IBMPlexMono', // Style doesn't work!
//                             fontSize: Theme.of(
//                               context,
//                             ).textTheme.bodySmall!.fontSize,
//                           ),
//                           child: TextFormField(
//                             controller: textController,
//                             maxLines: 1,
//                             style: TextStyle(
//                               fontFamily: 'IBMPlexMono', // Style doesn't work!
//                               fontSize: Theme.of(
//                                 context,
//                               ).textTheme.bodySmall!.fontSize,
//                             ),
//                             onChanged: (value) => setValue(context, value),
//                           ),
//                         ),
//                       ),
//                       BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
//                         selector: (state) => state.showResetToDefaultButtons,
//                         builder: (context, state) => state
//                             ? Flexible(
//                                 child: Tooltip(
//                                   message: "Reset to default",
//                                   child: TextButton(
//                                     style: controlButtonStyle,
//                                     onPressed: () => resetToDefault(context),
//                                     child: Icon(
//                                       YaruIcons.minus,
//                                       color: ColorScheme.of(context).onSurface,
//                                     ),
//                                   ),
//                                 ),
//                               )
//                             : Flexible(child: SizedBox(height: 32)),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class DropdownThemisWidget
//     extends ConfigThemisWidget<String, String, DropdownItem> {
//   const DropdownThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       child: SizedBox(
//         width: 500,
//         child: BlocSelector<ConfigDataCubit, ConfigInterface, String>(
//           selector: (state) => item.deserializeValue(
//             state.config[item.key] ?? item.defaultValue,
//           ),
//           builder: (context, state) {
//             return Row(
//               crossAxisAlignment: .center,
//               mainAxisAlignment: .spaceBetween,
//               spacing: 4,
//               children: [
//                 Column(
//                   crossAxisAlignment: .start,
//                   children: [
//                     DefaultTextStyle(
//                       style: Theme.of(context).textTheme.titleSmall!,
//                       child: Text(item.title),
//                     ),
//                     if (item.description != "")
//                       DefaultTextStyle(
//                         style: Theme.of(context).textTheme.bodySmall!,
//                         child: Text(item.description),
//                       ),
//                   ],
//                 ),
//                 Row(
//                   mainAxisSize: .min,
//                   spacing: 4,
//                   children: [
//                     DropdownMenu(
//                       dropdownMenuEntries: item.options
//                           .map(
//                             (option) => DropdownMenuEntry(
//                               value: option,
//                               label: option,
//                               style: ButtonStyle(
//                                 textStyle: WidgetStatePropertyAll(
//                                   TextStyle(
//                                     fontFamily:
//                                         'IBMPlexMono', // Style works here!??
//                                     fontSize: Theme.of(
//                                       context,
//                                     ).textTheme.bodySmall!.fontSize,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           )
//                           .toList(),
//                       textStyle: TextStyle(
//                         fontFamily: 'IBMPlexMono', // Style doesn't work!
//                         fontSize: Theme.of(
//                           context,
//                         ).textTheme.bodySmall!.fontSize,
//                       ),
//                       enableFilter: true,
//                       initialSelection: state,
//                       onSelected: (value) => setValue(context, value!),
//                     ),
//                     BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
//                       selector: (state) => state.showResetToDefaultButtons,
//                       builder: (context, state) => state
//                           ? Flexible(
//                               child: Tooltip(
//                                 message: "Reset to default",
//                                 child: TextButton(
//                                   style: controlButtonStyle,
//                                   onPressed: () => resetToDefault(context),
//                                   child: Icon(
//                                     YaruIcons.minus,
//                                     color: ColorScheme.of(context).onSurface,
//                                   ),
//                                 ),
//                               ),
//                             )
//                           : Flexible(child: SizedBox(height: 32)),
//                     ),
//                   ],
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class RadioThemisWidget extends ConfigThemisWidget<String, String, RadioItem> {
//   const RadioThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       child: ConstrainedBox(
//         constraints: .loose(Size(548, 400)),
//         child: BlocSelector<ConfigDataCubit, ConfigInterface, String>(
//           selector: (state) => item.deserializeValue(
//             state.config[item.key] ?? item.defaultValue,
//           ),
//           builder: (context, state) {
//             return Column(
//               crossAxisAlignment: .start,
//               mainAxisSize: .min,
//               spacing: 8,
//               children: [
//                 Row(
//                   spacing: 4,
//                   mainAxisAlignment: .spaceBetween,
//                   children: [
//                     DefaultTextStyle(
//                       style: Theme.of(context).textTheme.titleSmall!,
//                       child: Text(item.title),
//                     ),
//                     BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
//                       selector: (state) => state.showResetToDefaultButtons,
//                       builder: (context, state) => state
//                           ? Flexible(
//                               child: Tooltip(
//                                 message: "Reset to default",
//                                 child: TextButton(
//                                   style: controlButtonStyle,
//                                   onPressed: () => resetToDefault(context),
//                                   child: Icon(
//                                     YaruIcons.minus,
//                                     color: ColorScheme.of(context).onSurface,
//                                   ),
//                                 ),
//                               ),
//                             )
//                           : Flexible(child: SizedBox(height: 32)),
//                     ),
//                   ],
//                 ),
//                 if (item.description != "")
//                   DefaultTextStyle(
//                     style: Theme.of(context).textTheme.bodySmall!,
//                     child: Text(item.description),
//                   ),
//                 Flexible(
//                   child: ListView.builder(
//                     shrinkWrap: true,
//                     itemCount: item.options.length,
//                     itemBuilder: (context, index) {
//                       final option = item.options[index];
//                       return YaruRadioListTile(
//                         value: option,
//                         groupValue: state,
//                         onChanged: (value) => setValue(context, value!),
//                         title: DefaultTextStyle(
//                           style: Theme.of(context).textTheme.bodyMedium!,
//                           child: Text(option),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class CheckboxThemisWidget
//     extends ConfigThemisWidget<Set<String>, List<String>, CheckboxItem> {
//   const CheckboxThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       child: ConstrainedBox(
//         constraints: .loose(Size(580, 400)),
//         child: BlocSelector<ConfigDataCubit, ConfigInterface, Set<String>>(
//           selector: (state) => item.deserializeValue(
//             List<String>.from(state.config[item.key] ?? item.defaultValue),
//           ),
//           builder: (context, state) {
//             return Column(
//               crossAxisAlignment: .start,
//               mainAxisSize: .min,
//               spacing: 8,
//               children: [
//                 Row(
//                   spacing: 4,
//                   mainAxisAlignment: .spaceBetween,
//                   children: [
//                     DefaultTextStyle(
//                       style: Theme.of(context).textTheme.titleSmall!,
//                       child: Text(item.title),
//                     ),
//                     BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
//                       selector: (state) => state.showResetToDefaultButtons,
//                       builder: (context, state) => state
//                           ? Flexible(
//                               child: Tooltip(
//                                 message: "Reset to default",
//                                 child: TextButton(
//                                   style: controlButtonStyle,
//                                   onPressed: () => resetToDefault(context),
//                                   child: Icon(
//                                     YaruIcons.minus,
//                                     color: ColorScheme.of(context).onSurface,
//                                   ),
//                                 ),
//                               ),
//                             )
//                           : Flexible(child: SizedBox(height: 32)),
//                     ),
//                   ],
//                 ),
//                 if (item.description != "")
//                   DefaultTextStyle(
//                     style: Theme.of(context).textTheme.bodySmall!,
//                     child: Text(item.description),
//                   ),
//                 Flexible(
//                   child: ListView.builder(
//                     shrinkWrap: true,
//                     itemCount: item.options.length,
//                     itemBuilder: (context, index) {
//                       final option = item.options.toList()[index];
//                       return YaruCheckboxListTile(
//                         value: state.contains(option),
//                         onChanged: (value) => value!
//                             ? setValue(context, state..add(option))
//                             : setValue(context, state..remove(option)),
//                         title: DefaultTextStyle(
//                           style: Theme.of(context).textTheme.bodyMedium!,
//                           child: Text(option),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class BlankThemisWidget extends ThemisComponent<ThemisItem> {
//   const BlankThemisWidget(super.item, {super.key});

//   @override
//   Component build(BuildContext context) =>
//       YaruSection(headline: Text(item.title), child: Center());
// }
