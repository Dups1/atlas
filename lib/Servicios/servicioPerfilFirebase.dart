import 'dart:convert';

import 'package:http/http.dart' as http;

import 'configBackend.dart';

/// Lectura y actualización de documentos de usuario expuestos por el backend Firebase REST.
class ServicioPerfilFirebase {
  Future<Map<String, dynamic>> fetchPerfil() async {
    final response = await http.get(Uri.parse('${ConfigBackend.urlBase}/firebase/usuarios'));
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

  Future<void> actualizarPerfil(String userId, Map<String, dynamic> fields) async {
    final response = await http.patch(
      Uri.parse('${ConfigBackend.urlBase}/firebase/usuarios/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fields),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar perfil (${response.statusCode}): ${response.body}');
    }
  }
}
