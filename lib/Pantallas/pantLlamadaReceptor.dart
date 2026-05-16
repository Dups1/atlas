import 'dart:async';

import 'package:flutter/material.dart';

import '../Llamadas/servicioLlamadaReceptorNativo.dart';
import '../Llamadas/servicioLlamadaReceptorNativoFabrica.dart';
import '../Servicios/servicioLlamadas.dart';
import '../modelos/estadoUiLlamada.dart';
import '../modelos/llamadaModelo.dart';
import '../widgets/controlesLlamada.dart';

/// Pantalla solo para el **receptor**: timbre y, tras aceptar, sesion en la misma ruta.
class PantallaLlamadaReceptor extends StatefulWidget {
  const PantallaLlamadaReceptor({super.key, required this.servicio});

  final ServicioLlamadas servicio;

  @override
  State<PantallaLlamadaReceptor> createState() => _PantallaLlamadaReceptorState();
}

class _PantallaLlamadaReceptorState extends State<PantallaLlamadaReceptor> with SingleTickerProviderStateMixin {
  late final servicioLlamadaReceptorNativo _nativo;
  late final AnimationController _pulso;
  String? _ultimoIdNativo;

  @override
  void initState() {
    super.initState();
    _nativo = crearServicioLlamadaReceptorNativo();
    _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    widget.servicio.addListener(_repintar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _repintar());
  }

  @override
  void dispose() {
    final ui = widget.servicio.estadoUi;
    if (ui.llamadaEntrante != null && !ui.enCanalAgora) {
      unawaited(widget.servicio.rechazarLlamadaEntrante());
    }
    unawaited(_nativo.alOcultar());
    _pulso.dispose();
    widget.servicio.removeListener(_repintar);
    super.dispose();
  }

  void _repintar() {
    if (!mounted) return;
    final entrante = widget.servicio.estadoUi.llamadaEntrante;
    if (entrante != null && entrante.idLlamada != _ultimoIdNativo) {
      _ultimoIdNativo = entrante.idLlamada;
      unawaited(_nativo.alMostrar(entrante));
    }
    setState(() {});
  }

  String _tituloInterlocutor(EstadoUiLlamada ui) {
    final e = ui.llamadaEntrante;
    if (e != null) return e.nombreEmisor?.trim().isNotEmpty == true ? e.nombreEmisor! : e.idEmisor;
    final a = ui.llamadaActiva;
    if (a != null) {
      return a.nombreEmisor?.trim().isNotEmpty == true ? a.nombreEmisor! : a.idEmisor;
    }
    return 'Llamada';
  }

  String _subtitulo(EstadoUiLlamada ui) {
    if (!ServicioLlamadas.soportaLlamadasVozNativo) return 'Audio no disponible aqui';
    if (ui.textoError != null) return '';
    if (ui.enCanalAgora) return ui.remotoEnCanal ? 'En llamada' : 'Conectando...';
    if (ui.cargandoAccion) return 'Uniendo...';
    if (ui.llamadaEntrante != null) return 'Llamada entrante';
    return '';
  }

  static bool _enSesion(EstadoUiLlamada ui) {
    if (ui.enCanalAgora) return true;
    final a = ui.llamadaActiva;
    return a != null && a.estado == EstadoLlamadaFirebase.aceptada;
  }

  @override
  Widget build(BuildContext context) {
    final ui = widget.servicio.estadoUi;
    final scheme = Theme.of(context).colorScheme;
    final titulo = _tituloInterlocutor(ui);
    final inicial = titulo.isNotEmpty ? titulo.substring(0, 1).toUpperCase() : '?';
    final hablando = ui.indicadorHablaLocal || ui.indicadorHablaRemoto;
    final escala = hablando ? 1.0 + (_pulso.value * 0.08) : 1.0;
    final subtitulo = _subtitulo(ui);
    final entrante = ui.llamadaEntrante;
    final enSesion = _enSesion(ui);
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Llamada entrante'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            if (entrante != null && !ui.enCanalAgora) {
              await widget.servicio.rechazarLlamadaEntrante();
            } else {
              await widget.servicio.finalizarLlamada();
            }
            if (context.mounted) Navigator.of(context, rootNavigator: true).maybePop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (!ServicioLlamadas.soportaLlamadasVozNativo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Las llamadas de voz solo estan disponibles en Android o iOS.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 24),
          Center(
            child: AnimatedScale(
              scale: escala,
              duration: const Duration(milliseconds: 200),
              child: CircleAvatar(
                radius: 64,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(inicial, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              titulo,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          if (subtitulo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitulo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          if (ui.textoError != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                ui.textoError!,
                style: TextStyle(color: scheme.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (entrante != null) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: ui.cargandoAccion ? null : () => widget.servicio.rechazarLlamadaEntrante(),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: ui.cargandoAccion ? null : () => widget.servicio.aceptarLlamadaEntrante(),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (enSesion) ...[
            const SizedBox(height: 24),
            panelSesionLlamadaAgora(servicio: widget.servicio),
          ],
        ],
      ),
    );
  }
}
