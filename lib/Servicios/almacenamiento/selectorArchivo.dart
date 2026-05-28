import 'dart:typed_data';

import 'selectorArchivoIo.dart'
    if (dart.library.html) 'selectorArchivoWeb.dart';

class archivoSeleccionado {
  final String name;
  final Uint8List bytes;
  final String mimeType;

  archivoSeleccionado({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });
}

Future<archivoSeleccionado?> pickImageFile() => pickImageFileImpl();
