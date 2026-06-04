/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-19 22:41:50
 * @LastEditTime: 2026-03-08 12:18:03
 * @Description: 
 */

// ignore_for_file: must_be_immutable
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../misc/extensions.dart';

part "themis_item_abstract.dart";

// This file contains the definitions of basic ThemisItems.
// These should cover most cases.

/// The main root item of a plugin.
///
/// There must be only one config file of its config type.
class MainItem extends NestedItem<ThemisItem> {
  /// The config file type of the nested items.
  final String configType;
  @override
  String get type => "main";

  MainItem({
    required super.title,
    super.description,
    required super.items,
    required this.configType,
  });

  @override
  MainItem.fromJson(super.jmap)
    : configType = jmap['configType'],
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson()..removeWhere((k, v) => k == 'items'),
    'configType': configType,
    'items': [for (var it in items) it.toJson()],
  };

  @override
  List<Object?> get props => [...super.props, configType];
}

// Groups other items in a visual section.
class SectionItem extends NestedItem<ThemisItem> {
  @override
  String get type => "section";

  SectionItem({required super.title, super.description, required super.items});

  @override
  SectionItem.fromJson(super.jmap) : super.fromJson();
}

/// Nests its children with values different from the default.
/// Displays the rest in an itemSelector.
class ChangedItemsSection extends NestedItem<ConfigItem> {
  @override
  String get type => "changedItems";

  ChangedItemsSection({
    required super.title,
    super.description,
    required super.items,
  });

  late List<String> titles = items.map((item) => item.title).toList();

  @override
  ChangedItemsSection.fromJson(super.jmap) : super.fromJson();
}

/// Displays a subUi without visual grouping.
/// The title and description aren't displayed.
class PlainSubuiItem extends SubUiItem {
  @override
  String get type => "plainSubUi";

  PlainSubuiItem({required super.subUiId}) : super(title: "", description: "");

  @override
  PlainSubuiItem.fromJson(super.jmap) : super.fromJson();
}

/// Shows a button that opens a new page with the given items.
class PageButtonItem extends NestedItem<ThemisItem> {
  @override
  String get type => "pageButton";

  PageButtonItem({
    required super.title,
    super.description,
    required super.items,
  });

  @override
  PageButtonItem.fromJson(super.jmap) : super.fromJson();
}

/// Shows a button that opens a new page with the given subui.
/// The subui root is assumed to be a [PageButtonItem]
class SubUiPageButtonItem extends SubUiItem {
  @override
  String get type => "subUipageButton";

  SubUiPageButtonItem({
    required super.title,
    super.description,
    required super.subUiId,
  });

  @override
  SubUiPageButtonItem.fromJson(super.jmap) : super.fromJson();
}

/// Shows a selector for the titles of its children.
/// Displays only the selected child.
class ItemSelector extends NestedItem<ConfigItem> {
  @override
  String get type => "itemSelector";

  ItemSelector({required super.title, super.description, required super.items});

  late List<String> titles = items.map((item) => item.title).toList();

  @override
  ItemSelector.fromJson(super.jmap) : super.fromJson();
}

/// A section item that groups items that belong to a different config file type.
///
/// Expands to seperate sections for the available config files of the given type.
/// Each section includes the ui items of the subui, and the data of the corresponding file.
class ConfigTypedList extends ConfigTypedSubuiItem {
  @override
  String get type => "configTypedList";

  ConfigTypedList({
    required super.title,
    super.description,
    required super.subUiId,
    required super.configType,
  });

  @override
  ConfigTypedList.fromJson(super.jmap) : super.fromJson();
}

/// A page button item that groups items that belong to a different config file type.
///
/// Displays a list of buttons for the available config files of the given type.
/// Each button opens a new page with the ui items of this item, and the data
/// of the corresponding file.
class ConfigTypedPageButtons extends ConfigTypedSubuiItem {
  @override
  String get type => "configTypedPageButtons";

