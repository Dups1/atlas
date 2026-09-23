import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../Config/temaFixi.dart';

class BurbujaAudioMensaje extends StatefulWidget {
  final String mediaUrl;
  final int? duracionSegundos;
  final bool esMio;

  const BurbujaAudioMensaje({
    super.key,
    required this.mediaUrl,
    this.duracionSegundos,
    required this.esMio,
  });

  @override
  State<BurbujaAudioMensaje> createState() => _BurbujaAudioMensajeState();
}

class _BurbujaAudioMensajeState extends State<BurbujaAudioMensaje> {
  late final AudioPlayer _player;
  bool _estaCargando = false;
  bool _haCargado = false;
  Duration _duracion = Duration.zero;
  Duration _posicion = Duration.zero;
  bool _isPlaying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    if (widget.duracionSegundos != null && widget.duracionSegundos! > 0) {
      _duracion = Duration(seconds: widget.duracionSegundos!);
    }

    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _posicion = Duration.zero;
          _player.seek(Duration.zero);
          _player.pause();
        }
      });
    });

    _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _posicion = pos);
    });

    _player.durationStream.listen((d) {
      if (!mounted) return;
      if (d != null && d > Duration.zero) {
        setState(() => _duracion = d);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _alternarReproduccion() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    if (!_haCargado) {
      setState(() {
        _estaCargando = true;
        _error = null;
      });
      try {
        await _player.setUrl(widget.mediaUrl);
        _haCargado = true;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _estaCargando = false;
          _error = 'Error cargando audio';
        });
        return;
      } finally {
        if (mounted) setState(() => _estaCargando = false);
      }
    }

    await _player.play();
  }

  String _formatearTiempo(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
    final colorIcono = widget.esMio ? primario : primario;
    final colorSub = TemaFixi.colorSubtitulo(context);

    final duracionTotalMs = _duracion.inMilliseconds > 0 ? _duracion.inMilliseconds.toDouble() : 1.0;
    final posicionMs = _posicion.inMilliseconds.toDouble().clamp(0.0, duracionTotalMs);

    return SizedBox(
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _estaCargando ? null : _alternarReproduccion,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.esMio
                        ? primario.withValues(alpha: 0.18)
                        : TemaFixi.colorSuperficieSecundaria(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primario.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: _estaCargando
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorIcono,
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: colorIcono,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: primario,
                        inactiveTrackColor: primario.withValues(alpha: 0.25),
                        thumbColor: primario,
                      ),
                      child: Slider(
                        value: posicionMs,
                        max: duracionTotalMs,
                        onChanged: (val) {
                          if (_haCargado) {
                            _player.seek(Duration(milliseconds: val.toInt()));
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatearTiempo(_isPlaying ? _posicion : _duracion),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorSub,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic_rounded, size: 12, color: colorSub),
                              const SizedBox(width: 2),
                              Text(
                                'Audio',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: colorSub,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }
}
