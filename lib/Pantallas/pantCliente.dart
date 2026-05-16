import 'dart:async';

import 'package:flutter/material.dart';

import '../Servicios/autenticacionStorage.dart';
import '../Servicios/servicioLlamadas.dart';
import '../Servicios/servicioPerfilApi.dart';
import '../Servicios/servicioTrabajadores.dart';
import '../Servicios/sesionService.dart';
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

class PantallaCliente extends StatefulWidget {
  const PantallaCliente({super.key});

  @override
  State<PantallaCliente> createState() => _PantallaClienteState();
}

class _PantallaClienteState extends State<PantallaCliente> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final SesionService _sesionService = SesionService();
  final ServicioTrabajadores _trabajadoresService = ServicioTrabajadores();
  final AutenticacionStorage _storage = AutenticacionStorage();
  final ServicioPerfilApi _perfilApi = ServicioPerfilApi();
  late final ServicioLlamadas _servicioLlamadas;
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

  Future<void> _promptCerrarSesion() async {
    final confirmed = await _sesionService.confirmarCerrarSesion(context);
    if (!confirmed) return;
    await _servicioLlamadas.terminarRecursos();
    await _sesionService.limpiarSesion();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PantallaAuth()),
      (route) => false,
    );
  }

  Widget _buildDrawerContent({required BuildContext context}) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        const ListTile(
          title: Text('Ajustes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Configuraciones'),
          subtitle: const Text('Tema y permisos'),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VistaConfiguraciones()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Acerca de'),
          subtitle: const Text('Redes sociales y version'),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VistaAcerca()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesion'),
          subtitle: const Text('Advertencia de salida'),
          onTap: _promptCerrarSesion,
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> w) {
    final nombre = w['nombre'] as String? ?? 'Sin nombre';
    final categoria = w['categoria'] as String? ?? '';
    final subcategoria = w['subcategoria'] as String? ?? '';
    final calificacion = double.tryParse((w['calificacion'] ?? '4.0').toString()) ?? 4.0;
    final foto = (w['foto'] as String?)?.trim() ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PantallaPerfilTrabajadorPublico(data: w)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                child: foto.isEmpty ? const Icon(Icons.person_outline) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (categoria.isNotEmpty)
                      Text(categoria,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    if (subcategoria.isNotEmpty)
                      Text(subcategoria,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(calificacion.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.message_outlined),
                onPressed: () {
                  final nombre = w['nombre'] as String? ?? 'Trabajador';
                  final uid = uidDesdeMapaUsuario(w);
                  if (uid.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Este perfil no tiene id de usuario')),
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
          appBar: AppBar(
            title: const Text('Explorar Atlas'),
            centerTitle: true,
            backgroundColor: Colors.black,
            actions: [
              IconButton(
                icon: const Icon(Icons.science),
                tooltip: 'Laboratorio',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PantallaLaboratorio()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(76),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _controller,
                  onChanged: _filter,
                  decoration: InputDecoration(
                    hintText: 'Busca por nombre o categoria',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _trabajadoresFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final data = snapshot.data ?? [];
              final trabajadores = data
                  .where((w) => (w['rol'] ?? '').toString().toLowerCase() == 'trabajador')
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
                  return const Center(child: Text('No hay trabajadores registrados'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trabajadores.length,
                  itemBuilder: (_, i) => _buildCard(trabajadores[i]),
                );
              }

              if (_filtered.isEmpty) {
                return const Center(child: Text('Sin resultados'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                itemBuilder: (_, i) => _buildCard(_filtered[i]),
              );
            },
          ),
          endDrawer: Drawer(
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

    return BottomAppBar(
      color: Colors.white,
      elevation: 6,
      height: 88,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(labels.length, (index) {
            final isActive = _selectedIndex == index;
            final color = isActive ? Theme.of(context).colorScheme.primary : Colors.grey;
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    if (index == 1) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PantallaMensajesCliente()),
                      );
                    }
                    if (index == 2) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PantallaReservaCliente()),
                      );
                    }
                    if (index == 3) {
                      _openPerfilActual();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icons[index], size: 22, color: color),
                        const SizedBox(height: 2),
                        Text(
                          labels[index],
                          style: TextStyle(color: color, fontSize: 12),
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
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WorkerProfileView()),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PerfilClienteView()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el perfil: $e')),
      );
    }
  }
}
