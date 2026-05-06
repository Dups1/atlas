import 'package:flutter/material.dart';

import '../Servicios/perfil_service.dart';
import '../Servicios/servicio_laboratorio.dart';
import '../Servicios/sesion_service.dart';
import 'pantalla_ajustes.dart';
import 'pantalla_auth.dart';
import 'pantalla_laboratorio.dart';
import 'pantalla_perfil_cliente.dart';
import 'pantalla_trabajador.dart';

class PantallaCliente extends StatefulWidget {
  const PantallaCliente({super.key});

  @override
  State<PantallaCliente> createState() => _PantallaClienteState();
}

class _PantallaClienteState extends State<PantallaCliente> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final SesionService _sesionService = SesionService();
  final PerfilService _perfilService = PerfilService();
  final ServicioLaboratorio _labService = ServicioLaboratorio();

  late Future<List<Map<String, dynamic>>> _trabajadoresFuture;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  int _selectedIndex = 0;

  static const _fallbackImage =
      'https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&w=200&q=60';

  @override
  void initState() {
    super.initState();
    _trabajadoresFuture = _perfilService.fetchTrabajadores();
  }

  @override
  void dispose() {
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
    final foto = (w['foto'] as String?)?.isNotEmpty == true ? w['foto'] as String : _fallbackImage;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkerProfileView(initialData: w, readOnly: true),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: NetworkImage(foto),
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
                onPressed: () {},
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
          preferredSize: const Size.fromHeight(64),
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
      final perfil = await _labService.obtenerPerfilActivo();
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
