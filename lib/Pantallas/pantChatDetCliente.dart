import 'package:flutter/material.dart';

import '../Servicios/mensajesMockService.dart';

class PantallaChatDetalleCliente extends StatefulWidget {
  final ConversacionMock conversation;

  const PantallaChatDetalleCliente({
    super.key,
    required this.conversation,
  });

  @override
  State<PantallaChatDetalleCliente> createState() => _PantallaChatDetalleClienteState();
}

class _PantallaChatDetalleClienteState extends State<PantallaChatDetalleCliente> {
  final MensajesMockService _service = MensajesMockService.instance;
  final TextEditingController _inputController = TextEditingController();

  List<MensajeMock> get _messages => _service.obtenerMensajes(widget.conversation.id);

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.clienteNombre),
            Text(
              'Trabajador',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.phone_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.work_outline)),
        ],
      ),
      body: Column(
        children: [
          _quickReplies(),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final mine = msg.senderId != MensajesMockService.trabajadorId;
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
                        Text(msg.text),
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
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickReplies() {
    final replies = ['Me interesa tu servicio', 'Puedes venir hoy?', 'Podrias mandarme una cotizacion?'];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => ActionChip(
          label: Text(replies[i]),
          onPressed: () {
            _inputController.text = replies[i];
            _send();
          },
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: replies.length,
      ),
    );
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _service.sendMessage(
      conversationId: widget.conversation.id,
      senderId: 'cliente',
      text: text,
    );
    _inputController.clear();
    setState(() {});
  }

  String _hhmm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
