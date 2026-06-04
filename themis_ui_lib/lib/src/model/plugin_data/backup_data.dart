import 'dart:convert';

import 'package:equatable/equatable.dart';

class BackupData extends Equatable {
  final String id;
  final String path;
  const BackupData({required this.id, required this.path});

  BackupData.fromJson(Map<String, dynamic> jmap)
    : id = jmap['backup_id'],
      path = jmap['path'];

  Map<String, dynamic> toJson() => {'backup_id': id, 'path': path};

  @override
  List<Object?> get props => [id, path];
}
