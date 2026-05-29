import 'dart:async';

import 'package:flutter/material.dart';

import '../Servicios/llamadas/receptorNativo/servicioLlamadaReceptorNativo.dart';
import '../Servicios/llamadas/receptorNativo/servicioLlamadaReceptorNativoFabrica.dart';
import '../Servicios/llamadas/servicioLlamadas.dart';
import '../modelos/estadoUiLlamada.dart';
import '../modelos/llamadaModelo.dart';
import '../widgets/controlesLlamada.dart';

/// Pantalla solo para el **receptor**: timbre y, tras aceptar, sesion en la misma ruta.
class pantallaLlamadaReceptor extends StatefulWidget {
  const pantallaLlamadaReceptor({super.key, required this.servicio});

  final servicioLlamadas servicio;

  @override
  State<pantallaLlamadaReceptor> createState() =>
      _pantallaLlamadaReceptorState();
}

class _pantallaLlamadaReceptorState extends State<pantallaLlamadaReceptor>
    with SingleTickerProviderStateMixin {
  late final servicioLlamadaReceptorNativo _nativo;
  late final AnimationController _pulso;
  String? _ultimoIdNativo;

  @override
  void initState() {
    super.initState();
    _nativo = crearServicioLlamadaReceptorNativo();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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

  String _tituloInterlocutor(estadoUiLlamada ui) {
    final e = ui.llamadaEntrante;
    if (e != null) {
      return e.nombreEmisor?.trim().isNotEmpty == true
          ? e.nombreEmisor!
          : e.idEmisor;
    }
    final a = ui.llamadaActiva;
    if (a != null) {
      return a.nombreEmisor?.trim().isNotEmpty == true
          ? a.nombreEmisor!
          : a.idEmisor;
    }
    return 'Llamada';
  }

  String _subtitulo(estadoUiLlamada ui) {
    if (!servicioLlamadas.soportaLlamadasVozNativo) {
      return 'Audio no disponible aqui';
    }
    if (ui.textoError != null) return '';
    if (ui.enCanalAgora) {
      return ui.remotoEnCanal ? 'En llamada' : 'Conectando...';
    }
    if (ui.cargandoAccion) return 'Uniendo...';
    if (ui.llamadaEntrante != null) return 'Llamada entrante';
    return '';
  }

  static bool _enSesion(estadoUiLlamada ui) {
    if (ui.enCanalAgora) return true;
    final a = ui.llamadaActiva;
    return a != null && a.estado == EstadoLlamadaFirebase.aceptada;
  }

  @override
  Widget build(BuildContext context) {
    final ui = widget.servicio.estadoUi;
    final scheme = Theme.of(context).colorScheme;
    final titulo = _tituloInterlocutor(ui);
    final inicial = titulo.isNotEmpty
        ? titulo.substring(0, 1).toUpperCase()
        : '?';
    final hablando = ui.indicadorHablaLocal || ui.indicadorHablaRemoto;
    final escala = hablando ? 1.0 + (_pulso.value * 0.08) : 1.0;
    final subtitulo = _subtitulo(ui);
    final entrante = ui.llamadaEntrante;
    final enSesion = _enSesion(ui);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).maybePop();
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFEEF3FB)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            if (!servicioLlamadas.soportaLlamadasVozNativo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Las llamadas de voz solo estan disponibles en Android o iOS.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.blueGrey.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              child: Column(
                children: [
                  Center(
                    child: AnimatedScale(
                      scale: escala,
                      duration: const Duration(milliseconds: 200),
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        child: Text(
                          inicial,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      titulo,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (subtitulo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitulo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _BarraEstadoLlamadaReceptor(ui: ui, hablando: hablando),
            if (ui.textoError != null) ...[
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  ui.textoError!,
                  style: TextStyle(color: scheme.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (entrante != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: ui.cargandoAccion
                            ? null
                            : () => widget.servicio.rechazarLlamadaEntrante(),
                        icon: const Icon(Icons.call_end_outlined),
                        label: const Text('Rechazar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: ui.cargandoAccion
                            ? null
                            : () => widget.servicio.aceptarLlamadaEntrante(),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Aceptar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (enSesion) ...[
              const SizedBox(height: 16),
              panelSesionLlamadaAgora(servicio: widget.servicio),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarraEstadoLlamadaReceptor extends StatelessWidget {
  const _BarraEstadoLlamadaReceptor({required this.ui, required this.hablando});

  final estadoUiLlamada ui;
  final bool hablando;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 12,
      color: scheme.onSurfaceVariant,
    );

    Widget item(IconData icon, String label, bool activo) {
      final c = activo ? scheme.primary : scheme.outline;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: activo
              ? scheme.primary.withValues(alpha: 0.09)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: c),
            const SizedBox(width: 5),
            Text(
              label,
              style: base?.copyWith(
                color: activo ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          item(
            Icons.tune,
            ui.motorRtcListo ? 'Listo' : 'Motor',
            ui.motorRtcListo,
          ),
          item(
            Icons.podcasts_rounded,
            ui.enCanalAgora ? 'Canal' : 'Fuera',
            ui.enCanalAgora,
          ),
          item(
            Icons.person_outline,
            ui.remotoEnCanal ? 'Conectado' : 'Espera',
            ui.remotoEnCanal,
          ),
          item(Icons.mic_none, hablando ? 'Voz' : 'Nada', hablando),
        ],
      ),
    );
  }
}
