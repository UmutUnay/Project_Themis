/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-12-05 21:44:01
 * @LastEditTime: 2026-03-08 13:16:55
 * @Description: 
 */

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';
import 'package:toastification/toastification.dart';
import 'package:uuid/uuid.dart';
import 'package:yaru/yaru.dart';

import '../../../core/misc/constants.dart';
import '../../../core/misc/print_success.dart';
import '../../../core/misc/theme_transform.dart';
import '../../settings/cubit/settings_data.dart';
import '../cubit/config_file_cubit.dart';
import '../cubit/themis_plugin_cubit.dart';

part "themis_widget_abstract.dart";
part "themis_subui_widgets.dart";
part "themis_page_widgets.dart";

class SectionThemisWidget extends ThemisWidget<SectionItem> {
  const SectionThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) => YaruBorderContainer(
    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    padding: EdgeInsets.all(16),
    constraints: .loose(Size(548, 5000)),
    child: Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        if (item.title != "")
          DefaultTextStyle(
            style: Theme.of(context).textTheme.titleLarge!,
            child: Text(item.title),
          ),
        SizedBox(height: 4),
        if (item.description != "")
          DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium!,
            child: Text(item.description),
          ),
        SizedBox(height: 8),
        ...item.items.map((it) => ThemisWidget.fromItem(it)),
      ],
    ),
  );
}

