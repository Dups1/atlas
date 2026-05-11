import 'package:flutter/material.dart';

import '../Servicios/mensajesMockService.dart';
import 'pantChatDetTrabajador.dart';

class PantallaMensajesTrabajador extends StatefulWidget {
  final int initialTabIndex;
  final String initialSearch;

  const PantallaMensajesTrabajador({
    super.key,
    this.initialTabIndex = 0,
    this.initialSearch = '',
  });

  @override
  State<PantallaMensajesTrabajador> createState() => _PantallaMensajesTrabajadorState();
}

class _PantallaMensajesTrabajadorState extends State<PantallaMensajesTrabajador> with SingleTickerProviderStateMixin {
  final MensajesMockService _service = MensajesMockService.instance;
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final index = widget.initialTabIndex.clamp(0, 1);
    _tabController.index = index;
    if (widget.initialSearch.trim().isNotEmpty) {
      _searchController.text = widget.initialSearch.trim();
      _search = widget.initialSearch.trim().toLowerCase();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Solicitudes'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Buscar chat',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_service.obtenerConversaciones()),
                _buildList(_service.obtenerSolicitudes()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ConversacionMock> source) {
    final list = source.where((c) {
      if (_search.isEmpty) return true;
      final txt = '${c.clienteNombre} ${c.ultimoMensaje}'.toLowerCase();
      return txt.contains(_search);
    }).toList();

    if (list.isEmpty) {
      return const Center(child: Text('Sin conversaciones'));
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final c = list[i];
        return ListTile(
          leading: CircleAvatar(
            child: Text(c.clienteNombre.isNotEmpty ? c.clienteNombre.substring(0, 1) : '?'),
          ),
          title: Text(c.clienteNombre),
          subtitle: Text(
            c.ultimoMensaje,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_hhmm(c.fechaUltimo), style: Theme.of(context).textTheme.bodySmall),
              if (c.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${c.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PantallaChatDetalleTrabajador(conversation: c),
              ),
            );
            setState(() {});
          },
        );
      },
    );
  }

  String _hhmm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
