import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://backend-atlas-gwxq.onrender.com";

  Future<List<dynamic>> getDatos() async {
    final res = await http.get(Uri.parse('$baseUrl/datos'));
    return jsonDecode(res.body);
  }

  Future<void> crearDato(String nombre) async {
    await http.post(
      Uri.parse('$baseUrl/datos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre}),
    );
  }

  Future<void> actualizarDato(int id, String nombre) async {
    await http.put(
      Uri.parse('$baseUrl/datos/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre}),
    );
  }

  Future<void> eliminarDato(int id) async {
    await http.delete(Uri.parse('$baseUrl/datos/$id'));
  }
}