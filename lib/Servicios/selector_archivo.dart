import 'dart:typed_data';

import 'selector_archivo_io.dart'
    if (dart.library.html) 'selector_archivo_web.dart';

class ArchivoSeleccionado {
  final String name;
  final Uint8List bytes;
  final String mimeType;

  ArchivoSeleccionado({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });
}

Future<ArchivoSeleccionado?> pickImageFile() => pickImageFileImpl();
