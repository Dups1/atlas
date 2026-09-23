import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Pantallas/pantPortafolioCompartido.dart';

class TextoMensajeConEnlaces extends StatelessWidget {
  final String texto;
  final TextStyle? estiloTexto;
  final Color? colorEnlace;

  const TextoMensajeConEnlaces({
    super.key,
    required this.texto,
    this.estiloTexto,
    this.colorEnlace,
  });

  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+)|(www\.[^\s]+)|([a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?:\/[^\s]*)?)',
    caseSensitive: false,
  );

  static Future<void> abrirUrl(BuildContext context, String url) async {
    var link = url.trim();
    // Limpieza de signos de puntuación al final
    while (link.endsWith('.') || link.endsWith(',') || link.endsWith(')') || link.endsWith(';')) {
      link = link.substring(0, link.length - 1);
    }

    // Detectar si es un enlace de portafolio de Fixi
    final uri = Uri.tryParse(link);
    final portafolioId = uri?.queryParameters['portafolio'] ??
        (uri?.fragment.isNotEmpty == true
            ? Uri.tryParse(uri!.fragment)?.queryParameters['portafolio']
            : null);

    if (portafolioId != null && portafolioId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => pantallaPortafolioCompartido(
            trabajadorId: portafolioId,
          ),
        ),
      );
      return;
    }

    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }

    final targetUri = Uri.tryParse(link);
    if (targetUri != null) {
      try {
        final exito = await launchUrl(
          targetUri,
          mode: LaunchMode.externalApplication,
        );
        if (!exito) {
          await launchUrl(targetUri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo abrir el enlace: $link')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = _urlRegex.allMatches(texto);
    if (matches.isEmpty) {
      return Text(texto, style: estiloTexto);
    }

    final spans = <InlineSpan>[];
    int ultimoIndice = 0;
    String? portafolioDetectado;

    final colorLink = colorEnlace ?? Colors.blueAccent;

    for (final match in matches) {
      // Texto antes del enlace
      if (match.start > ultimoIndice) {
        spans.add(
          TextSpan(
            text: texto.substring(ultimoIndice, match.start),
            style: estiloTexto,
          ),
        );
      }

      final url = match.group(0)!;
      // Verificar si es un portafolio para mostrar tarjeta
      final uri = Uri.tryParse(url);
      final pId = uri?.queryParameters['portafolio'];
      if (pId != null && pId.isNotEmpty) {
        portafolioDetectado = pId;
      }

      spans.add(
        TextSpan(
          text: url,
          style: (estiloTexto ?? const TextStyle()).copyWith(
            color: colorLink,
            decoration: TextDecoration.underline,
            decorationColor: colorLink,
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => abrirUrl(context, url),
        ),
      );

      ultimoIndice = match.end;
    }

    // Texto restante después del último enlace
    if (ultimoIndice < texto.length) {
      spans.add(
        TextSpan(
          text: texto.substring(ultimoIndice),
          style: estiloTexto,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(children: spans),
        ),
        if (portafolioDetectado != null) ...[
          const SizedBox(height: 8),
          _tarjetaPrevisualizacionPortafolio(context, portafolioDetectado),
        ],
      ],
    );
  }

  Widget _tarjetaPrevisualizacionPortafolio(
    BuildContext context,
    String trabajadorId,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => pantallaPortafolioCompartido(
                  trabajadorId: trabajadorId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.business_center_rounded,
                  size: 20,
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Ver Portafolio de Trabajos',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

