import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../autenticacion/autenticacionStorage.dart';
import '../configBackend.dart';

class conversacionRemota {
  final String id;
  final List<String> participantes;
  final String? clienteUid;
  final String? trabajadorUid;
  final String? clienteNombre;
  final String? trabajadorNombre;
  final String? ultimoMensaje;
  final String? ultimoSenderUid;
  final DateTime? updatedAt;

  const conversacionRemota({
    required this.id,
    required this.participantes,
    this.clienteUid,
    this.trabajadorUid,
    this.clienteNombre,
    this.trabajadorNombre,
    this.ultimoMensaje,
    this.ultimoSenderUid,
    this.updatedAt,
  });

  String otroUid(String miUid) {
    for (final p in participantes) {
      if (p != miUid) return p;
    }
    return '';
  }

  /// Titulo del otro en la lista (nombres vienen del backend si existen en usuarios).
  String tituloLista(String miUid, {required bool vistaCliente}) {
    if (otroUid(miUid).isEmpty) return 'Chat';
    if (vistaCliente) {
      final n = trabajadorNombre?.trim();
      if (n != null && n.isNotEmpty) return n;
      return 'Trabajador';
    }
    final n = clienteNombre?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Cliente';
  }

  factory conversacionRemota.fromJson(Map<String, dynamic> j) {
    final parts =
        (j['participantes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    return conversacionRemota(
      id: j['id'] as String,
      participantes: parts,
      clienteUid: j['clienteUid'] as String?,
      trabajadorUid: j['trabajadorUid'] as String?,
      clienteNombre: j['clienteNombre'] as String?,
      trabajadorNombre: j['trabajadorNombre'] as String?,
      ultimoMensaje: j['ultimoMensaje'] as String?,
      ultimoSenderUid: j['ultimoSenderUid'] as String?,
      updatedAt: _parseIso(j['updatedAt'] as String?),
    );
  }

  static DateTime? _parseIso(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  factory conversacionRemota.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final m = d.data();
    if (m == null) {
      return conversacionRemota(id: d.id, participantes: const []);
    }
    final parts =
        (m['participantes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    DateTime? updatedAt;
    final u = m['updatedAt'];
    if (u is Timestamp) updatedAt = u.toDate();
    return conversacionRemota(
      id: d.id,
      participantes: parts,
      clienteUid: m['clienteUid'] as String?,
      trabajadorUid: m['trabajadorUid'] as String?,
      clienteNombre: m['clienteNombre'] as String?,
      trabajadorNombre: m['trabajadorNombre'] as String?,
      ultimoMensaje: m['ultimoMensaje'] as String?,
      ultimoSenderUid: m['ultimoSenderUid'] as String?,
      updatedAt: updatedAt,
    );
  }
}

class mensajeRemoto {
  final String id;
  final String conversationId;
  final String senderUid;
  final String texto;
  final DateTime createdAt;

  const mensajeRemoto({
    required this.id,
    required this.conversationId,
    required this.senderUid,
    required this.texto,
    required this.createdAt,
  });

  factory mensajeRemoto.fromJson(Map<String, dynamic> j) {
    final createdRaw = j['createdAt'];
    DateTime created;
    if (createdRaw is String) {
      created =
          DateTime.tryParse(createdRaw) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      created = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return mensajeRemoto(
      id: j['id'] as String,
      conversationId: j['conversationId'] as String? ?? '',
      senderUid: j['senderUid'] as String? ?? '',
      texto: j['texto'] as String? ?? '',
      createdAt: created,
    );
  }

  factory mensajeRemoto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final m = d.data() ?? <String, dynamic>{};
    DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    final c = m['createdAt'];
    if (c is Timestamp) createdAt = c.toDate();
    final convId = d.reference.parent.parent?.id ?? '';
    return mensajeRemoto(
      id: d.id,
      conversationId: convId,
      senderUid: m['senderUid'] as String? ?? '',
      texto: m['texto'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}

class servicioMensajes {
  final String baseUrl;
  final autenticacionStorage _storage = autenticacionStorage();

  servicioMensajes({String? baseUrl})
    : baseUrl = baseUrl ?? configBackend.urlBase;

  /// `conversationId` del backend: dos UIDs ordenados unidos por un solo `_`.
  static String? otroUidDesdeConversationId(
    String conversationId,
    String miUid,
  ) {
    final parts = conversationId.split('_');
    if (parts.length != 2) return null;
    final a = parts[0];
    final b = parts[1];
    if (a == miUid) return b;
    if (b == miUid) return a;
    return null;
  }

  Future<Map<String, String>> _headersAuth() async {
    final token = await _storage.recuperarToken();
    if (token == null) throw Exception('Sesion no iniciada');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Tiempo real: equivalente a `onSnapshot` en JS.
  Stream<List<conversacionRemota>> streamConversaciones(String miUid) {
    return FirebaseFirestore.instance
        .collection('conversaciones')
        .where('participantes', arrayContains: miUid)
        .snapshots()
        .map((s) {
          final items = s.docs.map(conversacionRemota.fromFirestore).toList();
          items.sort((a, b) {
            final aMs = a.updatedAt?.millisecondsSinceEpoch ?? 0;
            final bMs = b.updatedAt?.millisecondsSinceEpoch ?? 0;
            return bMs.compareTo(aMs);
          });
          return items;
        });
  }

  Stream<List<mensajeRemoto>> streamMensajes(String conversationId) {
    return FirebaseFirestore.instance
        .collection('conversaciones')
        .doc(conversationId)
        .collection('mensajes')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(mensajeRemoto.fromFirestore).toList());
  }

  Future<List<conversacionRemota>> fetchConversaciones() async {
    final headers = await _headersAuth();
    final r = await http.get(
      Uri.parse('$baseUrl/mensajes/conversaciones'),
      headers: headers,
    );
    if (r.statusCode != 200) {
      throw Exception('Error ${r.statusCode}: ${r.body}');
    }
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => conversacionRemota.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<mensajeRemoto>> fetchMensajes(
    String conversationId, {
    int limit = 100,
  }) async {
    final headers = await _headersAuth();
    final uri = Uri.parse(
      '$baseUrl/mensajes/conversaciones/$conversationId/mensajes',
    ).replace(queryParameters: {'limit': '$limit'});
    final r = await http.get(uri, headers: headers);
    if (r.statusCode != 200) {
      throw Exception('Error ${r.statusCode}: ${r.body}');
    }
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => mensajeRemoto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> enviarMensaje(String conversationId, String texto) async {
    final headers = await _headersAuth();
    final r = await http.post(
      Uri.parse('$baseUrl/mensajes/conversaciones/$conversationId'),
      headers: headers,
      body: jsonEncode({'texto': texto}),
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw Exception('Error ${r.statusCode}: ${r.body}');
    }
  }

  /// Crea la conversacion en Firestore si no existe (par cliente-trabajador).
  Future<String> asegurarConversacion({required String otroUid}) async {
    final headers = await _headersAuth();
    final r = await http.post(
      Uri.parse('$baseUrl/mensajes/conversaciones'),
      headers: headers,
      body: jsonEncode({'otroUid': otroUid}),
    );
    if (r.statusCode != 200) {
      throw Exception('Error ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final id = data['conversationId'] as String?;
    if (id == null) throw Exception('Respuesta sin conversationId');
    return id;
  }
}
