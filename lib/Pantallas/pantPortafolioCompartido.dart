import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Config/temaFixi.dart';
import '../Servicios/laboratorio/portafolioMockService.dart';
import 'pantAuth.dart';
import 'pantPortafolioTrabajador.dart';

/// Pantalla pública accesible sin autenticación previa mediante enlace compartido
/// Ejemplo: https://nexo-4c322.web.app/?portafolio=UID_TRABAJADOR
class pantallaPortafolioCompartido extends StatefulWidget {
  final String trabajadorId;

  const pantallaPortafolioCompartido({
    super.key,
    required this.trabajadorId,
  });

  @override
  State<pantallaPortafolioCompartido> createState() =>
      _pantallaPortafolioCompartidoState();
}

class _pantallaPortafolioCompartidoState
    extends State<pantallaPortafolioCompartido> {
  bool _cargando = true;
  String? _error;
  Map<String, dynamic>? _perfilData;
  List<portafolioProyecto> _proyectos = [];

  @override
  void initState() {
    super.initState();
    _cargarPortafolioPublico();
  }

  Future<void> _cargarPortafolioPublico() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.trabajadorId)
          .get();

      if (!doc.exists || doc.data() == null) {
        setState(() {
          _error = 'No se encontró el portafolio de este trabajador.';
          _cargando = false;
        });
        return;
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      final List<portafolioProyecto> lista = [];
      final rawProyectos = data['proyectos'];
      if (rawProyectos is List && rawProyectos.isNotEmpty) {
        for (final item in rawProyectos) {
          if (item is Map) {
            lista.add(
              portafolioProyecto.fromMap(
                item.map((k, v) => MapEntry(k.toString(), v)),
              ),
            );
          }
        }
      }

      // Si no hay proyectos estructurados pero hay galería
      final rawGaleria = data['galeria'];
      if (lista.isEmpty && rawGaleria is List && rawGaleria.isNotEmpty) {
        for (int i = 0; i < rawGaleria.length; i++) {
          final url = rawGaleria[i]?.toString() ?? '';
          if (url.isNotEmpty) {
            lista.add(
              portafolioProyecto(
                id: 'galeria_$i',
                titulo: 'Trabajo realizado #${i + 1}',
                categoria: data['categoria']?.toString() ?? 'General',
                descripcion: 'Servicio completado profesionalmente.',
                imagenAntes: '',
                imagenDespues: url,
                materiales: '',
                tiempo: '',
                costoRango: '',
                fecha: 'Completado',
              ),
            );
          }
        }
      }

      setState(() {
        _perfilData = data;
        _proyectos = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el portafolio: $e';
        _cargando = false;
      });
    }
  }

  void _irALogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const pantallaAuth()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _perfilData?['nombre'] ?? 'Profesional';
    final categoria = _perfilData?['categoria'] ?? 'Oficio profesional';
    final foto = _perfilData?['foto']?.toString() ?? '';
    final calificacion = double.tryParse(
          (_perfilData?['calificacion'] ?? '4.8').toString(),
        ) ??
        4.8;

    return Scaffold(
      backgroundColor: TemaFixi.colorFondo(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: TemaFixi.colorBarraSuperior(context),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Fixi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Portafolio Público',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _irALogin,
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Entrar a Fixi'),
          ),
          const SizedBox(width: 8),
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
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_search_outlined,
                            size: 56,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _irALogin,
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Ir al inicio de Fixi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Banner de presentación del profesional
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: TemaFixi.decoracionTarjeta(
                            context,
                            radio: 18,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.15),
                                    backgroundImage: foto.isNotEmpty
                                        ? NetworkImage(foto)
                                        : null,
                                    child: foto.isEmpty
                                        ? const Icon(Icons.person, size: 32)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nombre,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          categoria,
                                          style: TextStyle(
                                            color:
                                                TemaFixi.colorSubtitulo(context),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          calificacion.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _irALogin,
                                icon: const Icon(Icons.handyman_outlined, size: 18),
                                label: Text(
                                  'Contratar o cotizar con $nombre',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Lista de proyectos
                      Expanded(
                        child: _proyectos.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    'Este profesional aún no ha subido trabajos a su portafolio.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: TemaFixi.colorSubtitulo(context),
                                    ),
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final ancho = constraints.maxWidth;
                                  final crossAxisCount = ancho >= 900
                                      ? 3
                                      : (ancho >= 560 ? 2 : 1);
                                  final childAspectRatio = ancho >= 900
                                      ? 0.95
                                      : (ancho >= 560 ? 0.84 : 1.2);

                                  return GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      8,
                                      14,
                                      20,
                                    ),
                                    itemCount: _proyectos.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: childAspectRatio,
                                    ),
                                    itemBuilder: (_, i) {
                                      final p = _proyectos[i];
                                      return _proyectoCardPublica(
                                        context: context,
                                        proyecto: p,
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _proyectoCardPublica({
    required BuildContext context,
    required portafolioProyecto proyecto,
  }) {
    final tieneImagen = proyecto.imagenDespues.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => pantallaProyectoDetalle(
                proyecto: proyecto,
                readOnly: true,
              ),
            ),
          );
        },
        child: Ink(
          decoration: TemaFixi.decoracionTarjeta(context, radio: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: tieneImagen
                          ? Image.network(
                              proyecto.imagenDespues,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: Icon(Icons.image_outlined, size: 36),
                              ),
                            ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          proyecto.categoria,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proyecto.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proyecto.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: TemaFixi.colorSubtitulo(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

