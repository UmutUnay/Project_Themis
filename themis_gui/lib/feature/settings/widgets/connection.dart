import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';
import 'package:yaru/yaru.dart';

import '../../../core/model/settings_data/settings_data.dart';
import '../cubit/settings_data.dart';

class ConnectionMethod extends StatelessWidget {
  const ConnectionMethod({super.key});

  @override
  Widget build(BuildContext context) {
    late TempSettingsCubit settings = BlocProvider.of<TempSettingsCubit>(
      context,
      listen: false,
    );
    return YaruSection(
      margin: EdgeInsets.all(8),
      headline: Text("Connection method"),
      width: 500,
      child: BlocSelector<TempSettingsCubit, TempSettingsData, ClientType>(
        selector: (settings) => settings.data.clientData.type,
        builder: (context, state) => Column(
          children: [
            YaruRadioListTile(
              title: Text("Http"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Connect over the internet or local network."),
                  AnimatedSize(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: state == ClientType.http
                        ? BlocSelector<
                            SavedSettingsCubit,
                            SettingsData,
                            String
                          >(
                            selector: (settings) => settings.clientData.address,
                            builder: (context, state) {
                              if (state == "") {
                                state = "http://127.0.0.1:5000";
                                settings.setSetting(clientAddress: state);
                              }
                              return TextFormField(
                                decoration: InputDecoration(
                                  hintText: "Server address",
                                ),
                                initialValue: state,
                                onChanged: (value) =>
                                    settings.setSetting(clientAddress: value),
                              );
                            },
                          )
                        : Center(),
                  ),
                ],
              ),
              secondary: Icon(YaruIcons.network),
              value: ClientType.http,
              groupValue: state,
              onChanged: (ClientType? value) {
                if (value == ClientType.http) {
                  settings.setSetting(clientType: ClientType.http);
                }
              },
            ),
            YaruRadioListTile(
              title: Text("Test"),
              subtitle: Text("Load test configuration."),
              secondary: Icon(YaruIcons.code),
              value: ClientType.test,
              groupValue: state,
              onChanged: (ClientType? value) {
                if (value == ClientType.test) {
                  settings.setSetting(clientType: ClientType.test);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
