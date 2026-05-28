import 'package:flutter/material.dart';

class servicioModoEnigma extends ChangeNotifier {
  static servicioModoEnigma? _instanciaGlobal;

  static void registrarGlobal(servicioModoEnigma instancia) {
    _instanciaGlobal = instancia;
  }

  static void desactivarGlobal() {
    _instanciaGlobal?.desactivar();
  }

  bool _activo = false;

  bool get activo => _activo;

  void alternar() {
    _activo = !_activo;
    notifyListeners();
  }

  void activar() {
    if (_activo) return;
    _activo = true;
    notifyListeners();
  }

  void desactivar() {
    if (!_activo) return;
    _activo = false;
    notifyListeners();
  }
}