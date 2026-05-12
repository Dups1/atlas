import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../Config/configAgora.dart';
import '../modelos/llamadaModelo.dart';
import 'autenticacionStorage.dart';
import 'configBackend.dart';
import 'servicioFirebaseSync.dart';

/// Registro obligatorio para FCM en segundo plano (debe ser top-level).
///
/// El handler en segundo plano solo registra en debug; CallKit y pantalla
/// completa en Android requieren codigo nativo extra (no incluido aqui).
/// La UI al volver a primer plano puede sincronizar desde Firestore.
@pragma('vm:entry-point')
Future<void> manejadorMensajeriaLlamadasSegundoPlano(RemoteMessage mensaje) async {
  // Solo debug: CallKit (iOS) y notificacion full-screen / conexion RTC en
  // segundo plano en Android exigen capa nativa adicional no incluida en este repo.
  if (kDebugMode) {
    debugPrint('[FCM fondo] ${mensaje.messageId} data=${mensaje.data}');
  }
}

/// Estado de UI agregado para la pantalla de laboratorio (sin logica de negocio pesada en widgets).
@immutable
class EstadoUiLaboratorio {
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

  const EstadoUiLaboratorio({
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

  EstadoUiLaboratorio copiar({
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
    return EstadoUiLaboratorio(
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

/// Servicio central: Agora RTC, Firestore (senalizacion), FCM, permisos y ciclo de vida.
class ServicioLaboratorio extends ChangeNotifier {
  ServicioLaboratorio();

  final AutenticacionStorage _almacenAuth = AutenticacionStorage();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _mensajeria = FirebaseMessaging.instance;

  RtcEngine? _motor;
  RtcEngineEventHandler? _manejadorEventos;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subEntrantes;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subDocumentoLlamada;
  Timer? _temporizadorTimbre;

  EstadoUiLaboratorio _ui = const EstadoUiLaboratorio();
  EstadoUiLaboratorio get estadoUi => _ui;

  String? _idDocumentoLlamadaActual;
  String? _canalActual;
  int? _miUidAgora;
  bool _soportaNativo = false;

  static bool get soportaLlamadasVozNativo {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  /// Primeros 4 bytes de SHA-256(UTF-8 UID), big-endian uint32; 0 -> 1. Igual que Node `uidAgoraDesdeFirebaseUid`.
  static int uidAgoraDesdeUid(String firebaseUid) {
    final digest = sha256.convert(utf8.encode(firebaseUid));
    final b = digest.bytes;
    final u = ByteData.sublistView(Uint8List.fromList(b.sublist(0, 4))).getUint32(0, Endian.big);
    return u == 0 ? 1 : u;
  }

  void _ponerUi(EstadoUiLaboratorio nuevo) {
    _ui = nuevo;
    notifyListeners();
  }

  void _ponerError(String? msg) {
    _ponerUi(_ui.copiar(textoError: msg, limpiarError: msg == null));
  }

  /// Inicializa FCM, token en Firestore, escucha entrantes y sincroniza Firebase Auth con custom token.
  Future<void> prepararMensajeriaYAutenticacion() async {
    try {
      await ServicioFirebaseSync.sincronizarConTokenGuardado();
    } catch (_) {}

    await _mensajeria.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final ajustesNotificacion = await _mensajeria.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final st = ajustesNotificacion.authorizationStatus;
    if (st == AuthorizationStatus.authorized || st == AuthorizationStatus.provisional) {
      final token = await _mensajeria.getToken();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (token != null && uid != null) {
        await _db.collection('tokens_llamadas').doc(uid).set({
          'token': token,
          'actualizado': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      final tipo = m.data['tipo'];
      if (tipo == 'llamada_entrante') {
        _ponerError(null);
      }
    });

    _soportaNativo = soportaLlamadasVozNativo;
    final miUid = FirebaseAuth.instance.currentUser?.uid;
    if (miUid == null) return;

    await _subEntrantes?.cancel();
    _subEntrantes = _db
        .collection('llamadas')
        .where('idReceptor', isEqualTo: miUid)
        .where('estado', isEqualTo: EstadoLlamadaFirebase.timbrando.claveFirestore)
        .where('activa', isEqualTo: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isEmpty) {
        _ponerUi(_ui.copiar(limpiarEntrante: true));
        return;
      }
      final doc = snap.docs.first;
      final modelo = LlamadaModelo.fromFirestore(doc);
      if (_ui.llamadaActiva != null && _ui.llamadaActiva!.idLlamada == modelo.idLlamada) return;
      _ponerUi(_ui.copiar(llamadaEntrante: modelo));
    });
  }

  /// Crea motor Agora una sola vez; [idAppAgora] debe coincidir con el proyecto del token del servidor.
  Future<void> inicializarMotorRtc(String idAppAgora) async {
    if (!_soportaNativo) {
      _ponerUi(_ui.copiar(
        etiquetaConexion: 'no_soportado',
        textoError: 'Llamadas de voz solo en Android e iOS.',
      ));
      return;
    }
    if (idAppAgora.isEmpty) {
      _ponerUi(_ui.copiar(textoError: 'Falta AGORA_APP_ID (dart-define).'));
      return;
    }
    if (_motor != null) {
      _ponerUi(_ui.copiar(motorRtcListo: true));
      return;
    }

    try {
      _motor = createAgoraRtcEngine();
      await _motor!.initialize(RtcEngineContext(appId: idAppAgora));
      await _motor!.setChannelProfile(ChannelProfileType.channelProfileCommunication);
      await _motor!.enableAudio();
      await _motor!.disableVideo();

      _manejadorEventos = RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection con, int elapsed) {
          _ponerUi(_ui.copiar(
            enCanalAgora: true,
            etiquetaConexion: 'unido_canal',
            motorRtcListo: true,
          ));
          _motor?.enableAudioVolumeIndication(interval: 200, smooth: 3, reportVad: true);
        },
        onLeaveChannel: (RtcConnection con, RtcStats stats) {
          _ponerUi(_ui.copiar(
            enCanalAgora: false,
            remotoEnCanal: false,
            limpiarUidRemoto: true,
            etiquetaConexion: 'fuera_canal',
          ));
        },
        onUserJoined: (RtcConnection con, int remoteUid, int elapsed) {
          _ponerUi(_ui.copiar(
            remotoEnCanal: true,
            uidRemotoAgora: remoteUid,
          ));
        },
        onUserOffline: (RtcConnection con, int remoteUid, UserOfflineReasonType reason) {
          _ponerUi(_ui.copiar(
            remotoEnCanal: false,
            limpiarUidRemoto: true,
          ));
        },
        onConnectionStateChanged:
            (RtcConnection con, ConnectionStateType state, ConnectionChangedReasonType reason) {
          _ponerUi(_ui.copiar(etiquetaConexion: '${state.name}_${reason.name}'));
        },
        onAudioVolumeIndication:
            (RtcConnection con, List<AudioVolumeInfo> speakers, int speakerNumber, int totalVolume) {
          var local = false;
          var remoto = false;
          final mi = _miUidAgora;
          for (final s in speakers) {
            final u = s.uid;
            final v = s.volume ?? 0;
            if (u == 0 || u == mi) {
              if (v > 10) local = true;
            } else {
              if (v > 10) remoto = true;
            }
          }
          _ponerUi(_ui.copiar(
            indicadorHablaLocal: local,
            indicadorHablaRemoto: remoto,
          ));
        },
        onError: (ErrorCodeType err, String msg) {
          _ponerUi(_ui.copiar(textoError: 'Agora: ${err.name} $msg'));
        },
        onTokenPrivilegeWillExpire: (RtcConnection con, String token) {
          _renovarTokenSiHayCanal();
        },
      );

      _motor!.registerEventHandler(_manejadorEventos!);
      _ponerUi(_ui.copiar(motorRtcListo: true, etiquetaConexion: 'motor_listo'));
    } catch (e) {
      _ponerUi(_ui.copiar(textoError: 'init motor: $e', motorRtcListo: false));
    }
  }

  Future<Map<String, dynamic>> _obtenerTokenDesdeBackend(String canal) async {
    final idToken = await _almacenAuth.recuperarToken();
    if (idToken == null) throw Exception('Sin sesion HTTP');
    final uri = Uri.parse('${ConfigBackend.urlBase}/llamadas/agora-token');
    final r = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'canal': canal}),
    );
    if (r.statusCode != 200) {
      throw Exception('Token ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> _postLlamada(String subruta, Map<String, dynamic> cuerpo) async {
    final idToken = await _almacenAuth.recuperarToken();
    if (idToken == null) throw Exception('Sin sesion HTTP');
    final r = await http.post(
      Uri.parse('${ConfigBackend.urlBase}/llamadas/$subruta'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(cuerpo),
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('llamadas/$subruta ${r.statusCode}: ${r.body}');
    }
  }

  Future<Map<String, dynamic>> _postLlamadaJson(String subruta, Map<String, dynamic> cuerpo) async {
    final idToken = await _almacenAuth.recuperarToken();
    if (idToken == null) throw Exception('Sin sesion HTTP');
    final r = await http.post(
      Uri.parse('${ConfigBackend.urlBase}/llamadas/$subruta'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(cuerpo),
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('llamadas/$subruta ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> _renovarTokenSiHayCanal() async {
    final canal = _canalActual;
    if (canal == null || _motor == null) return;
    try {
      final map = await _obtenerTokenDesdeBackend(canal);
      final t = map['token'] as String?;
      if (t != null) await _motor!.renewToken(t);
    } catch (e) {
      _ponerError('Renovar token: $e');
    }
  }

  Future<void> _unirseCanalConCredenciales({
    required String canal,
    required String token,
    required int uidAgora,
  }) async {
    if (_motor == null) throw Exception('Motor no inicializado');
    _miUidAgora = uidAgora;
    _canalActual = canal;
    await _motor!.joinChannel(
      token: token,
      channelId: canal,
      uid: uidAgora,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: false,
        autoSubscribeAudio: true,
        autoSubscribeVideo: false,
      ),
    );
  }

  Future<void> _salirCanal() async {
    try {
      await _motor?.leaveChannel();
    } catch (_) {}
    _canalActual = null;
    _miUidAgora = null;
  }

  Future<bool> solicitarPermisoMicrofono() async {
    if (!_soportaNativo) return false;
    final st = await Permission.microphone.request();
    return st.isGranted;
  }

  /// Negocio en backend: POST /llamadas/iniciar (Firestore + FCM + token emisor).
  Future<void> iniciarLlamada({
    required String idReceptor,
    String? nombreRemoto,
    String? nombreLocal,
  }) async {
    final emisor = FirebaseAuth.instance.currentUser?.uid;
    if (emisor == null) {
      _ponerError('Inicia sesion (Firebase)');
      return;
    }
    if (emisor == idReceptor) {
      _ponerError('No puedes llamarte a ti mismo');
      return;
    }
    if (_ui.enCanalAgora) {
      _ponerError('Ya hay una sesion activa');
      return;
    }

    _ponerUi(_ui.copiar(cargandoAccion: true, limpiarError: true));
    try {
      if (!await solicitarPermisoMicrofono()) {
        throw Exception('Permiso de microfono denegado');
      }

      final cuerpo = <String, dynamic>{
        'idReceptor': idReceptor,
        if (nombreLocal != null && nombreLocal.trim().isNotEmpty) 'nombreEmisor': nombreLocal.trim(),
        if (nombreRemoto != null && nombreRemoto.trim().isNotEmpty) 'nombreReceptor': nombreRemoto.trim(),
      };

      final idToken = await _almacenAuth.recuperarToken();
      if (idToken == null) throw Exception('Sin sesion HTTP');
      final r = await http.post(
        Uri.parse('${ConfigBackend.urlBase}/llamadas/iniciar'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(cuerpo),
      );
      if (r.statusCode == 409) {
        throw Exception(jsonDecode(r.body)['error'] ?? 'Ocupado');
      }
      if (r.statusCode != 201) {
        throw Exception('iniciar ${r.statusCode}: ${r.body}');
      }
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      final idDoc = map['idLlamada'] as String?;
      final canal = map['canal'] as String?;
      final token = map['token'] as String?;
      final uidAgora = (map['uidAgora'] as num?)?.toInt();
      final agoraAppIdSrv = (map['agoraAppId'] as String?)?.trim() ?? '';
      if (idDoc == null || canal == null || token == null || uidAgora == null) {
        throw Exception('Respuesta incompleta del servidor');
      }
      final appIdMotor = agoraAppIdSrv.isNotEmpty ? agoraAppIdSrv : ConfigAgora.idApp;
      if (appIdMotor.isEmpty) {
        throw Exception('Sin agoraAppId en servidor: configura AGORA_APP_ID en Render y/o dart-define en cliente');
      }

      await inicializarMotorRtc(appIdMotor);
      _idDocumentoLlamadaActual = idDoc;
      _suscribirDocumentoLlamada(idDoc);
      await _unirseCanalConCredenciales(canal: canal, token: token, uidAgora: uidAgora);

      final modelo = LlamadaModelo(
        idLlamada: idDoc,
        idEmisor: emisor,
        idReceptor: idReceptor,
        canal: canal,
        estado: EstadoLlamadaFirebase.timbrando,
        activa: true,
        nombreEmisor: nombreLocal,
        nombreReceptor: nombreRemoto,
      );
      _ponerUi(_ui.copiar(
        llamadaActiva: modelo,
        cargandoAccion: false,
      ));
      _arrancarTemporizadorTimbre(idDoc: idDoc);
    } catch (e) {
      _ponerUi(_ui.copiar(cargandoAccion: false, textoError: '$e'));
    }
  }

  void _suscribirDocumentoLlamada(String idDoc) {
    _subDocumentoLlamada?.cancel();
    _subDocumentoLlamada = _db.collection('llamadas').doc(idDoc).snapshots().listen((snap) {
      if (!snap.exists) return;
      final m = LlamadaModelo.fromFirestore(snap);
      _ponerUi(_ui.copiar(llamadaActiva: m));
      if (m.estado == EstadoLlamadaFirebase.rechazada ||
          m.estado == EstadoLlamadaFirebase.perdida ||
          m.estado == EstadoLlamadaFirebase.finalizada) {
        unawaited(_salirCanal());
      }
    });
  }

  void _arrancarTemporizadorTimbre({required String idDoc}) {
    _temporizadorTimbre?.cancel();
    _temporizadorTimbre = Timer(const Duration(seconds: 45), () async {
      try {
        await _postLlamada('marcar-perdida', {'idLlamada': idDoc});
      } catch (_) {}
      unawaited(_salirCanal());
    });
  }

  Future<void> aceptarLlamadaEntrante() async {
    final entrante = _ui.llamadaEntrante;
    if (entrante == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid != entrante.idReceptor) return;

    _ponerUi(_ui.copiar(cargandoAccion: true, limpiarError: true));
    try {
      if (!await solicitarPermisoMicrofono()) {
        throw Exception('Permiso de microfono denegado');
      }
      final map = await _postLlamadaJson('aceptar', {'idLlamada': entrante.idLlamada});
      final canal = map['canal'] as String?;
      final token = map['token'] as String?;
      final uidAgora = (map['uidAgora'] as num?)?.toInt();
      final agoraAppIdSrv = (map['agoraAppId'] as String?)?.trim() ?? '';
      if (canal == null || token == null || uidAgora == null) {
        throw Exception('Respuesta incompleta del servidor');
      }
      final appIdMotor = agoraAppIdSrv.isNotEmpty ? agoraAppIdSrv : ConfigAgora.idApp;
      if (appIdMotor.isEmpty) {
        throw Exception('Sin agoraAppId en servidor');
      }
      await inicializarMotorRtc(appIdMotor);
      _idDocumentoLlamadaActual = entrante.idLlamada;
      _suscribirDocumentoLlamada(entrante.idLlamada);
      await _unirseCanalConCredenciales(canal: canal, token: token, uidAgora: uidAgora);
      _ponerUi(_ui.copiar(
        llamadaActiva: entrante.copiarCon(estado: EstadoLlamadaFirebase.aceptada),
        limpiarEntrante: true,
        cargandoAccion: false,
      ));
    } catch (e) {
      _ponerUi(_ui.copiar(cargandoAccion: false, textoError: '$e'));
    }
  }

  Future<void> rechazarLlamadaEntrante() async {
    final entrante = _ui.llamadaEntrante;
    if (entrante == null) return;
    try {
      await _postLlamada('rechazar', {'idLlamada': entrante.idLlamada});
    } catch (e) {
      _ponerError('$e');
      return;
    }
    _ponerUi(_ui.copiar(limpiarEntrante: true));
  }

  Future<void> finalizarLlamada() async {
    final id = _idDocumentoLlamadaActual;
    final activa = _ui.llamadaActiva;
    _temporizadorTimbre?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      if (id != null && uid != null) {
        final esEmisor = activa?.idEmisor == uid;
        final timbrando = activa?.estado == EstadoLlamadaFirebase.timbrando;
        final subruta = (esEmisor && timbrando) ? 'cancelar-emisor' : 'finalizar';
        await _postLlamada(subruta, {'idLlamada': id});
      }
    } catch (e) {
      _ponerError('$e');
    }
    await _salirCanal();
    await _subDocumentoLlamada?.cancel();
    _subDocumentoLlamada = null;
    _idDocumentoLlamadaActual = null;
    _ponerUi(_ui.copiar(
      limpiarActiva: true,
      limpiarEntrante: true,
      remotoEnCanal: false,
      limpiarUidRemoto: true,
    ));
  }

  Future<void> alternarSilencioMicrofono() async {
    if (_motor == null) return;
    final nuevo = !_ui.microSilenciado;
    await _motor!.muteLocalAudioStream(nuevo);
    _ponerUi(_ui.copiar(microSilenciado: nuevo));
  }

  Future<void> alternarAltavoz() async {
    if (_motor == null) return;
    final nuevo = !_ui.altavozActivo;
    await _motor!.setEnableSpeakerphone(nuevo);
    _ponerUi(_ui.copiar(altavozActivo: nuevo));
  }

  /// Libera motor, suscripciones y timers (llamar al salir de la pantalla).
  Future<void> terminarRecursos() async {
    _temporizadorTimbre?.cancel();
    await _subEntrantes?.cancel();
    await _subDocumentoLlamada?.cancel();
    _subEntrantes = null;
    _subDocumentoLlamada = null;

    if (_motor != null && _manejadorEventos != null) {
      try {
        _motor!.unregisterEventHandler(_manejadorEventos!);
      } catch (_) {}
      _manejadorEventos = null;
    }

    try {
      await _motor?.leaveChannel();
    } catch (_) {}

    try {
      await _motor?.release(sync: true);
    } catch (_) {}
    _motor = null;
    _canalActual = null;
    _miUidAgora = null;
    _idDocumentoLlamadaActual = null;
    _ponerUi(const EstadoUiLaboratorio());
  }

  @override
  void dispose() {
    unawaited(terminarRecursos());
    super.dispose();
  }
}
