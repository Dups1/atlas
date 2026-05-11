import 'dart:convert';

import 'package:http/http.dart' as http;

import 'configBackend.dart';

class Categoria {
  final String id;
  final String nombre;
  final String emoji;
  final List<String> subcategorias;

  const Categoria({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.subcategorias,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    final rawSub = json['subcategorias'];
    final subcategorias = (rawSub as List<dynamic>?)
            ?.map((value) => value.toString())
            .toList() ??
        [];
    return Categoria(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      emoji: json['emoji'] as String? ?? '',
      subcategorias: subcategorias,
    );
  }
}

class ServicioCategorias {
  final String baseUrl;

  ServicioCategorias({String? baseUrl}) : baseUrl = baseUrl ?? ConfigBackend.urlBase;

  Future<List<Categoria>> fetchCategorias() async {
    final response = await http.get(Uri.parse('$baseUrl/firebase/categorias'));
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((raw) => Categoria.fromJson(raw as Map<String, dynamic>))
        .toList();
  }
}
