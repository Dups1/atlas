import 'package:firebase_messaging/firebase_messaging.dart';

/// Registro obligatorio para FCM en segundo plano (debe ser top-level).
@pragma('vm:entry-point')
Future<void> manejadorMensajeriaLlamadasSegundoPlano(RemoteMessage mensaje) async {}
