import 'dart:ui';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '../Pantallas/pantAjustes.dart';
import '../Pantallas/pantCalendarioTrabajador.dart';
import '../Pantallas/pantLaboratorio.dart';
import '../Pantallas/pantMensajesCliente.dart';
import '../Pantallas/pantPerfilCliente.dart';
import '../Pantallas/pantReservaCliente.dart';
import '../Servicios/ia/servicioIA.dart';
import '../Servicios/transcripcion/servicioGrabacionTranscripcion.dart';
import '../Servicios/transcripcion/servicioTranscripcion.dart';
import '../Servicios/ia/servicioRellenoAgente.dart';
import '../Pantallas/pantChatDetCliente.dart';

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
  String? _ultimaRutaProcesada;
  bool _confirmVisible = false;

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
      debugPrint(
        '[panelModoEnigma] Historial length=${_historialMensajes.length}',
      );

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
    return Container(
      decoration: BoxDecoration(
        color: fondo.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      child: IconButton(
        visualDensity: VisualDensity.compact,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorMicrofono.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: (_transcribiendo || _procesandoIA)
                    ? null
                    : () async {
                        await _accionMicrofono();
                      },
                icon: Icon(
                  _grabacion.grabando ? Icons.mic : Icons.mic_none,
                  color: colorMicrofono,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _grabacion.haySonido ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  _grabacion.amplitude.toStringAsFixed(6),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [],
                  ),
                ),
              ),
            if (_transcribiendo || _procesandoIA)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Switch.adaptive(
                value: _grabacion.microfonoHabilitado,
                onChanged: (_transcribiendo || _procesandoIA)
                    ? null
                    : (val) {
                        _grabacion.alternarMicrofono();
                      },
                activeThumbColor: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _campoTexto(ThemeData theme, Color borde) {
    return TextField(
      controller: _textoController,
      minLines: 3,
      maxLines: 8,
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
        fillColor: theme.colorScheme.surface.withValues(alpha: 0.32),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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
            MaterialPageRoute(
              builder: (context) => const pantallaMensajesCliente(),
            ),
          );
          break;
        case 'perfil':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const perfilClienteView()),
          );
          break;
        case 'calendario':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const pantallaCalendarioTrabajador(),
            ),
          );
          break;
        case 'ajustes':
        case 'settings':
        case 'configuracion':
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const vistaCuenta()));
          break;
        case 'reserva':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const pantallaReservaCliente(),
            ),
          );
          break;
        case 'chatdetalle':
        case 'chat':
          // Intentar abrir chat detalle si el agente prellenó conversationId en servicioRellenoAgente
          try {
            final datos = servicioRellenoAgente().obtenerTodo();
            final conv = datos['conversationId'] as String?;
            final titulo =
                datos['titulo'] as String? ?? datos['nombre'] as String?;
            if (conv != null && conv.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => pantallaChatDetalleCliente(
                    conversationId: conv,
                    tituloAppBar: titulo ?? 'Chat',
                  ),
                ),
              );
              // limpiar relleno para evitar reusar datos accidentalmente
              servicioRellenoAgente().limpiar();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Para abrir chat necesita especificar una conversación',
                  ),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error abriendo chat: $e')));
          }
          break;
        case 'laboratorio':
        case 'lab':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const pantallaLaboratorio(),
            ),
          );
          break;
        default:
          debugPrint('⚠️ Pantalla desconocida: $screenName');
          throw Exception('Pantalla desconocida: $screenName');
      }
    } catch (e) {
      debugPrint('❌ Error navegando a $screenName: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borde = theme.colorScheme.onSurface.withValues(alpha: 0.18);
    final fondo = theme.colorScheme.surface.withValues(alpha: 0.18);
    final accent = theme.colorScheme.primary;

    if (_oculto) {
      return SizedBox(
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: fondo.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borde),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(child: _botonOjo(theme, fondo)),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 338,
      height: 300,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.62),
                    theme.colorScheme.surface.withValues(alpha: 0.42),
                  ],
                ),
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

                  // React to service events: auto-send in modoSimple, show confirm in modo extenso
                  // Schedule side-effects after build to avoid calling async during build
                  if (_grabacion.modoSimple &&
                      _grabacion.rutaAudio != null &&
                      _grabacion.rutaAudio!.isNotEmpty &&
                      _grabacion.rutaAudio != _ultimaRutaProcesada &&
                      !_transcribiendo) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _ultimaRutaProcesada = _grabacion.rutaAudio;
                      _transcribirAudio();
                    });
                  }

                  if (!_grabacion.grabando &&
                      _grabacion.microfonoHabilitado &&
                      !_grabacion.tieneAudio &&
                      !_grabacion.modoSimple &&
                      !_confirmVisible &&
                      !_transcribiendo &&
                      !_procesandoIA) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _confirmVisible = true;
                      });
                    });
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Modo enigma',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          _botonOjo(theme, fondo),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Asistente por voz con navegación inteligente.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ToggleButtons(
                            isSelected: [
                              _grabacion.modoSimple,
                              !_grabacion.modoSimple,
                            ],
                            onPressed: (index) {
                              final modo = index == 0;
                              _grabacion.modoSimple = modo;
                              setState(() {
                                _confirmVisible = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            selectedColor: theme.colorScheme.primary,
                            fillColor: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            color: theme.colorScheme.onSurfaceVariant,
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Text('Comando simple'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Text('Comando extenso'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _botonMicrofono(theme, colorMicrofono),
                      if (_confirmVisible)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  setState(() {
                                    _confirmVisible = false;
                                  });
                                  await _grabacion.detenerGrabacion();
                                  await _transcribirAudio();
                                },
                                icon: const Icon(Icons.send_rounded, size: 16),
                                label: const Text('Enviar orden'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  setState(() {
                                    _confirmVisible = false;
                                  });
                                  await _grabacion.reanudarGrabacion();
                                },
                                icon: const Icon(
                                  Icons.hearing_outlined,
                                  size: 16,
                                ),
                                label: const Text('Continuar escuchando'),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Flexible(child: _campoTexto(theme, borde)),
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
