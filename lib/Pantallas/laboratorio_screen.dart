import 'package:flutter/material.dart';

import '../Servicios/file_selector.dart';
import '../Servicios/laboratorio_service.dart';

class LaboratorioScreen extends StatefulWidget {
  const LaboratorioScreen({super.key});

  @override
  State<LaboratorioScreen> createState() => _LaboratorioScreenState();
}

class _LaboratorioScreenState extends State<LaboratorioScreen> {
  final LaboratorioService _service = LaboratorioService();
  Future<List<LaboratorioEntry>>? _future;
  bool _isUploading = false;
  bool _checkingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadUploads();
  }

  void _loadUploads() {
    debugPrint('Laboratorio: cargando uploads');
    setState(() {
      _future = _service.fetchUploads();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratorio'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud),
            tooltip: 'Verificar backend',
            onPressed: _checkingStatus ? null : _checkBackendStatus,
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Subir imagen',
            onPressed: _isUploading ? null : _selectAndUpload,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _loadUploads,
          ),
        ],
      ),
      body: FutureBuilder<List<LaboratorioEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudieron cargar las imágenes', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUploads,
                      child: const Text('Intentar de nuevo'),
                    ),
                  ],
                ),
              ),
            );
          }

          final uploads = snapshot.data ?? [];
          debugPrint('Laboratorio: datos recibidos ${uploads.length}');
          if (uploads.isEmpty) {
            return const Center(child: Text('No hay imágenes en el laboratorio aún'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadUploads();
              await _future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: uploads.length,
              itemBuilder: (context, index) {
                final upload = uploads[index];
                debugPrint('Laboratorio: mostrar upload ${upload.id} -> ${upload.url}');
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (upload.url.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              upload.url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              upload.originalName ?? upload.key,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              upload.createdAt != null
                                  ? 'Subido el ${upload.createdAt!.toLocal()}'
                                  : 'Fecha de carga desconocida',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              upload.url,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectAndUpload() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isUploading = true);
    try {
      debugPrint('Laboratorio: iniciar seleccion de archivo');
      final selected = await pickImageFile();
      if (selected == null) return;
      debugPrint('Laboratorio: archivo seleccionado ${selected.name} (${selected.bytes.length} bytes)');
      await _service.uploadFile(
        bytes: selected.bytes,
        filename: selected.name,
        contentType: selected.mimeType,
      );
      debugPrint('Laboratorio: upload completado, solicitando refresco');
      _loadUploads();
      messenger.showSnackBar(
        const SnackBar(content: Text('Imagen subida correctamente')),
      );
    } catch (err) {
      debugPrint('Laboratorio: upload fallido $err');
      messenger.showSnackBar(
        SnackBar(content: Text('Error al subir: $err')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _checkBackendStatus() async {
    setState(() => _checkingStatus = true);
    debugPrint('Laboratorio: verificando estado del backend');
    final messenger = ScaffoldMessenger.of(context);
    try {
      final status = await _service.checkBackendStatus();
      debugPrint('Laboratorio: estado backend -> $status');
      messenger.showSnackBar(
        SnackBar(content: Text('Backend: $status')),
      );
    } catch (err) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error conectando al backend: $err')),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingStatus = false);
      }
    }
  }
}
