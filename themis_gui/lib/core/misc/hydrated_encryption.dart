import 'dart:convert';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

Future<HydratedAesCipher> getHydratedStorageCypher() async {
  final storage = FlutterSecureStorage();
  final hasKey = await storage.containsKey(key: 'hydratedBlocKey');
  if (!hasKey) {
    final sec = Random.secure();
    var key = "";
    for (var i = 0; i < 16; i++) {
      key += sec.nextInt(1 << 16).toString();
    }
    final hash = sha256.convert(utf8.encode(key)).toString();
    await storage.write(key: 'hydratedBlocKey', value: hash);
  }
  final hash = await storage.read(key: 'hydratedBlocKey');
  return HydratedAesCipher(hex.decode(hash!));
}
