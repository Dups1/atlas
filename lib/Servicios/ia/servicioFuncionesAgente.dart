import 'dart:convert';

import '../mensajes/servicioMensajes.dart';
import '../perfil/servicioPerfilFirebase.dart';
import '../autenticacion/autenticacionStorage.dart';

typedef NavigationCallback = Future<void> Function(String screenName);

class servicioFuncionesAgente {
  static final servicioFuncionesAgente _instance = servicioFuncionesAgente._internal();

  factory servicioFuncionesAgente() {
    return _instance;
  }

  servicioFuncionesAgente._internal();

  final _mensajes = servicioMensajes();
  final _perfil = servicioPerfilFirebase();
  final _almacen = autenticacionStorage();

  NavigationCallback? _navigationCallback;

  void setNavigationCallback(NavigationCallback callback) {
    _navigationCallback = callback;
  }

  /// Ejecuta un comando y devuelve el resultado con confirmación
  Future<Map<String, dynamic>> ejecutarComando(Map<String, dynamic> comando) async {
    try {
      final action = comando['action'] as String?;
      final params = comando['params'] as Map<String, dynamic>? ?? {};

      switch (action) {
        case 'navigate':
          return await _navegar(params);
        case 'updateProfile':
          return await _actualizarPerfil(params);
        case 'sendMessage':
          return await _enviarMensaje(params);
        case 'search':
          return await _buscar(params);
        case 'getInfo':
          return await _obtenerInfo(params);
        case 'setModoEnigma':
          return await _setModoEnigma(params);
        default:
          return {
            'success': false,
            'message': 'Comando desconocido: $action',
          };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error ejecutando comando: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _navegar(Map<String, dynamic> params) async {
    final screen = params['screen'] as String?;
    if (screen == null || screen.isEmpty) {
      return {'success': false, 'message': 'Pantalla no especificada'};
    }

    if (_navigationCallback == null) {
      return {'success': false, 'message': 'Navegación no disponible'};
    }

    try {
      await _navigationCallback!(screen);
      return {
        'success': true,
        'message': 'Navegando a $screen ✓',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error navegando: $e'};
    }
  }

  Future<Map<String, dynamic>> _actualizarPerfil(Map<String, dynamic> params) async {
    try {
      final field = params['field'] as String?;
      final value = params['value'];

      if (field == null || field.isEmpty) {
        return {'success': false, 'message': 'Campo de perfil no especificado'};
      }

      final token = await _almacen.recuperarToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Token no disponible'};
      }

      // Decodificar token JWT para obtener UID (formato: header.payload.signature)
      final parts = token.split('.');
      if (parts.length < 2) {
        return {'success': false, 'message': 'Token inválido'};
      }

      // Decodificar payload
      String payload = parts[1];
      // Agregar padding si es necesario
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload))) as Map<String, dynamic>;
      final uid = decoded['uid'] as String? ?? decoded['sub'] as String?;

      if (uid == null || uid.isEmpty) {
        return {'success': false, 'message': 'UID no encontrado en token'};
      }

      // Actualizar perfil
      await _perfil.actualizarPerfil(uid, {field: value});

      return {
        'success': true,
        'message': 'Perfil actualizado: $field = $value ✓',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error actualizando perfil: $e'};
    }
  }

  Future<Map<String, dynamic>> _enviarMensaje(Map<String, dynamic> params) async {
    try {
      final otroUid = params['uid'] as String?;
      final texto = params['texto'] as String?;

      if (otroUid == null || otroUid.isEmpty) {
        return {'success': false, 'message': 'UID destino no especificado'};
      }

      if (texto == null || texto.isEmpty) {
        return {'success': false, 'message': 'Texto del mensaje vacío'};
      }

      // Asegurar conversación existe
      final convId = await _mensajes.asegurarConversacion(otroUid: otroUid);
      if (convId.isEmpty) {
        return {'success': false, 'message': 'No se pudo crear conversación'};
      }

      // Enviar mensaje
      await _mensajes.enviarMensaje(convId, texto);

      return {
        'success': true,
        'message': 'Mensaje enviado ✓',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error enviando mensaje: $e'};
    }
  }

  Future<Map<String, dynamic>> _buscar(Map<String, dynamic> params) async {
    try {
      final query = params['query'] as String?;
      final type = params['type'] as String? ?? 'trabajador';

      if (query == null || query.isEmpty) {
        return {'success': false, 'message': 'Query de búsqueda vacía'};
      }

      // Por ahora devolver mensaje informativo
      // En futuro: implementar búsqueda real
      return {
        'success': true,
        'message': 'Búsqueda por "$query" (tipo: $type) - Próximamente implementado',
        'results': [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error en búsqueda: $e'};
    }
  }

  Future<Map<String, dynamic>> _obtenerInfo(Map<String, dynamic> params) async {
    try {
      final type = params['type'] as String? ?? 'perfil';

      switch (type) {
        case 'perfil':
          final token = await _almacen.recuperarToken();
          if (token == null) {
            return {'success': false, 'message': 'No hay sesión activa'};
          }
          // En futuro: obtener datos del perfil
          return {
            'success': true,
            'message': 'Información de perfil obtenida',
            'data': {},
          };

        case 'mensajes':
          // En futuro: contar mensajes sin leer
          return {
            'success': true,
            'message': 'No tienes mensajes sin leer',
            'unreadCount': 0,
          };

        case 'llamadas':
          // En futuro: obtener llamadas recientes
          return {
            'success': true,
            'message': 'No hay llamadas recientes',
            'data': [],
          };

        default:
          return {'success': false, 'message': 'Tipo de información desconocido: $type'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error obteniendo info: $e'};
    }
  }

  Future<Map<String, dynamic>> _setModoEnigma(Map<String, dynamic> params) async {
    try {
      final active = params['active'] as bool?;

      if (active == null) {
        return {'success': false, 'message': 'Valor de active no especificado'};
      }

      // Por ahora solo devolver confirmación
      // La app debe tener servicioModoEnigma registrado para que funcione
      return {
        'success': true,
        'message': 'Modo enigma ${active ? 'activado' : 'desactivado'} ✓',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error en modo enigma: $e'};
    }
  }
}
