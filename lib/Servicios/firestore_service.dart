import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> injectExamples() async {
    final collection = _firestore.collection('atlas_samples');
    final batch = _firestore.batch();

    final samples = [
      {
        'nombre': 'Atlas Cliente',
        'categoria': 'app',
        'activo': true,
        'caracteristicas': ['rastreo', 'alertas', 'analisis'],
        'meta': {'version': '0.1', 'region': 'global'},
        'creado': FieldValue.serverTimestamp(),
      },
      {
        'nombre': 'Modulo Energia',
        'categoria': 'iot',
        'activo': false,
        'caracteristicas': ['sensores', 'reportes'],
        'meta': {'version': '0.9', 'region': 'costa', 'prioridad': 'alta'},
        'creado': FieldValue.serverTimestamp(),
      },
      {
        'nombre': 'Equipo Atlas',
        'categoria': 'infra',
        'activo': true,
        'caracteristicas': ['deploy', 'monitoreo'],
        'meta': {'version': '1.2', 'region': 'alta'},
        'creado': FieldValue.serverTimestamp(),
      },
    ];

    for (final sample in samples) {
      final doc = collection.doc();
      batch.set(doc, sample);
    }

    await batch.commit();

    return 'Documentos guardados';
  }
}
