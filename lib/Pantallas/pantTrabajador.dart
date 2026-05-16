import 'dart:async';

import 'package:flutter/material.dart';

import '../Servicios/servicioLlamadas.dart';
import '../Servicios/servicioPerfilFirebase.dart';
import '../Servicios/selectorArchivo.dart';
import '../Servicios/servicioAlmacenamiento.dart';
import '../Servicios/servicioCategorias.dart';
import '../Servicios/sesionService.dart';
import '../widgets/alcanceServicioLlamadas.dart';
import '../widgets/escuchaLlamadasEntrantes.dart';
import 'pantAjustes.dart';
import 'pantAuth.dart';
import 'pantCalendarioTrabajador.dart';
import 'pantLaboratorio.dart';
import 'navegacionChat.dart';
import 'pantMensajesTrabajador.dart';
import 'pantPortafolioTrabajador.dart';

class PantallaTrabajador extends StatefulWidget {
  const PantallaTrabajador({super.key});

  @override
  State<PantallaTrabajador> createState() => _PantallaTrabajadorState();
}

class _PantallaTrabajadorState extends State<PantallaTrabajador> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final SesionService _sesionService = SesionService();
  late final ServicioLlamadas _servicioLlamadas;
  bool _servicioLlamadasInicializada = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
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
          onTap: _promptCerrarSesion,
        ),
      ],
    );
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
  Widget build(BuildContext context) {
    return escuchaLlamadasEntrantes(
      child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Panel de control'),
            centerTitle: true,
            backgroundColor: const Color(0xFF7B1E3A),
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
          ),
          body: const WorkerProfileView(embedded: true),
          endDrawer: _settingsDrawer(),
          bottomNavigationBar: _buildBottomBar(),
        ),
    );
  }

  Widget _buildBottomBar() {
    const labels = ['Escritorio', 'Calendario', 'Mensajes', 'Portafolio', 'Mi cuenta'];
    const icons = [
      Icons.space_dashboard_outlined,
      Icons.calendar_month_outlined,
      Icons.message_outlined,
      Icons.work_outline,
      Icons.person_outline,
    ];

    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      height: 88,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                        MaterialPageRoute(builder: (_) => const PantallaCalendarioTrabajador()),
                      );
                    }
                    if (index == 2) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PantallaMensajesTrabajador()),
                      );
                    }
                    if (index == 3) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PantallaPortafolioTrabajador()),
                      );
                    }
                    if (index == 4) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PerfilTrabajadorBasicoView()),
                      );
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
                          style: TextStyle(color: color, fontSize: 11),
                          textAlign: TextAlign.center,
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
}

class WorkerProfileView extends StatefulWidget {
  /// Si se provee [initialData] se muestra ese perfil (modo lectura desde cliente).
  final Map<String, dynamic>? initialData;
  final bool readOnly;
  final bool embedded;

  const WorkerProfileView({
    super.key,
    this.initialData,
    this.readOnly = false,
    this.embedded = false,
  });

  @override
  State<WorkerProfileView> createState() => _WorkerProfileViewState();
}

class PerfilTrabajadorBasicoView extends StatefulWidget {
  const PerfilTrabajadorBasicoView({super.key});

  @override
  State<PerfilTrabajadorBasicoView> createState() => _PerfilTrabajadorBasicoViewState();
}

class _PerfilTrabajadorBasicoViewState extends State<PerfilTrabajadorBasicoView> {
  final ServicioPerfilFirebase _perfilService = ServicioPerfilFirebase();
  final ServicioCategorias _categoriasService = ServicioCategorias();
  final ServicioAlmacenamiento _almacenamiento = ServicioAlmacenamiento();
  late final Future<Map<String, dynamic>> _perfilFuture;
  late final Future<List<Categoria>> _categoriasFuture;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _subcategoriaController = TextEditingController();
  Categoria? _categoriaSeleccionada;
  String? _subcategoriaSeleccionada;
  bool _uploadingPhoto = false;
  bool _savingFields = false;
  bool _fieldsInitialized = false;
  Map<String, dynamic>? _perfilCache;

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

