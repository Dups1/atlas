import 'package:flutter/material.dart';

import 'pantalla_laboratorio.dart';

class PantallaExplorar extends StatefulWidget {
  const PantallaExplorar({super.key});

  @override
  State<PantallaExplorar> createState() => _PantallaExplorarState();
}

class _PantallaExplorarState extends State<PantallaExplorar> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _locations = const [
    {
      'nombre': 'Mirador Atlas',
      'calificacion': 4.8,
      'distancia': 1.2,
      'unidad': 'km',
      'imagen':
          'https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&w=200&q=60',
    },
    {
      'nombre': 'Café Horizonte',
      'calificacion': 4.3,
      'distancia': 420,
      'unidad': 'm',
      'imagen':
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=200&q=60',
    },
    {
      'nombre': 'Galería Naranja',
      'calificacion': 4.6,
      'distancia': 2.4,
      'unidad': 'km',
      'imagen':
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=200&q=60',
    },
    {
      'nombre': 'Centro Eco',
      'calificacion': 4.9,
      'distancia': 820,
      'unidad': 'm',
      'imagen':
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=200&q=60',
    },
  ];
  List<Map<String, dynamic>> _filtered = const [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_locations);
  }

  void _filterPlaces(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filtered = _locations
          .where((place) => place['nombre'].toString().toLowerCase().contains(lower))
          .toList();
    });
  }

  Widget _buildDrawerContent({required BuildContext context}) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        const ListTile(
          title: Text('Ajustes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Cuenta'),
          subtitle: const Text('Datos personales y perfil'),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VistaCuenta()));
          },
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
          subtitle: const Text('Redes sociales y versión'),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VistaAcerca()));
          },
        ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              subtitle: const Text('Advertencia de salida'),
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Seguro que quieres cerrar sesión? Perderás la conexión actual y no podrás revertirlo.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
                      ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cerrar sesión')),
                    ],
                  ),
                );
              },
            ),
      ],
    );
  }

  Widget _settingsDrawer() {
    return Drawer(
      child: StatefulBuilder(
        builder: (context, _) {
          return _buildDrawerContent(context: context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              onChanged: _filterPlaces,
              decoration: InputDecoration(
                hintText: 'Busca por nombre',
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final place = _filtered[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black12,
                      image: DecorationImage(
                        image: NetworkImage(place['imagen'] as String),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['nombre'] as String,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 18, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text('${place['calificacion']}'),
                            const SizedBox(width: 18),
                            const Icon(Icons.place, size: 18),
                            const SizedBox(width: 4),
                            Text('${place['distancia']} ${place['unidad']}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.message),
                    onPressed: () {
                      // Placeholder action
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      endDrawer: _settingsDrawer(),
    );
  }
}

class VistaCuenta extends StatelessWidget {
  const VistaCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: Laura Ruiz', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Edad: 32 años'),
            SizedBox(height: 8),
            Text('Correo: laura@atlas.com'),
            SizedBox(height: 8),
            Text('Rol: Coordinadora de campo'),
          ],
        ),
      ),
    );
  }
}

class VistaConfiguraciones extends StatelessWidget {
  const VistaConfiguraciones({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuraciones')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tema', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Claro / Oscuro'),
            SizedBox(height: 16),
            Text('Permiso de ubicacion', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Permitido (precisión alta)'),
            SizedBox(height: 16),
            Text('Informacion de red', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('WiFi: Atlas WiFi - Latencia 18 ms'),
          ],
        ),
      ),
    );
  }
}

class VistaAcerca extends StatelessWidget {
  const VistaAcerca({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Atlas 2026', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Icon(Icons.facebook),
            SizedBox(height: 8),
            Icon(Icons.public),
            SizedBox(height: 8),
            Icon(Icons.message),
            SizedBox(height: 8),
            Icon(Icons.mail),
          ],
        ),
      ),
    );
  }
}
