/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-12-06 16:30:32
 * @LastEditTime: 2026-03-08 13:17:47
 * @Description: 
 */

import 'dart:convert';

import '../../themis_ui_lib.dart';
import '../misc/extensions.dart';
import '../model/plugin_data/config_file_data.dart';
import '../model/themis_item/themis_item.dart';
import '../model/plugin_data/themis_plugin_data.dart';

Map<String, List<ThemisItem>> _sourceDemoItem = {
  'main': [
    MainItem(
      title: "main",
      description:
          "The item at the root of a plugin ui. It is found at the key 'main'. It fetches the first config of its type and sets it as the current config.",
      configType: "mainConfigType",
      items: [
        SectionItem(
          title: "Information",
          description:
              "Most items have title and description fields that can be used to display information.",
          items: [
            InfoItem(
              title: "info",
              description:
                  "Info items can display monospaced text. This is normal text.",
              info: "This is monospaced.",
            ),
            KeyedInfoItem(
              title: "infoKey",
              description:
                  "Keyed info items can fetch text to display from a config file.",
              key: "text",
            ),
          ],
        ),
        SectionItem(
          title: "Config items obtain their data from the current config.",
          items: [
            SwitchItem(
              title: "switch",
              description:
                  "A switch that represents a boolean. The 'trueValue' and 'falseValue' parameters allow setting custom constants for the two states.",
              key: "bool_custom",
              defaultValue: "off",
              trueValue: true,
              falseValue: "off",
            ),
            ButtonItem(
              title: "button",
              description:
                  "A button that represents a boolean. Intended for plugin-meta functionality.",
              key: "bool",
              defaultValue: false,
            ),
            TextItem(
              title: "text",
              description: "A multi-line text box.",
              key: "text",
              defaultValue: "Default",
            ),
            ShortTextItem(
              title: "textShort",
              description: "A single-line text box.",
              key: "text",
              defaultValue: "Default",
            ),
          ],
        ),
        SectionItem(
          title:
              "Enumerated items allow a single choice among the given options.",
          items: [
            DropdownItem(
              title: "dropdown",
              description: "Shows a searchable dropdown button.",
              key: "text",
              defaultValue: "daily",
              options: ["daily", "weekly", "monthly"],
            ),
            RadioItem(
              title: "radio",
              description: "Shows a list of radio buttons.",
              key: "text",
              defaultValue: "daily",
              options: ["daily", "weekly", "monthly"],
            ),
          ],
        ),
        CheckboxItem(
          title: "checkbox",
          description:
              "Subset items allow multiple choices among the given options. Checkbox item shows a list of check boxes.",
          key: "textList",
          defaultValue: ["daily", "weekly"],
          options: {"daily", "weekly", "monthly"},
        ),
        SectionItem(
          title: "Nested items nest other items.",
          items: [
            SectionItem(
              title: "section",
              description: "Groups items in a visual section.",
              items: [],
            ),
            PageButtonItem(
              title: "pageButton",
              description:
                  "Shows a button that opens a page with the given items.",
              items: [],
            ),
            ItemSelector(
              title: "itemSelector",
              description:
                  "Shows a selector for the keys of its children. Displays only the selected child.",
              items: [
                SwitchItem(
                  title: "switch",
                  key: "bool_custom",
                  defaultValue: "off",
                  trueValue: true,
                  falseValue: "off",
                ),
                ShortTextItem(
                  title: "textShort",
                  key: "text",
                  defaultValue: "Default",
                ),
                MapListItem(
                  title: "mapList",
                  subUiId: "ui1",
                  key: "mapList",
                  defaultValue: [
                    {"name": "Default", "enabled": true},
                  ],
                  templateValue: {"name": "New", "enabled": false},
                ),
              ],
            ),
            ChangedItemsSection(
              title: "changedItems",
              description:
                  "Displays its children with non-default values while hiding the ones with default values in a itemSelector.",
              items: [
                SwitchItem(
                  title: "switch",
                  key: "bool_custom",
                  defaultValue: "off",
                  trueValue: true,
                  falseValue: "off",
                ),
                ShortTextItem(
                  title: "textShort",
                  key: "text",
                  defaultValue: "Default",
                ),
                MapListItem(
                  title: "mapList",
                  subUiId: "ui1",
                  key: "mapList",
                  defaultValue: [
                    {"name": "Default", "enabled": true},
                  ],
                  templateValue: {"name": "New", "enabled": false},
                ),
              ],
            ),
          ],
        ),
        SectionItem(
          title:
              "SubUi items nest items from another key of the ui json. Each value of the ui json is referred to as a subUi.",
          description:
              "plainSubUi nests the subui without visual grouping. It can't have a title or description.",
          items: [
            PlainSubuiItem(subUiId: "ui1"),
            SubUiPageButtonItem(
              title: "subUipageButton",
              description:
                  "Shows a button that opens a page with items from the subUi.",
              subUiId: "ui1",
            ),
          ],
        ),
        SectionItem(
          title:
              "ConfigTyped items fetch the list of configurations with the given configType.",
          description:
              "They display a list where each list member takes its data from the corresponding config file.",
          items: [
            ConfigTypedList(
              title: "configTypedList",
              description:
                  "Displays a list where each list member takes its appearance from the subUi. The config files are fetched as the list member corresponding to them appears and set as the current config for that member.",
              subUiId: "ui1",
              configType: "configType1",
            ),
            ConfigTypedPageButtons(
              title: "configTypedPageButtons",
              description:
                  "Displays a list of buttons that open a different page with items from the subUi. The config files are fetched if the button corresponding to them is clicked and set as the current config for that page.",
              subUiId: "ui1",
              configType: "configType1",
            ),
          ],
        ),
        SectionItem(
          title:
              "Mutable items show a growable reorderable list. Each member of the list represents a sub-config file with its own keys and values. "
              "The list members take their appearence from the subUi. The corresponding sub-config is set as the current config for that member. The subUi config item keys should reference the keys of the sub-config. "
              "Template value is used when adding new members. It's a sub-config (key-value map) and not the underlying data type.",
          description:
              "All mutable items except plainList is displayed the same way, but the type of the underlying value is different."
              "The variants are provided to help reduce plugin-side data restructuring.",
          items: [
            MapListItem(
              title: "mapList",
              description:
                  "A list of maps. Each map is treated as a sub-config.",
              subUiId: "ui1",
              key: "mapList",
              defaultValue: [
                {"name": "Default", "enabled": true},
              ],
              templateValue: {"name": "New", "enabled": false},
            ),
            PlainListItem(
              title: "plainList",
              description:
                  "A list of values. For each value the sub-config is a map where the 'themis_value' key contains the value. This mutable item is displayed more densely than others.",
              subUiId: "ui1",
              key: "plainList",
              defaultValue: ["Default"],
              templateValue: {"themis_value": "New"},
            ),
            MapMapItem(
              title: "mapMap",
              description:
                  "A map where the values are maps. Each value is treated as a sub-config. Additionally the key that the value is found at is contained at the 'themis_key' key.",
              subUiId: "ui1",
              key: "mapMap",
              defaultValue: {
                "Default": {"enabled": true},
              },
              templateValue: {"themis_key": "New", "enabled": false},
            ),
            PlainMapItem(
              title: "plainMap",
              description:
                  "A map. For each key-value pair the sub-config is a map where the 'themis_key' key contains the key and 'themis_value' key contains the value.",
              subUiId: "ui1",
              key: "plainMap",
              defaultValue: {"Default": true},
              templateValue: {"themis_key": "New", "themis_value": false},
            ),
          ],
        ),
      ],
    ),
  ],
  'ui1': [InfoItem(title: "This is a subUi.", info: "Its id is ui1.")],
};

