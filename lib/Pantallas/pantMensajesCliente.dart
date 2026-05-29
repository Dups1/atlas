import 'package:flutter/material.dart';

import '../Servicios/autenticacion/autenticacionStorage.dart';
import '../Servicios/mensajes/servicioMensajes.dart';
import '../Servicios/perfil/servicioPerfilApi.dart';
import 'pantChatDetCliente.dart';

class pantallaMensajesCliente extends StatefulWidget {
  final int initialTabIndex;
  final String initialSearch;

  const pantallaMensajesCliente({
    super.key,
    this.initialTabIndex = 0,
    this.initialSearch = '',
  });

  @override
  State<pantallaMensajesCliente> createState() =>
      _pantallaMensajesClienteState();
}

class _pantallaMensajesClienteState extends State<pantallaMensajesCliente>
    with SingleTickerProviderStateMixin {
  final servicioMensajes _mensajes = servicioMensajes();
  final autenticacionStorage _storage = autenticacionStorage();
  final servicioPerfilApi _perfilApi = servicioPerfilApi();
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
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Mensajes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.blueGrey.withValues(alpha: 0.12),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.blueGrey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                indicator: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                tabs: const [
                  Tab(text: 'Trabajadores'),
                  Tab(text: 'Servicios'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFEEF3FB)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blueGrey.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _search = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Buscar chat',
                    hintStyle: TextStyle(color: Colors.blueGrey.shade500),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.blueGrey.shade600,
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
                        color: Colors.blueGrey.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blueGrey.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _cuerpo()),
          ],
        ),
      ),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return _estadoVisual(
        icon: Icons.hourglass_top_rounded,
        titulo: 'Cargando conversaciones',
        subtitulo: 'Espera un momento mientras sincronizamos tus chats.',
        trailing: const Padding(
          padding: EdgeInsets.only(top: 10),
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }
    if (_error != null) {
      return _estadoVisual(
        icon: Icons.wifi_off_rounded,
        titulo: 'No se pudieron cargar los mensajes',
        subtitulo: _error!,
        trailing: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton.icon(
            onPressed: _resolverUid,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
      );
    }
    if (_miUid == null) {
      return _estadoVisual(
        icon: Icons.lock_outline,
        titulo: 'Sin sesion',
        subtitulo:
            'Inicia sesion nuevamente para acceder a tus conversaciones.',
      );
    }
    final uid = _miUid!;
    return StreamBuilder<List<conversacionRemota>>(
      stream: _mensajes.streamConversaciones(uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return _estadoVisual(
            icon: Icons.error_outline,
            titulo: 'Error al escuchar conversaciones',
            subtitulo: '${snap.error}',
            trailing: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton.icon(
                onPressed: _resolverUid,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return _estadoVisual(
            icon: Icons.sync_rounded,
            titulo: 'Actualizando conversaciones',
            subtitulo: 'Cargando datos en tiempo real.',
            trailing: const Padding(
              padding: EdgeInsets.only(top: 10),
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        }
        final todas = snap.data ?? const <conversacionRemota>[];
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

  Widget _buildList(
    List<conversacionRemota> source,
    String miUid, {
    required bool vistaCliente,
  }) {
    final list = source.where((c) {
      if (_search.isEmpty) return true;
      final titulo = c.tituloLista(miUid, vistaCliente: vistaCliente);
      final txt =
          '$titulo ${c.ultimoMensaje ?? ''} ${c.trabajadorNombre ?? ''} ${c.clienteNombre ?? ''}'
              .toLowerCase();
      return txt.contains(_search);
    }).toList();

    if (list.isEmpty) {
      return _estadoVisual(
        icon: Icons.forum_outlined,
        titulo: 'Sin conversaciones',
        subtitulo: 'Cuando tengas actividad de chat aparecera aqui.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = list[i];
        final titulo = c.tituloLista(miUid, vistaCliente: vistaCliente);
        final fecha = c.updatedAt ?? DateTime.now();
        final avatarColor = _colorAvatar(titulo);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => pantallaChatDetalleCliente(
                    conversationId: c.id,
                    tituloAppBar: titulo,
                  ),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blueGrey.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: avatarColor.withValues(alpha: 0.15),
                      child: Text(
                        titulo.isNotEmpty
                            ? titulo.substring(0, 1).toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: avatarColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.ultimoMensaje?.isNotEmpty == true
                                ? c.ultimoMensaje!
                                : 'Sin mensajes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _hhmm(fecha),
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Colors.blueGrey.shade400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

  Color _colorAvatar(String seed) {
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
