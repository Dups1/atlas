import 'package:flutter/material.dart';

import '../Pantallas/pantLlamadaReceptor.dart';
import '../Servicios/servicioLlamadas.dart';
import '../modelos/estadoUiLlamada.dart';
import '../modelos/llamadaModelo.dart';
import 'alcanceServicioLlamadas.dart';

/// Abre [PantallaLlamadaReceptor] cuando hay [EstadoUiLlamada.llamadaEntrante] y cierra si la llamada se cancela sin sesion.
class escuchaLlamadasEntrantes extends StatefulWidget {
  const escuchaLlamadasEntrantes({super.key, required this.child});

  final Widget child;

  @override
  State<escuchaLlamadasEntrantes> createState() => _escuchaLlamadasEntrantesState();
}

class _escuchaLlamadasEntrantesState extends State<escuchaLlamadasEntrantes> {
  bool _rutaReceptorAbierta = false;
  bool _cerrandoPorListener = false;

  void _sincronizar(BuildContext context, ServicioLlamadas servicio) {
    if (!context.mounted) return;
    final ui = servicio.estadoUi;
    final entrante = ui.llamadaEntrante;

    if (entrante != null) {
      if (!_rutaReceptorAbierta) {
        _rutaReceptorAbierta = true;
        Navigator.of(context, rootNavigator: true)
            .push<void>(
          PageRouteBuilder<void>(
            fullscreenDialog: true,
            opaque: true,
            settings: const RouteSettings(name: 'pantallaLlamadaReceptor'),
            pageBuilder: (ctx, animation, secondaryAnimation) {
              return PantallaLlamadaReceptor(servicio: servicio);
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        )
            .then((_) {
          if (mounted) setState(() => _rutaReceptorAbierta = false);
        });
      }
      return;
    }

    final enSesion = _enSesionActiva(ui);
    if (!enSesion && _rutaReceptorAbierta && !_cerrandoPorListener) {
      _cerrandoPorListener = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          _cerrandoPorListener = false;
          return;
        }
        Navigator.of(context, rootNavigator: true).maybePop();
        _cerrandoPorListener = false;
      });
    }
  }

  static bool _enSesionActiva(EstadoUiLlamada ui) {
    if (ui.enCanalAgora) return true;
    final a = ui.llamadaActiva;
    if (a == null) return false;
    return a.estado == EstadoLlamadaFirebase.aceptada;
  }

  @override
  Widget build(BuildContext context) {
    final servicio = alcanceServicioLlamadas.of(context);
    return ListenableBuilder(
      listenable: servicio,
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) _sincronizar(context, servicio);
        });
        return widget.child;
      },
    );
  }
}
