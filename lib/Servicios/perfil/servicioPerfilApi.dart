import 'dart:convert';

import 'package:http/http.dart' as http;

import '../configBackend.dart';

/// Perfil del usuario autenticado vía API principal (`/usuarios/me`).
class servicioPerfilApi {
  final String baseUrl;

  servicioPerfilApi({String? baseUrl}) : baseUrl = baseUrl ?? configBackend.urlBase;

  Future<Map<String, dynamic>> fetchPerfil(String idToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/me'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
