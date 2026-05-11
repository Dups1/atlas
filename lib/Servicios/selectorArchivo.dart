import 'dart:typed_data';

import 'selectorArchivoIo.dart'
    if (dart.library.html) 'selectorArchivoWeb.dart';

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
