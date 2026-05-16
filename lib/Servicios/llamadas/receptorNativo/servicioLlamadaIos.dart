import 'package:flutter/services.dart';

import '../../../modelos/llamadaModelo.dart';
import 'servicioLlamadaReceptorNativo.dart';

class servicioLlamadaIos implements servicioLlamadaReceptorNativo {
  @override
  Future<void> alMostrar(llamadaModelo _) async {
    await HapticFeedback.mediumImpact();
  }

  @override
  Future<void> alOcultar() async {}
}
