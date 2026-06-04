import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';
import 'package:yaru/yaru.dart';

import '../../../core/model/settings_data/settings_data.dart';
import '../cubit/settings_data.dart';

class ShowTestButton extends StatelessWidget {
  const ShowTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    late TempSettingsCubit settings = BlocProvider.of<TempSettingsCubit>(
      context,
      listen: false,
    );
    return YaruSection(
      margin: EdgeInsets.all(8),
      headline: Text("Debug Options"),
      width: 500,
      child: BlocSelector<TempSettingsCubit, TempSettingsData, bool>(
        selector: (settings) => settings.data.debugData.showTestButton,
        builder: (context, state) => Column(
          children: [
            YaruSwitchListTile(
              title: Text("Show plugin test button"),
              value: state,
              onChanged: (value) => settings.setSetting(showTestButton: value),
            ),
          ],
        ),
      ),
    );
  }
}
