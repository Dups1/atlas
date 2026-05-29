import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum TipoEventoCalendario { servicio, bloqueo }

enum EstadoEventoCalendario {
  pendiente,
  confirmado,
  enCurso,
  completado,
  cancelado,
}

class eventoCalendario {
  final String id;
  final String titulo;
  final String cliente;
  final DateTime inicio;
  final DateTime fin;
  final TipoEventoCalendario tipo;
  final EstadoEventoCalendario estado;
  final String notas;
  final bool eliminado;

  const eventoCalendario({
    required this.id,
    required this.titulo,
    required this.cliente,
    required this.inicio,
    required this.fin,
    required this.tipo,
    required this.estado,
    required this.notas,
    this.eliminado = false,
  });

  Duration get duracion => fin.difference(inicio);

  String get duracionFormateada {
    final total = duracion.inMinutes;
    final horas = total ~/ 60;
    final mins = total % 60;
    if (horas == 0) return '${mins}min';
    if (mins == 0) return '${horas}h';
    return '${horas}h ${mins}min';
  }

  bool get estaActivo =>
      !eliminado && estado != EstadoEventoCalendario.cancelado;

  eventoCalendario copyWith({
    String? id,
    String? titulo,
    String? cliente,
    DateTime? inicio,
    DateTime? fin,
    TipoEventoCalendario? tipo,
    EstadoEventoCalendario? estado,
    String? notas,
    bool? eliminado,
  }) {
    return eventoCalendario(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      cliente: cliente ?? this.cliente,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      eliminado: eliminado ?? this.eliminado,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'cliente': cliente,
      'inicio': Timestamp.fromDate(inicio),
      'fin': Timestamp.fromDate(fin),
      'tipo': tipo.name,
      'estado': estado.name,
      'notas': notas,
      'eliminado': eliminado,
    };
  }

  factory eventoCalendario.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return eventoCalendario(
      id: doc.id,
      titulo: d['titulo'] as String? ?? '',
      cliente: d['cliente'] as String? ?? '-',
      inicio: (d['inicio'] as Timestamp).toDate(),
      fin: (d['fin'] as Timestamp).toDate(),
      tipo: TipoEventoCalendario.values.firstWhere(
        (e) => e.name == d['tipo'],
        orElse: () => TipoEventoCalendario.servicio,
      ),
      estado: EstadoEventoCalendario.values.firstWhere(
        (e) => e.name == d['estado'],
        orElse: () => EstadoEventoCalendario.pendiente,
      ),
      notas: d['notas'] as String? ?? '',
      eliminado: d['eliminado'] as bool? ?? false,
    );
  }
}

class ErrorCalendario implements Exception {
  final String mensaje;
  ErrorCalendario(this.mensaje);
  @override
  String toString() => mensaje;
}

class calendarioService {
  final FirebaseFirestore _db;
  List<eventoCalendario> _cache = [];
  bool _cargado = false;

