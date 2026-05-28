import 'dart:ui';

import 'package:flutter/material.dart';

import '../Pantallas/pantAjustes.dart';
import '../Pantallas/pantCalendarioTrabajador.dart';
import '../Pantallas/pantMensajesCliente.dart';
import '../Pantallas/pantPerfilCliente.dart';
import '../Servicios/ia/servicioIA.dart';
import '../Servicios/transcripcion/servicioGrabacionTranscripcion.dart';
import '../Servicios/transcripcion/servicioTranscripcion.dart';

class panelModoEnigma extends StatefulWidget {
  const panelModoEnigma({super.key});

  @override
  State<panelModoEnigma> createState() => _panelModoEnigmaState();
}

class _panelModoEnigmaState extends State<panelModoEnigma> {
  final TextEditingController _textoController = TextEditingController();
  final servicioGrabacionTranscripcion _grabacion =
      servicioGrabacionTranscripcion();
  final servicioTranscripcion _transcripcion = servicioTranscripcion();
  final servicioIA _ia = servicioIA();
  final List<Map<String, String>> _historialMensajes = [];

  bool _oculto = false;
  bool _transcribiendo = false;
  bool _procesandoIA = false;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _ia.setNavigationCallback(_navegarAPantalla);
  }

  @override
  void dispose() {
    _grabacion.dispose();
    _textoController.dispose();
    super.dispose();
  }

  Future<void> _accionMicrofono() async {
    if (_transcribiendo || _procesandoIA) return;

    if (_grabacion.grabando) {
      await _grabacion.detenerGrabacion();
      await _transcribirAudio();
      return;
    }

    setState(() {
      _mensajeError = null;
      _textoController.clear();
    });

    await _grabacion.iniciarGrabacion();
  }

  Future<void> _transcribirAudio() async {
    final rutaAudio = _grabacion.rutaAudio;
    if (rutaAudio == null || rutaAudio.isEmpty) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'Primero graba un audio.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _mensajeError = null;
      _transcribiendo = true;
    });

    try {
      final texto = await _transcripcion.transcribirArchivo(rutaAudio);
      if (!mounted) return;
      debugPrint('[panelModoEnigma] Texto transcrito length=${texto.length}');
      if (texto.trim().isEmpty) {
        setState(() {
          _mensajeError = 'No se detecto texto en el audio.';
          _transcribiendo = false;
        });
        return;
      }
      setState(() {
        _textoController.text = texto;
        _textoController.selection = TextSelection.collapsed(
          offset: texto.length,
        );
        _transcribiendo = false;
      });
      await _consultarIA(texto);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'No se pudo transcribir el audio: $error';
        _transcribiendo = false;
      });
    }

    if (!mounted) {
      _transcribiendo = false;
      return;
    }

    setState(() {
      _transcribiendo = false;
    });
  }

  Future<void> _consultarIA(String textoTranscrito) async {
    final consulta = textoTranscrito.trim();
    if (consulta.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _mensajeError = null;
      _procesandoIA = true;
    });

    try {
      debugPrint('[panelModoEnigma] Consultando IA length=${consulta.length}');
      debugPrint('[panelModoEnigma] Historial length=${_historialMensajes.length}');
      
      final respuesta = await _ia.ejecutarAgente(
        consulta,
        historial: _historialMensajes,
        maxContextTokens: 3000,
      );
      
      if (!mounted) return;
      debugPrint('[panelModoEnigma] Respuesta IA length=${respuesta.length}');
      
      // Agregar mensaje del usuario al historial
      _historialMensajes.add({'role': 'user', 'content': consulta});
      
      // Agregar respuesta de la IA al historial
      _historialMensajes.add({'role': 'assistant', 'content': respuesta});
      
      final resultado = StringBuffer()
        ..writeln('Texto transcrito:')
        ..writeln(consulta)
        ..writeln()
        ..writeln('Respuesta IA:')
        ..writeln(respuesta);
      setState(() {
        _textoController.text = resultado.toString().trim();
        _textoController.selection = TextSelection.collapsed(
          offset: _textoController.text.length,
        );
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('[panelModoEnigma] Error IA: $error');
      setState(() {
        _mensajeError = 'No se pudo consultar la IA: $error';
      });
    } finally {
      if (!mounted) {
        _procesandoIA = false;
        return;
      }
      setState(() {
        _procesandoIA = false;
      });
    }
  }

  Widget _botonOjo(ThemeData theme, Color fondo) {
    return Material(
      color: fondo,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: () {
          setState(() {
            _oculto = !_oculto;
          });
        },
        icon: Icon(
          _oculto ? Icons.visibility : Icons.visibility_off,
          semanticLabel: _oculto ? 'Mostrar overlay' : 'Ocultar overlay',
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _botonMicrofono(ThemeData theme, Color colorMicrofono) {
    return Center(
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.28),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: (_transcribiendo || _procesandoIA)
              ? null
              : _accionMicrofono,
          icon: (_transcribiendo || _procesandoIA)
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.mic,
                  color: colorMicrofono,
                  semanticLabel: _grabacion.grabando
                      ? 'Detener y transcribir'
                      : 'Activar microfono',
                ),
        ),
      ),
    );
  }

  Widget _campoTexto(ThemeData theme, Color borde) {
    return TextField(
      controller: _textoController,
      expands: true,
      maxLines: null,
      minLines: null,
      textAlignVertical: TextAlignVertical.top,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: _transcribiendo
            ? 'Transcribiendo audio...'
            : 'Ventana de texto',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface.withValues(alpha: 0.22),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.8),
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Future<void> _navegarAPantalla(String screenName) async {
    if (!mounted) return;

    try {
      switch (screenName.toLowerCase()) {
        case 'mensajes':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const pantallaMensajesCliente()),
          );
          break;
        case 'perfil':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const perfilClienteView()),
          );
          break;
        case 'calendario':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const pantallaCalendarioTrabajador()),
          );
          break;
        case 'ajustes':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const vistaCuenta()),
          );
          break;
        default:
          throw Exception('Pantalla desconocida: $screenName');
      }
    } catch (e) {
      debugPrint('Error navegando a $screenName: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borde = theme.colorScheme.onSurface.withValues(alpha: 0.18);
    final fondo = theme.colorScheme.surface.withValues(alpha: 0.18);

    if (_oculto) {
      return SizedBox(
        width: 52,
        height: 52,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(child: _botonOjo(theme, fondo)),
          ),
        ),
      );
    }

    return SizedBox(
      width: 320,
      height: 280,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borde),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ListenableBuilder(
                listenable: _grabacion,
                builder: (context, _) {
                  final colorMicrofono = _grabacion.grabando
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary;
                  final mensajeEstado =
                      _mensajeError ??
                      (_procesandoIA
                          ? 'Consultando IA...'
                          : (_transcribiendo
                                ? 'Transcribiendo audio...'
                                : (_grabacion.grabando
                                      ? 'Grabando audio...'
                                      : 'Pulsa el microfono para grabar, transcribir y consultar la IA.')));

                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Modo enigma',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          _botonOjo(theme, fondo),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _botonMicrofono(theme, colorMicrofono),
                      const SizedBox(height: 12),
                      Expanded(child: _campoTexto(theme, borde)),
                      const SizedBox(height: 10),
                      Text(
                        mensajeEstado,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _mensajeError != null
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
