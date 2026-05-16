class portafolioProyecto {
  final String id;
  final String titulo;
  final String categoria;
  final String descripcion;
  final String imagenAntes;
  final String imagenDespues;
  final String materiales;
  final String tiempo;
  final String costoRango;
  final String fecha;

  const portafolioProyecto({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.descripcion,
    required this.imagenAntes,
    required this.imagenDespues,
    required this.materiales,
    required this.tiempo,
    required this.costoRango,
    required this.fecha,
  });
}

class portafolioMockService {
  portafolioMockService._();
  static final portafolioMockService instance = portafolioMockService._();

  final List<portafolioProyecto> _proyectos = const [
    portafolioProyecto(
      id: 'p1',
      titulo: 'Reparacion fuga de agua',
      categoria: 'Plomeria',
      descripcion: 'Se reemplazo tramo danado y se corrigio presion de salida.',
      imagenAntes: 'https://images.unsplash.com/photo-1620625515031-4f2f48e9f95b?auto=format&fit=crop&w=900&q=60',
      imagenDespues: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?auto=format&fit=crop&w=900&q=60',
      materiales: 'Tuberia PVC, abrazaderas, sellador',
      tiempo: '3 horas',
      costoRango: 'MXN 900 - 1300',
      fecha: 'Abr 2026',
    ),
    portafolioProyecto(
      id: 'p2',
      titulo: 'Instalacion luminaria LED',
      categoria: 'Electricidad',
      descripcion: 'Cambio de luminaria y ajuste de cableado de techo.',
      imagenAntes: 'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=900&q=60',
      imagenDespues: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=900&q=60',
      materiales: 'Luminaria LED, cable THW, taquetes',
      tiempo: '2 horas',
      costoRango: 'MXN 700 - 1100',
      fecha: 'Mar 2026',
    ),
    portafolioProyecto(
      id: 'p3',
      titulo: 'Mantenimiento tablero',
      categoria: 'Electricidad',
      descripcion: 'Limpieza, etiquetado y sustitucion de termomagneticos.',
      imagenAntes: 'https://images.unsplash.com/photo-1558442086-8ea19f2f50bb?auto=format&fit=crop&w=900&q=60',
      imagenDespues: 'https://images.unsplash.com/photo-1581093458791-9d2f7f2b065c?auto=format&fit=crop&w=900&q=60',
      materiales: 'Breakers, etiquetas, terminales',
      tiempo: '4 horas',
      costoRango: 'MXN 1200 - 1800',
      fecha: 'Feb 2026',
    ),
  ];

  List<portafolioProyecto> listarProyectos() => [..._proyectos];
}
