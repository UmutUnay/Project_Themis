import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

import '../../../core/misc/constants.dart';
import '../cubit/settings_data.dart';

/// Confirmation dialog for exiting settings without saving
class ExitConfirmationDialog extends StatelessWidget {
  final TempSettingsCubit tempSettings;
  const ExitConfirmationDialog(this.tempSettings, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: YaruDialogTitleBar(title: Text("Exit confirmation")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Settings changes have not been saved. Are you sure you want to exit?",
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: tempSettings.state.canSaveSettings
              ? () async {
                  tempSettings.saveSettings();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              : null,
          child: Row(
            mainAxisSize: .min,
            spacing: 4,
            children: [
              Icon(YaruIcons.floppy, color: saveIconColor),
              Text("Save"),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () async {
            tempSettings.restoreSettings();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          child: Row(
            mainAxisSize: .min,
            spacing: 4,
            children: [
              Icon(YaruIcons.refresh, color: discardIconColor),
              Text("Discard"),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: Navigator.of(context).pop,
          child: Text("Cancel"),
        ),
      ],
    );
  }
}