  ConfigTypedPageButtons({
    required super.title,
    super.description,
    required super.subUiId,
    required super.configType,
  });

  @override
  ConfigTypedPageButtons.fromJson(super.jmap) : super.fromJson();
}

/// An item that groups items that belong to members of a list.
///
/// Displays its subui in a subsection for each member of the list at [key].
/// The list may be expanded by [templateValue] or its members may be removed.
///
/// This variant is for lists with key:value maps as members.
/// The subitems should reference keys available at this map directly.
class MapListItem extends MutableConfigItem<List<Map<String, dynamic>>> {
  @override
  String get type => "mapList";

  MapListItem({
    required super.title,
    super.description,
    required super.subUiId,
    required super.key,
    required super.defaultValue,
    required super.templateValue,
    super.omitDefault,
    super.order,
  });

  @override
  MapListItem.fromJson(Map<String, dynamic> jmap)
    : super.fromJson({
        ...jmap,
        'default': jmap['default'] == null
            ? null
            : List<Map<String, dynamic>>.from(jmap['default']),
      });

  @override
  List<Map<String, dynamic>> deserializeValue(List<dynamic> value) =>
      List<Map<String, dynamic>>.from(value);

  @override
  List<Map<String, dynamic>> serializeValue(List<Map<String, dynamic>> value) =>
      List<Map<String, dynamic>>.from(value);

  @override
  bool canAddNew(List<Map<String, dynamic>> value) => true;
}

/// An item that groups items that belong to members of a list.
///
/// Displays its subui in a subsection for each member of the list at [key].
/// The list may be expanded by [templateValue] or its members may be removed.
///
/// This variant is for lists with misc members.
/// The subitems should reference the 'themis_value' key, which holds the value
/// of the member.
class PlainListItem<S> extends MutableConfigItem<List<S>> {
  @override
  String get type => "plainList";

  PlainListItem({
    required super.title,
    super.description,
    required super.subUiId,
    required super.key,
    required super.defaultValue,
    required super.templateValue,
    super.omitDefault,
    super.order,
  });

  @override
  PlainListItem.fromJson(Map<String, dynamic> jmap)
    : super.fromJson({
        ...jmap,
        'default': jmap['default'] == null
            ? null
            : List<S>.from(jmap['default']),
      });

  @override
  List<Map<String, S>> deserializeValue(List<S> value) =>
      value.map((e) => {'themis_value': e}).toList();

  @override
  List<S> serializeValue(List<Map<String, dynamic>> value) =>
      value.map((e) => e['themis_value']! as S).toList();

  @override
  bool canAddNew(List<Map<String, dynamic>> value) => true;
}

/// An item that groups items that belong to entries of a map.
///
/// Displays its subui in a subsection for each entry of a map at [key].
/// The list may be expanded by [templateValue] or its members may be removed.
///
/// This variant is for maps with other key:value maps as values.
/// The nesting is flattened so that the main map entry's key is accessible at
/// the 'themis_key' key alongside the key:value pairs of the value map.
/// The subitems should reference keys available at this level directly.
class MapMapItem extends MutableConfigItem<Map<String, Map<String, dynamic>>> {
  @override
  String get type => "mapMap";

  MapMapItem({
    required super.title,
    super.description,
    required super.subUiId,
    required super.key,
    required super.defaultValue,
    required super.templateValue,
    super.omitDefault,
    super.order,
  });

  @override
  MapMapItem.fromJson(Map<String, dynamic> jmap)
    : super.fromJson({
        ...jmap,
        'default': jmap['default'] == null
            ? null
            : Map<String, Map<String, dynamic>>.from(jmap['default']),
      });

  @override
  List<Map<String, dynamic>> deserializeValue(Map<String, dynamic> value) =>
      Map<String, Map<String, dynamic>>.from(
        value,
      ).entries.map((e) => {'themis_key': e.key, ...e.value}).toList();

