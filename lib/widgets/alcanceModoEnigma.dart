import 'package:flutter/material.dart';

import '../Servicios/automatizacion/servicioModoEnigma.dart';

class alcanceModoEnigma extends InheritedNotifier<servicioModoEnigma> {
  const alcanceModoEnigma({
    super.key,
    required servicioModoEnigma servicioModoEnigma,
    required super.child,
  }) : super(notifier: servicioModoEnigma);

  static servicioModoEnigma of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<alcanceModoEnigma>();
    assert(widget != null, 'alcanceModoEnigma no encontrado');
    return widget!.notifier!;
  }

  static servicioModoEnigma? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<alcanceModoEnigma>()?.notifier;
  }
}