import 'package:flutter/foundation.dart';

import '../modelos/llamadaModelo.dart';
import 'servicioLlamadaAndroid.dart';
import 'servicioLlamadaIos.dart';
import 'servicioLlamadaReceptorNativo.dart';

class servicioLlamadaReceptorNativoNulo implements servicioLlamadaReceptorNativo {
  @override
  Future<void> alMostrar(LlamadaModelo _) async {}

  @override
  Future<void> alOcultar() async {}
}

servicioLlamadaReceptorNativo crearServicioLlamadaReceptorNativo() {
  if (kIsWeb) return servicioLlamadaReceptorNativoNulo();
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return servicioLlamadaAndroid();
    case TargetPlatform.iOS:
      return servicioLlamadaIos();
    default:
      return servicioLlamadaReceptorNativoNulo();
  }
}