  @override
  Map<String, Map<String, dynamic>> serializeValue(
    List<Map<String, dynamic>> value,
  ) => Map.fromEntries(
    value.map((e) => MapEntry(e['themis_key'], {...e}..remove('themis_key'))),
  );

  @override
  bool canAddNew(List<Map<String, dynamic>> value) =>
      value.every((e) => e['themis_key'] != templateValue['themis_key']);
}

/// An item that groups items that belong to entries of a map.
///
/// Displays its subui in a subsection for each entry of a map at [key].
/// The list may be expanded by [templateValue] or its members may be removed.
///
/// This variant is for maps that don't have another key-value map as value.
/// The value is treated as a single, ordinary value.
/// The main map entry's key is accessible at the 'themis_key' key.
/// Its value is accessible at the 'themis_value' key.
/// The subitems should reference keys available at this level directly.
class PlainMapItem<T> extends MutableConfigItem<Map<String, T>> {
  @override
  String get type => "plainMap";

  PlainMapItem({
    required super.title,
    super.description,
    required super.subUiId,
    required super.key,
    required super.defaultValue,
    required super.templateValue,
    super.omitDefault,
    super.order,
  });

  @override
  PlainMapItem.fromJson(super.jmap) : super.fromJson();

  @override
  List<Map<String, dynamic>> deserializeValue(Map<String, T> value) => value
      .entries
      .map((e) => {'themis_key': e.key, 'themis_value': e.value})
      .toList();

  @override
  Map<String, T> serializeValue(List<Map<String, dynamic>> value) =>
      Map.fromEntries(
        value.map((e) => MapEntry(e['themis_key'], e['themis_value'])),
      );

  @override
  bool canAddNew(List<Map<String, dynamic>> value) =>
      value.every((e) => e['themis_key'] != templateValue['themis_key']);
}

// An item that holds information to be displayed.
class InfoItem extends ThemisItem {
  @override
  final String type = "info";

  /// Info text displayed
  final String info;

  InfoItem({
    required super.title,
    super.description,
    required this.info,
    super.id,
  });

  @override
  InfoItem.fromJson(super.jmap) : info = jmap['value'], super.fromJson();

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'value': info};

  @override
  List<Object?> get props => [...super.props, info];
}

// An item that fetches information from the config
class KeyedInfoItem extends ConfigItem<String, String> {
  @override
  final String type = "infoKey";

  KeyedInfoItem({
    required super.title,
    super.description,
    required super.key,
    super.defaultValue = "",
    super.omitDefault,
    super.order,
  });

  @override
  KeyedInfoItem.fromJson(super.jmap) : super.fromJson();

  @override
  String deserializeValue(value) => value;

  @override
  String serializeValue(value) => value;

  @override
  bool validate(value) => true;

  @override
  List<Object?> get props => [...super.props, key];
}

/// A configuration item that can be on or off.
class SwitchItem<S> extends ConfigItem<bool, S> {
  @override
  String get type => "switch";

  /// The serialized 'true' value.
  final S trueValue;

  /// The serialized 'false' value.
  final S falseValue;

  SwitchItem({
    required super.title,
    super.description,
    required super.key,
    required super.defaultValue,
    super.omitDefault,
    super.order,
    required this.trueValue,
    required this.falseValue,
  });

  @override
  SwitchItem.fromJson(super.jmap)
    : trueValue = jmap['trueValue'] ?? true,
      falseValue = jmap['falseValue'] ?? false,
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'trueValue': trueValue,
    'falseValue': falseValue,
  };

  @override
  bool validate(bool value) => true;

  @override
  bool deserializeValue(S value) => value == trueValue;

  @override
  S serializeValue(bool value) => value ? trueValue : falseValue;

  @override
  List<Object?> get props => [...super.props, trueValue, falseValue];
}

