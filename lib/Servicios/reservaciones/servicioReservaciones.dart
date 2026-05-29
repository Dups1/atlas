import 'dart:convert';

import 'package:http/http.dart' as http;

import '../autenticacion/autenticacionStorage.dart';
import '../configBackend.dart';

class estadosTrabajo {
  static const String pendiente = 'pendiente';
  static const String confirmado = 'confirmado';
  static const String enCurso = 'en_curso';
  static const String completado = 'completado';
  static const String cancelado = 'cancelado';

  static const List<String> values = [
    pendiente,
    confirmado,
    enCurso,
    completado,
    cancelado,
  ];
}

class reservacionRemota {
  final String id;
  final String clienteUid;
  final String trabajadorUid;
  final String clienteNombre;
  final String trabajadorNombre;
  final DateTime? fecha;
  final String direccion;
  final String referencias;
  final String telefono;
  final String detalle;
  final String urgencia;
  final String metodoPago;
  final String estadoTrabajo;
  final bool pagado;
  final DateTime? pagadoEn;

  const reservacionRemota({
    required this.id,
    required this.clienteUid,
    required this.trabajadorUid,
    required this.clienteNombre,
    required this.trabajadorNombre,
    required this.fecha,
    required this.direccion,
    required this.referencias,
    required this.telefono,
    required this.detalle,
    required this.urgencia,
    required this.metodoPago,
    required this.estadoTrabajo,
    required this.pagado,
    required this.pagadoEn,
  });

  factory reservacionRemota.fromJson(Map<String, dynamic> j) {
    DateTime? parseFecha(dynamic v) {
      if (v is String && v.trim().isNotEmpty) {
        return DateTime.tryParse(v.trim());
      }
      return null;
    }

    return reservacionRemota(
      id: (j['id'] ?? '').toString(),
      clienteUid: (j['clienteUid'] ?? '').toString(),
      trabajadorUid: (j['trabajadorUid'] ?? '').toString(),
      clienteNombre: (j['clienteNombre'] ?? 'Cliente').toString(),
      trabajadorNombre: (j['trabajadorNombre'] ?? 'Trabajador').toString(),
      fecha: parseFecha(j['fecha']),
      direccion: (j['direccion'] ?? '').toString(),
      referencias: (j['referencias'] ?? '').toString(),
      telefono: (j['telefono'] ?? '').toString(),
      detalle: (j['detalle'] ?? '').toString(),
      urgencia: (j['urgencia'] ?? 'Normal').toString(),
      metodoPago: (j['metodoPago'] ?? j['pago'] ?? 'Efectivo').toString(),
      estadoTrabajo: (j['estadoTrabajo'] ?? estadosTrabajo.pendiente).toString(),
      pagado: j['pagado'] == true,
      pagadoEn: parseFecha(j['pagadoEn']),
    );
  }
}

/// Crea, lista y actualiza reservaciones entre cliente y trabajador.
class servicioReservaciones {
  final String baseUrl;
  final autenticacionStorage _storage = autenticacionStorage();

  servicioReservaciones({String? baseUrl})
      : baseUrl = baseUrl ?? configBackend.urlBase;

  Future<Map<String, String>> _headersAuth() async {
    final token = await _storage.recuperarToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Sesion no iniciada');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<String> crearReservacion({
    required String trabajadorUid,
    DateTime? fecha,
    required String direccion,
    String referencias = '',
    required String telefono,
    String detalle = '',
    String urgencia = 'Normal',
    String pago = 'Efectivo',
  }) async {
    final headers = await _headersAuth();
    final r = await http.post(
      Uri.parse('$baseUrl/reservaciones'),
      headers: headers,
      body: jsonEncode({
        'trabajadorUid': trabajadorUid,
        if (fecha != null) 'fecha': fecha.toIso8601String(),
        'direccion': direccion,
        'referencias': referencias,
        'telefono': telefono,
        'detalle': detalle,
        'urgencia': urgencia,
        'pago': pago,
      }),
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw Exception('Error ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final id = data['id'] as String?;
    if (id == null || id.trim().isEmpty) {
      throw Exception('Respuesta sin id de reservacion');
    }
    return id;
  }

  Future<List<reservacionRemota>> listarMias({
    required String rol,
    DateTime? mes,
  }) async {
    final headers = await _headersAuth();
    final mesParam = mes == null
        ? null
        : '${mes.year}-${mes.month.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$baseUrl/reservaciones/mias').replace(
      queryParameters: {
        'rol': rol,
        'mes': ?mesParam,
      },
    );
    final r = await http.get(uri, headers: headers);
    if (r.statusCode != 200) {
      throw Exception('Error ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(r.body);
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(reservacionRemota.fromJson)
        .toList();
  }

  Future<reservacionRemota> actualizarEstadoTrabajo({
    required String reservacionId,
    required String estadoTrabajo,
  }) async {
    final headers = await _headersAuth();
    final r = await http.patch(
      Uri.parse('$baseUrl/reservaciones/$reservacionId/estado-trabajo'),
      headers: headers,
      body: jsonEncode({'estadoTrabajo': estadoTrabajo}),
    );
    if (r.statusCode != 200) {
      throw Exception('Error ${r.statusCode}: ${r.body}');
    }
    return reservacionRemota.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<reservacionRemota> confirmarPago({required String reservacionId}) async {
    final headers = await _headersAuth();
    final r = await http.patch(
      Uri.parse('$baseUrl/reservaciones/$reservacionId/confirmar-pago'),
      headers: headers,
      body: jsonEncode(const {}),
    );
    if (r.statusCode != 200) {
      throw Exception('Error ${r.statusCode}: ${r.body}');
    }
    return reservacionRemota.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }
}
