import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> leerAudioBytes(String pathOrUri) async {
  final file = File(pathOrUri);
  return await file.readAsBytes();
}

