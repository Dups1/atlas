import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados persistidos en Firestore (valores en ingles por convencion Agora/backend).
enum EstadoLlamadaFirebase {
  timbrando('ringing'),
  aceptada('accepted'),
  rechazada('rejected'),
  finalizada('ended'),
  perdida('missed'),
  ocupado('busy');

  const EstadoLlamadaFirebase(this.claveFirestore);
  final String claveFirestore;

  static EstadoLlamadaFirebase? desdeCadena(String? s) {
    if (s == null || s.isEmpty) return null;
    for (final e in EstadoLlamadaFirebase.values) {
      if (e.claveFirestore == s) return e;
    }
    return null;
  }
}

/// Modelo de documento `llamadas/{id}` para senalizacion y sincronizacion.
class llamadaModelo {
  final String idLlamada;
  final String idEmisor;
  final String idReceptor;
  final String canal;
  final EstadoLlamadaFirebase? estado;
  final DateTime? fecha;
  final bool activa;
  final String? nombreEmisor;
  final String? nombreReceptor;

  const llamadaModelo({
    required this.idLlamada,
    required this.idEmisor,
    required this.idReceptor,
    required this.canal,
    this.estado,
    this.fecha,
    this.activa = true,
    this.nombreEmisor,
    this.nombreReceptor,
  });

  Map<String, dynamic> aMapaCreacion() {
    final ahora = FieldValue.serverTimestamp();
    return {
      'idLlamada': idLlamada,
      'idEmisor': idEmisor,
      'idReceptor': idReceptor,
      'canal': canal,
      'estado': (estado ?? EstadoLlamadaFirebase.timbrando).claveFirestore,
      'fecha': ahora,
      'activa': activa,
      if (nombreEmisor != null) 'nombreEmisor': nombreEmisor,
      if (nombreReceptor != null) 'nombreReceptor': nombreReceptor,
    };
  }

  factory llamadaModelo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return llamadaModelo(
      idLlamada: (m['idLlamada'] as String?) ?? d.id,
      idEmisor: (m['idEmisor'] as String?) ?? '',
      idReceptor: (m['idReceptor'] as String?) ?? '',
      canal: (m['canal'] as String?) ?? '',
      estado: EstadoLlamadaFirebase.desdeCadena(m['estado'] as String?),
      fecha: _fechaDesdeCampo(m['fecha']),
      activa: m['activa'] as bool? ?? true,
      nombreEmisor: m['nombreEmisor'] as String?,
      nombreReceptor: m['nombreReceptor'] as String?,
    );
  }

  static DateTime? _fechaDesdeCampo(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  llamadaModelo copiarCon({
    EstadoLlamadaFirebase? estado,
    bool? activa,
    String? nombreEmisor,
    String? nombreReceptor,
  }) {
    return llamadaModelo(
      idLlamada: idLlamada,
      idEmisor: idEmisor,
      idReceptor: idReceptor,
      canal: canal,
      estado: estado ?? this.estado,
      fecha: fecha,
      activa: activa ?? this.activa,
      nombreEmisor: nombreEmisor ?? this.nombreEmisor,
      nombreReceptor: nombreReceptor ?? this.nombreReceptor,
    );
  }
}
