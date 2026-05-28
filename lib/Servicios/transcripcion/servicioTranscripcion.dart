import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../autenticacion/autenticacionStorage.dart';
import '../configBackend.dart';

class servicioTranscripcion {
	static const String _nombreArchivo = 'laboratorio_audio.wav';

	final String baseUrl;
	final autenticacionStorage _almacen;

	servicioTranscripcion({String? baseUrl, autenticacionStorage? almacen})
		: baseUrl = baseUrl ?? configBackend.urlBase,
		  _almacen = almacen ?? autenticacionStorage();

	Future<String> transcribirArchivo(String rutaAudio) async {
		final request = http.MultipartRequest(
			'POST',
			Uri.parse('$baseUrl/laboratorio/transcribir'),
		)
			..headers.addAll(await _headersAutenticados());

		request.files.add(await _crearParteArchivoAudio(rutaAudio));

		final streamed = await request.send();
		final response = await http.Response.fromStream(streamed);

		if (response.statusCode < 200 || response.statusCode >= 300) {
			throw Exception(_extraerMensajeError(response.body, response.statusCode));
		}

		final decoded = jsonDecode(response.body) as Map<String, dynamic>;
		final texto = decoded['text']?.toString().trim() ?? '';
		if (texto.isNotEmpty) return texto;

		final segmentos = decoded['segments'];
		if (segmentos is List) {
			final buffer = StringBuffer();
			for (final segmento in segmentos) {
				if (segmento is Map<String, dynamic>) {
					final textoSegmento = segmento['text']?.toString().trim();
					if (textoSegmento != null && textoSegmento.isNotEmpty) {
						if (buffer.isNotEmpty) buffer.write(' ');
						buffer.write(textoSegmento);
					}
				}
			}
			return buffer.toString().trim();
		}

		return '';
	}

	Future<Map<String, String>> _headersAutenticados() async {
		final token = await _almacen.recuperarToken();
		if (token == null || token.isEmpty) {
			throw Exception('Sesion no iniciada');
		}
		return {
			'Authorization': 'Bearer $token',
			'Accept': 'application/json',
		};
	}

	Future<http.MultipartFile> _crearParteArchivoAudio(String rutaAudio) async {
		if (kIsWeb) {
			final respuesta = await http.get(Uri.parse(rutaAudio));
			if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
				throw Exception('No se pudo leer el audio grabado en web.');
			}
			return http.MultipartFile.fromBytes(
				'file',
				respuesta.bodyBytes,
				filename: _nombreArchivo,
				contentType: MediaType('audio', 'wav'),
			);
		}

		return http.MultipartFile.fromPath(
			'file',
			rutaAudio,
			filename: _nombreArchivo,
			contentType: MediaType('audio', 'wav'),
		);
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
					if (mensaje != null && mensaje.isNotEmpty) {
						return 'Backend $statusCode: $mensaje';
					}
				}
			}
		} catch (_) {}
		return 'Backend $statusCode: ${body.trim()}';
	}
}