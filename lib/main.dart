import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'preferencias/stubWebPreferencias.dart'
    if (dart.library.html) 'package:shared_preferences_web/shared_preferences_web.dart';

import 'Pantallas/pantAuth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    SharedPreferencesPlugin.registerWith(null);
  }
  runApp(const Aplicacion());
}

class Aplicacion extends StatelessWidget {
  const Aplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        bottomAppBarTheme: const BottomAppBarThemeData(
          padding: EdgeInsets.zero,
        ),
      ),
      home: const PantallaAuth(),
      debugShowCheckedModeBanner: false,
    );
  }
}