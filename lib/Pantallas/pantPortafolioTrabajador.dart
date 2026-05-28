import 'package:flutter/material.dart';

import '../Servicios/laboratorio/portafolioMockService.dart';

class pantallaPortafolioTrabajador extends StatelessWidget {
  pantallaPortafolioTrabajador({super.key});

  final portafolioMockService _service = portafolioMockService.instance;

  @override
  Widget build(BuildContext context) {
    final proyectos = _service.listarProyectos();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portafolio'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Proyectos destacados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link de portafolio copiado (mock)')),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Compartir'),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: proyectos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.83,
              ),
              itemBuilder: (_, i) {
                final p = proyectos[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => pantallaProyectoDetalle(proyecto: p),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            p.imagenDespues,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.categoria,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.fecha,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class pantallaProyectoDetalle extends StatelessWidget {
  final portafolioProyecto proyecto;

  const pantallaProyectoDetalle({super.key, required this.proyecto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(proyecto.titulo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Antes y despues', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _imagenCard('Antes', proyecto.imagenAntes)),
                const SizedBox(width: 10),
                Expanded(child: _imagenCard('Despues', proyecto.imagenDespues)),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proyecto.descripcion),
                    const SizedBox(height: 10),
                    Text('Materiales: ${proyecto.materiales}'),
                    const SizedBox(height: 6),
                    Text('Tiempo: ${proyecto.tiempo}'),
                    const SizedBox(height: 6),
                    Text('Costo: ${proyecto.costoRango}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagenCard(String label, String url) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Image.network(url, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
