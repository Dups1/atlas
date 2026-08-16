import 'package:flutter/material.dart';

import '../Servicios/autenticacion/authService.dart';
import '../Servicios/categorias/servicioCategorias.dart';
import 'pantCliente.dart';
import 'pantTrabajador.dart';

class pantallaAuth extends StatefulWidget {
  const pantallaAuth({super.key});

  @override
  State<pantallaAuth> createState() => _pantallaAuthState();
}

class _pantallaAuthState extends State<pantallaAuth> {
  bool _modoLogin = true;
  String _rolSeleccionado = 'cliente';
  bool _isSubmitting = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  final servicioCategorias _categoriasService = servicioCategorias();
  Future<List<categoria>>? _categoriasFuture;
  categoria? _categoriaSeleccionada;
  String? _subcategoriaSeleccionada;
  late final autenticacionService _authService;

  void _continuar() {
    _handleAuth();
  }

  void _navegarSegunRol(String rol) {
    if (rol == 'trabajador') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const pantallaTrabajador()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const pantallaCliente()),
      );
    }
  }

  Future<void> _handleAuth() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (!_modoLogin && _nombreCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nombre es obligatorio')),
      );
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Correo y contraseña son obligatorios')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final rol = await (_modoLogin
          ? _authService.login(email: email, password: password)
          : _authService.register(
              email: email,
              password: password,
              rol: _rolSeleccionado,
              categoria: _categoriaSeleccionada?.nombre,
              subcategoria: _subcategoriaSeleccionada,
              nombre: _nombreCtrl.text.trim(),
              descripcion: _descripcionCtrl.text.trim().isEmpty
                  ? null
                  : _descripcionCtrl.text.trim(),
            ));
      _navegarSegunRol(rol);
    } catch (err) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $err')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _authService = autenticacionService();
    _categoriasFuture = _categoriasService.fetchCategorias();
    _restaurarSesion();
  }

  Future<void> _restaurarSesion() async {
    try {
      final rol = await _authService.restoreSession();
      if (rol == null) return;
      _navegarSegunRol(rol);
    } catch (_) {
      await _authService.limpiarToken();
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mostrarCategorias =
        !_modoLogin && _rolSeleccionado == 'trabajador';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Atlas',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _modoLogin ? 'Inicia sesion' : 'Crea tu cuenta',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 32),

                if (!_modoLogin) ...[
                  TextField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electronico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contrasena',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),

                if (!_modoLogin)
                  DropdownButtonFormField<String>(
                    key: ValueKey('rol-$_rolSeleccionado'),
                    initialValue: _rolSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                      DropdownMenuItem(
                          value: 'trabajador', child: Text('Trabajador')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _rolSeleccionado = val;
                          if (val == 'cliente') {
                            _categoriaSeleccionada = null;
                            _subcategoriaSeleccionada = null;
                          }
                        });
                      }
                    },
                  ),
                if (!_modoLogin) const SizedBox(height: 24),

                if (mostrarCategorias)
                  FutureBuilder<List<categoria>>(
                    future: _categoriasFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: SizedBox(
                            height: 36,
                            width: 36,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Text(
                          'No se pudieron cargar las categorias',
                          textAlign: TextAlign.center,
                        );
                      }
                      final categorias = snapshot.data ?? [];
                      if (categorias.isEmpty) {
                        return const Text(
                          'No hay categorias disponibles',
                          textAlign: TextAlign.center,
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<categoria>(
                            key: ValueKey(
                                'categoria-${_categoriaSeleccionada?.id ?? ''}'),
                            initialValue: _categoriaSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: categorias
                                .map(
                                  (categoriaItem) => DropdownMenuItem(
                                    value: categoriaItem,
                                    child: Text('${categoriaItem.emoji} ${categoriaItem.nombre}'),
                                  ),
                                )
                                .toList(),
                            onChanged: (categoriaSeleccionada) {
                              setState(() {
                                _categoriaSeleccionada = categoriaSeleccionada;
                                _subcategoriaSeleccionada = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            key: ValueKey(
                                'subcategoria-${_subcategoriaSeleccionada ?? ''}'),
                            initialValue: _subcategoriaSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Subcategoria',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.subdirectory_arrow_right),
                            ),
                            items: (_categoriaSeleccionada?.subcategorias ?? [])
                                .map(
                                  (subcategoria) => DropdownMenuItem(
                                    value: subcategoria,
                                    child: Text(subcategoria),
                                  ),
                                )
                                .toList(),
                            onChanged: _categoriaSeleccionada == null
                                ? null
                                : (value) =>
                                    setState(() => _subcategoriaSeleccionada = value),
                          ),
                        ],
                      );
                    },
                  ),

                FilledButton(
                  onPressed: _isSubmitting ? null : _continuar,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_modoLogin ? 'Entrar' : 'Registrarse'),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => setState(() {
                    _modoLogin = !_modoLogin;
                    if (_modoLogin) {
                      _categoriaSeleccionada = null;
                      _subcategoriaSeleccionada = null;
                    }
                  }),
                  child: Text(
                    _modoLogin
                        ? '¿No tienes cuenta? Registrate'
                        : '¿Ya tienes cuenta? Inicia sesion',
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
