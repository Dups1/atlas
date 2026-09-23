import 'package:flutter/material.dart';

import '../Config/temaFixi.dart';

class BurbujaImagenMensaje extends StatelessWidget {
  final String mediaUrl;
  final String? texto;
  final bool esMio;

  const BurbujaImagenMensaje({
    super.key,
    required this.mediaUrl,
    this.texto,
    required this.esMio,
  });

  void _verImagenCompleta(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton.filledTonal(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _verImagenCompleta(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 240,
                maxHeight: 280,
              ),
              child: Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    color: TemaFixi.colorSuperficieSecundaria(context),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 120,
                    color: TemaFixi.colorSuperficieSecundaria(context),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
                          const SizedBox(height: 4),
                          Text(
                            'Error al cargar imagen',
                            style: TextStyle(
                              fontSize: 11,
                              color: TemaFixi.colorSubtitulo(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (texto != null && texto!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            texto!,
            style: TextStyle(
              fontSize: 13.5,
              color: TemaFixi.colorTextoPrincipal(context),
            ),
          ),
        ],
      ],
    );
  }
}

