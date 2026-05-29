import 'dart:convert';

import 'package:http/http.dart' as http;

import '../autenticacion/autenticacionStorage.dart';
import '../configBackend.dart';

/// Contexto de calificacion del trabajador para el cliente actual.
class contextoCalificacion {
  final bool puedeCalificar;
  final double? miCalificacion;
  final double promedio;
  final int total;
  final String? mensajeBloqueo;

  const contextoCalificacion({
    required this.puedeCalificar,
    required this.miCalificacion,
    required this.promedio,
    required this.total,
    this.mensajeBloqueo,
  });

  factory contextoCalificacion.fromJson(Map<String, dynamic> j) {
    final mia = j['miCalificacion'];
    return contextoCalificacion(
      puedeCalificar: j['puedeCalificar'] == true,
      miCalificacion: mia == null ? null : (mia as num).toDouble(),
      promedio: (j['promedio'] as num?)?.toDouble() ?? 0,
      total: (j['total'] as num?)?.toInt() ?? 0,
      mensajeBloqueo: (j['mensajeBloqueo'] as String?)?.trim(),
    );
  }
}

/// Calificaciones de trabajadores: solo clientes con trabajo completado y pagado.
class servicioCalificaciones {
  final String baseUrl;
  final autenticacionStorage _storage = autenticacionStorage();

  servicioCalificaciones({String? baseUrl})
    : baseUrl = baseUrl ?? configBackend.urlBase;

  Future<Map<String, String>> _headersAuth() async {
    final token = await _storage.recuperarToken();
    if (token == null) throw Exception('Sesion no iniciada');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<contextoCalificacion> obtenerContexto(String trabajadorUid) async {
    final headers = await _headersAuth();
    final r = await http.get(
      Uri.parse('$baseUrl/calificaciones/$trabajadorUid/contexto'),
      headers: headers,
    );
    if (r.statusCode != 200) {
      throw Exception('Error ${r.statusCode}: ${r.body}');
    }
    return contextoCalificacion.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<contextoCalificacion> calificar({
    required String trabajadorUid,
    required double estrellas,
  }) async {
    final headers = await _headersAuth();
    final r = await http.post(
      Uri.parse('$baseUrl/calificaciones'),
      headers: headers,
      body: jsonEncode({'trabajadorUid': trabajadorUid, 'estrellas': estrellas}),
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('Error ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return contextoCalificacion(
      puedeCalificar: true,
      miCalificacion: (data['miCalificacion'] as num?)?.toDouble(),
      promedio: (data['promedio'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      mensajeBloqueo: null,
    );
  }
}
