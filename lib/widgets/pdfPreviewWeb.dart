import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class PdfPreview extends StatefulWidget {
  const PdfPreview({super.key, required this.bytes, required this.title});

  final Uint8List bytes;
  final String title;

  @override
  State<PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<PdfPreview> {
  static int _contador = 0;

  late final String _viewType;
  String? _objectUrl;

  @override
  void initState() {
    super.initState();
    _viewType = 'pdf-preview-${_contador++}';
    final jsArray = widget.bytes.toJS;
    final blob = web.Blob([jsArray].toJS, web.BlobPropertyBag(type: 'application/pdf'));
    _objectUrl = web.URL.createObjectURL(blob);
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement
        ..src = _objectUrl ?? ''
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
  }

  @override
  void dispose() {
    final url = _objectUrl;
    if (url != null) {
      web.URL.revokeObjectURL(url);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: HtmlElementView(viewType: _viewType),
          ),
        ),
      ],
    );
  }
}
