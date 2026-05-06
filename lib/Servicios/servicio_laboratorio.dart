import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'autenticacion_storage.dart';

const _defaultBackendUrl = 'https://backend-atlas-gwxq.onrender.com';

class EntradaLaboratorio {
  final String id;
  final String key;
  final String url;
  final String? originalName;
  final DateTime? createdAt;

  const EntradaLaboratorio({
    required this.id,
    required this.key,
    required this.url,
    this.originalName,
    this.createdAt,
  });

  factory EntradaLaboratorio.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    return EntradaLaboratorio(
      id: json['id'] as String,
      key: json['key'] as String,
      url: json['url'] as String,
      originalName: json['originalName'] as String?,
      createdAt: createdAt,
    );
  }
}

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

class ServicioLaboratorio {
  final String baseUrl;
  final AutenticacionStorage _storage = AutenticacionStorage();

  ServicioLaboratorio({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBackendUrl;

  Future<List<EntradaLaboratorio>> fetchUploads() async {
    final response = await http.get(Uri.parse('$baseUrl/firebase/laboratorio'));

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }

    debugPrint('ServicioLaboratorio: /firebase/laboratorio -> ${response.body}');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((raw) => EntradaLaboratorio.fromJson(raw as Map<String, dynamic>))
        .toList();
  }

  Future<String> uploadFile({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final uri = Uri.parse('$baseUrl/storage/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('El backend no retornó una URL válida');
    }
    return url;
  }

  Future<String> checkBackendStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/status'));
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['status'] as String? ?? 'unknown';
  }

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

  Future<Map<String, dynamic>> obtenerPerfilActivo() async {
    final token = await recuperarToken();
    if (token == null) {
      throw Exception('Sesión no iniciada');
    }
    return fetchPerfil(token);
  }

  Future<void> guardarToken(String token) => _storage.guardarToken(token);

  Future<String?> recuperarToken() => _storage.recuperarToken();

  Future<void> limpiarToken() => _storage.limpiarToken();
}
