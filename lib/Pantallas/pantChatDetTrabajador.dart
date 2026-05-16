import 'package:flutter/material.dart';

import '../Servicios/autenticacionStorage.dart';
import '../Servicios/servicioMensajes.dart';
import '../Servicios/servicioPerfilApi.dart';
import '../widgets/alcance_servicio_llamadas.dart';
import 'pantLlamadaEmisor.dart';

class PantallaChatDetalleTrabajador extends StatefulWidget {
  final String conversationId;
  final String tituloAppBar;

  const PantallaChatDetalleTrabajador({
    super.key,
    required this.conversationId,
    required this.tituloAppBar,
  });

  @override
  State<PantallaChatDetalleTrabajador> createState() => _PantallaChatDetalleTrabajadorState();
}

class _PantallaChatDetalleTrabajadorState extends State<PantallaChatDetalleTrabajador> {
  final ServicioMensajes _mensajes = ServicioMensajes();
  final AutenticacionStorage _storage = AutenticacionStorage();
  final ServicioPerfilApi _perfilApi = ServicioPerfilApi();
  final TextEditingController _inputController = TextEditingController();

  String? _miUid;
  String? _error;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
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
    final otro = ServicioMensajes.otroUidDesdeConversationId(widget.conversationId, _miUid!);
    if (otro == null || otro.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener el UID del contacto')),
      );
      return;
    }
    final servicio = alcanceServicioLlamadas.maybeOf(context);
    if (servicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servicio de llamadas no disponible en esta pantalla')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaLlamadaEmisor(
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tituloAppBar),
            Text(
              'Cliente',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _abrirLlamada, icon: const Icon(Icons.phone_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.location_on_outlined)),
        ],
      ),
      body: Column(
        children: [
          _quickReplies(),
          const Divider(height: 1),
          Expanded(child: _cuerpoLista()),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      enabled: !_enviando && _miUid != null,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _enviando ? null : _send,
                    icon: _enviando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cuerpoLista() {
    if (_error != null && _miUid == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _bootstrap, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (_miUid == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<List<MensajeRemoto>>(
      stream: _mensajes.streamMensajes(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _bootstrap, child: const Text('Reintentar')),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final lista = snapshot.data ?? const <MensajeRemoto>[];
        if (lista.isEmpty) {
          return const Center(child: Text('Sin mensajes aun'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            final msg = lista[index];
            final mine = msg.senderUid == _miUid;
            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: mine ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg.texto),
                    const SizedBox(height: 4),
                    Text(
                      _hhmm(msg.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
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
    final replies = ['Voy en camino', 'Estoy en sitio', 'Trabajo finalizado'];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => ActionChip(
          label: Text(replies[i]),
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
    );
  }

  String _hhmm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
