import 'package:equatable/equatable.dart';

/// Holds data about development / debug options.
class DebugData extends Equatable {
  final bool showTestButton;

  const DebugData({required this.showTestButton});

  const DebugData.firstTime() : showTestButton = false;

  DebugData.fromJson(Map<String, dynamic> json)
    : showTestButton = json['showTestButton'];

  Map<String, dynamic> toJson() => {'showTestButton': showTestButton};

  DebugData copyWith({bool? showTestButton}) =>
      DebugData(showTestButton: showTestButton ?? this.showTestButton);

  @override
  List<Object?> get props => [showTestButton];
}
