import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'Servicios/servicioLlamadas.dart';
import 'Servicios/agora/manejadorMensajeriaLlamadas.dart'
    show manejadorMensajeriaLlamadasSegundoPlano;
import 'preferencias/stubWebPreferencias.dart'
    if (dart.library.html) 'package:shared_preferences_web/shared_preferences_web.dart';

import 'Pantallas/pantAuth.dart';
import 'widgets/alcanceServicioLlamadas.dart';

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

class Aplicacion extends StatefulWidget {
  const Aplicacion({super.key});

  @override
  State<Aplicacion> createState() => _AplicacionState();
}

class _AplicacionState extends State<Aplicacion> {
  final ServicioLlamadas _servicioLlamadas = ServicioLlamadas();

  @override
  void dispose() {
    _servicioLlamadas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return alcanceServicioLlamadas(
      servicioLlamadas: _servicioLlamadas,
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          bottomAppBarTheme: const BottomAppBarThemeData(
            padding: EdgeInsets.zero,
          ),
        ),
        home: const PantallaAuth(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}