/// A configuration item that can be turned on and turns back off after applying.
class ButtonItem extends SwitchItem<bool> {
  @override
  String get type => "button";

  ButtonItem({
    required super.title,
    super.description,
    required super.key,
    super.defaultValue = false,
    super.omitDefault,
    super.order,
  }) : super(trueValue: true, falseValue: false);

  @override
  ButtonItem.fromJson(Map<String, dynamic> jmap) : super.fromJson({...jmap});

  @override
  bool validate(bool value) => true;
}

/// A configuration item that allows text submission.
class TextItem extends ConfigItem<String, String> {
  @override
  String get type => "text";

  final RegExp? validator;

  TextItem({
    required super.title,
    super.description,
    required super.key,
    required super.defaultValue,
    super.omitDefault,
    super.order,
    this.validator,
  });

  @override
  TextItem.fromJson(super.jmap)
    : validator = (jmap['validator'] as String?).toRegex(),
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    if (validator != null) 'validator': validator!.pattern,
  };

  @override
  bool validate(String value) {
    if (validator != null) return validator!.hasMatch(value);
    return true;
  }

  @override
  String deserializeValue(String value) => value;

  @override
  String serializeValue(String value) => value;

  @override
  List<Object?> get props => [...super.props, validator];
}

/// A configuration item that allows a single line text submission.
/// Can't have a description.
class ShortTextItem extends TextItem {
  @override
  String get type => "textShort";

  ShortTextItem({
    required super.title,
    super.description,
    required super.key,
    required super.defaultValue,
    super.omitDefault,
    super.order,
    super.validator,
  });

  @override
  ShortTextItem.fromJson(super.jmap) : super.fromJson();
}

/// A placeholder configuration item for items in the tree that have unknown types.
class UnknownItem extends InfoItem {
  @override
  String get type => "unknown";

  UnknownItem({super.info = ""})
    : super(
        title: "Unknown Item",
        description:
            "This item has a type unknown to the ui. This was the given json:",
      );

  @override
  UnknownItem.fromJson(Map<String, dynamic> jmap)
    : super(
        title: "Unknown Item",
        description:
            "This item has a type unknown to the ui. This was the given json:",
        info: json.encode(jmap),
      );

  @override
  Map<String, dynamic> toJson() => {...super.toJson()};
}

/// An enumerated configuration item displayed as a dropdown button.
class DropdownItem extends EnumeratedConfigItem<String, String> {
  @override
  String get type => "dropdown";

  DropdownItem({
    required super.title,
    super.description,
    required super.key,
    required super.defaultValue,
    super.omitDefault,
    super.order,
    required super.options,
  });

  @override
  String deserializeValue(String value) => value;

  @override
  String serializeValue(String value) => value;

  @override
  DropdownItem.fromJson(super.jmap) : super.fromJson();
}

/// An enumerated configuration item displayed as radio buttons.
class RadioItem extends EnumeratedConfigItem<String, String> {
  @override
  String get type => "radio";

  RadioItem({
    required super.title,
    super.description,
    required super.key,
    required super.defaultValue,
    super.omitDefault,
    super.order,
    required super.options,
  });

  @override
  String deserializeValue(String value) => value;

  @override
  String serializeValue(String value) => value;

  @override
  RadioItem.fromJson(super.jmap) : super.fromJson();
}

/// A subset configuration item that allows selection of multiple options.
class CheckboxItem extends SubsetConfigItem<String, Set<String>, String> {
  @override
  String get type => "checkbox";

  CheckboxItem({
    required super.title,
    super.description,
    required super.key,
    required super.defaultValue,
    super.omitDefault,
    super.order,
    required super.options,
  });

  @override
  Set<String> deserializeValue(List<String> value) => value.toSet();

  @override
  List<String> serializeValue(Set<String> value) => value.toList();

  @override
  CheckboxItem.fromJson(super.jmap) : super.fromJson();
}
