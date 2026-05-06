import 'package:flutter/material.dart';

import '../Servicios/servicio_laboratorio.dart';

class VistaCuenta extends StatefulWidget {
  const VistaCuenta({super.key});

  @override
  State<VistaCuenta> createState() => _VistaCuentaState();
}

class _VistaCuentaState extends State<VistaCuenta> {
  final ServicioLaboratorio _service = ServicioLaboratorio();
  late final Future<Map<String, dynamic>> _perfilFuture;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _service.obtenerPerfilActivo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _perfilFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final perfil = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nombre: ${perfil['nombre'] ?? '—'}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Correo: ${perfil['email'] ?? '—'}'),
                const SizedBox(height: 8),
                Text('Rol: ${perfil['rol'] ?? '—'}'),
                if (perfil['categoria'] != null) ...[
                  const SizedBox(height: 8),
                  Text('Categoría: ${perfil['categoria']}'),
                ],
                if (perfil['subcategoria'] != null) ...[
                  const SizedBox(height: 8),
                  Text('Subcategoría: ${perfil['subcategoria']}'),
                ],
              ],
            ),
          );
        },
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
