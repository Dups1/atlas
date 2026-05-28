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

  const eventoCalendario({
    required this.id,
    required this.titulo,
    required this.cliente,
    required this.inicio,
    required this.fin,
    required this.tipo,
    required this.estado,
    required this.notas,
  });

  eventoCalendario copyWith({
    String? id,
    String? titulo,
    String? cliente,
    DateTime? inicio,
    DateTime? fin,
    TipoEventoCalendario? tipo,
    EstadoEventoCalendario? estado,
    String? notas,
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
    );
  }
}

class calendarioMockService {
  calendarioMockService._();
  static final calendarioMockService instance = calendarioMockService._();

  final List<eventoCalendario> _eventos = [
    eventoCalendario(
      id: 'ev-1',
      titulo: 'Revision electrica',
      cliente: 'Pedro M',
      inicio: DateTime(2026, 5, 9, 9, 0),
      fin: DateTime(2026, 5, 9, 10, 30),
      tipo: TipoEventoCalendario.servicio,
      estado: EstadoEventoCalendario.confirmado,
      notas: 'Revisar tablero principal',
    ),
    eventoCalendario(
      id: 'ev-2',
      titulo: 'Instalacion luminaria',
      cliente: 'Laura G',
      inicio: DateTime(2026, 5, 10, 12, 0),
      fin: DateTime(2026, 5, 10, 13, 0),
      tipo: TipoEventoCalendario.servicio,
      estado: EstadoEventoCalendario.pendiente,
      notas: 'Llevar escalera y taladro',
    ),
    eventoCalendario(
      id: 'ev-3',
      titulo: 'Bloqueo personal',
      cliente: '-',
      inicio: DateTime(2026, 5, 11, 15, 0),
      fin: DateTime(2026, 5, 11, 17, 0),
      tipo: TipoEventoCalendario.bloqueo,
      estado: EstadoEventoCalendario.confirmado,
      notas: 'No disponible',
    ),
  ];

  List<eventoCalendario> eventosDelMes(DateTime month) {
    return _eventos.where((e) => e.inicio.year == month.year && e.inicio.month == month.month).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
  }

  List<eventoCalendario> eventosDelDia(DateTime day) {
    return _eventos.where((e) => DateUtils.isSameDay(e.inicio, day)).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
  }

  Future<void> agregarBloqueo({
    required DateTime inicio,
    required DateTime fin,
    String notas = '',
  }) async {
    _eventos.add(
      eventoCalendario(
        id: 'bloq-${DateTime.now().microsecondsSinceEpoch}',
        titulo: 'Bloqueo de horario',
        cliente: '-',
        inicio: inicio,
        fin: fin,
        tipo: TipoEventoCalendario.bloqueo,
        estado: EstadoEventoCalendario.confirmado,
        notas: notas,
      ),
    );
  }

  Future<void> actualizarEvento(eventoCalendario actualizado) async {
    final index = _eventos.indexWhere((e) => e.id == actualizado.id);
    if (index >= 0) {
      _eventos[index] = actualizado;
    }
  }

  Future<void> eliminarEvento(String id) async {
    _eventos.removeWhere((e) => e.id == id);
  }
}
