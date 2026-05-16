import 'dart:convert';

import 'package:http/http.dart' as http;

import '../configBackend.dart';

class servicioTrabajadores {
  Future<List<Map<String, dynamic>>> fetchTrabajadores() async {
    final response = await http.get(
      Uri.parse('${configBackend.urlBase}/firebase/usuarios?rol=trabajador'),
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
}
