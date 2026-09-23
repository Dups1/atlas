import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'Servicios/automatizacion/servicioModoEnigma.dart';
import 'preferencias/stubWebPreferencias.dart'
    if (dart.library.html) 'package:shared_preferences_web/shared_preferences_web.dart';

import 'Pantallas/pantAuth.dart';
import 'Pantallas/pantPortafolioCompartido.dart';
import 'widgets/alcanceModoEnigma.dart';
import 'widgets/panelModoEnigma.dart';
import 'Config/controladorTema.dart';
import 'Config/temaFixi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    SharedPreferencesPlugin.registerWith(null);
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ControladorTema.instancia.cargarPreferencia();
  runApp(const aplicacion());
}

class aplicacion extends StatefulWidget {
  const aplicacion({super.key});

  @override
  State<aplicacion> createState() => _aplicacionState();
}

class _aplicacionState extends State<aplicacion> {
  final servicioModoEnigma _servicioModoEnigma = servicioModoEnigma();

  @override
  void initState() {
    super.initState();
    servicioModoEnigma.registrarGlobal(_servicioModoEnigma);
  }

  @override
  void dispose() {
    _servicioModoEnigma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return alcanceModoEnigma(
      servicioModoEnigma: _servicioModoEnigma,
      child: ListenableBuilder(
        listenable: ControladorTema.instancia,
        builder: (context, _) {
          return MaterialApp(
            theme: TemaFixi.temaClaro,
            darkTheme: TemaFixi.temaOscuro,
            themeMode: ControladorTema.instancia.modo,
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
            home: _determinarPantallaInicial(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  Widget _determinarPantallaInicial() {
    final portafolioId = _extraerPortafolioId();
    if (portafolioId.isNotEmpty) {
      return pantallaPortafolioCompartido(trabajadorId: portafolioId);
    }
    return const pantallaAuth();
  }

  String _extraerPortafolioId() {
    // 1. Query parameters directos (?portafolio=UID)
    final direct = Uri.base.queryParameters['portafolio'] ??
        Uri.base.queryParameters['trabajador'] ??
        Uri.base.queryParameters['p'];
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    // 2. Fragment / Hash route (#/?portafolio=UID o #/portafolio?id=UID)
    if (Uri.base.fragment.isNotEmpty) {
      try {
        final frag = Uri.base.fragment.startsWith('/')
            ? Uri.base.fragment
            : '/${Uri.base.fragment}';
        final uri = Uri.parse(frag);
        final fromFrag = uri.queryParameters['portafolio'] ??
            uri.queryParameters['trabajador'] ??
            uri.queryParameters['id'] ??
            uri.queryParameters['p'];
        if (fromFrag != null && fromFrag.trim().isNotEmpty) {
          return fromFrag.trim();
        }
      } catch (_) {}
    }

    return '';
  }
}
