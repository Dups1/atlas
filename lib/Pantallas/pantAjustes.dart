import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../Servicios/autenticacionStorage.dart';
import '../Servicios/servicioPerfilApi.dart';
import '../Servicios/servicioUbicacion.dart';

class VistaCuenta extends StatefulWidget {
  const VistaCuenta({super.key});

  @override
  State<VistaCuenta> createState() => _VistaCuentaState();
}

class _VistaCuentaState extends State<VistaCuenta> {
  final AutenticacionStorage _storage = AutenticacionStorage();
  final ServicioPerfilApi _perfilApi = ServicioPerfilApi();
  late final Future<Map<String, dynamic>> _perfilFuture;

  @override
  void initState() {
    super.initState();
    _perfilFuture = () async {
      final token = await _storage.recuperarToken();
      if (token == null) throw Exception('Sesion no iniciada');
      return _perfilApi.fetchPerfil(token);
    }();
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

class VistaConfiguraciones extends StatefulWidget {
  const VistaConfiguraciones({super.key});

  @override
  State<VistaConfiguraciones> createState() => _VistaConfiguracionesState();
}

class _VistaConfiguracionesState extends State<VistaConfiguraciones> {
  final ServicioUbicacion _ubicacion = ServicioUbicacion();
  String _textoEstadoPermiso = 'Cargando...';
  String? _ultimaLectura;
  bool _cargandoPermiso = true;
  bool _solicitando = false;

  @override
  void initState() {
    super.initState();
    _refrescarEstadoPermiso();
  }

  Future<void> _refrescarEstadoPermiso() async {
    setState(() {
      _cargandoPermiso = true;
    });
    try {
      final p = await _ubicacion.permisoActual();
      if (!mounted) return;
      setState(() {
        _textoEstadoPermiso = _ubicacion.etiquetaPermiso(p);
        _cargandoPermiso = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _textoEstadoPermiso = 'Error al leer permiso: $e';
        _cargandoPermiso = false;
      });
    }
  }

  Future<void> _solicitarUbicacion() async {
    setState(() => _solicitando = true);
    try {
      final r = await _ubicacion.solicitarPermisoYPosicion();
      if (!mounted) return;
      await _refrescarEstadoPermiso();
      if (!mounted) return;
      if (r.ok && r.latitud != null && r.longitud != null) {
        setState(() {
          _ultimaLectura =
              'Lat ${r.latitud!.toStringAsFixed(5)}, lon ${r.longitud!.toStringAsFixed(5)}';
        });
      } else {
        setState(() => _ultimaLectura = null);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.mensaje)),
      );
      if (r.sugerirAbrirAjustesApp && mounted) {
        final abrir = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ajustes'),
            content: const Text(
              'Quieres abrir los ajustes de la app o del sistema para activar ubicacion?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Si, ajustes'),
              ),
            ],
          ),
        );
        if (abrir == true && mounted) {
          await _ubicacion.abrirAjustesApp();
        }
      }
    } finally {
      if (mounted) setState(() => _solicitando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuraciones')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tema', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Claro / Oscuro'),
          const SizedBox(height: 24),
          const Text('Ubicacion', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (kIsWeb)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Web: entra solo con http://localhost:PUERTO (origen seguro). Arranca con la config de VS Code "atlas web (localhost)" o scripts/runWebLocalhost.sh.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          Text(
            _cargandoPermiso ? '...' : _textoEstadoPermiso,
            style: const TextStyle(fontSize: 14),
          ),
          if (_ultimaLectura != null) ...[
            const SizedBox(height: 8),
            Text('Ultima lectura: $_ultimaLectura', style: const TextStyle(fontSize: 13)),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _solicitando ? null : _solicitarUbicacion,
            icon: _solicitando
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.location_on_outlined),
            label: Text(_solicitando ? 'Obteniendo...' : 'Solicitar permiso y ubicacion'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _cargandoPermiso ? null : _refrescarEstadoPermiso,
            child: const Text('Actualizar estado del permiso'),
          ),
          const SizedBox(height: 24),
          const Text('Informacion de red', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('WiFi: Atlas WiFi - Latencia 18 ms'),
        ],
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
