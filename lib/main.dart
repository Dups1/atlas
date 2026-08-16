import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'Servicios/automatizacion/servicioModoEnigma.dart';
import 'Servicios/llamadas/servicioLlamadas.dart';
import 'Servicios/llamadas/agora/manejadorMensajeriaLlamadas.dart'
    show manejadorMensajeriaLlamadasSegundoPlano;
import 'preferencias/stubWebPreferencias.dart'
    if (dart.library.html) 'package:shared_preferences_web/shared_preferences_web.dart';

import 'Pantallas/pantAuth.dart';
import 'widgets/alcanceModoEnigma.dart';
import 'widgets/alcanceServicioLlamadas.dart';
import 'widgets/panelModoEnigma.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    SharedPreferencesPlugin.registerWith(null);
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(manejadorMensajeriaLlamadasSegundoPlano);
  }
  runApp(const aplicacion());
}

class aplicacion extends StatefulWidget {
  const aplicacion({super.key});

  @override
  State<aplicacion> createState() => _aplicacionState();
}

class _aplicacionState extends State<aplicacion> {
  final servicioLlamadas _servicioLlamadas = servicioLlamadas();
  final servicioModoEnigma _servicioModoEnigma = servicioModoEnigma();

  @override
  void initState() {
    super.initState();
    servicioModoEnigma.registrarGlobal(_servicioModoEnigma);
  }

  @override
  void dispose() {
    _servicioLlamadas.dispose();
    _servicioModoEnigma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return alcanceModoEnigma(
      servicioModoEnigma: _servicioModoEnigma,
      child: alcanceServicioLlamadas(
        servicioLlamadas: _servicioLlamadas,
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            bottomAppBarTheme: const BottomAppBarThemeData(
              padding: EdgeInsets.zero,
            ),
          ),
          builder: (context, child) {
            final modoEnigma = alcanceModoEnigma.of(context);
            return Stack(
              fit: StackFit.expand,
              children: [
                child ?? const SizedBox.shrink(),
                if (modoEnigma.activo)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: SafeArea(
                      child: const panelModoEnigma(),
                    ),
                  ),
              ],
            );
          },
          home: const pantallaAuth(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}