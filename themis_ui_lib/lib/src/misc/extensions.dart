import 'dart:convert';

import '../../themis_ui_lib.dart';

extension StringToRegex on String? {
  /// Turns nullable [String] into nullable [RegExp]
  RegExp? toRegex() => this == null ? null : RegExp(this!);
}

extension ThemisItemMap on Map<String, List<ThemisItem>> {
  String encode() => json.encode(
    map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
  );
}
