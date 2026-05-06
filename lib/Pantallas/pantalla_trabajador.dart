import 'package:flutter/material.dart';

import '../Servicios/perfil_service.dart';
import '../Servicios/selector_archivo.dart';
import '../Servicios/servicio_laboratorio.dart';
import '../Servicios/sesion_service.dart';
import 'pantalla_ajustes.dart';
import 'pantalla_auth.dart';
import 'pantalla_laboratorio.dart';

class PantallaTrabajador extends StatefulWidget {
  const PantallaTrabajador({super.key});

  @override
  State<PantallaTrabajador> createState() => _PantallaTrabajadorState();
}

class _PantallaTrabajadorState extends State<PantallaTrabajador> {
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
  final SesionService _sesionService = SesionService();

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
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WorkerProfileView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person),
                  label: const Text('Perfil'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkerProfileView extends StatefulWidget {
  /// Si se provee [initialData] se muestra ese perfil (modo lectura desde cliente).
  final Map<String, dynamic>? initialData;
  final bool readOnly;

  const WorkerProfileView({super.key, this.initialData, this.readOnly = false});

  @override
  State<WorkerProfileView> createState() => _WorkerProfileViewState();
}

class _WorkerProfileViewState extends State<WorkerProfileView> {
  final PerfilService _perfilService = PerfilService();
  late final Future<Map<String, dynamic>> _profileFuture;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subcategoryController = TextEditingController();
  bool _editing = false;
  bool _initialized = false;
  bool _uploadingPhoto = false;
  bool _uploadingGallery = false;
  Map<String, dynamic> _profileData = {};
  List<String> _gallery = [];
  final ServicioLaboratorio _labService = ServicioLaboratorio();
  late final Future<List<Categoria>> _categoriasFuture;
  Categoria? _categoriaSeleccionada;
  String? _subcategoriaSeleccionada;

  static const _fallbackGallery = [
    'https://images.unsplash.com/photo-1506784983877-45594efa4cbe?auto=format&fit=crop&w=320&q=60',
    'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=320&q=60',
    'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=320&q=60',
    'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=320&q=60',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    _profileFuture = initial != null
        ? Future.value(initial)
        : _perfilService.fetchProfile();
    _categoriasFuture = _labService.fetchCategorias();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _subcategoryController.dispose();
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
        : _fallbackGallery.first;
    final rating = double.tryParse((profile['calificacion'] ?? '4.0').toString()) ?? 4.0;
    final reviews = int.tryParse((profile['reseñas'] ?? profile['resenas'] ?? '100').toString()) ?? 100;
    final category = profile['categoria'] ?? 'Instalaciones';
    final subcategory = profile['subcategoria'] ?? 'Montaje IoT';
    final description = profile['descripcion'] ??
        'Samuel lleva 8 años realizando instalaciones residenciales y de pequeña industria. Su experiencia incluye cableado, calibración de sensores y soporte post-instalación.';

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
                  backgroundImage: NetworkImage(avatar),
                  child: _uploadingPhoto
                      ? Container(
                          decoration: const BoxDecoration(
                            color: Color(0x88000000),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(color: Colors.white),
                        )
                      : null,
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

          // Nombre (editable)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _editing
                ? TextField(
                    key: const ValueKey('name-edit'),
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(border: UnderlineInputBorder()),
                  )
                : Text(
                    key: ValueKey('name-view-${_nameController.text}'),
                    _nameController.text.isNotEmpty
                        ? _nameController.text
                        : profile['nombre'] ?? 'Samuel Ruiz',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 8),

          // Calificacion
          _buildRatingRow(rating, reviews),
          const SizedBox(height: 16),

          // Categoria / Subcategoria
          if (_editing)
            FutureBuilder<List<Categoria>>(
              future: _categoriasFuture,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  );
                }
                final categorias = snapshot.data ?? [];
                // Preseleccionar categoria/subcategoria si aun no se ha elegido una
                if (_categoriaSeleccionada == null && _categoryController.text.isNotEmpty) {
                  final match = categorias.where(
                    (c) => c.nombre == _categoryController.text,
                  ).firstOrNull;
                  if (match != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _categoriaSeleccionada = match;
                          _subcategoriaSeleccionada =
                              match.subcategorias.contains(_subcategoryController.text)
                                  ? _subcategoryController.text
                                  : null;
                        });
                      }
                    });
                  }
                }
                return Column(
                  children: [
                    DropdownButtonFormField<Categoria>(
                      key: ValueKey('cat-${_categoriaSeleccionada?.id ?? ''}'),
                      initialValue: _categoriaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categorias
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text('${c.emoji} ${c.nombre}'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _categoriaSeleccionada = val;
                          _subcategoriaSeleccionada = null;
                          _categoryController.text = val?.nombre ?? '';
                          _subcategoryController.text = '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('sub-${_subcategoriaSeleccionada ?? ''}'),
                      initialValue: _subcategoriaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Subcategoría',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.subdirectory_arrow_right),
                      ),
                      items: (_categoriaSeleccionada?.subcategorias ?? [])
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: _categoriaSeleccionada == null
                          ? null
                          : (val) {
                              setState(() {
                                _subcategoriaSeleccionada = val;
                                _subcategoryController.text = val ?? '';
                              });
                            },
                    ),
                  ],
                );
              },
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Categoría: $category',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Text('Subcategoría: $subcategory',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          const SizedBox(height: 16),

          // Descripcion (editable)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _editing
                ? TextField(
                    key: const ValueKey('description-edit'),
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Descripción',
                    ),
                  )
                : Text(
                    key: ValueKey('desc-view-${_descriptionController.text}'),
                    _descriptionController.text.isNotEmpty
                        ? _descriptionController.text
                        : description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
          const SizedBox(height: 20),

          // Boton editar / guardar
          if (!widget.readOnly)
          Align(
            alignment: Alignment.centerRight,
            child: _editing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _editing = false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => _saveProfile(),
                        child: const Text('Guardar'),
                      ),
                    ],
                  )
                : TextButton.icon(
                    onPressed: () => setState(() {
                      _editing = true;
                      _categoriaSeleccionada = null;
                      _subcategoriaSeleccionada = null;
                    }),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
          ),
          const SizedBox(height: 8),

          // Galeria / chip mis trabajos
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Chip(
                label: const Text('Mis trabajos'),
                backgroundColor: Colors.orange.shade100,
              ),
              const SizedBox(height: 16),
              _buildEditableGallery(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableGallery() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
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
                      Text('Agregar', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
      final url = await _labService.uploadFile(
        bytes: file.bytes,
        filename: file.name,
        contentType: file.mimeType,
      );

      final updated = [..._gallery, url];
      setState(() => _gallery = updated);

      final userId = _profileData['id'] as String?;
      if (userId != null && userId.isNotEmpty) {
        await _perfilService.updateProfile(userId, {'galeria': updated});
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
        await _perfilService.updateProfile(userId, {'galeria': updated});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar imagen: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    final userId = _profileData['id'] as String?;
    final fields = {
      'nombre': _nameController.text,
      'categoria': _categoryController.text,
      'subcategoria': _subcategoryController.text,
      'descripcion': _descriptionController.text,
    };

    setState(() {
      _profileData.addAll(fields);
      _editing = false;
    });

    if (userId == null || userId.isEmpty) return;

    try {
      await _perfilService.updateProfile(userId, fields);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final file = await pickImageFile();
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _labService.uploadFile(
        bytes: file.bytes,
        filename: file.name,
        contentType: file.mimeType,
      );

      final userId = _profileData['id'] as String?;
      if (userId != null && userId.isNotEmpty) {
        await _perfilService.updateProfile(userId, {'foto': url});
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
    _nameController.text = data['nombre'] ?? 'Samuel Ruiz';
    _categoryController.text = data['categoria'] ?? 'Instalaciones';
    _subcategoryController.text = data['subcategoria'] ?? 'Montaje IoT';
    _descriptionController.text = data['descripcion'] ??
        'Samuel lleva 8 años realizando instalaciones residenciales y de pequeña industria. '
            'Su experiencia incluye cableado, calibración de sensores y soporte post-instalación.';
    _gallery = _resolveGallery(data['galeria']);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
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
      ),
    );
  }
}
