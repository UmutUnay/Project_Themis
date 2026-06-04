part of "themis_component.dart";

sealed class ThemisComponent<I extends ThemisItem> extends StatelessComponent {
  final I item;

  const ThemisComponent(this.item, {super.key});

  factory ThemisComponent.fromItem(ThemisItem item) =>
      switch (item) {
            MainItem(type: "main") => ThemisSubpage(item),
            SectionItem(type: "section") => SectionThemisWidget(item),
            // PlainSubuiItem(type: "plainSubUi") => Subui(item),
            // PageButtonItem(type: "pageButton") => PageButtonThemisWidget(item),
            // SubUiPageButtonItem(type: "subUipageButton") => SubUiPageButton(
            //   item,
            // ),
            // ItemSelectorItem(type: "itemSelector") => ChildSelectorThemisWidget(
            //   item,
            // ),
            // ConfigTypedList(type: "configTypedList") => ConfigFileList(item),
            // ConfigTypedPageButtons(type: "configTypedPageButtons") =>
            //   ConfigFilePageButtonList(item),
            // MutableConfigItem(
            //   type: "mapList" || "plainList" || "mapMap" || "plainMap",
            // ) =>
            //   MutableList(item),
            // InfoItem(type: "info") => InfoThemisWidget(item),
            // KeyedInfoItem(type: "infoKey") => KeyedInfoThemisWidget(item),
            // SwitchItem(type: "switch") => SwitchThemisWidget(item),
            // ButtonItem(type: "button") => ButtonThemisWidget(item),
            // TextItem(type: "text") => TextThemisWidget(item),
            // ShortTextItem(type: "textShort") => ShortTextThemisWidget(item),
            // DropdownItem(type: "dropdown") => DropdownThemisWidget(item),
            // RadioItem(type: "radio") => RadioThemisWidget(item),
            // CheckboxItem(type: "checkbox") => CheckboxThemisWidget(item),
            // UnknownItem() => InfoThemisWidget(item),
            _ => SectionThemisWidget(SectionItem(title: "", items: [])),
          }
          as ThemisComponent<I>;
}

sealed class ConfigThemisWidget<T, S, I extends ConfigItem<T, S>>
    extends ThemisComponent<I> {
  const ConfigThemisWidget(super.item, {super.key});

  bool? setValue(BuildContext context, T newValue) => item.validate(newValue)
      ? InheritedProvider.of<ConfigDataCubit>(
          context,
        )!.setValue(item, item.serializeValue(newValue))
      : false;

  void resetToDefault(BuildContext context) =>
      InheritedProvider.of<ConfigDataCubit>(
        context,
      )!.setValue(item, item.defaultValue);

  bool validate(T value) => item.validate(value);
}
