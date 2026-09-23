import 'dart:async';

import 'package:flutter/material.dart';

import '../Config/temaFixi.dart';
import '../Servicios/perfil/servicioPerfilFirebase.dart';
import '../Servicios/almacenamiento/selectorArchivo.dart';
import '../Servicios/almacenamiento/servicioAlmacenamiento.dart';
import '../Servicios/categorias/servicioCategorias.dart';
import '../Servicios/autenticacion/sesionService.dart';
import '../widgets/alcanceModoEnigma.dart';
import 'pantAjustes.dart';
import 'pantAuth.dart';
import 'pantCalendarioTrabajador.dart';
import 'navegacionChat.dart';
import 'pantMensajesTrabajador.dart';
import 'pantPortafolioTrabajador.dart';

class pantallaTrabajador extends StatefulWidget {
  const pantallaTrabajador({super.key});

  @override
  State<pantallaTrabajador> createState() => _pantallaTrabajadorState();
}

class _pantallaTrabajadorState extends State<pantallaTrabajador> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final sesionService _sesionService = sesionService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
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

  Widget _settingsDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: StatefulBuilder(
        builder: (context, _) {
          return _buildDrawerContent(context: context);
        },
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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TemaFixi.logoAppBar(context, height: 30),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TemaFixi.naranjaNexo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: TemaFixi.naranjaNexo,
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Pro',
                  style: TextStyle(
                    color: TemaFixi.naranjaNexo,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
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
          child: const workerProfileView(embedded: true),
        ),
        endDrawer: _settingsDrawer(),
        bottomNavigationBar: _buildBottomBar(),
      );
  }

  Widget _buildBottomBar() {
    const labels = [
      'Escritorio',
      'Calendario',
      'Mensajes',
      'Portafolio',
      'Mi cuenta',
    ];
    const icons = [
      Icons.space_dashboard_outlined,
      Icons.calendar_month_outlined,
      Icons.chat_bubble_outline_rounded,
      Icons.work_outline_rounded,
      Icons.person_outline_rounded,
    ];
    const activeIcons = [
      Icons.space_dashboard_rounded,
      Icons.calendar_month_rounded,
      Icons.chat_bubble_rounded,
      Icons.work_rounded,
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
                          builder: (_) =>
                              const pantallaCalendarioTrabajador(),
                        ),
                      );
                    }
                    if (index == 2) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const pantallaMensajesTrabajador(),
                        ),
                      );
                    }
                    if (index == 3) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => pantallaPortafolioTrabajador(),
                        ),
                      );
                    }
                    if (index == 4) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const perfilTrabajadorBasicoView(),
                        ),
                      );
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? activeIcons[index] : icons[index],
                        size: 21,
                        color: color,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: color,
                          fontSize: 10.5,
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
}

class workerProfileView extends StatefulWidget {
  /// Si se provee [initialData] se muestra ese perfil (modo lectura desde cliente).
  final Map<String, dynamic>? initialData;
  final bool readOnly;
  final bool embedded;

  const workerProfileView({
    super.key,
    this.initialData,
    this.readOnly = false,
    this.embedded = false,
  });

  @override
  State<workerProfileView> createState() => _workerProfileViewState();
}

class perfilTrabajadorBasicoView extends StatefulWidget {
  const perfilTrabajadorBasicoView({super.key});

  @override
  State<perfilTrabajadorBasicoView> createState() =>
      _perfilTrabajadorBasicoViewState();
}

