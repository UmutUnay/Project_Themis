/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-12-05 21:25:22
 * @LastEditTime: 2026-03-08 12:40:52
 * @Description: 
 */

part of "themis_widget.dart";

sealed class ThemisWidget<I extends ThemisItem> extends StatelessWidget {
  final I item;

  const ThemisWidget(this.item, {super.key});

  factory ThemisWidget.fromItem(ThemisItem item) =>
      switch (item) {
            MainItem(type: "main") => ThemisSubpage(item),
            SectionItem(type: "section") => SectionThemisWidget(item),
            PlainSubuiItem(type: "plainSubUi") => Subui(item),
            PageButtonItem(type: "pageButton") => PageButtonThemisWidget(item),
            SubUiPageButtonItem(type: "subUipageButton") => SubUiPageButton(
              item,
            ),
            ItemSelector(type: "itemSelector") => ChildSelectorThemisWidget(
              item,
            ),
            ChangedItemsSection(type: "changedItems") =>
              ChangedChildrenSectionThemisWidget(item),
            ConfigTypedList(type: "configTypedList") => ConfigFileList(item),
            ConfigTypedPageButtons(type: "configTypedPageButtons") =>
              ConfigFilePageButtonList(item),
            MutableConfigItem(
              type: "mapList" || "plainList" || "mapMap" || "plainMap",
            ) =>
              MutableList(item),
            InfoItem(type: "info") => InfoThemisWidget(item),
            KeyedInfoItem(type: "infoKey") => KeyedInfoThemisWidget(item),
            SwitchItem(type: "switch") => SwitchThemisWidget(item),
            ButtonItem(type: "button") => ButtonThemisWidget(item),
            TextItem(type: "text") => TextThemisWidget(item),
            ShortTextItem(type: "textShort") => ShortTextThemisWidget(item),
            DropdownItem(type: "dropdown") => DropdownThemisWidget(item),
            RadioItem(type: "radio") => RadioThemisWidget(item),
            CheckboxItem(type: "checkbox") => CheckboxThemisWidget(item),
            UnknownItem() => InfoThemisWidget(item),
            _ => SectionThemisWidget(SectionItem(title: "", items: [])),
          }
          as ThemisWidget<I>;
}

sealed class ConfigThemisWidget<T, S, I extends ConfigItem<T, S>>
    extends ThemisWidget<I> {
  const ConfigThemisWidget(super.item, {super.key});

  bool? setValue(BuildContext context, T newValue) => item.validate(newValue)
      ? BlocProvider.of<ConfigDataCubit>(
          context,
        ).setKey(item, item.serializeValue(newValue))
      : false;

  void resetToDefault(BuildContext context) =>
      BlocProvider.of<ConfigDataCubit>(context).setKey(item, item.defaultValue);

  bool validate(T value) => item.validate(value);

  Widget buildResetToDefault(BuildContext context) =>
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
      );
}
