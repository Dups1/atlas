import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Config/temaFixi.dart';

class BurbujaUbicacionMensaje extends StatelessWidget {
  final double latitud;
  final double longitud;
  final String? texto;
  final bool esMio;

  const BurbujaUbicacionMensaje({
    super.key,
    required this.latitud,
    required this.longitud,
    this.texto,
    required this.esMio,
  });

  Future<void> _abrirMapa(BuildContext context) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitud,$longitud',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el mapa: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primario.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: primario.withValues(alpha: 0.25),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: primario.withValues(alpha: 0.2),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.shade700,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ubicación actual',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TemaFixi.colorTextoPrincipal(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coordenadas: ${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}',
            style: TextStyle(
              fontSize: 11.5,
              color: TemaFixi.colorSubtitulo(context),
            ),
          ),
          if (texto != null && texto!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              texto!,
              style: TextStyle(
                fontSize: 13,
                color: TemaFixi.colorTextoPrincipal(context),
              ),
            ),
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _abrirMapa(context),
              icon: const Icon(Icons.directions_outlined, size: 16),
              label: const Text(
                'Abrir en Google Maps',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

