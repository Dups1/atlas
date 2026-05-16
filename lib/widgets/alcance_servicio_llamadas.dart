import 'package:flutter/material.dart';

import '../Servicios/servicioLlamadas.dart';

/// Expone un unico [ServicioLlamadas] bajo el arbol post-login (cliente / trabajador).
class alcanceServicioLlamadas extends InheritedNotifier<ServicioLlamadas> {
  const alcanceServicioLlamadas({
    super.key,
    required ServicioLlamadas servicioLlamadas,
    required super.child,
  }) : super(notifier: servicioLlamadas);

  static ServicioLlamadas of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<alcanceServicioLlamadas>();
    assert(w != null, 'alcanceServicioLlamadas no encontrado');
    return w!.notifier!;
  }

  static ServicioLlamadas? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<alcanceServicioLlamadas>()?.notifier;
  }

  /// Rutas nuevas del [Navigator] no heredan ancestros de la ruta de debajo.
  /// Usa el contexto del widget que hace el push (donde suele existir el alcance).
  static Widget envolverChatSiHayServicio(BuildContext contextOrigenPush, Widget pantallaChat) {
    final s = maybeOf(contextOrigenPush);
    if (s == null) return pantallaChat;
    return alcanceServicioLlamadas(servicioLlamadas: s, child: pantallaChat);
  }
}
