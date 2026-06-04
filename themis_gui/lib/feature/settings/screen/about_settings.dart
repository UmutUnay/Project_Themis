/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-24 23:43:13
 * @LastEditTime: 2025-11-25 00:23:31
 * @Description: 
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:yaru/yaru.dart';

import '../../../core/misc/constants.dart';

/// The "About" settings page.
class AboutSettings extends StatelessWidget {
  const AboutSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10000,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: .center,
          children: [
            YaruSection(
              margin: EdgeInsets.all(8),
              width: 500,
              headline: Text("Themis GUI"),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Column(
                    children: [
                      Text("v0.3.1"),
                      OutlinedButton(
                        onPressed: () => showLicensePage(
                          context: context,
                          applicationName: "Themis GUI",
                          applicationVersion: "v0.3.1",
                        ),
                        child: Text("Show licenses"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (context) => ResetDialog(),
                );
              },
              child: Text("Reset GUI settings"),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog for GUI settings reset.
class ResetDialog extends StatelessWidget {
  const ResetDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: YaruDialogTitleBar(title: Text("Reseting settings")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "This action will reset all Themis GUI settings.\nThemis settings and configurations will not be changed.",
            textAlign: TextAlign.center,
          ),
          if (kIsWeb)
            Text(
              "Please reload the page afterwards.",
              textAlign: TextAlign.center,
            ),
        ],
      ),
      actions: [
        OutlinedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(deleteIconColor),
          ),
          onPressed: () async {
            await HydratedBloc.storage.clear();
            SystemNavigator.pop();
          },
          child: Text("Delete"),
        ),
        OutlinedButton(
          onPressed: Navigator.of(context).pop,
          child: Text("Cancel"),
        ),
      ],
    );
  }
}
