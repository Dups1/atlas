import 'package:flutter/material.dart';

import '../Servicios/servicioLlamadas.dart';

/// Expone un unico [ServicioLlamadas] para toda la app.
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
}
