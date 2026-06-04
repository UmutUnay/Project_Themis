import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';
import 'package:yaru/yaru.dart';

import '../../../core/misc/print_success.dart';

class SelectPluginFile extends StatefulWidget {
  const SelectPluginFile({super.key});

  @override
  State<SelectPluginFile> createState() => _SelectPluginFileState();
}

class _SelectPluginFileState extends State<SelectPluginFile> {
  bool filePickerFailed = false;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      margin: EdgeInsets.all(8),
      width: 500,
      headline: Text("Install from file"),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: AnimatedSize(
          alignment: .topCenter,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCirc,
          child: Column(
            mainAxisAlignment: .end,
            spacing: 8,
            children: [
              YaruSection(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: .start,
                    crossAxisAlignment: .start,
                    spacing: 8,
                    children: [
                      Text("Select a plugin file from this computer."),
                      Text(
                        "Note: Currently this only works with a native gui and local Themis Server installed on the same computer.",
                        style: TextTheme.of(context).labelMedium,
                      ),
                      Center(
                        child: Column(
                          children: [
                            if (filePickerFailed)
                              Text(
                                "No file was selected",
                                style: TextTheme.of(context).labelMedium!
                                    .copyWith(
                                      color: ColorScheme.of(context).error,
                                    ),
                              ),
                            OutlinedButton(
                              onPressed: kIsWeb
                                  ? null
                                  : () async {
                                      FilePickerResult? file;
                                      final downloads =
                                          await getDownloadsDirectory();
                                      file = await FilePicker.pickFiles(
                                        initialDirectory: downloads?.path,
                                      );
                                      if (file == null) {
                                        filePickerFailed = true;
                                      } else {
                                        filePickerFailed = false;
                                        textController.text = file.paths.first!;
                                      }
                                      setState(() {});
                                    },
                              child: Text("Select file"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text("OR"),
              YaruSection(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: .start,
                    crossAxisAlignment: .start,
                    spacing: 8,
                    children: [
                      Text("Enter a file path on the server."),
                      Center(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: textController,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily:
                                    'IBMPlexMono', // Style doesn't work!
                                fontSize: Theme.of(
                                  context,
                                ).textTheme.bodySmall!.fontSize,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (textController.text != "")
                Text(
                  "Selected path: ${textController.text}",
                  style: TextTheme.of(context).bodySmall,
                ),
              OutlinedButton(
                onPressed: () async {
                  final success = await ThemisClient.instance
                      .installLocalPlugin(textController.text);
                  if (context.mounted) {
                    notifySuccess(
                      context,
                      success,
                      successText: "Plugin installed.",
                      failureText: "Plugin installation failed.",
                    );
                  }
                },
                child: Text("Install plugin"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
