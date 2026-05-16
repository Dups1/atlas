import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Config/configAgora.dart';
import '../modelos/estadoUiLlamada.dart';
import '../modelos/llamadaModelo.dart';
import 'agora/clienteHttpLlamadas.dart';
import 'agora/motorAgoraRtc.dart';
import 'agora/utilidadUidAgora.dart';
import 'servicioFirebaseSync.dart';

/// Orquesta senalizacion (Firestore + HTTP), FCM y [MotorAgoraRtc].
class ServicioLlamadas extends ChangeNotifier {
  ServicioLlamadas() : _clienteHttp = ClienteHttpLlamadas() {
    _motorRtc = MotorAgoraRtc(
      soportaPlataforma: MotorAgoraRtc.soportaLlamadasVozNativo,
      alUnionCanal: _alUnionCanal,
      alSalirCanal: _alSalirCanal,
      alUsuarioRemoto: _alUsuarioRemoto,
      alEtiquetaConexion: _alEtiquetaConexion,
      alVolumenHabla: _alVolumenHabla,
      alError: _alErrorMotor,
      alTokenPorExpirar: _alTokenPorExpirar,
    );
  }

  final ClienteHttpLlamadas _clienteHttp;
  late final MotorAgoraRtc _motorRtc;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _mensajeria = FirebaseMessaging.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subEntrantes;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subDocumentoLlamada;
  Timer? _temporizadorTimbre;

  EstadoUiLlamada _ui = const EstadoUiLlamada();
  EstadoUiLlamada get estadoUi => _ui;

  String? _idDocumentoLlamadaActual;
  String? _canalActual;
  bool _soportaNativo = false;

  static bool get soportaLlamadasVozNativo => MotorAgoraRtc.soportaLlamadasVozNativo;

  static int uidAgoraDesdeUid(String firebaseUid) => UtilidadUidAgora.desdeFirebaseUid(firebaseUid);

  void _ponerUi(EstadoUiLlamada nuevo) {
    _ui = nuevo;
    notifyListeners();
  }

  void _ponerError(String? msg) {
    _ponerUi(_ui.copiar(textoError: msg, limpiarError: msg == null));
  }

  void _alUnionCanal() {
    _ponerUi(_ui.copiar(
      enCanalAgora: true,
      etiquetaConexion: 'unido_canal',
      motorRtcListo: true,
    ));
  }

  void _alSalirCanal() {
    _ponerUi(_ui.copiar(
      enCanalAgora: false,
      remotoEnCanal: false,
      limpiarUidRemoto: true,
      etiquetaConexion: 'fuera_canal',
    ));
  }

  void _alUsuarioRemoto(bool enCanal, int? uidRemoto) {
    _ponerUi(_ui.copiar(
      remotoEnCanal: enCanal,
      uidRemotoAgora: uidRemoto,
      limpiarUidRemoto: !enCanal,
    ));
  }

  void _alEtiquetaConexion(String etiqueta) {
    _ponerUi(_ui.copiar(
      etiquetaConexion: etiqueta,
      motorRtcListo: _motorRtc.inicializado,
    ));
  }

  void _alVolumenHabla({required bool local, required bool remoto}) {
    _ponerUi(_ui.copiar(
      indicadorHablaLocal: local,
      indicadorHablaRemoto: remoto,
    ));
  }

  void _alErrorMotor(String mensaje) {
    _ponerUi(_ui.copiar(textoError: mensaje, motorRtcListo: false));
  }

  void _alTokenPorExpirar() {
    unawaited(_renovarTokenSiHayCanal());
  }

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
    if (_motorRtc.inicializado) {
      _ponerUi(_ui.copiar(motorRtcListo: true));
      return;
    }
    await _motorRtc.inicializar(idAppAgora);
    if (_motorRtc.inicializado) {
      _ponerUi(_ui.copiar(motorRtcListo: true, etiquetaConexion: _ui.etiquetaConexion));
    }
  }

  Future<void> _renovarTokenSiHayCanal() async {
    final canal = _canalActual;
    if (canal == null || !_motorRtc.inicializado) return;
    try {
      final map = await _clienteHttp.obtenerTokenRtc(canal);
      final t = map['token'] as String?;
      if (t != null) await _motorRtc.renovarToken(t);
    } catch (e) {
      _ponerError('Renovar token: $e');
    }
  }

  Future<void> _unirseCanalConCredenciales({
    required String canal,
    required String token,
    required int uidAgora,
  }) async {
    _canalActual = canal;
    await _motorRtc.unirseCanal(canal: canal, token: token, uidAgora: uidAgora);
  }

  Future<void> _salirCanal() async {
    await _motorRtc.salirCanal();
    _canalActual = null;
  }

  Future<bool> solicitarPermisoMicrofono() async {
    if (!_soportaNativo) return false;
    final st = await Permission.microphone.request();
    return st.isGranted;
  }

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

      final map = await _clienteHttp.iniciarLlamada(cuerpo);
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
        await _clienteHttp.postSinJson('marcar-perdida', {'idLlamada': idDoc});
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
      final map = await _clienteHttp.postJson('aceptar', {'idLlamada': entrante.idLlamada});
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
      await _clienteHttp.postSinJson('rechazar', {'idLlamada': entrante.idLlamada});
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
        await _clienteHttp.postSinJson(subruta, {'idLlamada': id});
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
    if (!_motorRtc.inicializado) return;
    final nuevo = !_ui.microSilenciado;
    await _motorRtc.alternarMuteLocal(nuevo);
    _ponerUi(_ui.copiar(microSilenciado: nuevo));
  }

  Future<void> alternarAltavoz() async {
    if (!_motorRtc.inicializado) return;
    final nuevo = !_ui.altavozActivo;
    await _motorRtc.alternarAltavoz(nuevo);
    _ponerUi(_ui.copiar(altavozActivo: nuevo));
  }

  Future<void> terminarRecursos() async {
    _temporizadorTimbre?.cancel();
    await _subEntrantes?.cancel();
    await _subDocumentoLlamada?.cancel();
    _subEntrantes = null;
    _subDocumentoLlamada = null;

    await _motorRtc.liberar();

    _canalActual = null;
    _idDocumentoLlamadaActual = null;
    _ponerUi(const EstadoUiLlamada());
  }

  @override
  void dispose() {
    unawaited(terminarRecursos());
    super.dispose();
  }
}