    final userId = (perfil['id'] ?? '').toString();
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
        _perfilCache = {
          ...(_perfilCache ?? perfil),
          'foto': url,
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir foto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _guardarPerfilBasico(Map<String, dynamic> perfil) async {
    final userId = (perfil['id'] ?? '').toString();
    if (userId.isEmpty) return;
    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();
    final categoria = _categoriaController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre requerido')),
      );
      return;
    }
    if (telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefono requerido')),
      );
      return;
    }
    if (categoria.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria requerida')),
      );
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
        _perfilCache = {
          ...(_perfilCache ?? perfil),
          ...fields,
        };
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
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
            onPressed: _uploadingPhoto ? null : () => _pickAndUploadPhoto(perfil),
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
            FutureBuilder<List<Categoria>>(
              future: _categoriasFuture,
              builder: (ctx, catSnapshot) {
                if (catSnapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final categorias = catSnapshot.data ?? [];
                if (categorias.isEmpty) {
                  return const Text('No hay categorias disponibles');
                }

                if (_categoriaSeleccionada == null && _categoriaController.text.isNotEmpty) {
                  Categoria? match;
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
                        _subcategoriaSeleccionada = match!.subcategorias.contains(_subcategoriaController.text)
                            ? _subcategoriaController.text
                            : null;
                      });
                    });
                  }
                }

                return Column(
                  children: [
                    DropdownButtonFormField<Categoria>(
                      initialValue: _categoriaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categorias
                          .map(
                            (c) => DropdownMenuItem<Categoria>(
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
                          .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
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

  Widget _buildDatosContacto(String email, String telefono, String direccion, String rol) {
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
            onPressed: _savingFields ? null : () => _guardarPerfilBasico(perfil),
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
      appBar: AppBar(title: const Text('Perfil')),
      body: FutureBuilder<Map<String, dynamic>>(
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
          final direccion = (perfil['direccion'] ?? 'Sin direccion').toString();
          final rol = (perfil['rol'] ?? 'trabajador').toString();
          final descripcion = (perfil['descripcion'] ?? 'Sin descripcion').toString();
          final categoria = (perfil['categoria'] ?? 'Sin categoria').toString();
          final subcategoria = (perfil['subcategoria'] ?? 'Sin subcategoria').toString();
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
    );
  }
}

class _WorkerProfileViewState extends State<WorkerProfileView> {
  final ServicioPerfilFirebase _perfilService = ServicioPerfilFirebase();
  late final Future<Map<String, dynamic>> _profileFuture;
  bool _initialized = false;
  bool _uploadingPhoto = false;
  bool _uploadingGallery = false;
  Map<String, dynamic> _profileData = {};
  List<String> _gallery = [];
  final ServicioAlmacenamiento _almacenamiento = ServicioAlmacenamiento();

  static const List<String> _fallbackGallery = [];

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

  List<String> _resolveGallery(dynamic raw) {
    if (raw is List) {
      final strings = raw.map((e) => e?.toString()).whereType<String>().where((s) => s.isNotEmpty).toList();
      if (strings.isNotEmpty) return strings;
    }
    return _fallbackGallery;
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
    final rating = double.tryParse((profile['calificacion'] ?? '4.0').toString()) ?? 4.0;
    final reviews = int.tryParse((profile['reseñas'] ?? profile['resenas'] ?? '100').toString()) ?? 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          GestureDetector(
            onTap: widget.readOnly || _uploadingPhoto ? null : _pickAndUploadPhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 62,
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: _uploadingPhoto
                      ? Container(
                          decoration: const BoxDecoration(
                            color: Color(0x88000000),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(color: Colors.white),
                        )
                      : (avatar.isEmpty ? const Icon(Icons.person, size: 44) : null),
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
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      children: const [
                        Text(
                          'Ingresos mensuales (MXN)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '0.00 MXN',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      children: const [
                        Text(
                          'Trabajos completados',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '0',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  _itemSolicitud('Pedro M', 'Fuga de agua en baño', clienteUid: null),
                  const Divider(height: 20),
                  _itemSolicitud('Laura G', 'Instalacion de luminaria en sala', clienteUid: null),
                  const Divider(height: 20),
                  _itemSolicitud('Carlos R', 'Revision de corto en cocina', clienteUid: null),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Galeria / chip mis trabajos
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Mis trabajos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildEditableGallery(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.settings_suggest_outlined, size: 18),
                      label: const Text('Gestionar servicios'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PantallaCalendarioTrabajador()),
                        );
                      },
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: const Text('Ver mi calendario'),
                    ),
                  ),
                ],
              ),
            ],
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
                        builder: (_) => PantallaMensajesTrabajador(
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

  Widget _buildEditableGallery() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (_gallery.isEmpty)
          Container(
            width: 150,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'Sin imagenes',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ..._gallery.asMap().entries.map((entry) {
          final idx = entry.key;
          final url = entry.value;
          return Stack(
            children: [
              Container(
                width: 150,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (!widget.readOnly)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeGalleryImage(idx),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xCC000000),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }),
        // Boton agregar (solo en modo propio)
        if (!widget.readOnly)
        GestureDetector(
          onTap: _uploadingGallery ? null : _addGalleryImage,
          child: Container(
            width: 150,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
              color: Colors.grey.shade100,
            ),
            child: _uploadingGallery
                ? const Center(child: CircularProgressIndicator())
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey),
                      SizedBox(height: 4),
                      Text('Agregar nuevo trabajo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _addGalleryImage() async {
    final file = await pickImageFile();
    if (file == null) return;

    setState(() => _uploadingGallery = true);
    try {
      final url = await _almacenamiento.uploadFile(
        bytes: file.bytes,
        filename: file.name,
        contentType: file.mimeType,
      );

      final updated = [..._gallery, url];
      setState(() => _gallery = updated);

      final userId = _profileData['id'] as String?;
      if (userId != null && userId.isNotEmpty) {
        await _perfilService.actualizarPerfil(userId, {'galeria': updated});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingGallery = false);
    }
  }

  Future<void> _removeGalleryImage(int index) async {
    final updated = [..._gallery]..removeAt(index);
    setState(() => _gallery = updated);

    final userId = _profileData['id'] as String?;
    if (userId != null && userId.isNotEmpty) {
      try {
        await _perfilService.actualizarPerfil(userId, {'galeria': updated});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar imagen: $e')),
          );
        }
      }
    }
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

      final userId = _profileData['id'] as String?;
      if (userId != null && userId.isNotEmpty) {
        await _perfilService.actualizarPerfil(userId, {'foto': url});
      }

      setState(() {
        _profileData['foto'] = url;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _initializeControllers(Map<String, dynamic> data) {
    _profileData = Map.from(data);
    _gallery = _resolveGallery(data['galeria']);
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
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.black,
      ),
      body: body,
    );
  }
}