  calendarioService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('usuarios').doc(uid).collection('eventos');
  }

  // ── Carga inicial ──────────────────────────────────────────

  Future<void> cargar() async {
    final col = _col;
    if (col == null) throw ErrorCalendario('No hay sesion activa');
    final snap = await col.where('eliminado', isEqualTo: false).get();
    _cache = snap.docs.map((d) => eventoCalendario.fromFirestore(d)).toList();
    _cargado = true;
  }

  // Recarga desde Firestore (util para refrescar manualmente)
  Future<void> recargar() async {
    _cargado = false;
    await cargar();
  }

  bool get estaCargado => _cargado;

  // ── Consultas (sobre cache local) ──────────────────────────

  List<eventoCalendario> eventosDelMes(DateTime month) {
    return _cache
        .where((e) =>
            !e.eliminado &&
            e.inicio.year == month.year &&
            e.inicio.month == month.month)
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
  }

  List<eventoCalendario> eventosDelDia(DateTime day) {
    return _cache
        .where((e) => !e.eliminado && DateUtils.isSameDay(e.inicio, day))
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
  }

  List<eventoCalendario> eventosDelRango(DateTime desde, DateTime hasta) {
    return _cache
        .where((e) =>
            !e.eliminado &&
            (e.inicio.isAtSameMomentAs(desde) || e.inicio.isAfter(desde)) &&
            e.inicio.isBefore(hasta))
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
  }

  List<eventoCalendario> eventosProximos({int dias = 7}) {
    final ahora = DateTime.now();
    final limite = ahora.add(Duration(days: dias));
    return eventosDelRango(ahora, limite);
  }

  List<eventoCalendario> eventosFiltrados({
    TipoEventoCalendario? tipo,
    EstadoEventoCalendario? estado,
    DateTime? mes,
    bool incluirEliminados = false,
  }) {
    return _cache.where((e) {
      if (!incluirEliminados && e.eliminado) return false;
      if (tipo != null && e.tipo != tipo) return false;
      if (estado != null && e.estado != estado) return false;
      if (mes != null &&
          (e.inicio.year != mes.year || e.inicio.month != mes.month)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
  }

  ResumenDia resumenDelDia(DateTime dia) {
    final eventos = eventosDelDia(dia).where((e) => e.estaActivo).toList();
    final minutosOcupados = eventos.fold<int>(
      0,
      (acc, e) => acc + e.duracion.inMinutes,
    );
    return ResumenDia(
      totalEventos: eventos.length,
      servicios: eventos.where((e) => e.tipo == TipoEventoCalendario.servicio).length,
      bloqueos: eventos.where((e) => e.tipo == TipoEventoCalendario.bloqueo).length,
      minutosOcupados: minutosOcupados,
    );
  }

  // ── Disponibilidad ─────────────────────────────────────────

  static const int _horaInicio = 8;
  static const int _horaFin = 20;

  bool estaDisponible(DateTime inicio, DateTime fin) {
    if (inicio.hour < _horaInicio || fin.hour > _horaFin) return false;
    if (fin.hour == _horaFin && fin.minute > 0) return false;
    if (!fin.isAfter(inicio)) return false;
    return !hayConflicto(inicio, fin);
  }

  List<BloqueLibre> bloquesLibresDelDia(DateTime dia) {
    final limiteInicio = DateTime(dia.year, dia.month, dia.day, _horaInicio);
    final limiteFin = DateTime(dia.year, dia.month, dia.day, _horaFin);
    final ocupados = eventosDelDia(dia)
        .where((e) => e.estaActivo)
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final libres = <BloqueLibre>[];
    var cursor = limiteInicio;
    for (final e in ocupados) {
      if (e.inicio.isAfter(cursor)) {
        libres.add(BloqueLibre(inicio: cursor, fin: e.inicio));
      }
      if (e.fin.isAfter(cursor)) cursor = e.fin;
    }
    if (cursor.isBefore(limiteFin)) {
      libres.add(BloqueLibre(inicio: cursor, fin: limiteFin));
    }
    return libres;
  }

  // ── Validaciones ───────────────────────────────────────────

  bool hayConflicto(DateTime inicio, DateTime fin, {String? excluirId}) {
    return _cache.any((e) {
      if (excluirId != null && e.id == excluirId) return false;
      if (!e.estaActivo) return false;
      return inicio.isBefore(e.fin) && fin.isAfter(e.inicio);
    });
  }

  // ── Escritura (Firestore + cache) ──────────────────────────

  Future<void> agregarBloqueo({
    required DateTime inicio,
    required DateTime fin,
    String titulo = 'Bloqueo de horario',
    String notas = '',
  }) async {
    if (!fin.isAfter(inicio)) {
      throw ErrorCalendario('La hora de fin debe ser despues del inicio');
    }
    if (hayConflicto(inicio, fin)) {
      throw ErrorCalendario('El horario se solapa con otro evento existente');
    }
    final col = _col;
    if (col == null) throw ErrorCalendario('No hay sesion activa');

    final nuevo = eventoCalendario(
      id: '',
      titulo: titulo,
      cliente: '-',
      inicio: inicio,
      fin: fin,
      tipo: TipoEventoCalendario.bloqueo,
      estado: EstadoEventoCalendario.confirmado,
      notas: notas,
    );
    final ref = await col.add(nuevo.toFirestore());
    _cache.add(nuevo.copyWith(id: ref.id));
  }

  Future<void> agregarBloqueoRecurrente({
    required DateTime inicioBase,
    required DateTime finBase,
    String titulo = 'Bloqueo recurrente',
    String notas = '',
    int repeticiones = 4,
  }) async {
    final dur = finBase.difference(inicioBase);
    final conflictos = <String>[];
    for (int i = 0; i < repeticiones; i++) {
      final inicio = inicioBase.add(Duration(days: 7 * i));
      final fin = inicio.add(dur);
      if (hayConflicto(inicio, fin)) {
        conflictos.add('${inicio.day}/${inicio.month}');
      }
    }
    if (conflictos.isNotEmpty) {
      throw ErrorCalendario('Conflicto en: ${conflictos.join(', ')}');
    }
    final col = _col;
    if (col == null) throw ErrorCalendario('No hay sesion activa');
    for (int i = 0; i < repeticiones; i++) {
      final inicio = inicioBase.add(Duration(days: 7 * i));
      final fin = inicio.add(dur);
      final nuevo = eventoCalendario(
        id: '',
        titulo: titulo,
        cliente: '-',
        inicio: inicio,
        fin: fin,
        tipo: TipoEventoCalendario.bloqueo,
        estado: EstadoEventoCalendario.confirmado,
        notas: notas,
      );
      final ref = await col.add(nuevo.toFirestore());
      _cache.add(nuevo.copyWith(id: ref.id));
    }
  }

  Future<void> actualizarEvento(eventoCalendario actualizado) async {
    if (!actualizado.fin.isAfter(actualizado.inicio)) {
      throw ErrorCalendario('La hora de fin debe ser despues del inicio');
    }
    if (hayConflicto(actualizado.inicio, actualizado.fin, excluirId: actualizado.id)) {
      throw ErrorCalendario('El horario se solapa con otro evento existente');
    }
    final col = _col;
    if (col == null) throw ErrorCalendario('No hay sesion activa');
    await col.doc(actualizado.id).update(actualizado.toFirestore());
    final idx = _cache.indexWhere((e) => e.id == actualizado.id);
    if (idx >= 0) _cache[idx] = actualizado;
  }

  // Soft delete: marca eliminado en Firestore y quita del cache visible
  Future<void> eliminarEvento(String id) async {
    final col = _col;
    if (col == null) throw ErrorCalendario('No hay sesion activa');
    await col.doc(id).update({'eliminado': true});
    final idx = _cache.indexWhere((e) => e.id == id);
    if (idx >= 0) _cache[idx] = _cache[idx].copyWith(eliminado: true);
  }

  Future<void> cancelarEvento(String id) async {
    final col = _col;
    if (col == null) throw ErrorCalendario('No hay sesion activa');
    await col.doc(id).update({'estado': EstadoEventoCalendario.cancelado.name});
    final idx = _cache.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _cache[idx] = _cache[idx].copyWith(estado: EstadoEventoCalendario.cancelado);
    }
  }
}

// ── Modelos auxiliares ─────────────────────────────────────

class ResumenDia {
  final int totalEventos;
  final int servicios;
  final int bloqueos;
  final int minutosOcupados;

  const ResumenDia({
    required this.totalEventos,
    required this.servicios,
    required this.bloqueos,
    required this.minutosOcupados,
  });

  int get horasOcupadas => minutosOcupados ~/ 60;
  int get minutosRestantes => minutosOcupados % 60;

  String get ocupadoFormateado {
    if (horasOcupadas == 0) return '${minutosOcupados}min';
    if (minutosRestantes == 0) return '${horasOcupadas}h';
    return '${horasOcupadas}h ${minutosRestantes}min';
  }
}

class BloqueLibre {
  final DateTime inicio;
  final DateTime fin;

  const BloqueLibre({required this.inicio, required this.fin});

  Duration get duracion => fin.difference(inicio);

  String get duracionFormateada {
    final mins = duracion.inMinutes;
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}min libre';
    if (m == 0) return '${h}h libre';
    return '${h}h ${m}min libre';
  }
}
