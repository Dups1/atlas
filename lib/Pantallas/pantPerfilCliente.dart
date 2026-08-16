import 'package:flutter/material.dart';

import '../Servicios/autenticacion/autenticacionStorage.dart';
import '../Servicios/almacenamiento/selectorArchivo.dart';
import '../Servicios/almacenamiento/servicioAlmacenamiento.dart';
import '../Servicios/perfil/servicioPerfilApi.dart';
import '../Servicios/perfil/servicioPerfilFirebase.dart';

class perfilClienteView extends StatefulWidget {
  const perfilClienteView({super.key});

  @override
  State<perfilClienteView> createState() => _perfilClienteViewState();
}

class _perfilClienteViewState extends State<perfilClienteView> {
  final autenticacionStorage _storage = autenticacionStorage();
  final servicioPerfilApi _perfilApi = servicioPerfilApi();
  final servicioAlmacenamiento _almacenamiento = servicioAlmacenamiento();
  final servicioPerfilFirebase _perfilFirebase = servicioPerfilFirebase();
  late final Future<Map<String, dynamic>> _perfilFuture;
  bool _uploadingPhoto = false;
  Map<String, dynamic>? _perfilCache;
  bool _savingFields = false;
  bool _fieldsInitialized = false;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

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
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil cliente')),
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
          final rol = (perfil['rol'] ?? 'cliente').toString();

          if (!_fieldsInitialized) {
            _nombreController.text = nombre;
            _telefonoController.text = telefono;
            _fieldsInitialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(foto, perfil),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _tituloSeccion('Datos de cliente'),
                        TextField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _tituloSeccion('Informacion adicional'),
                        _linea('Direccion', direccion, Icons.location_on_outlined),
                        const SizedBox(height: 12),
                        _linea('Rol', rol, Icons.badge_outlined),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
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
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _savingFields ? 'Guardando...' : 'Guardar cambios',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String foto, Map<String, dynamic> perfil) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
      ),
    );
  }

  Future<void> _guardarPerfilBasico(Map<String, dynamic> perfil) async {
    final userId = (perfil['id'] ?? '').toString();
    if (userId.isEmpty) return;

    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();

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

    setState(() => _savingFields = true);
    try {
      await _perfilFirebase.actualizarPerfil(
        userId,
        {'nombre': nombre, 'telefono': telefono},
      );
      setState(() {
        _perfilCache = {
          ...(_perfilCache ?? perfil),
          'nombre': nombre,
          'telefono': telefono,
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
      if (mounted) setState(() => _savingFields = false);
    }
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

      await _perfilFirebase.actualizarPerfil(userId, {'foto': url});

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
}
