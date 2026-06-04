/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-17 16:14:35
 * @LastEditTime: 2026-03-08 12:41:56
 * @Description: 
 */

// ignore_for_file: must_be_immutable

part of "themis_item.dart";

// This file contains the definitions of base abstract ThemisItem types.

/// An item to be displayed in the ui.
///
///
sealed class ThemisItem extends Equatable {
  /// The identifier of the item type.
  String get type;

  /// Unique ui id of the item, used when editing ui.
  final String id;

  /// Short (50 chars) name of the item.
  final String title;

  /// Full description of the item. Can be empty.
  final String description;

  ThemisItem({required this.title, this.description = "", String? id})
    : id = id ?? Uuid().v4();

  /// Constructs the item from a decoded json.
  /// Json representations are tentative.
  ThemisItem.fromJson(Map<String, dynamic> jmap)
    : id = Uuid().v4(),
      title = jmap['title'],
      description = jmap['description'] ?? "";

  /// Turns a decoded Themis ui definition json into [ThemisItem]s of unknown type.
  /// Json representations are tentative.
  factory ThemisItem.json(Map<String, dynamic> jmap) => switch (jmap) {
    {'type': 'main'} => MainItem.fromJson(jmap),
    {'type': 'section'} => SectionItem.fromJson(jmap),
    {'type': 'changedItems'} => ChangedItemsSection.fromJson(jmap),
    {'type': 'plainSubUi'} => PlainSubuiItem.fromJson(jmap),
    {'type': 'pageButton'} => PageButtonItem.fromJson(jmap),
    {'type': 'subUipageButton'} => SubUiPageButtonItem.fromJson(jmap),
    {'type': 'itemSelector'} => ItemSelector.fromJson(jmap),
    {'type': 'configTypedList'} => ConfigTypedList.fromJson(jmap),
    {'type': 'configTypedPageButtons'} => ConfigTypedPageButtons.fromJson(jmap),
    {'type': 'mapList'} => MapListItem.fromJson(jmap),
    {'type': 'plainList'} => PlainListItem.fromJson(jmap),
    {'type': 'mapMap'} => MapMapItem.fromJson(jmap),
    {'type': 'plainMap'} => PlainMapItem.fromJson(jmap),
    {'type': 'info'} => InfoItem.fromJson(jmap),
    {'type': 'infoKey'} => KeyedInfoItem.fromJson(jmap),
    {'type': 'switch'} => SwitchItem.fromJson(jmap),
    {'type': 'button'} => ButtonItem.fromJson(jmap),
    {'type': 'text'} => TextItem.fromJson(jmap),
    {'type': 'textShort'} => ShortTextItem.fromJson(jmap),
    {'type': 'dropdown'} => DropdownItem.fromJson(jmap),
    {'type': 'radio'} => RadioItem.fromJson(jmap),
    {'type': 'checkbox'} => CheckboxItem.fromJson(jmap),
    // {'type': 'presets'} => PresetsItem.fromJson( jmap),
    _ => UnknownItem.fromJson(jmap),
  };

  /// Converts a [ThemisItem] into json map.
  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'description': description,
  };

  @override
  List<Object?> get props => [id];
}

/// An item that nests other items.
sealed class NestedItem<T extends ThemisItem> extends ThemisItem {
  /// The items in this nesting
  final List<T> items;

  NestedItem({
    required super.title,
    super.description = "",
    required this.items,
  });

  @override
  NestedItem.fromJson(super.jmap)
    : items = List<T>.from(
        (jmap['items'] as List).map((e) => ThemisItem.json(e)),
      ),
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'items': [for (var it in items) it.toJson()],
  };

  /// Copies the item with the given items list.
  dynamic copyWithItems(List<T> newItems) => switch (this) {
    MainItem(type: "main", :var configType) => MainItem(
      title: title,
      description: description,
      items: newItems,
      configType: configType,
    ),
    SectionItem(type: "section") => SectionItem(
      title: title,
      description: description,
      items: newItems,
    ),
    PageButtonItem(type: "page") => PageButtonItem(
      title: title,
      description: description,
      items: newItems,
    ),
    _ => this,
  };

  @override
  List<Object?> get props => [...super.props, items];
}

/// An item that holds a configurable value.
/// [T] is the ui type while [S] is the serialized type.
sealed class ConfigItem<T, S> extends ThemisItem {
  /// The key of the configuration.
  final String key;

  /// Default value of the configuration, in the serialized format.
  final S defaultValue;

  /// Omits the key from the config if the value is the [defaultValue].
  final bool omitDefault;

  /// The ordering of the key relative to other keys in the config (when saving).
  final int order;

  ConfigItem({
    required super.title,
    super.description = "",
    required this.key,
    required this.defaultValue,
    this.omitDefault = false,
    this.order = 0,
  });

