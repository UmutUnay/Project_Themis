/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-24 00:38:33
 * @LastEditTime: 2026-03-08 09:04:42
 * @Description: 
 */
import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

import '../../../core/misc/test_item.dart';
import '../../../core/model/settings_data/debug_data.dart';
import '../../../core/model/settings_data/login_data.dart';
import '../../../core/model/settings_data/settings_data.dart';

TestThemisClient getTestClient() => TestThemisClient.saved(
  testBrief,
  testItem,
  testConfigBriefs,
  testConfig,
  [],
);

/// Cubit that applies its settings and persists them to storage.
class SavedSettingsCubit extends HydratedCubit<SettingsData> {
  SavedSettingsCubit() : super(SettingsData.firstTime());

  late final Future<void> initDone;

  @override
  SettingsData fromJson(Map<String, dynamic> json) {
    return SettingsData.fromJson(json);
  }

  @override
  void hydrate({
    Storage? storage,
    OnHydrationError onError = defaultOnHydrationError,
  }) {
    super.hydrate(storage: storage, onError: onError);
    initDone = ThemisClient.trySetInstance(
      ThemisClient.fromData(
        state.clientData,
        state.loginData.authToken,
        getTestClient,
      ),
    );
  }

  @override
  Map<String, dynamic>? toJson(SettingsData state) => state.toJson();

  Future<bool> setSettings({
    ClientData? client,
    LoginData? login,
    DebugData? debug,
  }) async {
    bool result = true;
    if (client != null && client != state.clientData) {
      // First set new client, clearing old login.
      result &= await _setClient(client);
    }
    if (result && login != null && login != state.loginData) {
      // Only if client is successfully set then send the login.
      result &= await _setLogin(login);
    }
    if (result && debug != null && debug != state.debugData) {
      emit(state.copyWith(debugData: debug));
    }
    return result;
  }

  /// Tries to set client instance to [client], if successful saves the client info.
  Future<bool> _setClient(ClientData client) async {
    if (await ThemisClient.trySetInstance(
      ThemisClient.fromData(client, "", getTestClient),
    )) {
      emit(
        state.copyWith(
          clientData: client,
          loginData: state.loginData.copyWith(authToken: null),
        ),
      );
      return true;
    }
    return false;
  }

  /// Tries to set client instance to one with [login], if successful saves the login.
  Future<bool> _setLogin(LoginData login) async {
    if (await ThemisClient.trySetInstance(
      ThemisClient.fromData(state.clientData, login.authToken, getTestClient),
    )) {
      emit(state.copyWith(loginData: login));
      return true;
    }
    return false;
  }
}

/// Holds work in progress settings modifications.
class TempSettingsData extends Equatable {
  /// Temp (work in progress) settings data.
  final SettingsData data;

  /// Saved settings data.
  final SettingsData savedData;

  const TempSettingsData({required this.savedData, required this.data});
  const TempSettingsData.saved(this.savedData) : data = savedData;

  bool get canSaveSettings => data.clientData.validate();
  bool get settingsChanged => data != savedData;

  TempSettingsData copyWith({
    SettingsData? savedData,
    ClientData? clientData,
    LoginData? loginData,
    DebugData? debugData,
  }) => TempSettingsData(
    savedData: savedData ?? this.savedData,
    data:
        savedData ??
        data.copyWith(
          clientData: clientData,
          loginData: loginData,
          debugData: debugData,
        ),
  );

  @override
  List<Object?> get props => [data, savedData];
}

/// Cubit that holds work in progress settings changes before saving
/// to enable the Save and Restore buttons.
class TempSettingsCubit extends Cubit<TempSettingsData> {
  final SavedSettingsCubit savedSettings;
  late final StreamSubscription savedSettingsStream;

  TempSettingsCubit(this.savedSettings)
    : super(TempSettingsData.saved(savedSettings.state)) {
    savedSettingsStream = savedSettings.stream.distinct().listen(
      (savedData) => emit(state.copyWith(savedData: savedData)),
    );
  }

  @override
  Future<void> close() {
    savedSettingsStream.cancel();
    return super.close();
  }

  void setSetting({
    ClientType? clientType,
    String? clientAddress,
    String? loginUsername,
    String? loginAuthToken,
    bool? showTestButton,
  }) {
    final s = state.copyWith(
      clientData: clientType == null && clientAddress == null
          ? null
          : state.data.clientData.copyWith(
              type: clientType,
              address: clientAddress,
            ),
      loginData:
          loginUsername == null && clientType == null && clientAddress == null
          ? null
          : state.data.loginData.copyWith(
              username: loginUsername,
              authToken:
                  loginAuthToken ??
                  (clientType == null && clientAddress == null ? null : ""),
            ),
      debugData: showTestButton == null
          ? null
          : state.data.debugData.copyWith(showTestButton: showTestButton),
    );
    emit(s);
  }

  /// Tries to save and apply the settings, returns success.
  Future<bool> saveSettings() async => savedSettings.setSettings(
    client: state.data.clientData,
    login: state.data.loginData,
    debug: state.data.debugData,
  );

  /// Restores work in progress to saved settings.
  void restoreSettings() => emit(TempSettingsData.saved(savedSettings.state));
}
