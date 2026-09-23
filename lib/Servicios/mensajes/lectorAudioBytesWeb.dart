import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<Uint8List> leerAudioBytes(String pathOrUri) async {
  final respuesta = await http.get(Uri.parse(pathOrUri));
  if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
    throw Exception('No se pudo leer el audio grabado en web: ${respuesta.statusCode}');
  }
  return respuesta.bodyBytes;
}

