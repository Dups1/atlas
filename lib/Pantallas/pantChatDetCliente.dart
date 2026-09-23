import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../Config/temaFixi.dart';
import '../Servicios/almacenamiento/selectorArchivo.dart';
import '../Servicios/almacenamiento/servicioAlmacenamiento.dart';
import '../Servicios/autenticacion/autenticacionStorage.dart';
import '../Servicios/ia/servicioRellenoAgente.dart';
import '../Servicios/mensajes/grabadorAudioChat.dart';
import '../Servicios/mensajes/servicioMensajes.dart';
import '../Servicios/perfil/servicioPerfilApi.dart';
import '../widgets/avatarUsuarioFixi.dart';
import '../widgets/burbujaAudioMensaje.dart';
import '../widgets/burbujaImagenMensaje.dart';
import '../widgets/burbujaUbicacionMensaje.dart';
import '../widgets/textoMensajeConEnlaces.dart';

class pantallaChatDetalleCliente extends StatefulWidget {
  final String conversationId;
  final String tituloAppBar;
  final String? otroUid;
  final String? fotoUrl;

  const pantallaChatDetalleCliente({
    super.key,
    required this.conversationId,
    required this.tituloAppBar,
    this.otroUid,
    this.fotoUrl,
  });

  @override
  State<pantallaChatDetalleCliente> createState() =>
      _pantallaChatDetalleClienteState();
}

