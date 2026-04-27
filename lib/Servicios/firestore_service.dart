import 'dart:convert';
import 'package:http/http.dart' as http;

class FirestoreService {
  final String _baseUrl = 'https://backend-atlas-gwxq.onrender.com';

  Future<String> injectExamples() async {
    final samples = [
      {
        'nombre': 'Atlas Cliente',
        'categoria': 'app',
        'activo': true,
        'caracteristicas': ['rastreo', 'alertas', 'analisis'],
        'meta': {'version': '0.1', 'region': 'global'},
      },
      {
        'nombre': 'Modulo Energia',
        'categoria': 'iot',
        'activo': false,
        'caracteristicas': ['sensores', 'reportes'],
        'meta': {'version': '0.9', 'region': 'costa', 'prioridad': 'alta'},
      },
      {
        'nombre': 'Equipo Atlas',
        'categoria': 'infra',
        'activo': true,
        'caracteristicas': ['deploy', 'monitoreo'],
        'meta': {'version': '1.2', 'region': 'alta'},
      },
    ];

    final res = await http.post(
      Uri.parse('$_baseUrl/firebase/atlas_samples/batch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'docs': samples}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return 'Documentos guardados: ${data['insertados']}';
    } else {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }
}
