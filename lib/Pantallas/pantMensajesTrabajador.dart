import 'package:flutter/material.dart';

import '../Config/temaFixi.dart';
import '../Servicios/autenticacion/autenticacionStorage.dart';
import '../Servicios/mensajes/servicioMensajes.dart';
import '../Servicios/perfil/servicioPerfilApi.dart';
import '../widgets/avatarUsuarioFixi.dart';
import 'pantChatDetTrabajador.dart';

class pantallaMensajesTrabajador extends StatefulWidget {
  final int initialTabIndex;
  final String initialSearch;

  const pantallaMensajesTrabajador({
    super.key,
    this.initialTabIndex = 0,
    this.initialSearch = '',
  });

  @override
  State<pantallaMensajesTrabajador> createState() =>
      _pantallaMensajesTrabajadorState();
}

class _pantallaMensajesTrabajadorState extends State<pantallaMensajesTrabajador>
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
      backgroundColor: TemaFixi.colorFondo(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: TemaFixi.colorBarraSuperior(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('Mensajes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: TemaFixi.colorSuperficieSecundaria(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: TemaFixi.colorBorde(context),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: TemaFixi.colorSubtitulo(context),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                indicator: BoxDecoration(
                  color: TemaFixi.azulFacebook,
                  borderRadius: BorderRadius.circular(18),
                ),
                tabs: const [
                  Tab(text: 'Chats'),
                  Tab(text: 'Solicitudes'),
                ],
              ),
            ),
          ),
        ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: TemaFixi.colorSuperficieSecundaria(context),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.search_rounded,
                      color: TemaFixi.colorSubtitulo(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _search = v.trim().toLowerCase()),
                        style: TextStyle(
                          color: TemaFixi.colorTextoPrincipal(context),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar chat...',
                          hintStyle: TextStyle(
                            color: TemaFixi.colorSubtitulo(context),
                            fontSize: 13.5,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 18),
                        color: TemaFixi.colorSubtitulo(context),
                        splashRadius: 16,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      ),
                    const SizedBox(width: 4),
                  ],
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
            _buildList(todas, uid, vistaCliente: false),
            _buildList(
              todas.where((c) => (c.ultimoMensaje ?? '').isNotEmpty).toList(),
              uid,
              vistaCliente: false,
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
          '$titulo ${c.ultimoMensaje ?? ''} ${c.clienteNombre ?? ''} ${c.trabajadorNombre ?? ''}'
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
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => pantallaChatDetalleTrabajador(
                    conversationId: c.id,
                    tituloAppBar: titulo,
                    otroUid: c.otroUid(miUid),
                    fotoUrl: c.fotoLista(miUid, vistaCliente: vistaCliente),
                  ),
                ),
              );
            },
            child: Ink(
              decoration: TemaFixi.decoracionTarjeta(context, radio: 16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    AvatarUsuarioFixi(
                      uid: c.otroUid(miUid),
                      urlFoto: c.fotoLista(miUid, vistaCliente: vistaCliente),
                      nombre: titulo,
                      radio: 23,
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
                              color: TemaFixi.colorSubtitulo(context),
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
                            color: TemaFixi.colorSubtitulo(context),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: TemaFixi.colorSubtitulo(context),
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
