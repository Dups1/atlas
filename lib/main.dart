import 'package:flutter/material.dart';
import 'Pantallas/pruebas_crud.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PantallaCrud(),
      debugShowCheckedModeBanner: false,
    );
  }
}