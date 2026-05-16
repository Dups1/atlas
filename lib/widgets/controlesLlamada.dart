import 'package:flutter/material.dart';

import '../modelos/llamadaModelo.dart';
import '../Servicios/llamadas/servicioLlamadas.dart';

/// Panel de estado Firestore + controles Agora (mute, altavoz, colgar). Compartido emisor / receptor en sesion.
class panelSesionLlamadaAgora extends StatelessWidget {
  const panelSesionLlamadaAgora({super.key, required this.servicio});

  final servicioLlamadas servicio;

  static llamadaModelo? _modeloParaEstadoFirestore(llamadaModelo? activa) {
    final m = activa;
    if (m == null || m.estado == null) return null;
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final ui = servicio.estadoUi;
    final activa = ui.llamadaActiva;
    final modeloEstado = _modeloParaEstadoFirestore(activa);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (modeloEstado != null) indicadorEstadoFirestore(modelo: modeloEstado),
            if (ui.enCanalAgora) ...[
              if (modeloEstado != null) const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    tooltip: ui.microSilenciado ? 'Activar micro' : 'Silenciar',
                    onPressed: servicio.alternarSilencioMicrofono,
                    icon: Icon(ui.microSilenciado ? Icons.mic_off : Icons.mic),
                  ),
                  IconButton.filledTonal(
                    tooltip: ui.altavozActivo ? 'Auricular' : 'Altavoz',
                    onPressed: servicio.alternarAltavoz,
                    icon: Icon(ui.altavozActivo ? Icons.volume_up : Icons.hearing),
                  ),
                  IconButton.filled(
                    tooltip: 'Colgar',
                    style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                    onPressed: ui.cargandoAccion ? null : servicio.finalizarLlamada,
                    icon: Icon(Icons.call_end, color: Theme.of(context).colorScheme.onError),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Llamada saliente: UID, iniciar, estado y sesion. La entrante va en [PantallaLlamadaReceptor].
class controlesLlamada extends StatelessWidget {
  final servicioLlamadas servicio;
  final VoidCallback onIniciarLlamada;
  final TextEditingController controladorIdReceptor;
  final bool ocultarCampoIdReceptor;

  const controlesLlamada({
    super.key,
    required this.servicio,
    required this.onIniciarLlamada,
    required this.controladorIdReceptor,
    this.ocultarCampoIdReceptor = false,
  });

  static llamadaModelo? _modeloParaEstadoFirestore(llamadaModelo? activa) {
    final m = activa;
    if (m == null || m.estado == null) return null;
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final ui = servicio.estadoUi;
    final activa = ui.llamadaActiva;
    final modeloEstado = _modeloParaEstadoFirestore(activa);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!ocultarCampoIdReceptor) ...[
              TextField(
                controller: controladorIdReceptor,
                decoration: const InputDecoration(
                  labelText: 'UID del contacto (solo pruebas)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                enabled: !ui.cargandoAccion && !ui.enCanalAgora,
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: ui.cargandoAccion || !servicioLlamadas.soportaLlamadasVozNativo
                  ? null
                  : onIniciarLlamada,
              icon: ui.cargandoAccion
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.call),
              label: Text(ocultarCampoIdReceptor ? 'Llamar' : 'Iniciar llamada'),
            ),
            if (modeloEstado != null || ui.enCanalAgora) ...[
              const SizedBox(height: 12),
              panelSesionLlamadaAgora(servicio: servicio),
            ],
          ],
        ),
      ),
    );
  }
}

class indicadorEstadoFirestore extends StatelessWidget {
  const indicadorEstadoFirestore({super.key, required this.modelo});

  final llamadaModelo modelo;

  static bool estadoActivo(EstadoLlamadaFirebase e) {
    return e == EstadoLlamadaFirebase.timbrando || e == EstadoLlamadaFirebase.aceptada;
  }

  @override
  Widget build(BuildContext context) {
    final e = modelo.estado;
    if (e == null) return const SizedBox.shrink();

    final ok = estadoActivo(e);
    final color = ok ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.error;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 6, spreadRadius: 0),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          e.claveFirestore,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
