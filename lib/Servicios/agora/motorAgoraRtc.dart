import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

typedef OnUnionCanal = void Function();
typedef OnSalirCanal = void Function();
typedef OnUsuarioRemoto = void Function(bool enCanal, int? uidRemoto);
typedef OnEtiquetaConexion = void Function(String etiqueta);
typedef OnVolumenHabla = void Function({required bool local, required bool remoto});
typedef OnErrorAgora = void Function(String mensaje);
typedef OnTokenPorExpirar = void Function();

/// Encapsula [RtcEngine]: audio 1:1, perfil comunicacion, sin logica de negocio ni HTTP.
class MotorAgoraRtc {
  MotorAgoraRtc({
    required this.soportaPlataforma,
    required this.alUnionCanal,
    required this.alSalirCanal,
    required this.alUsuarioRemoto,
    required this.alEtiquetaConexion,
    required this.alVolumenHabla,
    required this.alError,
    required this.alTokenPorExpirar,
  });

  final bool soportaPlataforma;
  final OnUnionCanal alUnionCanal;
  final OnSalirCanal alSalirCanal;
  final OnUsuarioRemoto alUsuarioRemoto;
  final OnEtiquetaConexion alEtiquetaConexion;
  final OnVolumenHabla alVolumenHabla;
  final OnErrorAgora alError;
  final OnTokenPorExpirar alTokenPorExpirar;

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

  RtcEngine? _motor;
  RtcEngineEventHandler? _manejador;
  int? _miUidAgora;

  RtcEngine? get motor => _motor;
  int? get miUidAgora => _miUidAgora;

  bool get inicializado => _motor != null;

  Future<void> inicializar(String idAppAgora) async {
    if (!soportaPlataforma) return;
    if (idAppAgora.isEmpty) {
      alError('Falta AGORA_APP_ID (dart-define).');
      return;
    }
    if (_motor != null) return;

    try {
      _motor = createAgoraRtcEngine();
      await _motor!.initialize(RtcEngineContext(appId: idAppAgora));
      await _motor!.setChannelProfile(ChannelProfileType.channelProfileCommunication);
      await _motor!.enableAudio();
      await _motor!.disableVideo();

      _manejador = RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection con, int elapsed) {
          alUnionCanal();
          _motor?.enableAudioVolumeIndication(interval: 200, smooth: 3, reportVad: true);
        },
        onLeaveChannel: (RtcConnection con, RtcStats stats) {
          alSalirCanal();
        },
        onUserJoined: (RtcConnection con, int remoteUid, int elapsed) {
          alUsuarioRemoto(true, remoteUid);
        },
        onUserOffline: (RtcConnection con, int remoteUid, UserOfflineReasonType reason) {
          alUsuarioRemoto(false, null);
        },
        onConnectionStateChanged:
            (RtcConnection con, ConnectionStateType state, ConnectionChangedReasonType reason) {
          alEtiquetaConexion('${state.name}_${reason.name}');
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
          alVolumenHabla(local: local, remoto: remoto);
        },
        onError: (ErrorCodeType err, String msg) {
          alError('Agora: ${err.name} $msg');
        },
        onTokenPrivilegeWillExpire: (RtcConnection con, String token) {
          alTokenPorExpirar();
        },
      );

      _motor!.registerEventHandler(_manejador!);
      alEtiquetaConexion('motor_listo');
    } catch (e) {
      alError('init motor: $e');
      await liberar();
    }
  }

  Future<void> unirseCanal({
    required String canal,
    required String token,
    required int uidAgora,
  }) async {
    if (_motor == null) throw Exception('Motor no inicializado');
    _miUidAgora = uidAgora;
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

  Future<void> salirCanal() async {
    try {
      await _motor?.leaveChannel();
    } catch (_) {}
    _miUidAgora = null;
  }

  Future<void> renovarToken(String token) async {
    await _motor?.renewToken(token);
  }

  Future<void> alternarMuteLocal(bool silenciado) async {
    await _motor?.muteLocalAudioStream(silenciado);
  }

  Future<void> alternarAltavoz(bool activo) async {
    await _motor?.setEnableSpeakerphone(activo);
  }

  Future<void> liberar() async {
    if (_motor != null && _manejador != null) {
      try {
        _motor!.unregisterEventHandler(_manejador!);
      } catch (_) {}
      _manejador = null;
    }
    try {
      await _motor?.leaveChannel();
    } catch (_) {}
    try {
      await _motor?.release(sync: true);
    } catch (_) {}
    _motor = null;
    _miUidAgora = null;
  }
}
