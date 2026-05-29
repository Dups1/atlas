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
    final rolNormalizado = rol.trim().toLowerCase();
    if (rolNormalizado == 'trabajador') {
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
      messenger.showSnackBar(SnackBar(content: Text('Error: $err')));
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

  InputDecoration _decoracionCampo({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.65),
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mostrarCategorias = !_modoLogin && _rolSeleccionado == 'trabajador';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFEFF3FB)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.blueGrey.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.055),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: scheme.primary,
                          size: 30,
                        ),
                      ),
                      Text(
                        'Fixi',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _modoLogin ? 'Inicia sesion' : 'Crea tu cuenta',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.blueGrey.withValues(alpha: 0.12),
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: _botonModo(
                                activo: _modoLogin,
                                label: 'Entrar',
                                onTap: () {
                                  if (!_modoLogin) {
                                    setState(() {
                                      _modoLogin = true;
                                      _categoriaSeleccionada = null;
                                      _subcategoriaSeleccionada = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: _botonModo(
                                activo: !_modoLogin,
                                label: 'Registrarme',
                                onTap: () {
                                  if (_modoLogin) {
                                    setState(() => _modoLogin = false);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (!_modoLogin) ...[
                        TextField(
                          controller: _nombreCtrl,
                          decoration: _decoracionCampo(
                            label: 'Nombre',
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _decoracionCampo(
                          label: 'Correo electronico',
                          icon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: _decoracionCampo(
                          label: 'Contrasena',
                          icon: Icons.lock_outline,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (!_modoLogin)
                        DropdownButtonFormField<String>(
                          key: ValueKey('rol-$_rolSeleccionado'),
                          initialValue: _rolSeleccionado,
                          decoration: _decoracionCampo(
                            label: 'Rol',
                            icon: Icons.badge_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'cliente',
                              child: Text('Cliente'),
                            ),
                            DropdownMenuItem(
                              value: 'trabajador',
                              child: Text('Trabajador'),
                            ),
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
                      if (!_modoLogin) const SizedBox(height: 18),
                      if (mostrarCategorias)
                        FutureBuilder<List<categoria>>(
                          future: _categoriasFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: SizedBox(
                                  height: 36,
                                  width: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                                    'categoria-${_categoriaSeleccionada?.id ?? ''}',
                                  ),
                                  initialValue: _categoriaSeleccionada,
                                  decoration: _decoracionCampo(
                                    label: 'Categoria',
                                    icon: Icons.category_outlined,
                                  ),
                                  items: categorias
                                      .map(
                                        (categoriaItem) => DropdownMenuItem(
                                          value: categoriaItem,
                                          child: Text(
                                            '${categoriaItem.emoji} ${categoriaItem.nombre}',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (categoriaSeleccionada) {
                                    setState(() {
                                      _categoriaSeleccionada =
                                          categoriaSeleccionada;
                                      _subcategoriaSeleccionada = null;
                                    });
                                  },
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  key: ValueKey(
                                    'subcategoria-${_subcategoriaSeleccionada ?? ''}',
                                  ),
                                  initialValue: _subcategoriaSeleccionada,
                                  decoration: _decoracionCampo(
                                    label: 'Subcategoria',
                                    icon: Icons.subdirectory_arrow_right,
                                  ),
                                  items:
                                      (_categoriaSeleccionada?.subcategorias ??
                                              [])
                                          .map(
                                            (subcategoria) => DropdownMenuItem(
                                              value: subcategoria,
                                              child: Text(subcategoria),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: _categoriaSeleccionada == null
                                      ? null
                                      : (value) => setState(
                                          () =>
                                              _subcategoriaSeleccionada = value,
                                        ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          },
                        ),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _continuar,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_modoLogin ? 'Entrar' : 'Registrarse'),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonModo({
    required bool activo,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: activo
                ? Theme.of(context).colorScheme.primary
                : Colors.blueGrey.shade700,
          ),
        ),
      ),
    );
  }
}
