import 'package:flutter/foundation.dart';

import '../modelos/llamadaModelo.dart';

/// Estado de UI para pantallas de llamada (motor Agora + Firestore + entrada manual).
@immutable
class EstadoUiLlamada {
  final String etiquetaConexion;
  final bool motorRtcListo;
  final bool enCanalAgora;
  final bool remotoEnCanal;
  final int? uidRemotoAgora;
  final bool microSilenciado;
  final bool altavozActivo;
  final bool indicadorHablaLocal;
  final bool indicadorHablaRemoto;
  final String? textoError;
  final bool cargandoAccion;
  final LlamadaModelo? llamadaEntrante;
  final LlamadaModelo? llamadaActiva;

  const EstadoUiLlamada({
    this.etiquetaConexion = 'inactivo',
    this.motorRtcListo = false,
    this.enCanalAgora = false,
    this.remotoEnCanal = false,
    this.uidRemotoAgora,
    this.microSilenciado = false,
    this.altavozActivo = false,
    this.indicadorHablaLocal = false,
    this.indicadorHablaRemoto = false,
    this.textoError,
    this.cargandoAccion = false,
    this.llamadaEntrante,
    this.llamadaActiva,
  });

  EstadoUiLlamada copiar({
    String? etiquetaConexion,
    bool? motorRtcListo,
    bool? enCanalAgora,
    bool? remotoEnCanal,
    int? uidRemotoAgora,
    bool limpiarUidRemoto = false,
    bool? microSilenciado,
    bool? altavozActivo,
    bool? indicadorHablaLocal,
    bool? indicadorHablaRemoto,
    String? textoError,
    bool limpiarError = false,
    bool? cargandoAccion,
    LlamadaModelo? llamadaEntrante,
    bool limpiarEntrante = false,
    LlamadaModelo? llamadaActiva,
    bool limpiarActiva = false,
  }) {
    return EstadoUiLlamada(
      etiquetaConexion: etiquetaConexion ?? this.etiquetaConexion,
      motorRtcListo: motorRtcListo ?? this.motorRtcListo,
      enCanalAgora: enCanalAgora ?? this.enCanalAgora,
      remotoEnCanal: remotoEnCanal ?? this.remotoEnCanal,
      uidRemotoAgora: limpiarUidRemoto ? null : (uidRemotoAgora ?? this.uidRemotoAgora),
      microSilenciado: microSilenciado ?? this.microSilenciado,
      altavozActivo: altavozActivo ?? this.altavozActivo,
      indicadorHablaLocal: indicadorHablaLocal ?? this.indicadorHablaLocal,
      indicadorHablaRemoto: indicadorHablaRemoto ?? this.indicadorHablaRemoto,
      textoError: limpiarError ? null : (textoError ?? this.textoError),
      cargandoAccion: cargandoAccion ?? this.cargandoAccion,
      llamadaEntrante: limpiarEntrante ? null : (llamadaEntrante ?? this.llamadaEntrante),
      llamadaActiva: limpiarActiva ? null : (llamadaActiva ?? this.llamadaActiva),
    );
  }
}
