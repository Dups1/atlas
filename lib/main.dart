import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'shared_preferences_web_stub.dart'
    if (dart.library.html) 'package:shared_preferences_web/shared_preferences_web.dart';

import 'Pantallas/pantalla_auth.dart';

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
    return const MaterialApp(
      home: PantallaAuth(),
      debugShowCheckedModeBanner: false,
    );
  }
}