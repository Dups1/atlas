import 'dart:async';

import 'package:flutter/material.dart';

import '../Servicios/autenticacion/autenticacionStorage.dart';
import '../Servicios/llamadas/servicioLlamadas.dart';
import '../Servicios/perfil/servicioPerfilApi.dart';
import '../Servicios/trabajadores/servicioTrabajadores.dart';
import '../Servicios/autenticacion/sesionService.dart';
import '../widgets/alcanceModoEnigma.dart';
import '../widgets/alcanceServicioLlamadas.dart';
import '../widgets/escuchaLlamadasEntrantes.dart';
import 'pantAjustes.dart';
import 'pantAuth.dart';
import 'pantLaboratorio.dart';
import 'navegacionChat.dart';
import 'pantMensajesCliente.dart';
import 'pantPerfilCliente.dart';
import 'pantPerfilTrabPublico.dart';
import 'pantReservaCliente.dart';
import 'pantTrabajador.dart';

class pantallaCliente extends StatefulWidget {
  const pantallaCliente({super.key});

  @override
  State<pantallaCliente> createState() => _pantallaClienteState();
}

class _pantallaClienteState extends State<pantallaCliente> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final sesionService _sesionService = sesionService();
  final servicioTrabajadores _trabajadoresService = servicioTrabajadores();
  final autenticacionStorage _storage = autenticacionStorage();
  final servicioPerfilApi _perfilApi = servicioPerfilApi();
  late final servicioLlamadas _servicioLlamadas;
  bool _servicioLlamadasInicializada = false;

  late Future<List<Map<String, dynamic>>> _trabajadoresFuture;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _trabajadoresFuture = _trabajadoresService.fetchTrabajadores();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_servicioLlamadasInicializada) return;
    _servicioLlamadas = alcanceServicioLlamadas.of(context);
    _servicioLlamadasInicializada = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _servicioLlamadas.prepararMensajeriaYAutenticacion();
    });
  }

  @override
  void dispose() {
    if (_servicioLlamadasInicializada) {
      unawaited(_servicioLlamadas.terminarRecursos());
    }
    _controller.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filtered = _all.where((w) {
        final nombre = (w['nombre'] ?? '').toString().toLowerCase();
        final cat = (w['categoria'] ?? '').toString().toLowerCase();
        return nombre.contains(lower) || cat.contains(lower);
      }).toList();
    });
  }

  Widget _botonModoEnigma(BuildContext context) {
    final modoEnigma = alcanceModoEnigma.of(context);
    final color = modoEnigma.activo
        ? const Color(0xFF15803D)
        : const Color(0xFFB91C1C);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: TextButton.icon(
        onPressed: modoEnigma.alternar,
        style: TextButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.14),
          side: BorderSide(color: color.withValues(alpha: 0.35)),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: Icon(
          modoEnigma.activo
              ? Icons.verified_user_outlined
              : Icons.visibility_off_outlined,
          size: 15,
          color: color,
        ),
        label: Text(
          'Modo enigma',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _promptCerrarSesion() async {
    final confirmed = await _sesionService.confirmarCerrarSesion(context);
    if (!confirmed) return;
    await _servicioLlamadas.terminarRecursos();
    await _sesionService.limpiarSesion();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const pantallaAuth()),
      (route) => false,
    );
  }

  Widget _buildDrawerContent({required BuildContext context}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9FBFF), Color(0xFFF1F5FD)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blueGrey.withValues(alpha: 0.12),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajustes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Administra preferencias, permisos y sesión.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _drawerTile(
            icon: Icons.settings_outlined,
            title: 'Configuraciones',
            subtitle: 'Tema y permisos',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const vistaConfiguraciones()),
              );
            },
          ),
          _drawerTile(
            icon: Icons.info_outline,
            title: 'Acerca de',
            subtitle: 'Redes sociales y version',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const vistaAcerca()));
            },
          ),
          _drawerTile(
            icon: Icons.logout,
            title: 'Cerrar sesion',
            subtitle: 'Advertencia de salida',
            warning: true,
            onTap: _promptCerrarSesion,
          ),
        ],
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool warning = false,
  }) {
    final iconColor = warning
        ? const Color(0xFFB91C1C)
        : Colors.blueGrey.shade700;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.12)),
          ),
          leading: Icon(icon, color: iconColor),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: warning ? iconColor : null,
            ),
          ),
          subtitle: Text(subtitle),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _estadoCentrado({
    required IconData icon,
    required String titulo,
    String? subtitulo,
    Widget? trailing,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
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

  Widget _buildCard(Map<String, dynamic> w) {
    final nombre = w['nombre'] as String? ?? 'Sin nombre';
    final categoria = w['categoria'] as String? ?? '';
    final subcategoria = w['subcategoria'] as String? ?? '';
    final calificacion =
        double.tryParse((w['calificacion'] ?? '4.0').toString()) ?? 4.0;
    final foto = (w['foto'] as String?)?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => pantallaPerfilTrabajadorPublico(data: w),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                child: foto.isEmpty ? const Icon(Icons.person_outline) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (categoria.isNotEmpty)
                      Text(
                        categoria,
                        style: TextStyle(
                          fontSize: 12.8,
                          color: Colors.blueGrey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (subcategoria.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            subcategoria,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          calificacion.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12.8,
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.message_outlined),
                onPressed: () {
                  final nombre = w['nombre'] as String? ?? 'Trabajador';
                  final uid = uidDesdeMapaUsuario(w);
                  if (uid.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Este perfil no tiene id de usuario'),
                      ),
                    );
                    return;
                  }
                  abrirChatClienteConTrabajador(
                    context,
                    trabajadorUid: uid,
                    tituloMostrar: nombre,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return escuchaLlamadasEntrantes(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const Text('Explorar Atlas'),
          actions: [
            _botonModoEnigma(context),
            IconButton.filledTonal(
              icon: const Icon(Icons.science_outlined),
              tooltip: 'Laboratorio',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const pantallaLaboratorio()),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            const SizedBox(width: 10),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
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
                  controller: _controller,
                  onChanged: _filter,
                  decoration: InputDecoration(
                    hintText: 'Busca por nombre o categoria',
                    hintStyle: TextStyle(color: Colors.blueGrey.shade500),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.blueGrey.shade600,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blueGrey.withValues(alpha: 0.18),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blueGrey.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _trabajadoresFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _estadoCentrado(
                  icon: Icons.hourglass_top_rounded,
                  titulo: 'Cargando trabajadores',
                  subtitulo:
                      'Espera un momento mientras preparamos resultados.',
                  trailing: const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _estadoCentrado(
                  icon: Icons.error_outline,
                  titulo: 'No se pudo cargar la lista',
                  subtitulo: 'Error: ${snapshot.error}',
                );
              }

              final data = snapshot.data ?? [];
              final trabajadores = data
                  .where(
                    (w) =>
                        (w['rol'] ?? '').toString().toLowerCase() ==
                        'trabajador',
                  )
                  .toList();

              if (_all.isEmpty && trabajadores.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _all = trabajadores;
                      _filtered = trabajadores;
                    });
                  }
                });
              }

              if (_filtered.isEmpty && _controller.text.isEmpty) {
                if (trabajadores.isEmpty) {
                  return _estadoCentrado(
                    icon: Icons.person_search_outlined,
                    titulo: 'No hay trabajadores registrados',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  itemCount: trabajadores.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildCard(trabajadores[i]),
                  ),
                );
              }

              if (_filtered.isEmpty) {
                return _estadoCentrado(
                  icon: Icons.search_off_rounded,
                  titulo: 'Sin resultados',
                  subtitulo: 'Prueba con otro nombre o categoria.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                itemCount: _filtered.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildCard(_filtered[i]),
                ),
              );
            },
          ),
        ),
        endDrawer: Drawer(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
          ),
          child: StatefulBuilder(
            builder: (ctx, _) => _buildDrawerContent(context: ctx),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    const labels = ['Inicio', 'Mensajes', 'Reserva', 'Perfil'];
    const icons = [
      Icons.home_outlined,
      Icons.message_outlined,
      Icons.calendar_month_outlined,
      Icons.person_outline,
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(labels.length, (index) {
              final isActive = _selectedIndex == index;
              final color = isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.blueGrey.shade500;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      if (index == 1) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const pantallaMensajesCliente(),
                          ),
                        );
                      }
                      if (index == 2) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const pantallaReservaCliente(),
                          ),
                        );
                      }
                      if (index == 3) {
                        _openPerfilActual();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icons[index], size: 20, color: color),
                          const SizedBox(height: 3),
                          Text(
                            labels[index],
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<void> _openPerfilActual() async {
    try {
      final token = await _storage.recuperarToken();
      if (token == null) throw Exception('Sesion no iniciada');
      final perfil = await _perfilApi.fetchPerfil(token);
      final rol = (perfil['rol'] ?? '').toString().toLowerCase();
      if (!mounted) return;

      if (rol == 'trabajador') {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const workerProfileView()));
      } else {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const perfilClienteView()));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo abrir el perfil: $e')));
    }
  }
}
