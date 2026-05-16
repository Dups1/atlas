import 'dart:convert';

import 'package:crypto/crypto.dart';

/// UID Agora uint32 estable: primeros 4 bytes de SHA-256(UTF-8 del UID Firebase), big-endian.
/// Coincide con `uidAgoraDesdeFirebaseUid` en el backend Node.
class UtilidadUidAgora {
  UtilidadUidAgora._();

  static int desdeFirebaseUid(String firebaseUid) {
    final digest = sha256.convert(utf8.encode(firebaseUid));
    final b = digest.bytes;
    var u = (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
    u = u & 0xFFFFFFFF;
    return u == 0 ? 1 : u;
  }
}
