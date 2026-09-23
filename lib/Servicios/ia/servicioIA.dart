import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../autenticacion/autenticacionStorage.dart';
import '../configBackend.dart';
import 'servicioFuncionesAgente.dart';

class servicioIA {
  servicioIA({String? baseUrl, autenticacionStorage? almacen, String? ruta})
    : baseUrl = baseUrl ?? configBackend.urlBase,
      _almacen = almacen ?? autenticacionStorage(),
      ruta = ruta ?? '/laboratorio/vertex';

  final String baseUrl;
  final String ruta;
  final autenticacionStorage _almacen;
  NavigationCallback? _navigationCallback;

  static const String _instruccionSistemaPorDefecto =
      'Eres el agente de modo enigma de Fixi. Responde en espanol, breve, claro y accionable.';

  void setNavigationCallback(NavigationCallback callback) {
    _navigationCallback = callback;
  }

  Future<String> ejecutarAgente(
    String prompt, {
    String? systemInstruction,
    double temperature = 0.2,
    int maxOutputTokens = 512,
    List<Map<String, String>>? historial,
    int maxContextTokens = 3000,
  }) async {
    final consulta = prompt.trim();
    if (consulta.isEmpty) {
      throw Exception('Escribe un prompt para el agente.');
    }

    debugPrint('[IA] Inicio de solicitud');
    debugPrint('[IA] baseUrl=$baseUrl ruta=$ruta');
    debugPrint('[IA] promptLength=${consulta.length}');
    debugPrint(
      '[IA] systemInstructionLength=${(systemInstruction ?? _instruccionSistemaPorDefecto).trim().length}',
    );
    debugPrint(
      '[IA] temperature=$temperature maxOutputTokens=$maxOutputTokens maxContextTokens=$maxContextTokens',
    );
    debugPrint('[IA] historialLength=${historial?.length ?? 0}');

    final token = await _almacen.recuperarToken();
    if (token == null || token.isEmpty) {
      debugPrint('[IA] No hay token disponible');
      throw Exception('No hay token disponible');
    }
    debugPrint('[IA] tokenLength=${token.length}');

    final uri = Uri.parse('$baseUrl$ruta');
    debugPrint('[IA] POST $uri');
    late final http.Response response;

    try {
      response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'prompt': consulta,
          'systemInstruction':
              (systemInstruction ?? _instruccionSistemaPorDefecto).trim(),
          'temperature': temperature,
          'maxOutputTokens': maxOutputTokens,
          'maxContextTokens': maxContextTokens,
          if (historial != null && historial.isNotEmpty) 'historial': historial,
        }),
      );
      debugPrint('[IA] Respuesta HTTP ${response.statusCode}');
    } catch (e, stackTrace) {
      debugPrint('[IA] Error de conexion: $e');
      debugPrint(stackTrace.toString());
      throw Exception('Error de conexion: $e');
    }

    if (response.statusCode == 404) {
      debugPrint('[IA] 404 recibido en $uri');
      debugPrint(
        '[IA] Body 404: ${response.body.substring(0, response.body.length > 1000 ? 1000 : response.body.length)}',
      );
      throw Exception('Endpoint no encontrado (404)');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[IA] Error HTTP ${response.statusCode}');
      debugPrint(
        '[IA] Body error: ${response.body.substring(0, response.body.length > 1000 ? 1000 : response.body.length)}',
      );
      throw Exception(_extraerMensajeError(response.body, response.statusCode));
    }

    final texto = _extraerTextoRespuesta(response.body);
    if (texto.isEmpty) {
      debugPrint('[IA] Respuesta vacia de Vertex');
      debugPrint(
        '[IA] Body exito: ${response.body.substring(0, response.body.length > 1000 ? 1000 : response.body.length)}',
      );
      throw Exception('Respuesta vacia de Vertex');
    }

    debugPrint('[IA] Texto extraido length=${texto.length}');

    final textoConComandos = await _procesarComandosEnRespuesta(texto);

    return textoConComandos;
  }

  String _extraerTextoRespuesta(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final textoDirecto = decoded['text']?.toString().trim() ?? '';
        if (textoDirecto.isNotEmpty) {
          return textoDirecto;
        }

        final respuesta = decoded['answer']?.toString().trim() ?? '';
        if (respuesta.isNotEmpty) {
          return respuesta;
        }

        final candidates = decoded['candidates'];
        if (candidates is List) {
          final buffer = StringBuffer();
          for (final candidate in candidates) {
            if (candidate is Map<String, dynamic>) {
              final content = candidate['content'];
              if (content is Map<String, dynamic>) {
                final parts = content['parts'];
                if (parts is List) {
                  for (final part in parts) {
                    if (part is Map<String, dynamic>) {
                      final texto = part['text']?.toString().trim();
                      if (texto != null && texto.isNotEmpty) {
                        if (buffer.isNotEmpty) {
                          buffer.write(' ');
                        }
                        buffer.write(texto);
                      }
                    }
                  }
                }
              }
            }
          }

          final combinado = buffer.toString().trim();
          if (combinado.isNotEmpty) {
            return combinado;
          }
        }
      }
    } catch (_) {}

    return body.trim();
  }

  String _extraerMensajeError(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) {
          return 'Backend $statusCode: ${error.trim()}';
        }

        if (error is Map<String, dynamic>) {
          final mensaje = error['message']?.toString();
          if (mensaje != null && mensaje.trim().isNotEmpty) {
            return 'Backend $statusCode: ${mensaje.trim()}';
          }
        }

        final mensaje = decoded['message']?.toString();
        if (mensaje != null && mensaje.trim().isNotEmpty) {
          return 'Backend $statusCode: ${mensaje.trim()}';
        }
      }
    } catch (_) {}

    return 'Backend $statusCode: ${body.trim()}';
  }

  Future<String> _procesarComandosEnRespuesta(String textoRespuesta) async {
    try {
      // Intentar parsear JSON con comandos
      final json = jsonDecode(textoRespuesta) as Map<String, dynamic>;
      final comandos = json['commands'] as List<dynamic>?;
      final textoAgente = json['text'] as String? ?? textoRespuesta;

      // Detectar acciones automáticamente en el texto si no hay comandos explícitos
      final servicioFunciones = servicioFuncionesAgente();
      var listaComandos = comandos?.cast<Map<String, dynamic>>() ?? [];

      if (listaComandos.isEmpty) {
        // Detectar sinónimos y frases naturales que signifiquen acciones
        final accionesDetectadas = servicioFunciones.detectarAccionesEnTexto(
          textoAgente,
        );
        if (accionesDetectadas.isNotEmpty) {
          listaComandos = accionesDetectadas;
        }
      }

      if (listaComandos.isEmpty) {
        return textoAgente;
      }

      // Ejecutar cada comando
      final confirmaciones = <String>[];

      if (_navigationCallback != null) {
        servicioFunciones.setNavigationCallback(
          _navigationCallback as NavigationCallback,
        );
      }

      for (final cmd in listaComandos) {
        final resultado = await servicioFunciones.ejecutarComando(cmd);
        if (resultado['message'] is String) {
          confirmaciones.add(resultado['message'] as String);
        }
      }

      // Combinar respuesta con confirmaciones
      if (confirmaciones.isEmpty) {
        return textoAgente;
      }

      return '$textoAgente\n\n${confirmaciones.join('\n')}';
    } catch (_) {
      // Si no es JSON válido, devolver como está
      return textoRespuesta;
    }
  }
}
