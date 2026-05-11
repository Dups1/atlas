// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:typed_data';

import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import 'selectorArchivo.dart';

Future<ArchivoSeleccionado?> pickImageFileImpl() {
  final completer = Completer<ArchivoSeleccionado?>();

  final input = html.FileUploadInputElement();
  input.accept = 'image/*';
  input.multiple = false;
  input.style.display = 'none';
  html.document.body?.append(input);
  input.click();

  void dispose() {
    html.document.body?.children.remove(input);
    input.remove();
  }

  input.onChange.listen((_) {
    debugPrint('file_selector_web: change event');
    final file = input.files?.first;
    if (file == null) {
      dispose();
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onLoad.first.then((_) {
      debugPrint('file_selector_web: file read');
      final result = reader.result;
      final data = result is ByteBuffer ? Uint8List.view(result) : (result as Uint8List);
      final mime = file.type.isNotEmpty ? file.type : 'image/jpeg';
      dispose();
      completer.complete(ArchivoSeleccionado(name: file.name, bytes: data, mimeType: mime));
    });
    reader.readAsArrayBuffer(file);
  });

  return completer.future;
}
