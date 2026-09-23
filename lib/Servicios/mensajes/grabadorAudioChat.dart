import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'lectorAudioBytes.dart';

class ResultadoGrabacionChat {
  final Uint8List bytes;
  final int duracionSegundos;

  ResultadoGrabacionChat({
    required this.bytes,
    required this.duracionSegundos,
  });
}

class GrabadorAudioChat {
  final AudioRecorder _recorder = AudioRecorder();

  static const RecordConfig _configuracion = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 16000,
    numChannels: 1,
  );

  bool _grabando = false;
  DateTime? _inicio;
  Timer? _ticker;
  int _segundos = 0;

  bool get grabando => _grabando;
  int get segundos => _segundos;

  Future<bool> iniciarGrabacion({required void Function(int segundos) onTick}) async {
    if (_grabando) return true;

    final tienePermiso = await _recorder.hasPermission();
    if (!tienePermiso) {
      return false;
    }

    String path;
    if (kIsWeb) {
      path = 'chat_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
    } else {
      final dir = await getApplicationSupportDirectory();
      path = '${dir.path}/chat_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
    }

    try {
      await _recorder.start(_configuracion, path: path);
      _grabando = true;
      _segundos = 0;
      _inicio = DateTime.now();

      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_grabando) {
          timer.cancel();
          return;
        }
        _segundos = DateTime.now().difference(_inicio!).inSeconds;
        onTick(_segundos);
      });
      return true;
    } catch (e) {
      _grabando = false;
      _ticker?.cancel();
      return false;
    }
  }

  Future<ResultadoGrabacionChat?> detenerGrabacion() async {
    if (!_grabando) return null;
    _ticker?.cancel();
    _grabando = false;
    final duracion = _segundos > 0 ? _segundos : 1;

    try {
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) return null;

      final bytes = await obtenerAudioBytes(path);
      return ResultadoGrabacionChat(
        bytes: bytes,
        duracionSegundos: duracion,
      );
    } catch (e) {
      debugPrint('Error deteniendo grabación chat: $e');
      return null;
    }
  }

  Future<void> cancelarGrabacion() async {
    if (!_grabando) return;
    _ticker?.cancel();
    _grabando = false;
    _segundos = 0;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
  }
}