class ChangedChildrenSectionThemisWidget
    extends ThemisWidget<ChangedItemsSection> {
  const ChangedChildrenSectionThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) {
    int? currentIndex;
    return YaruBorderContainer(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: EdgeInsets.all(16),
      constraints: .loose(Size(548, 5000)),
      child: AnimatedSize(
        alignment: .topCenter,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOutCirc,
        child: BlocSelector<ConfigDataCubit, ConfigInterface, Set<int>>(
          selector: (state) => item.items
              .mapIndexed(
                (i, e) =>
                    state.config.containsKey(e.key) &&
                        state.config[e.key] != e.defaultValue
                    ? i
                    : null,
              )
              .nonNulls
              .toSet(),
          builder: (context, state) {
            currentIndex = null;
            return Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                if (item.title != "")
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.titleLarge!,
                    child: Text(item.title),
                  ),
                SizedBox(height: 4),
                if (item.description != "")
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyMedium!,
                    child: Text(item.description),
                  ),
                SizedBox(height: 8),
                ...item.items
                    .whereIndexed((i, e) => state.contains(i))
                    .map((it) => ThemisWidget.fromItem(it)),
                SizedBox(height: 8),
                StatefulBuilder(
                  builder: (context, setState) => Column(
                    crossAxisAlignment: .start,
                    mainAxisSize: .min,
                    children: [
                      Center(
                        child: Row(
                          crossAxisAlignment: .center,
                          mainAxisSize: .max,
                          spacing: 4,
                          children: [
                            Expanded(
                              flex: 3,
                              child: DefaultTextStyle(
                                style: Theme.of(context).textTheme.bodyMedium!,
                                child: Text("Unchanged values:"),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: DropdownMenu(
                                dropdownMenuEntries: item.titles
                                    .mapIndexed(
                                      (i, option) => state.contains(i)
                                          ? null
                                          : DropdownMenuEntry(
                                              value: i,
                                              label: option,
                                              style: ButtonStyle(
                                                textStyle:
                                                    WidgetStatePropertyAll(
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                    ),
                                              ),
                                            ),
                                    )
                                    .nonNulls
                                    .toList(),
                                textStyle: TextStyle(
                                  fontFamily:
                                      'IBMPlexMono', // Style doesn't work!
                                  fontSize: Theme.of(
                                    context,
                                  ).textTheme.bodySmall!.fontSize,
                                ),
                                enableFilter: true,
                                initialSelection: currentIndex,
                                onSelected: (value) =>
                                    setState(() => currentIndex = value),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (currentIndex != null)
                        ThemisWidget.fromItem(item.items[currentIndex!]),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PageButtonThemisWidget extends ThemisWidget<PageButtonItem> {
  const PageButtonThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 500,
        child: ListTile(
          title: DefaultTextStyle(
            style: Theme.of(context).textTheme.titleSmall!,
            child: Text(item.title),
          ),
          subtitle: item.description == ""
              ? null
              : Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodySmall!,
                    child: Text(item.description),
                  ),
                ),
          trailing: Icon(YaruIcons.go_next),
          onTap: () {
            final pluginCubit = BlocProvider.of<ThemisPluginCubit>(
              context,
              listen: false,
            );
            final configCubit = BlocProvider.of<ConfigDataCubit>(
              context,
              listen: false,
            );
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => BlocProvider<ThemisPluginCubit>.value(
                  value: pluginCubit,
                  child: BlocProvider<ConfigDataCubit>.value(
                    value: configCubit,
                    child: ThemisSubpage(item),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChildSelectorThemisWidget extends ThemisWidget<ItemSelector> {
  const ChildSelectorThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) {
    int? currentIndex;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: 500,
        child: AnimatedSize(
          alignment: .topCenter,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCirc,
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              spacing: 8,
              children: [
                Row(
                  crossAxisAlignment: .center,
                  mainAxisSize: .max,
                  spacing: 4,
                  children: [
                    if (item.title != "" || item.description != "")
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            if (item.title != "")
                              DefaultTextStyle(
                                style: Theme.of(context).textTheme.titleSmall!,
                                child: Text(item.title),
                              ),
                            if (item.description != "")
                              DefaultTextStyle(
                                style: Theme.of(context).textTheme.bodySmall!,
                                child: Text(item.description),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      flex: 3,
                      child: DropdownMenu(
                        dropdownMenuEntries: item.titles
                            .mapIndexed(
                              (i, option) => DropdownMenuEntry(
                                value: i,
                                label: option,
                                style: ButtonStyle(
                                  textStyle: WidgetStatePropertyAll(
                                    Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        textStyle: TextStyle(
                          fontFamily: 'IBMPlexMono', // Style doesn't work!
                          fontSize: Theme.of(
                            context,
                          ).textTheme.bodySmall!.fontSize,
                        ),
                        enableFilter: true,
                        initialSelection: currentIndex,
                        onSelected: (value) =>
                            setState(() => currentIndex = value),
                      ),
                    ),
                  ],
                ),
                if (currentIndex != null)
                  ThemisWidget.fromItem(item.items[currentIndex!]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoThemisWidget extends ThemisWidget<InfoItem> {
  const InfoThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: SizedBox(
      width: item.info.length > 1000 ? 800 : 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          if (item.title != "")
            DefaultTextStyle(
              style: Theme.of(context).textTheme.titleSmall!,
              child: Text(item.title),
            ),
          if (item.description != "")
            DefaultTextStyle(
              style: Theme.of(context).textTheme.bodySmall!,
              child: Text(item.description),
            ),
          YaruBorderContainer(
            color: ColorScheme.of(context).primaryContainer,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: DefaultTextStyle(
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
                color: Theme.of(context).textTheme.bodySmall!.color,
              ),
              child: SelectableText(item.info),
            ),
          ),
        ],
      ),
    ),
  );
}

class KeyedInfoThemisWidget extends ThemisWidget<KeyedInfoItem> {
  const KeyedInfoThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<ConfigDataCubit, ConfigInterface, String>(
        selector: (state) => state.config[item.key] ?? item.defaultValue,
        builder: (context, state) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: SizedBox(
            width: state.length > 1000 ? 800 : 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                if (item.title != "")
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.titleSmall!,
                    child: Text(item.title),
                  ),
                if (item.description != "")
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodySmall!,
                    child: Text(item.description),
                  ),
                YaruBorderContainer(
                  color: ColorScheme.of(context).primaryContainer,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
                      color: Theme.of(context).textTheme.bodySmall!.color,
                    ),
                    child: SelectableText(state),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class SwitchThemisWidget<S> extends ConfigThemisWidget<bool, S, SwitchItem<S>> {
  const SwitchThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigDataCubit, ConfigInterface, bool>(
      selector: (state) =>
          item.deserializeValue(state.config[item.key] ?? item.defaultValue),
      builder: (context, state) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 500,
          child: ListTile(
            title: DefaultTextStyle(
              style: Theme.of(context).textTheme.titleSmall!,
              child: Text(item.title),
            ),
            subtitle: item.description == ""
                ? null
                : Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodySmall!,
                      child: Text(item.description),
                    ),
                  ),
            onTap: () => setValue(context, !state),
            trailing: Row(
              mainAxisSize: .min,
              spacing: 4,
              children: [
                YaruSwitch(
                  value: state,
                  onChanged: (value) => setValue(context, value),
                ),
                BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
                  selector: (state) => state.showResetToDefaultButtons,
                  builder: (context, state) => state
                      ? Tooltip(
                          message: "Reset to default",
                          child: TextButton(
                            style: resetButtonStyle,
                            onPressed: () => resetToDefault(context),
                            child: Icon(
                              YaruIcons.minus,
                              color: ColorScheme.of(context).onSurface,
                            ),
                          ),
                        )
                      : SizedBox(height: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ButtonThemisWidget extends ConfigThemisWidget<bool, bool, ButtonItem> {
  const ButtonThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigDataCubit, ConfigInterface, bool>(
      selector: (state) =>
          item.deserializeValue(state.config[item.key] ?? item.defaultValue),
      builder: (context, state) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 500,
          child: ListTile(
            title: DefaultTextStyle(
              style: Theme.of(context).textTheme.titleSmall!,
              child: Text(item.title),
            ),
            subtitle: item.description == ""
                ? null
                : Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodySmall!,
                      child: Text(item.description),
                    ),
                  ),
            onTap: () => setValue(context, !state),
            trailing: Icon(state ? YaruIcons.ok_filled : YaruIcons.ok),
          ),
        ),
      ),
    );
  }
}

class TextThemisWidget extends ConfigThemisWidget<String, String, TextItem> {
  const TextThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: 500,
        child: BlocSelector<ConfigDataCubit, ConfigInterface, String>(
          selector: (state) => item.deserializeValue(
            state.config[item.key] ?? item.defaultValue,
          ),
          builder: (context, state) {
            if (textController.text != state) textController.text = state;
            return Column(
              crossAxisAlignment: .start,
              spacing: 4,
              children: [
                if (item.title != "")
                  Row(
                    spacing: 4,
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.titleSmall!,
                        child: Text(item.title),
                      ),
                      buildResetToDefault(context),
                    ],
                  ),
                if (item.description != "")
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodySmall!,
                    child: Text(item.description),
                  ),
                Row(
                  mainAxisSize: .min,
                  children: [
                    Flexible(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          fontFamily: 'IBMPlexMono', // Style doesn't work!
                          fontSize: Theme.of(
                            context,
                          ).textTheme.bodySmall!.fontSize,
                        ),
                        child: TextFormField(
                          controller: textController,
                          maxLines: null,
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono', // Style doesn't work!
                            fontSize: Theme.of(
                              context,
                            ).textTheme.bodySmall!.fontSize,
                          ),
                          onChanged: (value) => setValue(context, value),
                        ),
                      ),
                    ),
                    if (item.title == "") buildResetToDefault(context),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ShortTextThemisWidget
    extends ConfigThemisWidget<String, String, TextItem> {
  const ShortTextThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: 500,
        child: BlocSelector<ConfigDataCubit, ConfigInterface, String>(
          selector: (state) => item.deserializeValue(
            state.config[item.key] ?? item.defaultValue,
          ),
          builder: (context, state) {
            if (textController.text != state) textController.text = state;
            return Row(
              crossAxisAlignment: .center,
              mainAxisSize: .max,
              spacing: 4,
              children: [
                if (item.title != "" || item.description != "")
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        if (item.title != "")
                          DefaultTextStyle(
                            style: Theme.of(context).textTheme.titleSmall!,
                            child: Text(item.title),
                          ),
                        if (item.description != "")
                          DefaultTextStyle(
                            style: Theme.of(context).textTheme.bodySmall!,
                            child: Text(item.description),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  flex: 3,
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono', // Style doesn't work!
                      fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
                    ),
                    child: TextFormField(
                      controller: textController,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono', // Style doesn't work!
                        fontSize: Theme.of(
                          context,
                        ).textTheme.bodySmall!.fontSize,
                      ),
                      onChanged: (value) => setValue(context, value),
                    ),
                  ),
                ),
                BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
                  selector: (state) => state.showResetToDefaultButtons,
                  builder: (context, state) => state
                      ? Tooltip(
                          message: "Reset to default",
                          child: TextButton(
                            style: resetButtonStyle,
                            onPressed: () => resetToDefault(context),
                            child: Icon(
                              YaruIcons.minus,
                              color: ColorScheme.of(context).onSurface,
                            ),
                          ),
                        )
                      : SizedBox(height: 32),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class DropdownThemisWidget
    extends ConfigThemisWidget<String, String, DropdownItem> {
  const DropdownThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: 500,
        child: BlocSelector<ConfigDataCubit, ConfigInterface, String>(
          selector: (state) => item.deserializeValue(
            state.config[item.key] ?? item.defaultValue,
          ),
          builder: (context, state) {
            return Row(
              crossAxisAlignment: .center,
              mainAxisSize: .max,
              spacing: 4,
              children: [
                if (item.title != "" || item.description != "")
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        if (item.title != "")
                          DefaultTextStyle(
                            style: Theme.of(context).textTheme.titleSmall!,
                            child: Text(item.title),
                          ),
                        if (item.description != "")
                          DefaultTextStyle(
                            style: Theme.of(context).textTheme.bodySmall!,
                            child: Text(item.description),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  flex: 3,
                  child: DropdownMenu(
                    dropdownMenuEntries: item.options
                        .map(
                          (option) => DropdownMenuEntry(
                            value: option,
                            label: option,
                            style: ButtonStyle(
                              textStyle: WidgetStatePropertyAll(
                                TextStyle(
                                  fontFamily:
                                      'IBMPlexMono', // Style works here!??
                                  fontSize: Theme.of(
                                    context,
                                  ).textTheme.bodySmall!.fontSize,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    textStyle: TextStyle(
                      fontFamily: 'IBMPlexMono', // Style doesn't work!
                      fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
                    ),
                    enableFilter: true,
                    initialSelection: state,
                    onSelected: (value) => setValue(context, value!),
                  ),
                ),
                BlocSelector<ThemisPluginCubit, ThemisPluginData, bool>(
                  selector: (state) => state.showResetToDefaultButtons,
                  builder: (context, state) => state
                      ? Tooltip(
                          message: "Reset to default",
                          child: TextButton(
                            style: resetButtonStyle,
                            onPressed: () => resetToDefault(context),
                            child: Icon(
                              YaruIcons.minus,
                              color: ColorScheme.of(context).onSurface,
                            ),
                          ),
                        )
                      : SizedBox(height: 32),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class RadioThemisWidget extends ConfigThemisWidget<String, String, RadioItem> {
  const RadioThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ConstrainedBox(
        constraints: .loose(Size(548, 400)),
        child: BlocSelector<ConfigDataCubit, ConfigInterface, String>(
          selector: (state) => item.deserializeValue(
            state.config[item.key] ?? item.defaultValue,
          ),
          builder: (context, state) {
            return Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              spacing: 8,
              children: [
                if (item.title != "")
                  Row(
                    spacing: 4,
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.titleSmall!,
                        child: Text(item.title),
                      ),
                      buildResetToDefault(context),
                    ],
                  ),
                if (item.description != "")
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodySmall!,
                    child: Text(item.description),
                  ),
                Row(
                  children: [
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: item.options.length,
                        itemBuilder: (context, index) {
                          final option = item.options[index];
                          return YaruRadioListTile(
                            value: option,
                            groupValue: state,
                            onChanged: (value) => setValue(context, value!),
                            title: DefaultTextStyle(
                              style: Theme.of(context).textTheme.bodyMedium!,
                              child: Text(option),
                            ),
                          );
                        },
                      ),
                    ),
                    if (item.title == "") buildResetToDefault(context),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CheckboxThemisWidget
    extends ConfigThemisWidget<Set<String>, List<String>, CheckboxItem> {
  const CheckboxThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ConstrainedBox(
        constraints: .loose(Size(580, 400)),
        child: BlocSelector<ConfigDataCubit, ConfigInterface, Set<String>>(
          selector: (state) => item.deserializeValue(
            List<String>.from(state.config[item.key] ?? item.defaultValue),
          ),
          builder: (context, state) {
            return Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              spacing: 8,
              children: [
                if (item.title != "")
                  Row(
                    spacing: 4,
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.titleSmall!,
                        child: Text(item.title),
                      ),
                      buildResetToDefault(context),
                    ],
                  ),
                if (item.description != "")
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodySmall!,
                    child: Text(item.description),
                  ),
                Row(
                  children: [
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: item.options.length,
                        itemBuilder: (context, index) {
                          final option = item.options.toList()[index];
                          return YaruCheckboxListTile(
                            value: state.contains(option),
                            onChanged: (value) => value!
                                ? setValue(context, state..add(option))
                                : setValue(context, state..remove(option)),
                            title: DefaultTextStyle(
                              style: Theme.of(context).textTheme.bodyMedium!,
                              child: Text(option),
                            ),
                          );
                        },
                      ),
                    ),
                    if (item.title == "") buildResetToDefault(context),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class BlankThemisWidget extends ThemisWidget<ThemisItem> {
  const BlankThemisWidget(super.item, {super.key});

  @override
  Widget build(BuildContext context) =>
      YaruSection(headline: Text(item.title), child: Center());
}
