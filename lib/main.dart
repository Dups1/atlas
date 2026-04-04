import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Pantallas/pruebas_crud.dart';

void main() {
  runApp(const MyApp());
import 'firebase_options.dart';
import 'pantallas/text_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PantallaCrud(),
      debugShowCheckedModeBanner: false,
    return const MaterialApp(
      home: TextScreen(),
    );
  }
}