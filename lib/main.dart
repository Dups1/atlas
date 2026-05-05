import 'package:flutter/material.dart';

import 'Pantallas/pantalla_explorar.dart';

void main() {
  runApp(const Aplicacion());
}

class Aplicacion extends StatelessWidget {
  const Aplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PantallaExplorar(),
      debugShowCheckedModeBanner: false,
    );
  }
}