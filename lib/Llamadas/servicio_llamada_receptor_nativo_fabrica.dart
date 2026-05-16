import 'package:flutter/foundation.dart';

import '../modelos/llamadaModelo.dart';
import 'servicio_llamada_android.dart';
import 'servicio_llamada_ios.dart';
import 'servicio_llamada_receptor_nativo.dart';

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
