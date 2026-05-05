import 'dart:typed_data';

import 'file_selector_io.dart'
    if (dart.library.html) 'file_selector_web.dart';

class SelectedFile {
  final String name;
  final Uint8List bytes;
  final String mimeType;

  SelectedFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });
}

Future<SelectedFile?> pickImageFile() => pickImageFileImpl();
