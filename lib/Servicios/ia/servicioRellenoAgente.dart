/// Servicio singleton para almacenar datos temporales que el agente quiere
/// pre-llenar en las pantallas antes de navegar.
class servicioRellenoAgente {
  static final servicioRellenoAgente _instance = servicioRellenoAgente._internal();

  factory servicioRellenoAgente() {
    return _instance;
  }

  servicioRellenoAgente._internal();

  /// Almacén temporal de datos para pre-llenar
  final Map<String, dynamic> _datosTemporales = {};

  /// Establece todos los datos temporales de una pantalla
  void setDatos(Map<String, dynamic> datos) {
    _datosTemporales.clear();
    _datosTemporales.addAll(datos);
  }

  /// Obtiene un valor específico del almacén temporal
  dynamic obtener(String clave) {
    return _datosTemporales[clave];
  }

  /// Obtiene el valor de una clave con tipo específico
  T? obtenerComo<T>(String clave) {
    final valor = _datosTemporales[clave];
    return valor is T ? valor : null;
  }

  /// Obtiene el valor de una clave con fallback a un valor por defecto
  T obtenerConFallback<T>(String clave, T valorPorDefecto) {
    final valor = _datosTemporales[clave];
    return valor is T ? valor : valorPorDefecto;
  }

  /// Verifica si existe una clave
  bool contiene(String clave) {
    return _datosTemporales.containsKey(clave);
  }

  /// Limpia todos los datos almacenados
  void limpiar() {
    _datosTemporales.clear();
  }

  /// Devuelve una copia de todos los datos (sin modificar el almacén)
  Map<String, dynamic> obtenerTodo() {
    return Map<String, dynamic>.from(_datosTemporales);
  }
}
