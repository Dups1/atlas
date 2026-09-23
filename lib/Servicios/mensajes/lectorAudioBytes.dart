import 'dart:typed_data';

import 'lectorAudioBytesIo.dart'
    if (dart.library.html) 'lectorAudioBytesWeb.dart'
    if (dart.library.js_interop) 'lectorAudioBytesWeb.dart';

Future<Uint8List> obtenerAudioBytes(String pathOrUri) => leerAudioBytes(pathOrUri);

