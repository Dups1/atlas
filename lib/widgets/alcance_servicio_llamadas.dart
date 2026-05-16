import 'package:flutter/material.dart';

import '../Servicios/llamadas/servicioLlamadas.dart';

/// Expone un unico [servicioLlamadas] para toda la app.
class alcanceServicioLlamadas extends InheritedNotifier<servicioLlamadas> {
  const alcanceServicioLlamadas({
    super.key,
    required servicioLlamadas servicioLlamadas,
    required super.child,
  }) : super(notifier: servicioLlamadas);

  static servicioLlamadas of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<alcanceServicioLlamadas>();
    assert(w != null, 'alcanceServicioLlamadas no encontrado');
    return w!.notifier!;
  }

  static servicioLlamadas? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<alcanceServicioLlamadas>()?.notifier;
  }
}
