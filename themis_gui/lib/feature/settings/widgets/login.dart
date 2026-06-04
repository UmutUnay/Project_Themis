import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';
import 'package:yaru/yaru.dart';

import '../../../core/misc/test_item.dart';
import '../cubit/settings_data.dart';

class AccountLogin extends StatefulWidget {
  const AccountLogin({super.key});

  @override
  State<StatefulWidget> createState() => _AccountLoginState();
}

class _AccountLoginState extends State<StatefulWidget> {
  String password = "";
  bool showError = false;
  late TempSettingsCubit settings = BlocProvider.of<TempSettingsCubit>(
    context,
    listen: false,
  );
  late final StreamSubscription authTokenStream;
  bool noToken = false;
  late final TextEditingController passwordController = TextEditingController(
    text: settings.state.data.loginData.authToken != "" ? "***" : "",
  );

  @override
  void initState() {
    super.initState();
    authTokenStream = settings.stream.distinct().listen((state) {
      final hasToken = state.data.loginData.authToken != "";
      if (hasToken && noToken) {
        passwordController.text = "***";
      } else if (!hasToken && !noToken) {
        passwordController.text = "";
      }
      noToken = !hasToken;
    });
  }

  @override
  void dispose() {
    authTokenStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      margin: EdgeInsets.all(8),
      headline: Text("Account login"),
      width: 500,
      child: Center(
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: .centerLeft,
                child: Text(
                  "Username",
                  style: TextTheme.of(context).labelLarge,
                ),
              ),
              BlocSelector<TempSettingsCubit, TempSettingsData, String>(
                selector: (settings) => settings.data.loginData.username,
                builder: (context, state) => TextFormField(
                  initialValue: state,
                  decoration: InputDecoration(hintText: "Username"),
                  onChanged: (value) =>
                      settings.setSetting(loginUsername: value),
                ),
              ),
              SizedBox(height: 8),
              Align(
                alignment: .centerLeft,
                child: Text(
                  "Password",
                  style: TextTheme.of(context).labelLarge,
                ),
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(hintText: "Password"),
                obscureText: true,
                onChanged: (value) => setState(() => password = value),
              ),
              SizedBox(height: 8),
              Align(
                alignment: .center,
                child:
                    BlocSelector<
                      TempSettingsCubit,
                      TempSettingsData,
                      (bool, bool)
                    >(
                      selector: (settings) => (
                        settings.data.loginData.authToken != "",
                        settings.data.loginData.username != "" &&
                            password != "",
                      ),
                      builder: (context, state) => OutlinedButton(
                        onPressed: state.$1
                            ? () {
                                settings.setSetting(loginAuthToken: "");
                              }
                            : state.$2
                            ? () async {
                                showError = false;
                                final result =
                                    await ThemisClient.fromData(
                                      settings.state.data.clientData,
                                      "",
                                      getTestClient,
                                    ).login(
                                      settings.state.data.loginData.username,
                                      password,
                                    );
                                if (result == "") showError = true;
                                settings.setSetting(loginAuthToken: result);
                                setState(() {});
                              }
                            : null,
                        child: Text(state.$1 ? "Logout" : "Login"),
                      ),
                    ),
              ),
              if (showError)
                Text(
                  "Could not login with given credentials.",
                  style: TextTheme.of(
                    context,
                  ).bodyMedium!.copyWith(color: ColorScheme.of(context).error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
