import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const _defaultBackendUrl = 'https://backend-atlas-gwxq.onrender.com';

class LaboratorioEntry {
  final String id;
  final String key;
  final String url;
  final String? originalName;
  final DateTime? createdAt;

  const LaboratorioEntry({
    required this.id,
    required this.key,
    required this.url,
    this.originalName,
    this.createdAt,
  });

  factory LaboratorioEntry.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    return LaboratorioEntry(
      id: json['id'] as String,
      key: json['key'] as String,
      url: json['url'] as String,
      originalName: json['originalName'] as String?,
      createdAt: createdAt,
    );
  }
}

class LaboratorioService {
  final String baseUrl;

  LaboratorioService({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBackendUrl;

  Future<List<LaboratorioEntry>> fetchUploads() async {
    final response = await http.get(Uri.parse('$baseUrl/firebase/laboratorio'));

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }

    debugPrint('LaboratorioService: /firebase/laboratorio -> ${response.body}');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((raw) => LaboratorioEntry.fromJson(raw as Map<String, dynamic>))
        .toList();
  }

  Future<void> uploadFile({
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
  }

  Future<String> checkBackendStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/status'));
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['status'] as String? ?? 'unknown';
  }
}
