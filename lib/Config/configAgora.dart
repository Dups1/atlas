/// Identificador de proyecto Agora (no es secreto). El token RTC se genera en el backend con el certificado.
///
/// En compilacion: `flutter run --dart-define=AGORA_APP_ID=tu_app_id`
class configAgora {
  configAgora._();

  static const String idApp = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '',
  );

  static bool get configurado => idApp.isNotEmpty;
}
