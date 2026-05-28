import '../../../modelos/llamadaModelo.dart';

/// Comportamiento de plataforma asociado a la UI del receptor (timbre / sesion).
abstract class servicioLlamadaReceptorNativo {
  Future<void> alMostrar(llamadaModelo modelo);

  Future<void> alOcultar();
}
