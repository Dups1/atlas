import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Servicios/llamadas/servicioLlamadas.dart';
import '../modelos/estadoUiLlamada.dart';
import '../widgets/controlesLlamada.dart';

/// Pantalla solo para el **emisor**: llamada saliente y sesion. Sin UI de llamada entrante.
class pantallaLlamadaEmisor extends StatefulWidget {
  const pantallaLlamadaEmisor({
    super.key,
    required this.tituloAppBar,
    this.idReceptorInicial,
    this.nombreRemotoInicial,
    this.servicioCompartido,
  });

  final String tituloAppBar;
  final String? idReceptorInicial;
  final String? nombreRemotoInicial;
  final servicioLlamadas? servicioCompartido;

  @override
  State<pantallaLlamadaEmisor> createState() => _pantallaLlamadaEmisorState();
}

class _pantallaLlamadaEmisorState extends State<pantallaLlamadaEmisor>
    with SingleTickerProviderStateMixin {
  late final servicioLlamadas _servicio;
  late final bool _poseeServicio;
  final TextEditingController _controladorUidReceptor = TextEditingController();
  late final AnimationController _pulso;

  bool get _datosReceptorPrecargados {
    final id = widget.idReceptorInicial?.trim();
    return id != null && id.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _poseeServicio = widget.servicioCompartido == null;
    _servicio = widget.servicioCompartido ?? servicioLlamadas();
    _servicio.addListener(_repintar);
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    final id0 = widget.idReceptorInicial?.trim();
    if (id0 != null && id0.isNotEmpty) {
      _controladorUidReceptor.text = id0;
    }

    if (_poseeServicio) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _servicio.prepararMensajeriaYAutenticacion();
      });
    }
  }

  void _repintar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulso.dispose();
    _servicio.removeListener(_repintar);
    if (_poseeServicio) {
      _servicio.dispose();
    }
    _controladorUidReceptor.dispose();
    super.dispose();
  }

  String _nombreInterlocutorEmisor(estadoUiLlamada ui) {
    final activa = ui.llamadaActiva;
    if (activa != null) {
      final me = FirebaseAuth.instance.currentUser?.uid;
      if (me == activa.idEmisor) {
        return activa.nombreReceptor?.trim().isNotEmpty == true
            ? activa.nombreReceptor!
            : activa.idReceptor;
      }
      return activa.nombreReceptor ?? activa.idReceptor;
    }
    final tituloChat = widget.nombreRemotoInicial?.trim();
    if (tituloChat != null && tituloChat.isNotEmpty) return tituloChat;
    final id = _controladorUidReceptor.text.trim();
    if (id.isNotEmpty) return 'Contacto';
    return 'Llamada de voz';
  }

  String _leyendaConexionBreve(estadoUiLlamada ui) {
    if (!servicioLlamadas.soportaLlamadasVozNativo) {
      return 'Audio no disponible aqui';
    }
    if (ui.textoError != null) return '';
    if (ui.enCanalAgora) {
      return ui.remotoEnCanal ? 'En llamada' : 'Esperando a la otra persona';
    }
    if (ui.cargandoAccion) return 'Conectando...';
    return 'Toca llamar para iniciar';
  }

  Future<void> _iniciarLlamada() async {
    final id = _controladorUidReceptor.text.trim();
    if (id.isEmpty) return;
    final nr = widget.nombreRemotoInicial?.trim();
    await _servicio.iniciarLlamada(
      idReceptor: id,
      nombreRemoto: nr != null && nr.isNotEmpty ? nr : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = _servicio.estadoUi;
    final receptor = _nombreInterlocutorEmisor(ui);
    final inicial = receptor.isNotEmpty
        ? receptor.substring(0, 1).toUpperCase()
        : '?';
    final hablando = ui.indicadorHablaLocal || ui.indicadorHablaRemoto;
    final escala = hablando ? 1.0 + (_pulso.value * 0.08) : 1.0;
    final scheme = Theme.of(context).colorScheme;
    final subtitulo = _leyendaConexionBreve(ui);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.tituloAppBar),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFEEF3FB)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            if (!servicioLlamadas.soportaLlamadasVozNativo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Las llamadas de voz solo estan disponible para Android o iOS.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.blueGrey.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              child: Column(
                children: [
                  Center(
                    child: AnimatedScale(
                      scale: escala,
                      duration: const Duration(milliseconds: 200),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        child: Text(
                          inicial,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    receptor,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitulo.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitulo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _BarraEstadoLlamada(ui: ui, hablando: hablando),
            if (ui.textoError != null) ...[
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  ui.textoError!,
                  style: TextStyle(color: scheme.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 14),
            controlesLlamada(
              servicio: _servicio,
              controladorIdReceptor: _controladorUidReceptor,
              onIniciarLlamada: _iniciarLlamada,
              ocultarCampoIdReceptor: _datosReceptorPrecargados,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraEstadoLlamada extends StatelessWidget {
  const _BarraEstadoLlamada({required this.ui, required this.hablando});

  final estadoUiLlamada ui;
  final bool hablando;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 12,
      color: scheme.onSurfaceVariant,
    );

    Widget item(IconData icon, String label, bool activo) {
      final c = activo ? scheme.primary : scheme.outline;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: activo
              ? scheme.primary.withValues(alpha: 0.09)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: c),
            const SizedBox(width: 5),
            Text(
              label,
              style: base?.copyWith(
                color: activo ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          item(
            Icons.tune,
            ui.motorRtcListo ? 'Listo' : 'Motor',
            ui.motorRtcListo,
          ),
          item(
            Icons.podcasts_rounded,
            ui.enCanalAgora ? 'Canal' : 'Fuera',
            ui.enCanalAgora,
          ),
          item(
            Icons.person_outline,
            ui.remotoEnCanal ? 'Conectado' : 'Espera',
            ui.remotoEnCanal,
          ),
          item(Icons.mic_none, hablando ? 'Voz' : 'Nada', hablando),
        ],
      ),
    );
  }
}
