import 'package:flutter/material.dart';

import '../Servicios/mensajes/servicioMensajes.dart';
import 'pantChatDetCliente.dart';
import 'pantChatDetTrabajador.dart';

String uidDesdeMapaUsuario(Map<String, dynamic> data) {
  final v = data['id'] ?? data['uid'];
  return v?.toString().trim() ?? '';
}

/// Cliente escribe a un trabajador: crea conversacion en backend y abre el chat.
Future<void> abrirChatClienteConTrabajador(
  BuildContext context, {
  required String trabajadorUid,
  required String tituloMostrar,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (trabajadorUid.isEmpty) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('No hay id de trabajador en este perfil')),
    );
    return;
  }
  try {
    final cid = await servicioMensajes().asegurarConversacion(otroUid: trabajadorUid);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => pantallaChatDetalleCliente(
          conversationId: cid,
          tituloAppBar: tituloMostrar,
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      messenger?.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

/// Trabajador escribe a un cliente.
Future<void> abrirChatTrabajadorConCliente(
  BuildContext context, {
  required String clienteUid,
  required String tituloMostrar,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (clienteUid.isEmpty) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('No hay id de cliente')),
    );
    return;
  }
  try {
    final cid = await servicioMensajes().asegurarConversacion(otroUid: clienteUid);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => pantallaChatDetalleTrabajador(
          conversationId: cid,
          tituloAppBar: tituloMostrar,
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      messenger?.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