  @override
  ConfigItem.fromJson(super.jmap)
    : key = jmap['key'],
      defaultValue = jmap['default'],
      omitDefault = jmap['omitDefault'] ?? false,
      order = jmap['order'] ?? 0,
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'key': key,
    'default': defaultValue,
    'omitDefault': omitDefault,
    'order': order,
  };

  /// Serialize the value at this key.
  ///
  /// This function isn't included in the ui json.
  /// Subclasses where it is appropriate should implement it and
  /// include its configuration themselves.
  S serializeValue(T value);

  /// Deserialize the value at this key.
  ///
  /// This function isn't included in the ui json.
  /// Subclasses where it is appropriate should implement it and
  /// include its configuration themselves.
  T deserializeValue(S value);

  /// Validates that the value is allowed to be set.
  /// This should validate locally if possible,
  /// if not return true.
  ///
  /// This function isn't included in the ui json.
  /// Subclasses where it is appropriate should implement it and
  /// include its configuration themselves.
  bool validate(T value);

  @override
  List<Object?> get props => [
    ...super.props,
    key,
    defaultValue,
    omitDefault,
    order,
  ];
}

/// A configuration item that can have the value of one of a limited set.
sealed class EnumeratedConfigItem<T, S> extends ConfigItem<T, S> {
  /// The set of options value can take. In serialized format.
  final List<S> options;

  EnumeratedConfigItem({
    required super.title,
    super.description,
    required super.key,
    required super.defaultValue,
    super.omitDefault,
    super.order,
    required this.options,
  });

  @override
  EnumeratedConfigItem.fromJson(super.jmap)
    : options = List<S>.from(jmap['options']),
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'options': options};

  /// Validates that value is in the set of allowed options.
  @override
  bool validate(T value) => options.contains(value);
}

/// A configuration item that can have multiple values of a limited set.
sealed class SubsetConfigItem<T, C extends Iterable<T>, S>
    extends ConfigItem<C, List<S>> {
  /// The set of options value can take.
  final Set<S> options;

  SubsetConfigItem({
    required super.title,
    super.description,
    required super.key,
    required super.defaultValue,
    super.omitDefault,
    super.order,
    required this.options,
  });

  @override
  SubsetConfigItem.fromJson(Map<String, dynamic> jmap)
    : options = List<S>.from(jmap['options']).toSet(),
      super.fromJson({
        ...jmap,
        'default': jmap['default'] == null
            ? null
            : List<S>.from(jmap['default']),
      });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'options': options.toList(),
  };

  /// Validates that all members of value are in the set of allowed options.
  @override
  bool validate(C value) => value.toSet().difference(options).isEmpty;
}

/// An item that nests a subui. SubUis can be infinitely nested.
sealed class SubUiItem extends ThemisItem {
  /// Id of the subui.
  final String subUiId;

  SubUiItem({required super.title, super.description, required this.subUiId});

  @override
  SubUiItem.fromJson(super.jmap) : subUiId = jmap['subUiId'], super.fromJson();

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'subUiId': subUiId};

  @override
  List<Object?> get props => [...super.props, subUiId];
}

/// An item that nests a subui belonging to a config file of the given type.
sealed class ConfigTypedSubuiItem extends SubUiItem {
  /// The config file type of the nested items.
  final String configType;

  ConfigTypedSubuiItem({
    required super.title,
    super.description,
    required super.subUiId,
    required this.configType,
  });

  @override
  ConfigTypedSubuiItem.fromJson(super.jmap)
    : configType = jmap['configType'],
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'configType': configType,
  };

  @override
  List<Object?> get props => [...super.props, configType];
}

/// An item that a subui belonging to a mutable config value (list or map).
/// This is analogous to a ConfigTypedNestedItem that treats
/// each member of the mutable as a file of the same type.
sealed class MutableConfigItem<S> extends SubUiItem
    implements ConfigItem<List<Map<String, dynamic>>, S> {
  /// The key of the configuration.
  @override
  final String key;

  /// Default value of the configuration, in the serialized format.
  @override
  final S defaultValue;

  /// Template value for new items, in the deserialized format.
  final Map<String, dynamic> templateValue;

  /// Omits the key from the config if the value is the [defaultValue].
  @override
  final bool omitDefault;

  /// The ordering of the key relative to other keys in the config (when saving).
  @override
  final int order;

  MutableConfigItem({
    required super.title,
    super.description,
    required super.subUiId,
    required this.key,
    required this.defaultValue,
    required this.templateValue,
    this.omitDefault = false,
    this.order = 0,
  });

  @override
  MutableConfigItem.fromJson(super.jmap)
    : key = jmap['key'],
      defaultValue = jmap['default'],
      templateValue = jmap['template'],
      omitDefault = jmap['omitDefault'] ?? false,
      order = jmap['order'] ?? 0,
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'key': key,
    'default': defaultValue,
    'template': templateValue,
    'omitDefault': omitDefault,
    'order': order,
  };

  @override
  bool validate(List<Map<String, dynamic>> value) => true;
  // Since T binds to dynamic there's no guarantee value will be the expected type.
  // Actually testing this is difficult and it's not likely to be false, so this returns true.

  /// Wheter a new member can currently be added to the current value.
  bool canAddNew(List<Map<String, dynamic>> value);

  @override
  List<Object?> get props => [
    ...super.props,
    key,
    defaultValue,
    templateValue,
    omitDefault,
    order,
  ];
}
