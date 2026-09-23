import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../Config/controladorTema.dart';
import '../Config/temaFixi.dart';
import '../Servicios/autenticacion/autenticacionStorage.dart';
import '../Servicios/perfil/servicioPerfilApi.dart';
import '../Servicios/ubicacion/servicioUbicacion.dart';

class vistaCuenta extends StatefulWidget {
  const vistaCuenta({super.key});

  @override
  State<vistaCuenta> createState() => _vistaCuentaState();
}

class _vistaCuentaState extends State<vistaCuenta> {
  final autenticacionStorage _storage = autenticacionStorage();
  final servicioPerfilApi _perfilApi = servicioPerfilApi();
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
      backgroundColor: TemaFixi.colorFondo(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: TemaFixi.colorBarraSuperior(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('Cuenta'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: TemaFixi.gradienteFondo(context),
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _perfilFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final perfil = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              children: [
                _panelCard(
                  context: context,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.person_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        (perfil['nombre'] ?? '—').toString(),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (perfil['rol'] ?? '—').toString(),
                        style: TextStyle(color: Colors.blueGrey.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _panelCard(
                  context: context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Informacion de cuenta',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      _filaDato(
                        icon: Icons.badge_outlined,
                        label: 'Nombre',
                        value: (perfil['nombre'] ?? '—').toString(),
                      ),
                      const SizedBox(height: 8),
                      _filaDato(
                        icon: Icons.email_outlined,
                        label: 'Correo',
                        value: (perfil['email'] ?? '—').toString(),
                      ),
                      const SizedBox(height: 8),
                      _filaDato(
                        icon: Icons.verified_user_outlined,
                        label: 'Rol',
                        value: (perfil['rol'] ?? '—').toString(),
                      ),
                      if (perfil['categoria'] != null) ...[
                        const SizedBox(height: 8),
                        _filaDato(
                          icon: Icons.category_outlined,
                          label: 'Categoria',
                          value: perfil['categoria'].toString(),
                        ),
                      ],
                      if (perfil['subcategoria'] != null) ...[
                        const SizedBox(height: 8),
                        _filaDato(
                          icon: Icons.subdirectory_arrow_right,
                          label: 'Subcategoria',
                          value: perfil['subcategoria'].toString(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _panelCard({required BuildContext context, required Widget child}) {
    return Container(
      decoration: TemaFixi.decoracionTarjeta(context),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  Widget _filaDato({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: TemaFixi.colorSubtitulo(context)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: TemaFixi.colorTextoPrincipal(context),
                fontSize: 13.5,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class vistaConfiguraciones extends StatefulWidget {
  const vistaConfiguraciones({super.key});

  @override
  State<vistaConfiguraciones> createState() => _vistaConfiguracionesState();
}

class _vistaConfiguracionesState extends State<vistaConfiguraciones> {
  final servicioUbicacion _ubicacion = servicioUbicacion();
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
    setState(() => _cargandoPermiso = true);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(r.mensaje)));
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

  Widget _selectorTema(BuildContext context) {
    final modoActual = ControladorTema.instancia.modo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personaliza la apariencia de la aplicacion',
          style: TextStyle(
            fontSize: 13,
            color: TemaFixi.colorSubtitulo(context),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _opcionTema(
              context: context,
              icono: Icons.light_mode_outlined,
              titulo: 'Claro',
              seleccionado: modoActual == ThemeMode.light,
              onTap: () => ControladorTema.instancia.cambiarModo(ThemeMode.light),
            ),
            const SizedBox(width: 8),
            _opcionTema(
              context: context,
              icono: Icons.dark_mode_outlined,
              titulo: 'Oscuro',
              seleccionado: modoActual == ThemeMode.dark,
              onTap: () => ControladorTema.instancia.cambiarModo(ThemeMode.dark),
            ),
            const SizedBox(width: 8),
            _opcionTema(
              context: context,
              icono: Icons.brightness_auto_outlined,
              titulo: 'Sistema',
              seleccionado: modoActual == ThemeMode.system,
              onTap: () => ControladorTema.instancia.cambiarModo(ThemeMode.system),
            ),
          ],
        ),
      ],
    );
  }

  Widget _opcionTema({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    final primario = Theme.of(context).colorScheme.primary;
    final esOscuro = TemaFixi.esOscuro(context);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: seleccionado
                ? primario.withValues(alpha: esOscuro ? 0.22 : 0.12)
                : (esOscuro ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionado ? primario : TemaFixi.colorBorde(context),
              width: seleccionado ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icono,
                size: 22,
                color: seleccionado ? primario : TemaFixi.colorSubtitulo(context),
              ),
              const SizedBox(height: 6),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
                  color: seleccionado ? primario : TemaFixi.colorSubtitulo(context),
                ),
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
      backgroundColor: TemaFixi.colorFondo(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: TemaFixi.colorBarraSuperior(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('Configuraciones'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: TemaFixi.gradienteFondo(context),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          children: [
            _tarjetaSeccion(
              context: context,
              titulo: 'Tema',
              icon: Icons.palette_outlined,
              child: _selectorTema(context),
            ),
            const SizedBox(height: 12),
            _tarjetaSeccion(
              context: context,
              titulo: 'Ubicacion',
              icon: Icons.location_on_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (kIsWeb)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TemaFixi.colorSuperficieSecundaria(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: TemaFixi.colorBorde(context),
                        ),
                      ),
                      child: const Text(
                        'Web: entra solo con http://localhost:PUERTO (origen seguro). Arranca con la config de VS Code "Fixi web (localhost)" o scripts/runWebLocalhost.sh.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  Text(
                    _cargandoPermiso ? '...' : _textoEstadoPermiso,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (_ultimaLectura != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ultima lectura: $_ultimaLectura',
                      style: TextStyle(
                        fontSize: 13,
                        color: TemaFixi.colorSubtitulo(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _solicitando ? null : _solicitarUbicacion,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    icon: _solicitando
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.location_searching_outlined),
                    label: Text(
                      _solicitando
                          ? 'Obteniendo...'
                          : 'Solicitar permiso y ubicacion',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _cargandoPermiso
                        ? null
                        : _refrescarEstadoPermiso,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar estado del permiso'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _tarjetaSeccion(
              context: context,
              titulo: 'Informacion de red',
              icon: Icons.wifi_tethering_outlined,
              child: Text(
                'WiFi: Fixi WiFi - Latencia 18 ms',
                style: TextStyle(color: TemaFixi.colorSubtitulo(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaSeccion({
    required BuildContext context,
    required String titulo,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: TemaFixi.decoracionTarjeta(context),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class vistaAcerca extends StatelessWidget {
  const vistaAcerca({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaFixi.colorFondo(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: TemaFixi.colorBarraSuperior(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('Acerca de'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: TemaFixi.gradienteFondo(context),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(18),
              decoration: TemaFixi.decoracionTarjeta(context, radio: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.explore_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Fixi 2026',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Conecta clientes y trabajadores de forma inteligente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TemaFixi.colorSubtitulo(context)),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: const [
                      _iconoAcerca(icon: Icons.facebook),
                      _iconoAcerca(icon: Icons.public),
                      _iconoAcerca(icon: Icons.message_outlined),
                      _iconoAcerca(icon: Icons.mail_outline),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _iconoAcerca extends StatelessWidget {
  const _iconoAcerca({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}
