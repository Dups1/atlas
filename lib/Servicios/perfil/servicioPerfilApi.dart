import 'dart:convert';

import 'package:http/http.dart' as http;

import '../configBackend.dart';

/// Perfil del usuario autenticado vía API principal (`/usuarios/me`).
class servicioPerfilApi {
  final String baseUrl;

  servicioPerfilApi({String? baseUrl})
    : baseUrl = baseUrl ?? configBackend.urlBase;

  Uri _uriPerfilSinCache() {
    return Uri.parse('$baseUrl/usuarios/me').replace(
      queryParameters: {'_t': DateTime.now().microsecondsSinceEpoch.toString()},
    );
  }

  Uri _uriColeccionUsuariosSinCache() {
    return Uri.parse('$baseUrl/firebase/usuarios').replace(
      queryParameters: {'_t': DateTime.now().microsecondsSinceEpoch.toString()},
    );
  }

  Map<String, dynamic>? _decodeClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _uidSesion(Map<String, dynamic>? claims) {
    return (claims?['user_id'] ?? claims?['uid'] ?? claims?['sub'] ?? '')
        .toString()
        .trim();
  }

  String _emailSesion(Map<String, dynamic>? claims) {
    return (claims?['email'] ?? '').toString().trim().toLowerCase();
  }

  bool _coincideSesion(
    Map<String, dynamic> perfil,
    String uidSesion,
    String emailSesion,
  ) {
    final uidPerfil = (perfil['uid'] ?? perfil['id'] ?? '').toString().trim();
    final emailPerfil = (perfil['email'] ?? '').toString().trim().toLowerCase();
    if (uidSesion.isNotEmpty && uidPerfil == uidSesion) return true;
    if (emailSesion.isNotEmpty && emailPerfil == emailSesion) return true;
    return uidSesion.isEmpty && emailSesion.isEmpty;
  }

  Future<Map<String, dynamic>> _fetchPerfilDesdeColeccion(
    String token,
    String uidSesion,
    String emailSesion,
  ) async {
    final response = await http.get(
      _uriColeccionUsuariosSinCache(),
      headers: {
        'Authorization': 'Bearer $token',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic> &&
            _coincideSesion(item, uidSesion, emailSesion)) {
          return item;
        }
        if (item is Map) {
          final casted = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          if (_coincideSesion(casted, uidSesion, emailSesion)) {
            return casted;
          }
        }
      }
      throw Exception('No se encontró perfil para la sesión actual');
    }
    if (data is Map<String, dynamic>) {
      if (_coincideSesion(data, uidSesion, emailSesion)) return data;
      throw Exception('Perfil no coincide con la sesión actual');
    }
    throw Exception('Respuesta inválida de perfil');
  }

  Future<Map<String, dynamic>> fetchPerfil(String idToken) async {
    final claims = _decodeClaims(idToken);
    final uidSesion = _uidSesion(claims);
    final emailSesion = _emailSesion(claims);

    try {
      final response = await http.get(
        _uriPerfilSinCache(),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (_coincideSesion(data, uidSesion, emailSesion)) {
            return data;
          }
        } else if (data is Map) {
          final casted = data.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          if (_coincideSesion(casted, uidSesion, emailSesion)) {
            return casted;
          }
        }
      }
    } catch (_) {}

    return _fetchPerfilDesdeColeccion(idToken, uidSesion, emailSesion);
  }
}
