import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'Servicios/servicioLaboratorio.dart' show manejadorMensajeriaLlamadasSegundoPlano;
import 'preferencias/stubWebPreferencias.dart'
    if (dart.library.html) 'package:shared_preferences_web/shared_preferences_web.dart';

import 'Pantallas/pantAuth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    SharedPreferencesPlugin.registerWith(null);
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(manejadorMensajeriaLlamadasSegundoPlano);
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