import 'package:equatable/equatable.dart';
import 'package:themis_ui_lib/themis_ui_lib.dart';

import 'debug_data.dart';
import 'login_data.dart';

/// Stores all settings of the GUI.
class SettingsData extends Equatable {
  /// Client (connection) data.
  final ClientData clientData;

  /// Login (account) data.
  final LoginData loginData;

  /// Debug / development data.
  final DebugData debugData;

  const SettingsData({
    required this.clientData,
    required this.loginData,
    required this.debugData,
  });

  const SettingsData.firstTime()
    : clientData = const ClientData.firstTime(),
      loginData = const LoginData.firstTime(),
      debugData = const DebugData.firstTime();

  SettingsData.fromJson(Map<String, dynamic> json)
    : clientData = json['clientData'] == null
          ? ClientData.firstTime()
          : ClientData.fromJson(json['clientData']),
      loginData = json['loginData'] == null
          ? LoginData.firstTime()
          : LoginData.fromJson(json['loginData']),
      debugData = json['debugData'] == null
          ? DebugData.firstTime()
          : DebugData.fromJson(json['debugData']);

  Map<String, dynamic> toJson() => {
    'clientData': clientData.toJson(),
    'loginData': loginData.toJson(),
    'debugData': debugData.toJson(),
  };

  SettingsData copyWith({
    ClientData? clientData,
    LoginData? loginData,
    DebugData? debugData,
  }) => SettingsData(
    clientData: clientData ?? this.clientData,
    loginData: loginData ?? this.loginData,
    debugData: debugData ?? this.debugData,
  );

  @override
  List<Object?> get props => [clientData, loginData, debugData];
}
