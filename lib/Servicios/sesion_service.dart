import 'package:flutter/material.dart';

import 'servicio_laboratorio.dart';

class SesionService {
  final ServicioLaboratorio _laboratorioService = ServicioLaboratorio();

  Future<bool> confirmarCerrarSesion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text(
                '¿Seguro que quieres cerrar sesión? Perderás la conexión actual y no podrás revertirlo.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ) ??
        false;
    return confirmed;
  }

  Future<void> limpiarSesion() => _laboratorioService.limpiarToken();
}
