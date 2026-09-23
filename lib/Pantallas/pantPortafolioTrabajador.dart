import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Config/temaFixi.dart';
import '../Servicios/almacenamiento/selectorArchivo.dart';
import '../Servicios/almacenamiento/servicioAlmacenamiento.dart';
import '../Servicios/laboratorio/portafolioMockService.dart';
import '../Servicios/perfil/servicioPerfilFirebase.dart';

class pantallaPortafolioTrabajador extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool readOnly;

  const pantallaPortafolioTrabajador({
    super.key,
    this.initialData,
    this.readOnly = false,
  });

  @override
  State<pantallaPortafolioTrabajador> createState() =>
      _pantallaPortafolioTrabajadorState();
}

class _pantallaPortafolioTrabajadorState
    extends State<pantallaPortafolioTrabajador> {
  final servicioPerfilFirebase _perfilService = servicioPerfilFirebase();
  final servicioAlmacenamiento _almacenamiento = servicioAlmacenamiento();

  bool _cargando = true;
  String? _error;
  String _userId = '';
  List<portafolioProyecto> _proyectos = [];
  List<String> _galeriaUrls = [];

  @override
  void initState() {
    super.initState();
    _cargarPortafolio();
  }

  Future<void> _cargarPortafolio() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = widget.initialData ?? await _perfilService.fetchPerfil();
      _userId = (data['id'] ?? data['uid'] ?? '').toString().trim();

      // Cargar proyectos existentes
      final rawProyectos = data['proyectos'];
      final List<portafolioProyecto> lista = [];

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

      // Galeria de imagenes
      final rawGaleria = data['galeria'];
      if (rawGaleria is List) {
        _galeriaUrls = rawGaleria
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }

      // Si no hay proyectos estructurados pero hay imagenes en galeria, generar proyectos basicos
      if (lista.isEmpty && _galeriaUrls.isNotEmpty) {
        for (int i = 0; i < _galeriaUrls.length; i++) {
          lista.add(
            portafolioProyecto(
              id: 'galeria_$i',
              titulo: 'Trabajo realizado #${i + 1}',
              categoria: data['categoria']?.toString() ?? 'General',
              descripcion: 'Servicio completado profesionalmente.',
              imagenAntes: '',
              imagenDespues: _galeriaUrls[i],
              materiales: 'Materiales incluidos',
              tiempo: 'Completado',
              costoRango: 'Consultar',
              fecha: 'Reciente',
            ),
          );
        }
      }

      setState(() {
        _proyectos = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _guardarEnFirestore() async {
    if (_userId.isEmpty) return;

    final proyectosMap = _proyectos.map((p) => p.toMap()).toList();
    final galeriaList = _proyectos
        .map((p) => p.imagenDespues)
        .where((url) => url.isNotEmpty)
        .toList();

    await _perfilService.actualizarPerfil(_userId, {
      'proyectos': proyectosMap,
      'galeria': galeriaList,
    });
  }

  Future<void> _eliminarProyecto(String id) async {
    final idx = _proyectos.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    final eliminado = _proyectos[idx];
    setState(() {
      _proyectos.removeAt(idx);
    });

    try {
      await _guardarEnFirestore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Proyecto "${eliminado.titulo}" eliminado.'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () async {
                setState(() => _proyectos.insert(idx, eliminado));
                await _guardarEnFirestore();
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _proyectos.insert(idx, eliminado));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar proyecto: $e')),
        );
      }
    }
  }

  void _abrirModalNuevoProyecto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModalNuevoProyecto(
        almacenamiento: _almacenamiento,
        onGuardar: (nuevoProyecto) async {
          setState(() {
            _proyectos.insert(0, nuevoProyecto);
          });
          await _guardarEnFirestore();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Trabajo agregado a tu portafolio exitosamente!'),
              ),
            );
          }
        },
      ),
    );
  }

  void _compartirPortafolio() {
    var id = _userId.trim();
    if (id.isEmpty) {
      id = FirebaseAuth.instance.currentUser?.uid ?? '';
    }

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guarda tu perfil primero para poder compartir tu portafolio.'),
        ),
      );
      return;
    }

    final baseUrl = Uri.base.origin.isNotEmpty && !Uri.base.origin.contains('localhost')
        ? 'https://nexo-4c322.web.app'
        : (Uri.base.origin.isNotEmpty ? Uri.base.origin : 'https://nexo-4c322.web.app');

    final link = '$baseUrl/?portafolio=$id';
    final texto =
        '¡Hola! Te invito a ver mi portafolio de trabajos en Fixi: $link';

    Clipboard.setData(ClipboardData(text: link));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Compartir Portafolio'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu enlace público fue copiado al portapapeles. Cualquier persona que lo abra podrá ver tus proyectos y fotos sin necesidad de iniciar sesión:',
              style: TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                link,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: texto));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mensaje de invitación copiado.')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar mensaje'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCategorias = _proyectos.map((p) => p.categoria).toSet().length;

    return Scaffold(
      backgroundColor: TemaFixi.colorFondo(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: TemaFixi.colorBarraSuperior(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('Mi Portafolio'),
      ),
      floatingActionButton: !widget.readOnly
          ? FloatingActionButton.extended(
              onPressed: _abrirModalNuevoProyecto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Nuevo trabajo'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error al cargar portafolio: $_error',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: _cargarPortafolio,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarPortafolio,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: TemaFixi.decoracionTarjeta(
                              context,
                              radio: 18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Proyectos destacados',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Muestra tus trabajos realizados para atraer más clientes.',
                                            style: TextStyle(
                                              color: TemaFixi.colorSubtitulo(
                                                context,
                                              ),
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    FilledButton.tonalIcon(
                                      onPressed: _compartirPortafolio,
                                      icon: const Icon(
                                        Icons.share_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Compartir'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _metricChip(
                                      context: context,
                                      icon: Icons.work_outline,
                                      label: '${_proyectos.length} trabajos',
                                    ),
                                    if (totalCategorias > 0)
                                      _metricChip(
                                        context: context,
                                        icon: Icons.category_outlined,
                                        label: '$totalCategorias categorias',
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: _proyectos.isEmpty
                              ? _estadoVacio(context)
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
                                        12,
                                        8,
                                        12,
                                        80,
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
                                        return _proyectoCard(
                                          context: context,
                                          proyecto: p,
                                          onEliminar: !widget.readOnly
                                              ? () => _eliminarProyecto(p.id)
                                              : null,
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _estadoVacio(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                size: 54,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes trabajos en tu portafolio',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sube fotos de tus mejores reparaciones e instalaciones para que los clientes conozcan la calidad de tu servicio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TemaFixi.colorSubtitulo(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            if (!widget.readOnly)
              FilledButton.icon(
                onPressed: _abrirModalNuevoProyecto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Subir mi primer trabajo'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: TemaFixi.colorTextoPrincipal(context),
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _proyectoCard({
    required BuildContext context,
    required portafolioProyecto proyecto,
    VoidCallback? onEliminar,
  }) {
    final tieneImagen = proyecto.imagenDespues.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => pantallaProyectoDetalle(
                proyecto: proyecto,
                readOnly: widget.readOnly,
                onEliminar: onEliminar,
              ),
            ),
          );
          if (result == true && onEliminar != null) {
            onEliminar();
          }
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
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 36,
                                  ),
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
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.42),
                            ],
                            stops: const [0.55, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: TemaFixi.esOscuro(context)
                              ? Colors.black.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          proyecto.categoria,
                          style: TextStyle(
                            color: TemaFixi.esOscuro(context)
                                ? Colors.white
                                : Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    if (onEliminar != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xCC000000),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 18,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            tooltip: 'Eliminar trabajo',
                            onPressed: () {
                              _confirmarEliminacion(context, onEliminar);
                            },
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
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Colors.blueGrey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            proyecto.fecha,
                            style: TextStyle(
                              color: TemaFixi.colorSubtitulo(context),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                      ],
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

  void _confirmarEliminacion(BuildContext context, VoidCallback onConfirmar) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar trabajo'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este trabajo de tu portafolio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirmar();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class pantallaProyectoDetalle extends StatelessWidget {
  final portafolioProyecto proyecto;
  final bool readOnly;
  final VoidCallback? onEliminar;

  const pantallaProyectoDetalle({
    super.key,
    required this.proyecto,
    this.readOnly = false,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final tieneAntes = proyecto.imagenAntes.isNotEmpty;

    return Scaffold(
      backgroundColor: TemaFixi.colorFondo(context),
      appBar: AppBar(
        title: Text(proyecto.titulo),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: TemaFixi.colorBarraSuperior(context),
        surfaceTintColor: Colors.transparent,
        actions: [
          if (!readOnly && onEliminar != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Eliminar trabajo',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar trabajo'),
                    content: const Text(
                      '¿Estás seguro de que deseas eliminar este trabajo de tu portafolio?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
              },
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tieneAntes)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: TemaFixi.decoracionTarjeta(context, radio: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Antes y después',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _imagenCard(
                              context,
                              'Antes',
                              proyecto.imagenAntes,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _imagenCard(
                              context,
                              'Después',
                              proyecto.imagenDespues,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else if (proyecto.imagenDespues.isNotEmpty)
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: TemaFixi.decoracionTarjeta(context, radio: 18),
                  child: Image.network(
                    proyecto.imagenDespues,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 160,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, size: 48),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                decoration: TemaFixi.decoracionTarjeta(context, radio: 18),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              proyecto.categoria,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            proyecto.fecha,
                            style: TextStyle(
                              color: TemaFixi.colorSubtitulo(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (proyecto.descripcion.isNotEmpty) ...[
                        Text(
                          proyecto.descripcion,
                          style: TextStyle(
                            color: TemaFixi.colorTextoPrincipal(context),
                            height: 1.35,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (proyecto.materiales.isNotEmpty) ...[
                        _detalleFila(
                          context: context,
                          icon: Icons.inventory_2_outlined,
                          label: 'Materiales',
                          value: proyecto.materiales,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (proyecto.tiempo.isNotEmpty) ...[
                        _detalleFila(
                          context: context,
                          icon: Icons.timelapse_outlined,
                          label: 'Tiempo',
                          value: proyecto.tiempo,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (proyecto.costoRango.isNotEmpty) ...[
                        _detalleFila(
                          context: context,
                          icon: Icons.payments_outlined,
                          label: 'Costo',
                          value: proyecto.costoRango,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagenCard(BuildContext context, String label, String url) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: TemaFixi.colorSuperficieSecundaria(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TemaFixi.colorBorde(context)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  label == 'Antes'
                      ? Icons.history_toggle_off
                      : Icons.auto_awesome,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalleFila({
    required BuildContext context,
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

class _ModalNuevoProyecto extends StatefulWidget {
  final servicioAlmacenamiento almacenamiento;
  final Future<void> Function(portafolioProyecto) onGuardar;

  const _ModalNuevoProyecto({
    required this.almacenamiento,
    required this.onGuardar,
  });

  @override
  State<_ModalNuevoProyecto> createState() => _ModalNuevoProyectoState();
}

class _ModalNuevoProyectoState extends State<_ModalNuevoProyecto> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _tiempoCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _materialesCtrl = TextEditingController();

  String _categoriaSeleccionada = 'Plomería';
  final List<String> _categorias = const [
    'Plomería',
    'Electricidad',
    'Carpintería',
    'Albañilería',
    'Pintura',
    'Limpieza',
    'Jardinería',
    'Herrería',
    'Cerrajería',
    'Mecánica',
    'Línea Blanca y Climas',
    'Fletes y Mudanzas',
    'Costura y Tapicería',
    'Cuidado Personal y Belleza',
    'Otro oficio',
  ];

  archivoSeleccionado? _fotoDespues;
  archivoSeleccionado? _fotoAntes;
  bool _subiendo = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _tiempoCtrl.dispose();
    _costoCtrl.dispose();
    _materialesCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto({required bool esAntes}) async {
    final file = await pickImageFile();
    if (file == null) return;
    setState(() {
      if (esAntes) {
        _fotoAntes = file;
      } else {
        _fotoDespues = file;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fotoDespues == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos la foto del trabajo realizado.'),
        ),
      );
      return;
    }

    setState(() => _subiendo = true);

    try {
      // Subir foto principal (después)
      final urlDespues = await widget.almacenamiento.uploadFile(
        bytes: _fotoDespues!.bytes,
        filename: _fotoDespues!.name,
        contentType: _fotoDespues!.mimeType,
      );

      // Subir foto previa si existe
      String urlAntes = '';
      if (_fotoAntes != null) {
        urlAntes = await widget.almacenamiento.uploadFile(
          bytes: _fotoAntes!.bytes,
          filename: _fotoAntes!.name,
          contentType: _fotoAntes!.mimeType,
        );
      }

      final meses = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      final ahora = DateTime.now();
      final fechaStr = '${meses[ahora.month - 1]} ${ahora.year}';

      final nuevo = portafolioProyecto(
        id: 'proy_${DateTime.now().millisecondsSinceEpoch}',
        titulo: _tituloCtrl.text.trim(),
        categoria: _categoriaSeleccionada,
        descripcion: _descripcionCtrl.text.trim(),
        imagenAntes: urlAntes,
        imagenDespues: urlDespues,
        materiales: _materialesCtrl.text.trim(),
        tiempo: _tiempoCtrl.text.trim(),
        costoRango: _costoCtrl.text.trim(),
        fecha: fechaStr,
      );

      await widget.onGuardar(nuevo);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir trabajo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _subiendo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TemaFixi.colorTarjetaSolida(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_photo_alternate_rounded, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Nuevo trabajo para portafolio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Selector de foto principal
              const Text(
                'Foto del trabajo terminado *',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              _previewOSelector(
                foto: _fotoDespues,
                label: 'Seleccionar foto de resultado',
                onTap: () => _seleccionarFoto(esAntes: false),
              ),
              const SizedBox(height: 14),
              // Foto antes (opcional)
              const Text(
                'Foto antes de iniciar (Opcional)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              _previewOSelector(
                foto: _fotoAntes,
                label: 'Seleccionar foto previa (Antes)',
                onTap: () => _seleccionarFoto(esAntes: true),
              ),
              const SizedBox(height: 16),
              // Título
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título del trabajo *',
                  hintText: 'Ej. Reparación de fuga y cambio de llaves',
                  prefixIcon: Icon(Icons.title_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Ingresa un título' : null,
              ),
              const SizedBox(height: 14),
              // Categoría
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Oficio / Categoría *',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _categoriaSeleccionada = val);
                },
              ),
              const SizedBox(height: 14),
              // Descripción
              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción del trabajo',
                  hintText: 'Explica qué se hizo, qué técnica se utilizó, etc.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tiempoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tiempo (Opcional)',
                        hintText: 'Ej. 3 horas',
                        prefixIcon: Icon(Icons.timer_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _costoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Costo aprox (Opcional)',
                        hintText: 'Ej. \$800 MXN',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _materialesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Materiales utilizados (Opcional)',
                  hintText: 'Ej. Tubo PVC 1/2", pegamento, codos',
                  prefixIcon: Icon(Icons.handyman_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _subiendo ? null : _guardar,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _subiendo
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Subiendo a la nube...'),
                        ],
                      )
                    : const Text(
                        'Publicar en mi portafolio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewOSelector({
    required archivoSeleccionado? foto,
    required String label,
    required VoidCallback onTap,
  }) {
    if (foto != null) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.memory(foto.bytes, fit: BoxFit.cover),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xCC000000),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                  onPressed: onTap,
                  tooltip: 'Cambiar imagen',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: TemaFixi.colorSuperficieSecundaria(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TemaFixi.colorBorde(context),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
