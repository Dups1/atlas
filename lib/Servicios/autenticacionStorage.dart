import 'package:shared_preferences/shared_preferences.dart';

class AutenticacionStorage {
  static const _tokenKey = 'atlas_id_token';

  Future<void> guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> recuperarToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> limpiarToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
