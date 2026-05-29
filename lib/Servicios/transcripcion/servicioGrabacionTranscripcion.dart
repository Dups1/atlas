import 'dart:async';
import 'dart:math';

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
	bool _microfonoHabilitado = false;
	bool _disposeIniciado = false;
	bool _modoSimple = true;
	String? _rutaAudio;
	String? _mensajeEstado = 'Listo para grabar audio WAV';
	String? _mensajeError;


// Amplitude / silence detection
double _ultimaAmplitud = 0.0;
double? _ultimaAmplitudDb;
Timer? _amplitudeTimer;
int _silenceMs = 0;
final int _pollIntervalMs = 100; // más responsivo
final int _silenceAutoStopMs = 3500; // 3.5s es más natural
// Umbral de voz
final double _silenceThreshold = 0.015;
// Evitar micro-cambios por ruido
final double _amplitudeChangeEpsilon = 0.0008;

bool _autoStopping = false;
	servicioGrabacionTranscripcion() {
		_subEstadoGrabacion = _grabadora.onStateChanged().listen(_manejarEstadoGrabacion);
	}

	bool get grabando => _grabando;

	bool get microfonoHabilitado => _microfonoHabilitado;

	bool get tieneAudio => _rutaAudio != null && _rutaAudio!.isNotEmpty;

	String? get rutaAudio => _rutaAudio;

	double get amplitude => _ultimaAmplitud;

	double? get amplitudeDb => _ultimaAmplitudDb;

	bool get haySonido => _ultimaAmplitud > _silenceThreshold;

	String? get mensajeError => _mensajeError;

	String get mensajeEstado => _mensajeEstado ?? 'Listo para grabar audio WAV';

	String get formatoAudio => 'WAV · PCM 16-bit · Mono · 16 kHz';

	bool get modoSimple => _modoSimple;
	set modoSimple(bool valor) {
		if (_modoSimple == valor) return;
		_modoSimple = valor;
		_emitirCambio();
	}

	Future<void> alternarGrabacion() async {
		if (_grabando) {
			await detenerGrabacion();
			return;
		}

		await iniciarGrabacion();
	}

	/// Toggle the microphone enabled state (bound to the UI Switch).
	Future<void> alternarMicrofono() async {
		if (_microfonoHabilitado) {
			await desactivarMicrofono();
		} else {
			await activarMicrofono();
		}
	}

	Future<void> activarMicrofono() async {
		_microfonoHabilitado = true;
		_emitirCambio();
		// Start recording if not already recording
		if (!_grabando) {
			await iniciarGrabacion();
		}
	}

	Future<void> desactivarMicrofono() async {
		_microfonoHabilitado = false;
		// Stop recording if active
		if (_grabando) {
			await detenerGrabacion();
		}
		_emitirCambio();
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

			_iniciarPollingAmplitud();
		} catch (error) {
			_ponerError('No se pudo iniciar la grabacion: $error');
		}
	}

	Future<void> detenerGrabacion() async {
		if (!_grabando) return;

		_cancelarPollingAmplitud();

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
			_autoStopping = false;
			_silenceMs = 0;
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
				_grabando = false;
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

	// --- Amplitude polling & auto-stop ---

	void _iniciarPollingAmplitud() {
		if (_amplitudeTimer != null) return;
		_silenceMs = 0;
		_autoStopping = false;

		_amplitudeTimer = Timer.periodic(Duration(milliseconds: _pollIntervalMs), (_) async {
			await _chequearAmplitud();
		});
	}

	Future<void> _chequearAmplitud() async {
		// If recording state changed, bail early
		if (_autoStopping) return;

		try {
			final dynamic a = await _grabadora.getAmplitude();
			double nivel = 0.0;

			// Some platforms return an Amplitude object, others may vary. Use dynamic access.
			try {
				if (a == null) {
					nivel = 0.0;
				} else if (a is num) {
					nivel = (a as num).toDouble();
				} else {
					// Prefer 'current' then 'max' then parse fallback
					final dynamic current = a.current;
					final dynamic max = a.max;
					if (current is num) {
						nivel = (current as num).toDouble();
					} else if (max is num) {
						nivel = (max as num).toDouble();
					} else {
						final s = a.toString();
						nivel = double.tryParse(s) ?? 0.0;
					}
				}
			} catch (_) {
				nivel = 0.0;
			}

            

			// Detect if amplitude is in dB (negative values like -50..-80) and convert
			double linear = 0.0;
			if (nivel < -1.0) {
				// Treat as decibels
				_ultimaAmplitudDb = nivel;
				// Convert dBFS to linear (0..1): linear = 10^(dB/20)
				linear = pow(10.0, nivel / 20.0).toDouble();
			} else {
				_ultimaAmplitudDb = null;
				linear = nivel;
			}

			// Debug logging to help diagnose why amplitude may not be detected
			if (kDebugMode) {
				if (_ultimaAmplitudDb != null) {
					debugPrint('[servicioGrabacion] ampDb=${_ultimaAmplitudDb!.toStringAsFixed(2)}dB linear=${linear.toStringAsFixed(6)} grabando=$_grabando microfonoHabilitado=$_microfonoHabilitado modoSimple=$_modoSimple');
				} else {
					debugPrint('[servicioGrabacion] linear=${linear.toStringAsFixed(6)} grabando=$_grabando microfonoHabilitado=$_microfonoHabilitado modoSimple=$_modoSimple');
				}
			}

			// Use linear value to decide silence / sound
			final prevHaySonido = _ultimaAmplitud > _silenceThreshold;
			final newHaySonido = linear > _silenceThreshold;
			final changedEnough = (linear - _ultimaAmplitud).abs() > _amplitudeChangeEpsilon;

			_ultimaAmplitud = linear; // always update latest (linear scale)
			if (changedEnough || prevHaySonido != newHaySonido) {
				_emitirCambio();
			}

			if (linear <= _silenceThreshold) {
				_silenceMs += _pollIntervalMs;
				// If silence persists, either stop (modoSimple) or pause (modo extenso)
				if (_silenceMs >= _silenceAutoStopMs && !_autoStopping) {
					_autoStopping = true;
					_mensajeEstado = _modoSimple ? 'Silencio detectado — grabacion detenida' : 'Silencio detectado — en pausa';
					_emitirCambio();
					try {
						if (_modoSimple) {
							await detenerGrabacion();
						} else {
							await _grabadora.pause();
							_grabando = false;
						}
					} catch (_) {
						// If pause/stop isn't supported, leave recording state as-is
					}
				}
			} else {
				// Detected sound: if currently paused and microphone is enabled, resume
				_silenceMs = 0;
				if (!_grabando && _microfonoHabilitado) {
					try {
						await _grabadora.resume();
						_grabando = true;
						_mensajeEstado = 'Grabando audio en mono';
						_emitirCambio();
					} catch (_) {
						// If resume not supported, start a new recording session
						try {
							final ruta = await _crearRutaGrabacion();
							await _grabadora.start(_configuracionGrabacion, path: ruta);
							_grabando = true;
							_mensajeEstado = 'Grabando audio en mono';
							_emitirCambio();
						} catch (_) {}
					}
				}
			}
		} catch (_) {
			// Ignore transient polling errors
		}
	}

	Future<void> reanudarGrabacion() async {
		if (_grabando) return;

		_limpiarError();

		// Try to resume if supported
		try {
			await _grabadora.resume();
			_grabando = true;
			_mensajeEstado = 'Grabando audio en mono';
			_emitirCambio();
			return;
		} catch (_) {}

		// Fallback: start a new recording if the microphone is enabled
		if (!_microfonoHabilitado) {
			_ponerError('No se puede reanudar la grabacion: microfono no habilitado.');
			return;
		}

		try {
			final ruta = await _crearRutaGrabacion();
			await _grabadora.start(_configuracionGrabacion, path: ruta);
			_grabando = true;
			_mensajeEstado = 'Grabando audio en mono';
			_emitirCambio();
			_iniciarPollingAmplitud();
		} catch (error) {
			_ponerError('No se pudo reanudar la grabacion: $error');
		}
	}

	void _cancelarPollingAmplitud() {
		try {
			_amplitudeTimer?.cancel();
		} catch (_) {}
		_amplitudeTimer = null;
		_silenceMs = 0;
		_autoStopping = false;
	}

	Future<void> _cerrarRecursos() async {
		await _subEstadoGrabacion?.cancel();

		_cancelarPollingAmplitud();

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