import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../autenticacion/autenticacionStorage.dart';
import '../configBackend.dart';

class servicioFacturapi {
  servicioFacturapi({http.Client? client, autenticacionStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? autenticacionStorage();

  final http.Client _client;
  final autenticacionStorage _storage;

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse(
      '${configBackend.urlBase}$path',
    ).replace(queryParameters: queryParameters);
  }

  Future<String?> _obtenerToken({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final local = await _tokenLocal();
      if (local != null) return local;
    }

    final firebaseToken = await _tokenFirebase(forceRefresh: forceRefresh);
    if (firebaseToken != null) {
      await _storage.guardarToken(firebaseToken);
      return firebaseToken;
    }

    return _tokenLocal();
  }

  Future<String?> _tokenLocal() async {
    try {
      final token = await _storage.recuperarToken();
      if (token == null) return null;
      final limpio = token.trim();
      if (limpio.isEmpty) return null;
      return limpio;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tokenFirebase({bool forceRefresh = false}) async {
    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) return null;
      final token = await usuario.getIdToken(forceRefresh);
      if (token == null) return null;
      final limpio = token.trim();
      if (limpio.isEmpty) return null;
      return limpio;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _headers({bool forceRefresh = false}) async {
    final token = await _obtenerToken(forceRefresh: forceRefresh);
    if (token == null || token.isEmpty) {
      throw Exception('Sesion no iniciada. Inicia sesion nuevamente.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _conAutenticacion(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _headers();
    var respuesta = await request(headers);
    if (respuesta.statusCode == 401) {
      headers = await _headers(forceRefresh: true);
      respuesta = await request(headers);
    }
    return respuesta;
  }

  Future<http.Response> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return _conAutenticacion(
      (headers) => _client.get(_uri(path, queryParameters), headers: headers),
    );
  }

  Future<http.Response> _post(
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
  }) {
    return _conAutenticacion(
      (headers) => _client.post(
        _uri(path, queryParameters),
        headers: headers,
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> obtenerEstado() async {
    final respuesta = await _get('/facturacion/facturapi/estado');
    return _leerJson(respuesta);
  }

  Future<Map<String, dynamic>> crearFactura(
    Map<String, dynamic> payload,
  ) async {
    final respuesta = await _post(
      '/facturacion/facturapi/facturas',
      body: jsonEncode(payload),
    );
    return _leerJson(respuesta);
  }

  Future<Map<String, dynamic>> crearProducto(
    Map<String, dynamic> payload,
  ) async {
    final respuesta = await _post(
      '/facturacion/facturapi/productos',
      body: jsonEncode(payload),
    );
    return _leerJson(respuesta);
  }

  Future<Map<String, dynamic>> obtenerProducto(String id) async {
    final respuesta = await _get(
      '/facturacion/facturapi/productos/${Uri.encodeComponent(id)}',
    );
    return _leerJson(respuesta);
  }

  Future<Map<String, dynamic>> obtenerFactura(String id) async {
    final respuesta = await _get(
      '/facturacion/facturapi/facturas/${Uri.encodeComponent(id)}',
    );
    return _leerJson(respuesta);
  }

  Future<Map<String, dynamic>> obtenerFacturaPdf(String id) async {
    final respuesta = await _get(
      '/facturacion/facturapi/facturas/${Uri.encodeComponent(id)}/pdf',
    );
    return _leerBinario(respuesta, formato: 'pdf');
  }

  Future<Map<String, dynamic>> obtenerFacturaXml(String id) async {
    final respuesta = await _get(
      '/facturacion/facturapi/facturas/${Uri.encodeComponent(id)}/xml',
    );
    return _leerBinario(respuesta, formato: 'xml');
  }

  Future<Map<String, dynamic>> listarFacturas({
    Map<String, String>? filtros,
  }) async {
    final respuesta = await _get(
      '/facturacion/facturapi/facturas',
      queryParameters: filtros,
    );
    return _leerJson(respuesta);
  }

  bool _esExitosa(http.Response respuesta) {
    return respuesta.statusCode >= 200 && respuesta.statusCode < 300;
  }

  Map<String, dynamic> _leerJson(http.Response respuesta) {
    final body = respuesta.body.trim();
    final ok = _esExitosa(respuesta);
    if (body.isEmpty) {
      if (!ok) {
        throw Exception('Backend ${respuesta.statusCode}: respuesta vacia');
      }
      return {'statusCode': respuesta.statusCode, 'ok': ok};
    }

    if (!_pareceJson(respuesta.headers['content-type'], body)) {
      if (!ok) {
        throw Exception('Backend ${respuesta.statusCode}: $body');
      }
      return {
        'statusCode': respuesta.statusCode,
        'ok': ok,
        'error': 'Respuesta no JSON del backend',
        'body': body,
      };
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      if (!ok) {
        final detalle =
            (decoded['error'] ??
                    decoded['message'] ??
                    decoded['detalle'] ??
                    decoded['raw'] ??
                    body)
                .toString();
        throw Exception('Backend ${respuesta.statusCode}: $detalle');
      }
      return {...decoded, 'statusCode': respuesta.statusCode, 'ok': ok};
    }

    if (!ok) {
      throw Exception('Backend ${respuesta.statusCode}: $decoded');
    }

    return {'data': decoded, 'statusCode': respuesta.statusCode, 'ok': ok};
  }

  bool _pareceJson(String? contentType, String body) {
    final tipo = contentType?.toLowerCase() ?? '';
    if (tipo.contains('application/json') || tipo.contains('+json')) {
      return true;
    }

    return body.startsWith('{') || body.startsWith('[');
  }

  Map<String, dynamic> _leerBinario(
    http.Response respuesta, {
    required String formato,
  }) {
    final ok = _esExitosa(respuesta);
    final contentType =
        respuesta.headers['content-type'] ?? 'application/octet-stream';
    final sizeBytes = respuesta.bodyBytes.length;

    if (sizeBytes == 0) {
      if (!ok) {
        throw Exception(
          'Backend ${respuesta.statusCode}: respuesta vacia para $formato',
        );
      }
      return {
        'statusCode': respuesta.statusCode,
        'ok': ok,
        'formato': formato,
        'contentType': contentType,
        'sizeBytes': 0,
      };
    }

    final mimeType = contentType.toLowerCase();
    final esTexto = mimeType.contains('xml') || mimeType.contains('text/');
    final contenido = esTexto
        ? utf8.decode(respuesta.bodyBytes)
        : base64Encode(respuesta.bodyBytes);

    if (!ok) {
      final detalle = esTexto ? contenido : 'respuesta binaria no valida';
      throw Exception('Backend ${respuesta.statusCode}: $detalle');
    }

    return {
      'statusCode': respuesta.statusCode,
      'ok': ok,
      'formato': formato,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      if (esTexto) 'texto': contenido else 'base64': contenido,
    };
  }
}
