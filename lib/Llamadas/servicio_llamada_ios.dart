import 'package:flutter/services.dart';

import '../modelos/llamadaModelo.dart';
import 'servicio_llamada_receptor_nativo.dart';

class servicioLlamadaIos implements servicioLlamadaReceptorNativo {
  @override
  Future<void> alMostrar(LlamadaModelo _) async {
    await HapticFeedback.mediumImpact();
  }

  @override
  Future<void> alOcultar() async {}
}
