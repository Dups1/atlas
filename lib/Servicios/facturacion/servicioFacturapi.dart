import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../configBackend.dart';

class servicioFacturapi {
  servicioFacturapi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('${configBackend.urlBase}$path').replace(
      queryParameters: queryParameters,
    );
  }

  Future<String?> _obtenerToken() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return null;
    return usuario.getIdToken();
  }

  Future<Map<String, String>> _headers() async {
    final token = await _obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> obtenerEstado() async {
    final respuesta = await _client.get(
      _uri('/facturacion/facturapi/estado'),
      headers: await _headers(),
    );
    return _leerJson(respuesta);
  }

  Future<Map<String, dynamic>> crearFactura(Map<String, dynamic> payload) async {
    final respuesta = await _client.post(
      _uri('/facturacion/facturapi/facturas'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _leerJson(respuesta);
  }

  Future<Map<String, dynamic>> crearProducto(Map<String, dynamic> payload) async {
    final respuesta = await _client.post(
      _uri('/facturacion/facturapi/productos'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _leerJson(respuesta);
  }

  Future<Map<String, dynamic>> obtenerProducto(String id) async {
    final respuesta = await _client.get(
      _uri('/facturacion/facturapi/productos/${Uri.encodeComponent(id)}'),
      headers: await _headers(),
    );
    return _leerJson(respuesta);
  }

  Future<Map<String, dynamic>> obtenerFactura(String id) async {
    final respuesta = await _client.get(
      _uri('/facturacion/facturapi/facturas/${Uri.encodeComponent(id)}'),
      headers: await _headers(),
    );
    return _leerJson(respuesta);
  }

  Future<Map<String, dynamic>> obtenerFacturaPdf(String id) async {
    final respuesta = await _client.get(
      _uri('/facturacion/facturapi/facturas/${Uri.encodeComponent(id)}/pdf'),
      headers: await _headers(),
    );
    return _leerBinario(respuesta, formato: 'pdf');
  }

  Future<Map<String, dynamic>> obtenerFacturaXml(String id) async {
    final respuesta = await _client.get(
      _uri('/facturacion/facturapi/facturas/${Uri.encodeComponent(id)}/xml'),
      headers: await _headers(),
    );
    return _leerBinario(respuesta, formato: 'xml');
  }

  Future<Map<String, dynamic>> listarFacturas({Map<String, String>? filtros}) async {
    final respuesta = await _client.get(
      _uri('/facturacion/facturapi/facturas', filtros),
      headers: await _headers(),
    );
    return _leerJson(respuesta);
  }

  Map<String, dynamic> _leerJson(http.Response respuesta) {
    final body = respuesta.body.trim();
    if (body.isEmpty) {
      return {
        'statusCode': respuesta.statusCode,
        'ok': respuesta.statusCode >= 200 && respuesta.statusCode < 300,
      };
    }

    if (!_pareceJson(respuesta.headers['content-type'], body)) {
      return {
        'statusCode': respuesta.statusCode,
        'ok': respuesta.statusCode >= 200 && respuesta.statusCode < 300,
        'error': 'Respuesta no JSON del backend',
        'body': body,
      };
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return {
        ...decoded,
        'statusCode': respuesta.statusCode,
        'ok': respuesta.statusCode >= 200 && respuesta.statusCode < 300,
      };
    }

    return {
      'data': decoded,
      'statusCode': respuesta.statusCode,
      'ok': respuesta.statusCode >= 200 && respuesta.statusCode < 300,
    };
  }

  bool _pareceJson(String? contentType, String body) {
    final tipo = contentType?.toLowerCase() ?? '';
    if (tipo.contains('application/json') || tipo.contains('+json')) {
      return true;
    }

    return body.startsWith('{') || body.startsWith('[');
  }

  Map<String, dynamic> _leerBinario(http.Response respuesta, {required String formato}) {
    final contentType = respuesta.headers['content-type'] ?? 'application/octet-stream';
    final sizeBytes = respuesta.bodyBytes.length;

    if (sizeBytes == 0) {
      return {
        'statusCode': respuesta.statusCode,
        'ok': respuesta.statusCode >= 200 && respuesta.statusCode < 300,
        'formato': formato,
        'contentType': contentType,
        'sizeBytes': 0,
      };
    }

    final mimeType = contentType.toLowerCase();
    final esTexto = mimeType.contains('xml') || mimeType.contains('text/');
    final contenido = esTexto ? utf8.decode(respuesta.bodyBytes) : base64Encode(respuesta.bodyBytes);

    return {
      'statusCode': respuesta.statusCode,
      'ok': respuesta.statusCode >= 200 && respuesta.statusCode < 300,
      'formato': formato,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      if (esTexto) 'texto': contenido else 'base64': contenido,
    };
  }
}
