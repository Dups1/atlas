import 'package:flutter/material.dart';

class PantallaLaboratorio extends StatelessWidget {
  const PantallaLaboratorio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratorio'),
        centerTitle: true,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Area de laboratorio lista para nuevas funciones.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
