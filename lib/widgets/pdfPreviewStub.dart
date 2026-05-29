import 'dart:typed_data';

import 'package:flutter/material.dart';

class PdfPreview extends StatelessWidget {
  const PdfPreview({super.key, required this.bytes, required this.title});

  final Uint8List bytes;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        'La vista previa PDF solo está disponible en web.\n$title',
        textAlign: TextAlign.center,
      ),
    );
  }
}