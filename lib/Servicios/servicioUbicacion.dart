import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Resultado de pedir permiso y una lectura de posicion (web, Android, iOS).
class ResultadoUbicacion {
  final bool ok;
  final String mensaje;
  final double? latitud;
  final double? longitud;
  final bool sugerirAbrirAjustesApp;

  const ResultadoUbicacion({
    required this.ok,
    required this.mensaje,
    this.latitud,
    this.longitud,
    this.sugerirAbrirAjustesApp = false,
  });
}

class ServicioUbicacion {
  String etiquetaPermiso(LocationPermission p) {
    switch (p) {
      case LocationPermission.denied:
        return 'Sin permiso (aun no solicitado o denegado)';
      case LocationPermission.deniedForever:
        return 'Denegado en ajustes del sistema';
      case LocationPermission.whileInUse:
        return 'Permitido mientras usas la app';
      case LocationPermission.always:
        return 'Permitido (siempre)';
      case LocationPermission.unableToDetermine:
        return 'No se pudo determinar';
    }
  }

  Future<LocationPermission> permisoActual() => Geolocator.checkPermission();

  Future<bool> serviciosActivados() => Geolocator.isLocationServiceEnabled();

  Future<ResultadoUbicacion> solicitarPermisoYPosicion() async {
    final servicioOk = await Geolocator.isLocationServiceEnabled();
    if (!servicioOk) {
      return ResultadoUbicacion(
        ok: false,
        mensaje:
            'Los servicios de ubicacion estan desactivados. Activalos en los ajustes del dispositivo.',
        sugerirAbrirAjustesApp: !kIsWeb,
      );
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied) {
      return const ResultadoUbicacion(
        ok: false,
        mensaje: 'Permiso de ubicacion denegado.',
      );
    }

    if (permiso == LocationPermission.deniedForever) {
      return const ResultadoUbicacion(
        ok: false,
        mensaje:
            'El permiso esta bloqueado. Abre los ajustes de la app y permite ubicacion.',
        sugerirAbrirAjustesApp: true,
      );
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 25),
        ),
      );
      return ResultadoUbicacion(
        ok: true,
        mensaje: 'Ubicacion obtenida correctamente.',
        latitud: pos.latitude,
        longitud: pos.longitude,
      );
    } catch (e) {
      return ResultadoUbicacion(
        ok: false,
        mensaje: 'No se pudo obtener la posicion: $e',
      );
    }
  }

  Future<bool> abrirAjustesApp() => Geolocator.openAppSettings();

  Future<bool> abrirAjustesUbicacionSistema() => Geolocator.openLocationSettings();
}
