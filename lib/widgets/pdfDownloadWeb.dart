import 'dart:html' as html;

import 'package:flutter/material.dart';

class PdfDownload {
  const PdfDownload._();

  static Future<bool> descargar({
    required BuildContext context,
    required List<int> bytes,
    required String filename,
  }) async {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return true;
  }
}