import 'package:flutter/material.dart';

import '../Servicios/autenticacionStorage.dart';
import '../Servicios/servicioMensajes.dart';
import '../Servicios/servicioPerfilApi.dart';
import 'pantChatDetCliente.dart';

class PantallaMensajesCliente extends StatefulWidget {
  final int initialTabIndex;
  final String initialSearch;

  const PantallaMensajesCliente({
    super.key,
    this.initialTabIndex = 0,
    this.initialSearch = '',
  });

  @override
  State<PantallaMensajesCliente> createState() => _PantallaMensajesClienteState();
}

class _PantallaMensajesClienteState extends State<PantallaMensajesCliente> with SingleTickerProviderStateMixin {
  final ServicioMensajes _mensajes = ServicioMensajes();
  final AutenticacionStorage _storage = AutenticacionStorage();
  final ServicioPerfilApi _perfilApi = ServicioPerfilApi();
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;
  String _search = '';

  String? _miUid;
  bool _cargando = true;
  String? _error;

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
    _resolverUid();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _resolverUid() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final token = await _storage.recuperarToken();
      if (token == null) throw Exception('Sesion no iniciada');
      final perfil = await _perfilApi.fetchPerfil(token);
      final uid = perfil['id'] as String? ?? perfil['uid'] as String?;
      if (uid == null || uid.isEmpty) throw Exception('UID no disponible');
      setState(() {
        _miUid = uid;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trabajadores'),
            Tab(text: 'Servicios'),
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
            child: _cuerpo(),
          ),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _resolverUid, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (_miUid == null) {
      return const Center(child: Text('Sin sesion'));
    }
    final uid = _miUid!;
    return StreamBuilder<List<ConversacionRemota>>(
      stream: _mensajes.streamConversaciones(uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _resolverUid, child: const Text('Reintentar')),
                ],
              ),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final todas = snap.data ?? const <ConversacionRemota>[];
        return TabBarView(
          controller: _tabController,
          children: [
            _buildList(todas, uid, vistaCliente: true),
            _buildList(
              todas.where((c) => (c.ultimoMensaje ?? '').isNotEmpty).toList(),
              uid,
              vistaCliente: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(List<ConversacionRemota> source, String miUid, {required bool vistaCliente}) {
    final list = source.where((c) {
      if (_search.isEmpty) return true;
      final titulo = c.tituloLista(miUid, vistaCliente: vistaCliente);
      final txt =
          '$titulo ${c.ultimoMensaje ?? ''} ${c.trabajadorNombre ?? ''} ${c.clienteNombre ?? ''}'
              .toLowerCase();
      return txt.contains(_search);
    }).toList();

    if (list.isEmpty) {
      return const Center(child: Text('Sin conversaciones'));
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final c = list[i];
        final titulo = c.tituloLista(miUid, vistaCliente: vistaCliente);
        final fecha = c.updatedAt ?? DateTime.now();
        return ListTile(
          leading: CircleAvatar(
            child: Text(titulo.isNotEmpty ? titulo.substring(0, 1) : '?'),
          ),
          title: Text(titulo),
          subtitle: Text(
            c.ultimoMensaje?.isNotEmpty == true ? c.ultimoMensaje! : 'Sin mensajes',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(_hhmm(fecha), style: Theme.of(context).textTheme.bodySmall),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PantallaChatDetalleCliente(
                  conversationId: c.id,
                  tituloAppBar: titulo,
                ),
              ),
            );
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
