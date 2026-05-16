import 'package:flutter/services.dart';

import '../modelos/llamadaModelo.dart';
import 'servicioLlamadaReceptorNativo.dart';

class servicioLlamadaAndroid implements servicioLlamadaReceptorNativo {
  @override
  Future<void> alMostrar(LlamadaModelo _) async {
    for (var i = 0; i < 2; i++) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  @override
  Future<void> alOcultar() async {}
}
