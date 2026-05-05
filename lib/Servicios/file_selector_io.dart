import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

import 'file_selector.dart';

Future<SelectedFile?> pickImageFileImpl() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  final file = result?.files.first;
  if (file == null || file.bytes == null) return null;

  final mime = lookupMimeType(file.name) ?? 'image/jpeg';
  return SelectedFile(name: file.name, bytes: file.bytes!, mimeType: mime);
}