class _perfilTrabajadorBasicoViewState
    extends State<perfilTrabajadorBasicoView> {
  final servicioPerfilFirebase _perfilService = servicioPerfilFirebase();
  final servicioCategorias _categoriasService = servicioCategorias();
  final servicioAlmacenamiento _almacenamiento = servicioAlmacenamiento();
  late final Future<Map<String, dynamic>> _perfilFuture;
  late final Future<List<categoria>> _categoriasFuture;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _subcategoriaController = TextEditingController();
  categoria? _categoriaSeleccionada;
  String? _subcategoriaSeleccionada;
  bool _uploadingPhoto = false;
  bool _savingFields = false;
  bool _fieldsInitialized = false;
  Map<String, dynamic>? _perfilCache;

  String _idPerfil(Map<String, dynamic> perfil) {
    final id = (perfil['id'] ?? perfil['uid'] ?? '').toString().trim();
    return id;
  }

  @override
  void initState() {
    super.initState();
    _perfilFuture = _perfilService.fetchPerfil();
    _categoriasFuture = _categoriasService.fetchCategorias();
  }

  Widget _linea(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _tituloSeccion(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _telefonoController.dispose();
    _categoriaController.dispose();
    _subcategoriaController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(Map<String, dynamic> perfil) async {
    final file = await pickImageFile();
    if (file == null) return;

    final userId = _idPerfil(perfil);
    if (userId.isEmpty) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _almacenamiento.uploadFile(
        bytes: file.bytes,
        filename: file.name,
        contentType: file.mimeType,
      );

      await _perfilService.actualizarPerfil(userId, {'foto': url});

      setState(() {
        _perfilCache = {...(_perfilCache ?? perfil), 'foto': url};
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir foto: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _guardarPerfilBasico(Map<String, dynamic> perfil) async {
    final userId = _idPerfil(perfil);
    if (userId.isEmpty) return;
    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();
    final categoria = _categoriaController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nombre requerido')));
      return;
    }
    if (telefono.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Telefono requerido')));
      return;
    }
    if (categoria.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Categoria requerida')));
      return;
    }

    setState(() => _savingFields = true);
    try {
      final fields = {
        'nombre': nombre,
        'descripcion': _descripcionController.text.trim(),
        'telefono': telefono,
        'categoria': categoria,
        'subcategoria': _subcategoriaController.text.trim(),
      };
      await _perfilService.actualizarPerfil(userId, fields);
      setState(() {
        _perfilCache = {...(_perfilCache ?? perfil), ...fields};
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cambios guardados')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _savingFields = false);
      }
    }
  }

  Widget _buildHeaderCard(Map<String, dynamic> perfil, String foto) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 54,
                backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                child: foto.isEmpty ? const Icon(Icons.person, size: 48) : null,
              ),
              if (_uploadingPhoto)
                Container(
                  width: 108,
                  height: 108,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x88000000),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _uploadingPhoto
                ? null
                : () => _pickAndUploadPhoto(perfil),
            icon: const Icon(Icons.image_outlined),
            label: const Text('Seleccionar otra imagen'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosProfesionales(Map<String, dynamic> perfil) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tituloSeccion('Datos profesionales'),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<categoria>>(
              future: _categoriasFuture,
              builder: (ctx, catSnapshot) {
                if (catSnapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final categorias = catSnapshot.data ?? [];
                if (categorias.isEmpty) {
                  return const Text('No hay categorias disponibles');
                }

                if (_categoriaSeleccionada == null &&
                    _categoriaController.text.isNotEmpty) {
                  categoria? match;
                  for (final c in categorias) {
                    if (c.nombre == _categoriaController.text) {
                      match = c;
                      break;
                    }
                  }
                  if (match != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        _categoriaSeleccionada = match;
                        _subcategoriaSeleccionada =
                            match!.subcategorias.contains(
                              _subcategoriaController.text,
                            )
                            ? _subcategoriaController.text
                            : null;
                      });
                    });
                  }
                }

                return Column(
                  children: [
                    DropdownButtonFormField<categoria>(
                      initialValue: _categoriaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categorias
                          .map(
                            (c) => DropdownMenuItem<categoria>(
                              value: c,
                              child: Text('${c.emoji} ${c.nombre}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoriaSeleccionada = value;
                          _subcategoriaSeleccionada = null;
                          _categoriaController.text = value?.nombre ?? '';
                          _subcategoriaController.text = '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _subcategoriaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Subcategoria',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.subdirectory_arrow_right),
                      ),
                      items: (_categoriaSeleccionada?.subcategorias ?? [])
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(s),
                            ),
                          )
                          .toList(),
                      onChanged: _categoriaSeleccionada == null
                          ? null
                          : (value) {
                              setState(() {
                                _subcategoriaSeleccionada = value;
                                _subcategoriaController.text = value ?? '';
                              });
                            },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripcion',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosContacto(
    String email,
    String telefono,
    String direccion,
    String rol,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tituloSeccion('Datos de contacto'),
            _linea('Correo', email, Icons.email_outlined),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Telefono',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _linea('Direccion', direccion, Icons.location_on_outlined),
            const SizedBox(height: 12),
            _linea('Rol', rol, Icons.badge_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildAcciones(Map<String, dynamic> perfil) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _savingFields
                ? null
                : () => _guardarPerfilBasico(perfil),
            icon: _savingFields
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_savingFields ? 'Guardando...' : 'Guardar cambios'),
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
        title: const Text('Perfil'),
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

            final perfil = _perfilCache ?? snapshot.data ?? {};
            _perfilCache ??= perfil;
            final nombre = (perfil['nombre'] ?? 'Sin nombre').toString();
            final email = (perfil['email'] ?? 'Sin correo').toString();
            final foto = (perfil['foto'] ?? '').toString();
            final telefono = (perfil['telefono'] ?? 'Sin telefono').toString();
            final direccion = (perfil['direccion'] ?? 'Sin direccion')
                .toString();
            final rol = (perfil['rol'] ?? 'trabajador').toString();
            final descripcion = (perfil['descripcion'] ?? 'Sin descripcion')
                .toString();
            final categoria = (perfil['categoria'] ?? 'Sin categoria')
                .toString();
            final subcategoria = (perfil['subcategoria'] ?? 'Sin subcategoria')
                .toString();
            if (!_fieldsInitialized) {
              _nombreController.text = nombre;
              _descripcionController.text = descripcion;
              _telefonoController.text = telefono;
              _categoriaController.text = categoria;
              _subcategoriaController.text = subcategoria;
              _fieldsInitialized = true;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(perfil, foto),
                  const SizedBox(height: 14),
                  _buildDatosProfesionales(perfil),
                  const SizedBox(height: 12),
                  _buildDatosContacto(email, telefono, direccion, rol),
                  const SizedBox(height: 12),
                  _buildAcciones(perfil),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _workerProfileViewState extends State<workerProfileView> {
  final servicioPerfilFirebase _perfilService = servicioPerfilFirebase();
  late final Future<Map<String, dynamic>> _profileFuture;
  bool _initialized = false;
  bool _uploadingPhoto = false;
  Map<String, dynamic> _profileData = {};
  final servicioAlmacenamiento _almacenamiento = servicioAlmacenamiento();

  String _idPerfilActivo() {
    final id = (_profileData['id'] ?? _profileData['uid'] ?? '')
        .toString()
        .trim();
    return id;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    _profileFuture = initial != null
        ? Future.value(initial)
        : _perfilService.fetchPerfil();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildRatingRow(double rating, int reviews) {
    final filled = rating.floor().clamp(0, 5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < filled ? Icons.star : Icons.star_outline,
              color: Colors.orange,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('reseñas: $reviews', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfile(Map<String, dynamic> data) {
    final profile = _profileData.isNotEmpty ? _profileData : data;
    if (!_initialized) {
      _initializeControllers(profile);
    }
    final avatar = profile['foto']?.toString().isNotEmpty == true
        ? profile['foto'] as String
        : '';
    final nombre = (profile['nombre'] ?? 'Samuel Ruiz').toString();
    final rating =
        double.tryParse((profile['calificacion'] ?? '4.0').toString()) ?? 4.0;
    final reviews =
        int.tryParse(
          (profile['reseñas'] ?? profile['resenas'] ?? '100').toString(),
        ) ??
        100;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          GestureDetector(
            onTap: widget.readOnly || _uploadingPhoto
                ? null
                : _pickAndUploadPhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 62,
                  backgroundImage: avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,
                  child: _uploadingPhoto
                      ? Container(
                          decoration: const BoxDecoration(
                            color: Color(0x88000000),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : (avatar.isEmpty
                            ? const Icon(Icons.person, size: 44)
                            : null),
                ),
                if (!_uploadingPhoto && !widget.readOnly)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            nombre,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Calificacion
          _buildRatingRow(rating, reviews),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      children: const [
                        Text(
                          'Ingresos mensuales (MXN)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '0.00 MXN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      children: const [
                        Text(
                          'Trabajos completados',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Solicitudes pendientes (0)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _itemSolicitud(
                    'Pedro M',
                    'Fuga de agua en baño',
                    clienteUid: null,
                  ),
                  const Divider(height: 20),
                  _itemSolicitud(
                    'Laura G',
                    'Instalacion de luminaria en sala',
                    clienteUid: null,
                  ),
                  const Divider(height: 20),
                  _itemSolicitud(
                    'Carlos R',
                    'Revision de corto en cocina',
                    clienteUid: null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemSolicitud(String cliente, String problema, {String? clienteUid}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.person_outline, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$cliente - $problema',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    final uid = clienteUid?.trim();
                    if (uid != null && uid.isNotEmpty) {
                      abrirChatTrabajadorConCliente(
                        context,
                        clienteUid: uid,
                        tituloMostrar: cliente,
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => pantallaMensajesTrabajador(
                          initialTabIndex: 1,
                          initialSearch: cliente,
                        ),
                      ),
                    );
                  },
                  child: const Text('Contactar con el cliente'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final file = await pickImageFile();
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _almacenamiento.uploadFile(
        bytes: file.bytes,
        filename: file.name,
        contentType: file.mimeType,
      );

      final userId = _idPerfilActivo();
      if (userId.isNotEmpty) {
        await _perfilService.actualizarPerfil(userId, {'foto': url});
      }

      setState(() {
        _profileData['foto'] = url;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _initializeControllers(Map<String, dynamic> data) {
    _profileData = Map.from(data);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('No se pudo cargar el perfil: ${snapshot.error}'),
          );
        }
        final data = snapshot.data ?? {};
        return _buildProfile(data);
      },
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: TemaFixi.colorFondo(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: TemaFixi.colorBarraSuperior(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('Perfil'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: TemaFixi.gradienteFondo(context),
          ),
        ),
        child: body,
      ),
    );
  }
}
