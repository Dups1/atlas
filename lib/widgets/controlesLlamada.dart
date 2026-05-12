import 'package:flutter/material.dart';

import '../Servicios/servicioLaboratorio.dart';

/// Botones de llamada (mute, altavoz, colgar, aceptar/rechazar) separados de la pantalla principal.
class ControlesLlamada extends StatelessWidget {
  final ServicioLaboratorio servicio;
  final VoidCallback onIniciarLlamada;
  final TextEditingController controladorIdReceptor;

  const ControlesLlamada({
    super.key,
    required this.servicio,
    required this.onIniciarLlamada,
    required this.controladorIdReceptor,
  });

  @override
  Widget build(BuildContext context) {
    final ui = servicio.estadoUi;
    final entrante = ui.llamadaEntrante;
    final activa = ui.llamadaActiva;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controladorIdReceptor,
              decoration: const InputDecoration(
                labelText: 'UID Firebase del receptor',
                border: OutlineInputBorder(),
              ),
              enabled: !ui.cargandoAccion && !ui.enCanalAgora,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: ui.cargandoAccion || !ServicioLaboratorio.soportaLlamadasVozNativo
                  ? null
                  : onIniciarLlamada,
              icon: ui.cargandoAccion
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.call),
              label: const Text('Iniciar llamada'),
            ),
            if (entrante != null) ...[
              const SizedBox(height: 16),
              Text(
                'Entrante: ${entrante.nombreEmisor ?? entrante.idEmisor}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: ui.cargandoAccion ? null : servicio.rechazarLlamadaEntrante,
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: ui.cargandoAccion ? null : servicio.aceptarLlamadaEntrante,
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
            if (activa != null && activa.estado != null) ...[
              const SizedBox(height: 8),
              Text('Estado Firestore: ${activa.estado!.claveFirestore}'),
            ],
            if (ui.enCanalAgora) ...[
              const SizedBox(height: 16),
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
