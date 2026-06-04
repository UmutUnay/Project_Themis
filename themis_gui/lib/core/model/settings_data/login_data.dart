import 'package:equatable/equatable.dart';

/// Holds data about a Themis client configuration.
class LoginData extends Equatable {
  final String username;

  final String authToken;

  const LoginData({required this.username, required this.authToken});

  const LoginData.firstTime() : username = "", authToken = "";

  LoginData.fromJson(Map<String, dynamic> json)
    : username = json['username'],
      authToken = json['authToken'];

  Map<String, dynamic> toJson() => {
    'username': username,
    'authToken': authToken,
  };

  LoginData copyWith({String? username, String? authToken}) => LoginData(
    username: username ?? this.username,
    authToken: authToken ?? this.authToken,
  );

  @override
  List<Object?> get props => [username, authToken];
}