class _pantallaChatDetalleClienteState
    extends State<pantallaChatDetalleCliente> {
  final servicioMensajes _mensajes = servicioMensajes();
  final autenticacionStorage _storage = autenticacionStorage();
  final servicioPerfilApi _perfilApi = servicioPerfilApi();
  final servicioRellenoAgente _relleno = servicioRellenoAgente();
  final servicioAlmacenamiento _almacenamiento = servicioAlmacenamiento();
  final GrabadorAudioChat _grabadorAudio = GrabadorAudioChat();
  final TextEditingController _inputController = TextEditingController();

  String? _miUid;
  String? _error;
  bool _enviando = false;
  bool _grabandoAudio = false;
  int _segundosGrabacion = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _cargarMensajePreRellenado();
    _inputController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _cargarMensajePreRellenado() {
    if (_relleno.contiene('mensaje')) {
      _inputController.text = _relleno.obtenerConFallback<String>(
        'mensaje',
        '',
      );
    }
    _relleno.limpiar();
  }

  @override
  void dispose() {
    _grabadorAudio.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _error = null);
    try {
      final token = await _storage.recuperarToken();
      if (token == null) throw Exception('Sesion no iniciada');
      final perfil = await _perfilApi.fetchPerfil(token);
      final uid = perfil['id'] as String? ?? perfil['uid'] as String?;
      if (uid == null || uid.isEmpty) throw Exception('UID no disponible');
      setState(() {
        _miUid = uid;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      await _mensajes.enviarMensaje(widget.conversationId, text);
      _inputController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _iniciarGrabacionVoz() async {
    final ok = await _grabadorAudio.iniciarGrabacion(
      onTick: (segundos) {
        if (mounted) setState(() => _segundosGrabacion = segundos);
      },
    );
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo acceder al micrófono')),
        );
      }
      return;
    }
    setState(() {
      _grabandoAudio = true;
      _segundosGrabacion = 0;
    });
  }

  Future<void> _detenerYEnviarAudio() async {
    setState(() {
      _enviando = true;
      _grabandoAudio = false;
    });
    try {
      final res = await _grabadorAudio.detenerGrabacion();
      if (res != null && res.bytes.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final url = await _almacenamiento.uploadFile(
          bytes: res.bytes,
          filename: 'audio_$timestamp.wav',
          contentType: 'audio/wav',
        );
        await _mensajes.enviarMensajeEspecial(
          conversationId: widget.conversationId,
          tipo: 'audio',
          mediaUrl: url,
          duracionSegundos: res.duracionSegundos,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar audio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
          _segundosGrabacion = 0;
        });
      }
    }
  }

  Future<void> _cancelarGrabacionVoz() async {
    await _grabadorAudio.cancelarGrabacion();
    setState(() {
      _grabandoAudio = false;
      _segundosGrabacion = 0;
    });
  }

  Future<void> _compartirMultimedia() async {
    final archivo = await pickImageFile();
    if (archivo == null) return;

    setState(() => _enviando = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = await _almacenamiento.uploadFile(
        bytes: archivo.bytes,
        filename: 'chat_${timestamp}_${archivo.name}',
        contentType: archivo.mimeType,
      );
      await _mensajes.enviarMensajeEspecial(
        conversationId: widget.conversationId,
        tipo: 'imagen',
        mediaUrl: url,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _compartirUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor activa la localización GPS')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El permiso de ubicación está denegado en el sistema'),
          ),
        );
      }
      return;
    }

    setState(() => _enviando = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _mensajes.enviarMensajeEspecial(
        conversationId: widget.conversationId,
        tipo: 'ubicacion',
        latitud: pos.latitude,
        longitud: pos.longitude,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _abrirMenuAdjuntos() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TemaFixi.colorFondo(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TemaFixi.colorBorde(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.image_outlined, color: Colors.blue),
                  ),
                  title: Text(
                    'Foto o Multimedia',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: TemaFixi.colorTextoPrincipal(context),
                    ),
                  ),
                  subtitle: Text(
                    'Comparte una imagen desde tu dispositivo',
                    style: TextStyle(
                      color: TemaFixi.colorSubtitulo(context),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _compartirMultimedia();
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_outlined, color: Colors.green),
                  ),
                  title: Text(
                    'Ubicación en tiempo real',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: TemaFixi.colorTextoPrincipal(context),
                    ),
                  ),
                  subtitle: Text(
                    'Envía tus coordenadas GPS actuales',
                    style: TextStyle(
                      color: TemaFixi.colorSubtitulo(context),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _compartirUbicacion();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaFixi.colorFondo(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: TemaFixi.colorBarraSuperior(context),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarUsuarioFixi(
              uid: widget.otroUid ??
                  servicioMensajes.otroUidDesdeConversationId(
                    widget.conversationId,
                    _miUid ?? '',
                  ),
              urlFoto: widget.fotoUrl,
              nombre: widget.tituloAppBar,
              radio: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.tituloAppBar),
                  Text(
                    'Trabajador',
                    style: TextStyle(
                      color: TemaFixi.colorSubtitulo(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            onPressed: () {},
            icon: const Icon(Icons.work_outline, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: TemaFixi.gradienteFondo(context),
          ),
        ),
        child: Column(
          children: [
            _quickReplies(),
            Expanded(child: _cuerpoLista()),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: DecoratedBox(
                  decoration: TemaFixi.decoracionTarjeta(context, radio: 18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
                    child: _grabandoAudio
                        ? _barraGrabacionAudio(context)
                        : _barraEntradaTexto(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cuerpoLista() {
    if (_error != null && _miUid == null) {
      return _estadoVisual(
        icon: Icons.wifi_off_rounded,
        titulo: 'No se pudo abrir el chat',
        subtitulo: _error!,
        trailing: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton.icon(
            onPressed: _bootstrap,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
      );
    }
    if (_miUid == null) {
      return _estadoVisual(
        icon: Icons.sync_rounded,
        titulo: 'Cargando conversación',
        subtitulo: 'Estamos sincronizando tus mensajes.',
        trailing: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }
    return StreamBuilder<List<mensajeRemoto>>(
      stream: _mensajes.streamMensajes(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _estadoVisual(
            icon: Icons.error_outline,
            titulo: 'Error al cargar mensajes',
            subtitulo: '${snapshot.error}',
            trailing: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton.icon(
                onPressed: _bootstrap,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _estadoVisual(
            icon: Icons.hourglass_top_rounded,
            titulo: 'Cargando mensajes',
            trailing: const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        }
        final lista = snapshot.data ?? const <mensajeRemoto>[];
        if (lista.isEmpty) {
          return _estadoVisual(
            icon: Icons.chat_bubble_outline_rounded,
            titulo: 'Sin mensajes aun',
            subtitulo: 'Inicia la conversación con un mensaje.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            final msg = lista[index];
            final mine = msg.senderUid == _miUid;
            final colorPrimario = Theme.of(context).colorScheme.primary;
            final dark = TemaFixi.esOscuro(context);
            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!mine) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AvatarUsuarioFixi(
                        uid: widget.otroUid ?? msg.senderUid,
                        urlFoto: widget.fotoUrl,
                        nombre: widget.tituloAppBar,
                        radio: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: mine
                      ? colorPrimario.withValues(alpha: dark ? 0.32 : 0.16)
                      : (dark
                          ? TemaFixi.colorSuperficieSecundaria(context)
                          : Colors.white.withValues(alpha: 0.96)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(mine ? 14 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 14),
                  ),
                  border: Border.all(
                    color: mine
                        ? colorPrimario.withValues(alpha: 0.35)
                        : TemaFixi.colorBorde(context),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _contenidoBurbuja(msg, mine),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _hhmm(msg.createdAt),
                        style: TextStyle(
                          color: TemaFixi.colorSubtitulo(context),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _contenidoBurbuja(mensajeRemoto msg, bool mine) {
    if (msg.tipo == 'imagen' && msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) {
      return BurbujaImagenMensaje(
        mediaUrl: msg.mediaUrl!,
        texto: msg.texto.isNotEmpty ? msg.texto : null,
        esMio: mine,
      );
    }
    if (msg.tipo == 'audio' && msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) {
      return BurbujaAudioMensaje(
        mediaUrl: msg.mediaUrl!,
        duracionSegundos: msg.duracionSegundos,
        esMio: mine,
      );
    }
    if (msg.tipo == 'ubicacion' && msg.latitud != null && msg.longitud != null) {
      return BurbujaUbicacionMensaje(
        latitud: msg.latitud!,
        longitud: msg.longitud!,
        texto: msg.texto.isNotEmpty ? msg.texto : null,
        esMio: mine,
      );
    }
    return TextoMensajeConEnlaces(
      texto: msg.texto,
      estiloTexto: TextStyle(
        color: TemaFixi.colorTextoPrincipal(context),
        fontSize: 14,
        height: 1.35,
      ),
    );
  }

  Widget _barraGrabacionAudio(BuildContext context) {
    final m = (_segundosGrabacion ~/ 60).toString().padLeft(2, '0');
    final s = (_segundosGrabacion % 60).toString().padLeft(2, '0');

    return Row(
      children: [
        IconButton(
          tooltip: 'Cancelar grabación',
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
          onPressed: _enviando ? null : _cancelarGrabacionVoz,
        ),
        const SizedBox(width: 4),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$m:$s',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Grabando audio...',
            style: TextStyle(
              fontSize: 12.5,
              color: TemaFixi.colorSubtitulo(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _enviando ? null : _detenerYEnviarAudio,
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
          ),
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 20),
        ),
      ],
    );
  }

  Widget _barraEntradaTexto(BuildContext context) {
    final tieneTexto = _inputController.text.trim().isNotEmpty;
    final primario = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        IconButton(
          tooltip: 'Adjuntar archivo o ubicación',
          icon: Icon(
            Icons.add_circle_outline_rounded,
            color: primario,
            size: 24,
          ),
          onPressed: _enviando || _miUid == null ? null : _abrirMenuAdjuntos,
        ),
        Expanded(
          child: TextField(
            controller: _inputController,
            enabled: !_enviando && _miUid != null,
            style: TextStyle(
              color: TemaFixi.colorTextoPrincipal(context),
            ),
            decoration: InputDecoration(
              hintText: 'Escribe un mensaje',
              hintStyle: TextStyle(
                color: TemaFixi.colorSubtitulo(context),
              ),
              filled: true,
              fillColor: TemaFixi.colorSuperficieSecundaria(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: TemaFixi.colorBorde(context),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: TemaFixi.colorBorde(context),
                ),
              ),
            ),
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(width: 8),
        if (tieneTexto)
          FilledButton(
            onPressed: _enviando ? null : _send,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(13),
            ),
            child: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 20),
          )
        else
          IconButton.filledTonal(
            tooltip: 'Grabar mensaje de voz',
            onPressed: _enviando || _miUid == null ? null : _iniciarGrabacionVoz,
            icon: const Icon(Icons.mic_rounded, size: 22),
          ),
      ],
    );
  }

  Widget _quickReplies() {
    final replies = [
      'Me interesa tu servicio',
      'Puedes venir hoy?',
      'Podrias mandarme una cotizacion?',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Container(
        height: 54,
        decoration: TemaFixi.decoracionTarjeta(context, radio: 16),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, i) => ActionChip(
            label: Text(replies[i]),
            side: BorderSide(color: TemaFixi.colorBorde(context)),
            backgroundColor: TemaFixi.colorSuperficieSecundaria(context),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: TemaFixi.colorTextoPrincipal(context),
            ),
            onPressed: _enviando
                ? null
                : () {
                    _inputController.text = replies[i];
                    _send();
                  },
          ),
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemCount: replies.length,
        ),
      ),
    );
  }

  Widget _estadoVisual({
    required IconData icon,
    required String titulo,
    String? subtitulo,
    Widget? trailing,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: TemaFixi.decoracionTarjeta(context, radio: 20),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 10),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TemaFixi.colorSubtitulo(context),
                    fontSize: 12.5,
                  ),
                ),
              ],
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  String _hhmm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
