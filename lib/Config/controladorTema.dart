import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controlador singleton para la gestión reactiva y persistente del tema en Fixi.
class ControladorTema extends ChangeNotifier {
  ControladorTema._();

  static final ControladorTema instancia = ControladorTema._();

  static const String _prefKey = 'preferencia_tema';

  ThemeMode _modo = ThemeMode.system;

  /// Modo de tema actualmente seleccionado.
  ThemeMode get modo => _modo;

  /// Retorna true si el modo actual es oscuro, o si es sistema y la plataforma es oscura.
  bool esOscuro(BuildContext context) {
    if (_modo == ThemeMode.dark) return true;
    if (_modo == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  /// Carga la preferencia guardada en almacenamiento local al arrancar la app.
  Future<void> cargarPreferencia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_prefKey);
      if (guardado == 'oscuro') {
        _modo = ThemeMode.dark;
      } else if (guardado == 'claro') {
        _modo = ThemeMode.light;
      } else {
        _modo = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {
      _modo = ThemeMode.system;
    }
  }

  /// Cambia el modo de tema y lo persiste en SharedPreferences.
  Future<void> cambiarModo(ThemeMode nuevoModo) async {
    if (_modo == nuevoModo) return;
    _modo = nuevoModo;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String valor;
      switch (nuevoModo) {
        case ThemeMode.dark:
          valor = 'oscuro';
          break;
        case ThemeMode.light:
          valor = 'claro';
          break;
        case ThemeMode.system:
          valor = 'sistema';
          break;
      }
      await prefs.setString(_prefKey, valor);
    } catch (_) {}
  }
}
