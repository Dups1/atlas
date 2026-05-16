import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../autenticacion/autenticacionStorage.dart';
import '../../configBackend.dart';

/// Cliente HTTP para rutas `/llamadas/*` del backend (senalizacion y tokens RTC).
class clienteHttpLlamadas {
  clienteHttpLlamadas({autenticacionStorage? almacen})
      : _almacen = almacen ?? autenticacionStorage();

  final autenticacionStorage _almacen;

  Future<String> _bearer() async {
    final t = await _almacen.recuperarToken();
    if (t == null) throw Exception('Sin sesion HTTP');
    return t;
  }

  Future<Map<String, dynamic>> obtenerTokenRtc(String canal) async {
    final idToken = await _bearer();
    final r = await http.post(
      Uri.parse('${configBackend.urlBase}/llamadas/agora-token'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'canal': canal}),
    );
    if (r.statusCode != 200) {
      throw Exception('Token ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> postSinJson(String subruta, Map<String, dynamic> cuerpo) async {
    final idToken = await _bearer();
    final r = await http.post(
      Uri.parse('${configBackend.urlBase}/llamadas/$subruta'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(cuerpo),
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('llamadas/$subruta ${r.statusCode}: ${r.body}');
    }
  }

  Future<Map<String, dynamic>> postJson(String subruta, Map<String, dynamic> cuerpo) async {
    final idToken = await _bearer();
    final r = await http.post(
      Uri.parse('${configBackend.urlBase}/llamadas/$subruta'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(cuerpo),
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('llamadas/$subruta ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> iniciarLlamada(Map<String, dynamic> cuerpo) async {
    final idToken = await _bearer();
    final r = await http.post(
      Uri.parse('${configBackend.urlBase}/llamadas/iniciar'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(cuerpo),
    );
    if (r.statusCode == 409) {
      throw Exception(jsonDecode(r.body)['error'] ?? 'Ocupado');
    }
    if (r.statusCode != 201) {
      throw Exception('iniciar ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
