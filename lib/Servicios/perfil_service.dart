import 'dart:convert';

import 'package:http/http.dart' as http;

class PerfilService {
  final String _baseUrl = 'https://backend-atlas-gwxq.onrender.com';

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await http.get(Uri.parse('$_baseUrl/firebase/usuarios'));
    if (response.statusCode != 200) {
      throw Exception('Error al cargar perfil (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
    } else if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Colección vacía');
  }

  Future<List<Map<String, dynamic>>> fetchTrabajadores() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/firebase/usuarios?rol=trabajador'),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al cargar trabajadores (${response.statusCode})');
    }
    final data = jsonDecode(response.body);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> fields) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/firebase/usuarios/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fields),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar perfil (${response.statusCode}): ${response.body}');
    }
  }
}
