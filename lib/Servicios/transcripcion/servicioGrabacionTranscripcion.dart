import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class servicioGrabacionTranscripcion extends ChangeNotifier {
	static const RecordConfig _configuracionGrabacion = RecordConfig(
		encoder: AudioEncoder.wav,
		sampleRate: 16000,
		numChannels: 1,
	);

	static const String _nombreArchivo = 'laboratorio_audio.wav';

	final AudioRecorder _grabadora = AudioRecorder();

	StreamSubscription<RecordState>? _subEstadoGrabacion;

	bool _grabando = false;
	bool _disposeIniciado = false;
	String? _rutaAudio;
	String? _mensajeEstado = 'Listo para grabar audio WAV';
	String? _mensajeError;

	servicioGrabacionTranscripcion() {
		_subEstadoGrabacion = _grabadora.onStateChanged().listen(_manejarEstadoGrabacion);
	}

	bool get grabando => _grabando;

	bool get tieneAudio => _rutaAudio != null && _rutaAudio!.isNotEmpty;

	String? get rutaAudio => _rutaAudio;

	String? get mensajeError => _mensajeError;

	String get mensajeEstado => _mensajeEstado ?? 'Listo para grabar audio WAV';

	String get formatoAudio => 'WAV · PCM 16-bit · Mono · 16 kHz';

	Future<void> alternarGrabacion() async {
		if (_grabando) {
			await detenerGrabacion();
			return;
		}

		await iniciarGrabacion();
	}

	Future<void> iniciarGrabacion() async {
		if (_grabando) return;

		_limpiarError();

		if (!kIsWeb) {
			final soporteWav = await _grabadora.isEncoderSupported(AudioEncoder.wav);
			if (!soporteWav) {
				_ponerError('Este dispositivo no soporta grabacion WAV.');
				return;
			}

			final permiso = await _grabadora.hasPermission(request: true);
			if (!permiso) {
				_ponerError('Se necesita permiso de microfono para grabar.');
				return;
			}
		} else {
			_mensajeEstado = 'Solicitando permiso de microfono...';
			_emitirCambio();
		}

		try {
			final ruta = await _crearRutaGrabacion();
			await _grabadora.start(_configuracionGrabacion, path: ruta);
			_grabando = true;
			_mensajeEstado = 'Grabando audio en mono';
			_emitirCambio();
		} catch (error) {
			_ponerError('No se pudo iniciar la grabacion: $error');
		}
	}

	Future<void> detenerGrabacion() async {
		if (!_grabando) return;

		try {
			final ruta = await _grabadora.stop();
			if (ruta != null && ruta.isNotEmpty) {
				_rutaAudio = ruta;
				_mensajeEstado = 'Audio guardado y listo para transcribir';
			} else {
				_mensajeEstado = 'Grabacion detenida';
			}
		} catch (error) {
			_ponerError('No se pudo detener la grabacion: $error');
		} finally {
			_grabando = false;
			_emitirCambio();
		}
	}

	Future<String> _crearRutaGrabacion() async {
		if (kIsWeb) {
			return _nombreArchivo;
		}

		final directorio = await getApplicationSupportDirectory();
		await directorio.create(recursive: true);
		return Uri.directory(directorio.path).resolve(_nombreArchivo).toFilePath();
	}

	void _manejarEstadoGrabacion(RecordState estado) {
		switch (estado) {
			case RecordState.record:
				_grabando = true;
				_mensajeEstado = 'Grabando audio en mono';
				break;
			case RecordState.pause:
				_grabando = true;
				_mensajeEstado = 'Grabacion en pausa';
				break;
			case RecordState.stop:
				_grabando = false;
				if (_rutaAudio != null) {
					_mensajeEstado = 'Audio guardado y listo para transcribir';
				}
				break;
		}
		_emitirCambio();
	}

	void _ponerError(String mensaje) {
		_mensajeError = mensaje;
		_mensajeEstado = mensaje;
		_emitirCambio();
	}

	void _limpiarError() {
		if (_mensajeError == null) return;
		_mensajeError = null;
		_emitirCambio();
	}

	void _emitirCambio() {
		if (_disposeIniciado) return;
		notifyListeners();
	}

	Future<void> _cerrarRecursos() async {
		await _subEstadoGrabacion?.cancel();

		if (_grabando) {
			try {
				await _grabadora.cancel();
			} catch (_) {}
		}

		try {
			await _grabadora.dispose();
		} catch (_) {}
	}

	@override
	void dispose() {
		_disposeIniciado = true;
		unawaited(_cerrarRecursos());
		super.dispose();
	}
}