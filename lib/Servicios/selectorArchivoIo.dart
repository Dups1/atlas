import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

import 'selectorArchivo.dart';

Future<ArchivoSeleccionado?> pickImageFileImpl() async {
  final result = await FilePicker.pickFiles(
    type: FileType.image,
    withData: true,
  );
  final file = result?.files.first;
  if (file == null || file.bytes == null) return null;

  final mime = lookupMimeType(file.name) ?? 'image/jpeg';
  return ArchivoSeleccionado(name: file.name, bytes: file.bytes!, mimeType: mime);
}
