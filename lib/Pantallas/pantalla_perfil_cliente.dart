import 'package:flutter/material.dart';

import '../Servicios/perfil_service.dart';
import '../Servicios/selector_archivo.dart';
import '../Servicios/servicio_laboratorio.dart';

class PerfilClienteView extends StatefulWidget {
  const PerfilClienteView({super.key});

  @override
  State<PerfilClienteView> createState() => _PerfilClienteViewState();
}

class _PerfilClienteViewState extends State<PerfilClienteView> {
  final ServicioLaboratorio _service = ServicioLaboratorio();
  final PerfilService _perfilService = PerfilService();
  late final Future<Map<String, dynamic>> _perfilFuture;
  bool _uploadingPhoto = false;
  Map<String, dynamic>? _perfilCache;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _service.obtenerPerfilActivo();
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _uploadingPhoto ? null : () => _pickAndUploadPhoto(perfil),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                          child: foto.isEmpty
                              ? const Icon(Icons.person, size: 48)
                              : null,
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
                          )
                        else
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
                ),
                const SizedBox(height: 16),
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _linea('Correo', email, Icons.email_outlined),
                        const SizedBox(height: 12),
                        _linea('Telefono', telefono, Icons.phone_outlined),
                        const SizedBox(height: 12),
                        _linea('Direccion', direccion, Icons.location_on_outlined),
                        const SizedBox(height: 12),
                        _linea('Rol', rol, Icons.badge_outlined),
                      ],
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

  Future<void> _pickAndUploadPhoto(Map<String, dynamic> perfil) async {
    final file = await pickImageFile();
    if (file == null) return;

    final userId = (perfil['id'] ?? '').toString();
    if (userId.isEmpty) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _service.uploadFile(
        bytes: file.bytes,
        filename: file.name,
        contentType: file.mimeType,
      );

      await _perfilService.updateProfile(userId, {'foto': url});

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
