import 'package:flutter/material.dart';

import '../Servicios/autenticacion/autenticacionStorage.dart';
import '../Servicios/mensajes/servicioMensajes.dart';
import '../Servicios/perfil/servicioPerfilApi.dart';
import '../Servicios/ia/servicioRellenoAgente.dart';
import '../widgets/alcanceServicioLlamadas.dart';
import 'pantLlamadaEmisor.dart';

class pantallaChatDetalleCliente extends StatefulWidget {
  final String conversationId;
  final String tituloAppBar;

  const pantallaChatDetalleCliente({
    super.key,
    required this.conversationId,
    required this.tituloAppBar,
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
  final TextEditingController _inputController = TextEditingController();

  String? _miUid;
  String? _error;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _cargarMensajePreRellenado();
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

  void _abrirLlamada() {
    if (_miUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Espera a cargar la sesion')),
      );
      return;
    }
    final otro = servicioMensajes.otroUidDesdeConversationId(
      widget.conversationId,
      _miUid!,
    );
    if (otro == null || otro.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener el UID del contacto')),
      );
      return;
    }
    final servicio = alcanceServicioLlamadas.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => pantallaLlamadaEmisor(
          tituloAppBar: 'Llamada',
          idReceptorInicial: otro,
          nombreRemotoInicial: widget.tituloAppBar,
          servicioCompartido: servicio,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _avatarColor(
                widget.tituloAppBar,
              ).withValues(alpha: 0.15),
              child: Text(
                widget.tituloAppBar.isNotEmpty
                    ? widget.tituloAppBar.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  color: _avatarColor(widget.tituloAppBar),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.tituloAppBar),
                  Text(
                    'Trabajador',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            onPressed: _abrirLlamada,
            icon: const Icon(Icons.phone_outlined, size: 20),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            onPressed: () {},
            icon: const Icon(Icons.work_outline, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFEDF3FC)],
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.blueGrey.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            enabled: !_enviando && _miUid != null,
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje',
                              hintStyle: TextStyle(
                                color: Colors.blueGrey.shade500,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFF),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blueGrey.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blueGrey.withValues(
                                    alpha: 0.14,
                                  ),
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                        ),
                      ],
                    ),
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
            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                constraints: const BoxConstraints(maxWidth: 292),
                decoration: BoxDecoration(
                  color: mine
                      ? colorPrimario.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(mine ? 14 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 14),
                  ),
                  border: Border.all(
                    color: mine
                        ? colorPrimario.withValues(alpha: 0.24)
                        : Colors.blueGrey.withValues(alpha: 0.14),
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
                    Text(msg.texto),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _hhmm(msg.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blueGrey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, i) => ActionChip(
            label: Text(replies[i]),
            side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.12)),
            backgroundColor: const Color(0xFFF8FAFF),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
                    color: Colors.blueGrey.shade700,
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

  Color _avatarColor(String seed) {
    final total = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    const palette = <Color>[
      Color(0xFF0EA5E9),
      Color(0xFF4F46E5),
      Color(0xFF16A34A),
      Color(0xFFF59E0B),
      Color(0xFFDC2626),
      Color(0xFF0891B2),
    ];
    return palette[total % palette.length];
  }

  String _hhmm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
