import 'dart:async';

import 'package:flutter/material.dart';

import '../Config/temaFixi.dart';
import '../Servicios/autenticacion/autenticacionStorage.dart';
import '../Servicios/perfil/servicioPerfilApi.dart';
import '../Servicios/trabajadores/servicioTrabajadores.dart';
import '../Servicios/autenticacion/sesionService.dart';
import '../widgets/alcanceModoEnigma.dart';
import 'pantAjustes.dart';
import 'pantAuth.dart';
import 'navegacionChat.dart';
import 'pantMensajesCliente.dart';
import 'pantPerfilCliente.dart';
import 'pantPerfilTrabPublico.dart';
import 'pantCalendarioCliente.dart';
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _categoriaSeleccionada = 'Todos';

  void _filtrar({String? texto, String? categoria}) {
    if (categoria != null) {
      _categoriaSeleccionada = categoria;
    }
    final query = (texto ?? _controller.text).trim().toLowerCase();
    final catFiltro = _categoriaSeleccionada.toLowerCase();

    setState(() {
      _filtered = _all.where((w) {
        final nombre = (w['nombre'] ?? '').toString().toLowerCase();
        final cat = (w['categoria'] ?? '').toString().toLowerCase();
        final descripcion = (w['descripcion'] ?? '').toString().toLowerCase();

        final coincideTexto = query.isEmpty ||
            nombre.contains(query) ||
            cat.contains(query) ||
            descripcion.contains(query);

        final coincideCategoria =
            catFiltro == 'todos' || cat.contains(catFiltro);

        return coincideTexto && coincideCategoria;
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
    await _sesionService.limpiarSesion();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const pantallaAuth()),
      (route) => false,
    );
  }

  Widget _buildDrawerContent({required BuildContext context}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: TemaFixi.gradienteFondo(context),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: TemaFixi.decoracionTarjeta(context, radio: 16),
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
        : TemaFixi.colorSubtitulo(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: TemaFixi.colorTarjetaSolida(context),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: TemaFixi.colorBorde(context)),
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
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: TemaFixi.colorTextoPrincipal(context),
                ),
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
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => pantallaPerfilTrabajadorPublico(data: w),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: TemaFixi.decoracionTarjeta(context, radio: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                child: foto.isEmpty
                    ? Icon(
                        Icons.person_outline,
                        color: TemaFixi.colorSubtitulo(context),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: TemaFixi.colorTextoPrincipal(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (categoria.isNotEmpty)
                      Text(
                        categoria,
                        style: TextStyle(
                          fontSize: 12.8,
                          color: TemaFixi.colorSubtitulo(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (subcategoria.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TemaFixi.colorSuperficieSecundaria(context),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: TemaFixi.colorBorde(context),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            subcategoria,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: TemaFixi.colorSubtitulo(context),
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
                            color: TemaFixi.colorTextoPrincipal(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: TemaFixi.colorSuperficieSecundaria(context),
                  foregroundColor: TemaFixi.colorTextoPrincipal(context),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
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
    return Scaffold(
      key: _scaffoldKey,
        backgroundColor: TemaFixi.colorFondo(context),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: TemaFixi.colorBarraSuperior(context),
          surfaceTintColor: Colors.transparent,
          shape: const Border(),
          title: TemaFixi.logoAppBar(context, height: 32),
          actions: [
            _botonModoEnigma(context),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Ajustes',
                style: IconButton.styleFrom(
                  backgroundColor: TemaFixi.colorSuperficieSecundaria(context),
                  foregroundColor: TemaFixi.colorTextoPrincipal(context),
                ),
                icon: const Icon(Icons.menu_rounded, size: 20),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ),
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
              _buildBarraBusquedaFacebook(context),
              Expanded(
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

                    if (_filtered.isEmpty &&
                        _controller.text.isEmpty &&
                        _categoriaSeleccionada == 'Todos') {
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
                        subtitulo: _categoriaSeleccionada != 'Todos'
                            ? 'No se encontraron trabajadores en la categoría "$_categoriaSeleccionada".'
                            : 'Prueba con otro término de búsqueda.',
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
            ],
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
      );
  }

  Widget _buildBarraBusquedaFacebook(BuildContext context) {
    final dark = TemaFixi.esOscuro(context);
    final bgInput =
        dark ? TemaFixi.fbSecundarioOscuro : TemaFixi.fbSecundarioClaro;
    final colorTexto = TemaFixi.colorTextoPrincipal(context);
    final colorSub = TemaFixi.colorSubtitulo(context);

    return Container(
      decoration: BoxDecoration(
        color: TemaFixi.colorBarraSuperior(context),
        border: Border(
          bottom: BorderSide(
            color: TemaFixi.colorBorde(context).withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de búsqueda tipo cápsula / pill oficial de Facebook
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: bgInput,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.search_rounded,
                  color: colorSub,
                  size: 21,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (text) => _filtrar(texto: text),
                    style: TextStyle(
                      color: colorTexto,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar en Nexo...',
                      hintStyle: TextStyle(
                        color: colorSub,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    color: colorSub,
                    splashRadius: 16,
                    onPressed: () {
                      _controller.clear();
                      _filtrar(texto: '');
                    },
                  ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Pastillas de categoría horizontales estilo Facebook Marketplace
          _buildPastillasCategorias(context),
        ],
      ),
    );
  }

  Widget _buildPastillasCategorias(BuildContext context) {
    final dark = TemaFixi.esOscuro(context);
    final categorias = const [
      {'nombre': 'Todos', 'icon': Icons.apps_rounded},
      {'nombre': 'Plomería', 'icon': Icons.plumbing_rounded},
      {'nombre': 'Electricidad', 'icon': Icons.bolt_rounded},
      {'nombre': 'Carpintería', 'icon': Icons.handyman_rounded},
      {'nombre': 'Limpieza', 'icon': Icons.cleaning_services_rounded},
      {'nombre': 'Pintura', 'icon': Icons.format_paint_rounded},
      {'nombre': 'Jardinería', 'icon': Icons.yard_rounded},
      {'nombre': 'Cerrajería', 'icon': Icons.key_rounded},
      {'nombre': 'Mecánica', 'icon': Icons.build_circle_rounded},
    ];

    final azulMeta =
        dark ? TemaFixi.azulFacebookDark : TemaFixi.azulFacebook;

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = categorias[i];
          final nombre = item['nombre'] as String;
          final icon = item['icon'] as IconData;
          final seleccionada =
              _categoriaSeleccionada.toLowerCase() == nombre.toLowerCase();

          final colorFondo = seleccionada
              ? azulMeta
              : (dark ? TemaFixi.fbSecundarioOscuro : TemaFixi.fbSecundarioClaro);

          final colorTexto = seleccionada
              ? Colors.white
              : TemaFixi.colorTextoPrincipal(context);

          final colorIcon = seleccionada
              ? Colors.white
              : azulMeta;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: () => _filtrar(categoria: nombre),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorFondo,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: colorIcon),
                    const SizedBox(width: 6),
                    Text(
                      nombre,
                      style: TextStyle(
                        color: colorTexto,
                        fontSize: 12.5,
                        fontWeight:
                            seleccionada ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    const labels = ['Inicio', 'Mensajes', 'Calendario', 'Perfil'];
    const icons = [
      Icons.home_outlined,
      Icons.chat_bubble_outline_rounded,
      Icons.calendar_month_outlined,
      Icons.person_outline_rounded,
    ];
    const activeIcons = [
      Icons.home_filled,
      Icons.chat_bubble_rounded,
      Icons.calendar_month_rounded,
      Icons.person_rounded,
    ];

    final isDark = TemaFixi.esOscuro(context);
    final activeColor =
        isDark ? TemaFixi.azulFacebookDark : TemaFixi.azulFacebook;
    final inactiveColor = TemaFixi.colorSubtitulo(context);

    return Container(
      decoration: TemaFixi.decoracionBarraInferior(context),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(labels.length, (index) {
              final isActive = _selectedIndex == index;
              final color = isActive ? activeColor : inactiveColor;
              return Expanded(
                child: InkWell(
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
                          builder: (_) => const pantallaCalendarioCliente(),
                        ),
                      );
                    }
                    if (index == 3) {
                      _openPerfilActual();
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? activeIcons[index] : icons[index],
                        size: 22,
                        color: color,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
