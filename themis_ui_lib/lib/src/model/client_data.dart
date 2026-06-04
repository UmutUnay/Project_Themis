import 'package:equatable/equatable.dart';

/// Types of Themis clients
enum ClientType {
  http("http"),
  test("test"),
  none("none");

  const ClientType(this.name);
  factory ClientType.named(String name) => switch (name) {
    "http" => http,
    "test" => test,
    "none" => none,
    _ => none,
  };

  final String name;
}

/// Holds data about a Themis client configuration.
class ClientData extends Equatable {
  /// Type of the client.
  final ClientType type;

  /// Address of the server. (Only important for http client)
  final String address;

  const ClientData(this.type, [this.address = ""]);

  const ClientData.firstTime() : type = ClientType.none, address = "";

  ClientData.fromJson(Map<String, dynamic> json)
    : type = ClientType.named(json['type']),
      address = json['address'];

  Map<String, dynamic> toJson() => {'type': type.name, 'address': address};

  ClientData copyWith({ClientType? type, String? address}) =>
      ClientData(type ?? this.type, address ?? this.address);

  bool validate() => type != ClientType.http || address != "";

  @override
  List<Object?> get props => [address, type];
}
