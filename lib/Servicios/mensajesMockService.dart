class ConversacionMock {
  final String id;
  final String clienteNombre;
  final String? avatarUrl;
  final String ultimoMensaje;
  final DateTime fechaUltimo;
  final int unreadCount;
  final String? servicioResumen;
  final String estadoServicio;

  const ConversacionMock({
    required this.id,
    required this.clienteNombre,
    this.avatarUrl,
    required this.ultimoMensaje,
    required this.fechaUltimo,
    required this.unreadCount,
    this.servicioResumen,
    required this.estadoServicio,
  });

  ConversacionMock copyWith({
    String? id,
    String? clienteNombre,
    String? avatarUrl,
    String? ultimoMensaje,
    DateTime? fechaUltimo,
    int? unreadCount,
    String? servicioResumen,
    String? estadoServicio,
  }) {
    return ConversacionMock(
      id: id ?? this.id,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ultimoMensaje: ultimoMensaje ?? this.ultimoMensaje,
      fechaUltimo: fechaUltimo ?? this.fechaUltimo,
      unreadCount: unreadCount ?? this.unreadCount,
      servicioResumen: servicioResumen ?? this.servicioResumen,
      estadoServicio: estadoServicio ?? this.estadoServicio,
    );
  }
}

class MensajeMock {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  const MensajeMock({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });
}

class MensajesMockService {
  MensajesMockService._();
  static final MensajesMockService instance = MensajesMockService._();

  static const trabajadorId = 'trabajador';

  final List<ConversacionMock> _conversations = [
    ConversacionMock(
      id: 'c1',
      clienteNombre: 'Pedro M',
      ultimoMensaje: 'Gracias, te espero a las 5',
      fechaUltimo: DateTime(2026, 5, 7, 17, 10),
      unreadCount: 2,
      servicioResumen: 'Fuga de agua en baño',
      estadoServicio: 'pendiente',
    ),
    ConversacionMock(
      id: 'c2',
      clienteNombre: 'Laura G',
      ultimoMensaje: 'Perfecto, ya quedo',
      fechaUltimo: DateTime(2026, 5, 7, 12, 24),
      unreadCount: 0,
      servicioResumen: 'Instalacion de luminaria',
      estadoServicio: 'en curso',
    ),
    ConversacionMock(
      id: 'c3',
      clienteNombre: 'Carlos R',
      ultimoMensaje: 'Me avisas cuando llegues',
      fechaUltimo: DateTime(2026, 5, 6, 19, 41),
      unreadCount: 1,
      servicioResumen: 'Revision de corto en cocina',
      estadoServicio: 'confirmado',
    ),
  ];

  final Map<String, List<MensajeMock>> _messages = {
    'c1': [
      MensajeMock(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'cliente',
        text: 'Hola, aun vienes hoy?',
        createdAt: DateTime(2026, 5, 7, 16, 50),
      ),
      MensajeMock(
        id: 'm2',
        conversationId: 'c1',
        senderId: trabajadorId,
        text: 'Si, voy en camino',
        createdAt: DateTime(2026, 5, 7, 17, 0),
      ),
      MensajeMock(
        id: 'm3',
        conversationId: 'c1',
        senderId: 'cliente',
        text: 'Gracias, te espero a las 5',
        createdAt: DateTime(2026, 5, 7, 17, 10),
      ),
    ],
    'c2': [
      MensajeMock(
        id: 'm4',
        conversationId: 'c2',
        senderId: trabajadorId,
        text: 'Trabajo finalizado, revisa por favor',
        createdAt: DateTime(2026, 5, 7, 12, 20),
      ),
      MensajeMock(
        id: 'm5',
        conversationId: 'c2',
        senderId: 'cliente',
        text: 'Perfecto, ya quedo',
        createdAt: DateTime(2026, 5, 7, 12, 24),
      ),
    ],
    'c3': [
      MensajeMock(
        id: 'm6',
        conversationId: 'c3',
        senderId: 'cliente',
        text: 'Me avisas cuando llegues',
        createdAt: DateTime(2026, 5, 6, 19, 41),
      ),
    ],
  };

  List<ConversacionMock> obtenerConversaciones() {
    final copy = [..._conversations];
    copy.sort((a, b) => b.fechaUltimo.compareTo(a.fechaUltimo));
    return copy;
  }

  List<ConversacionMock> obtenerSolicitudes() {
    return obtenerConversaciones().where((c) => c.servicioResumen?.isNotEmpty == true).toList();
  }

  List<MensajeMock> obtenerMensajes(String conversationId) {
    return [...(_messages[conversationId] ?? [])]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final msg = MensajeMock(
      id: 'm-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      text: clean,
      createdAt: DateTime.now(),
    );
    _messages.putIfAbsent(conversationId, () => []).add(msg);
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx >= 0) {
      _conversations[idx] = _conversations[idx].copyWith(
        ultimoMensaje: clean,
        fechaUltimo: msg.createdAt,
        unreadCount: senderId == trabajadorId ? 0 : _conversations[idx].unreadCount + 1,
      );
    }
  }
}
