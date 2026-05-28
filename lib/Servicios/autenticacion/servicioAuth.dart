import 'dart:convert';

import 'package:http/http.dart' as http;

import '../configBackend.dart';

class servicioAuth {
  final String baseUrl;

  servicioAuth({String? baseUrl}) : baseUrl = baseUrl ?? configBackend.urlBase;

  Future<void> register({
    required String email,
    required String password,
    required String rol,
    String? nombre,
    String? categoria,
    String? subcategoria,
    String? descripcion,
  }) async {
    final payload = {
      'email': email,
      'password': password,
      'rol': rol,
    };
    if (nombre != null) payload['nombre'] = nombre;
    if (categoria != null) payload['categoria'] = categoria;
    if (subcategoria != null) payload['subcategoria'] = subcategoria;
    if (descripcion != null && descripcion.isNotEmpty) payload['descripcion'] = descripcion;
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
