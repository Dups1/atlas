import 'package:flutter/material.dart';

/// Pantalla reservada para integraciones futuras del area Laboratorio.
/// Las llamadas de voz usan `PantallaLlamadaEmisor` / `PantallaLlamadaReceptor` (sin acoplar aqui).
class pantallaLaboratorio extends StatelessWidget {
  const pantallaLaboratorio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratorio'),
        centerTitle: true,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Espacio libre para proximas integraciones.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
