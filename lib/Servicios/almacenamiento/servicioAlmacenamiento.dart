import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../configBackend.dart';

/// Subida de archivos al backend (B2 + metadata segun el servidor).
class servicioAlmacenamiento {
  final String baseUrl;

  servicioAlmacenamiento({String? baseUrl}) : baseUrl = baseUrl ?? configBackend.urlBase;

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
      throw Exception('El backend no retorno una URL valida');
    }
    return url;
  }
}