Map<String, List<ThemisItem>> demoItem = {
  ..._sourceDemoItem,
  'main': [
    (_sourceDemoItem['main']!.first as MainItem).copyWithItems([
      ...(_sourceDemoItem['main']!.first as MainItem).items,
      SectionItem(
        title: "Sources",
        description:
            "These are the source files used by the GUI to generate the rest of this page.",
        items: [
          InfoItem(title: "Plugin Brief", info: demoBrief.encode()),
          InfoItem(
            title: "Plugin Backup Briefs",
            info: json.encode(demoBackup.map((e) => e.toJson()).toList()),
          ),
          InfoItem(
            title: "Config File Briefs",
            info: json.encode(demoConfigBriefs.map((e) => e.toJson()).toList()),
          ),
          PlainMapItem(
            title: "Config Files",
            subUiId: "config_file",
            key: "configFiles",
            defaultValue: {},
            templateValue: {"themis_key": "New", "themis_value": "[]"},
          ),
          InfoItem(title: "Ui Json", info: _sourceDemoItem.encode()),
        ],
      ),
    ]),
  ],
  "config_type": [
    KeyedInfoItem(title: "Config Type", key: "themis_key"),
    KeyedInfoItem(title: "File Briefs", key: "themis_value"),
  ],
  "config_file": [
    KeyedInfoItem(title: "File Id", key: "themis_key"),
    KeyedInfoItem(title: "File Content", key: "themis_value"),
  ],
};

ThemisPluginBrief demoBrief = ThemisPluginBrief(
  pluginId: "demo",
  pluginVersion: "1",
  title: "UI Demo",
  subtitle: "Demonstration of UI items",
);

Map<String, Map<String, dynamic>> _demoConfigSource = {
  "mainConfig": {
    "bool_custom": "off",
    "bool": false,
    "text": "Lorem ipsum",
    "textList": ["daily"],
    "mapList": [
      {"name": "My Rule", "enabled": true},
    ],
    "plainList": ["My Rule"],
    "mapMap": {
      "My Rule": {"enabled": true},
    },
    "plainMap": {"My Rule": true},
  },
  "secondConfig1": {"firstBool": false, "secondBool": true},
  "secondConfig2": {"firstBool": false, "secondBool": true},
};

Map<String, Map<String, dynamic>> demoConfig = {
  ..._demoConfigSource,
  'mainConfig': {
    ..._demoConfigSource['mainConfig']!,
    "configFiles": _demoConfigSource.map((k, v) => MapEntry(k, json.encode(v))),
  },
};

List<ConfigFileBrief> demoConfigBriefs = [
  ConfigFileBrief(
    pluginId: "demo",
    configId: "mainConfig",
    configType: "mainConfigType",
    title: "Main Configuration",
  ),
  ConfigFileBrief(
    pluginId: "demo",
    configId: "secondConfig1",
    configType: "configType1",
    title: "Secondary Config 1",
  ),
  ConfigFileBrief(
    pluginId: "demo",
    configId: "secondConfig2",
    configType: "configType1",
    title: "Secondary Config 2",
  ),
];

List<BackupData> demoBackup = [
  BackupData(id: "2025.05.26", path: "/etc/themis"),
];
