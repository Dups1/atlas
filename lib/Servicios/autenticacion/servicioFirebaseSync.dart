import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'autenticacionStorage.dart';
import '../configBackend.dart';
import '../automatizacion/servicioModoEnigma.dart';

/// Sincroniza [FirebaseAuth] con el idToken HTTP (custom token desde el backend).
class servicioFirebaseSync {
  servicioFirebaseSync._();

  static Future<void> cerrarSesionFirebase() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    servicioModoEnigma.desactivarGlobal();
  }

  /// Llama a `POST /auth/custom-token` y hace signInWithCustomToken.
  static Future<void> sincronizarConTokenGuardado() async {
    final storage = autenticacionStorage();
    final idToken = await storage.recuperarToken();
    if (idToken == null) {
      await cerrarSesionFirebase();
      return;
    }
    final uri = Uri.parse('${configBackend.urlBase}/auth/custom-token');
    final r = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );
    if (r.statusCode != 200) {
      throw Exception('custom-token ${r.statusCode}: ${r.body}');
    }
    final map = jsonDecode(r.body) as Map<String, dynamic>;
    final custom = map['customToken'] as String?;
    if (custom == null || custom.isEmpty) {
      throw Exception('Respuesta sin customToken');
    }
    await FirebaseAuth.instance.signInWithCustomToken(custom);
  }
}
