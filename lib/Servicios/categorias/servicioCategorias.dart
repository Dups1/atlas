import 'dart:convert';

import 'package:http/http.dart' as http;

import '../configBackend.dart';

class categoria {
  final String id;
  final String nombre;
  final String emoji;
  final List<String> subcategorias;

  const categoria({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.subcategorias,
  });

  factory categoria.fromJson(Map<String, dynamic> json) {
    final rawSub = json['subcategorias'];
    final subcategorias = (rawSub as List<dynamic>?)
            ?.map((value) => value.toString())
            .toList() ??
        [];
    return categoria(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      emoji: json['emoji'] as String? ?? '',
      subcategorias: subcategorias,
    );
  }
}

class servicioCategorias {
  final String baseUrl;

  servicioCategorias({String? baseUrl}) : baseUrl = baseUrl ?? configBackend.urlBase;

  Future<List<categoria>> fetchCategorias() async {
    final response = await http.get(Uri.parse('$baseUrl/firebase/categorias'));
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((raw) => categoria.fromJson(raw as Map<String, dynamic>))
        .toList();
  }
}
