import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Servicios/servicioLlamadas.dart';
import '../modelos/estadoUiLlamada.dart';
import '../widgets/controlesLlamada.dart';

/// Pantalla solo para el **emisor**: llamada saliente y sesion. Sin UI de llamada entrante.
class PantallaLlamadaEmisor extends StatefulWidget {
  const PantallaLlamadaEmisor({
    super.key,
    required this.tituloAppBar,
    this.idReceptorInicial,
    this.nombreRemotoInicial,
    this.servicioCompartido,
  });

  final String tituloAppBar;
  final String? idReceptorInicial;
  final String? nombreRemotoInicial;
  final ServicioLlamadas? servicioCompartido;

  @override
  State<PantallaLlamadaEmisor> createState() => _PantallaLlamadaEmisorState();
}

class _PantallaLlamadaEmisorState extends State<PantallaLlamadaEmisor> with SingleTickerProviderStateMixin {
  late final ServicioLlamadas _servicio;
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
    _servicio = widget.servicioCompartido ?? ServicioLlamadas();
    _servicio.addListener(_repintar);
    _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

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

  String _nombreInterlocutorEmisor(EstadoUiLlamada ui) {
    final activa = ui.llamadaActiva;
    if (activa != null) {
      final me = FirebaseAuth.instance.currentUser?.uid;
      if (me == activa.idEmisor) {
        return activa.nombreReceptor?.trim().isNotEmpty == true ? activa.nombreReceptor! : activa.idReceptor;
      }
      return activa.nombreReceptor ?? activa.idReceptor;
    }
    final tituloChat = widget.nombreRemotoInicial?.trim();
    if (tituloChat != null && tituloChat.isNotEmpty) return tituloChat;
    final id = _controladorUidReceptor.text.trim();
    if (id.isNotEmpty) return 'Contacto';
    return 'Llamada de voz';
  }

  String _leyendaConexionBreve(EstadoUiLlamada ui) {
    if (!ServicioLlamadas.soportaLlamadasVozNativo) return 'Audio no disponible aqui';
    if (ui.textoError != null) return '';
    if (ui.enCanalAgora) return ui.remotoEnCanal ? 'En llamada' : 'Esperando a la otra persona';
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
    final inicial = receptor.isNotEmpty ? receptor.substring(0, 1).toUpperCase() : '?';
    final hablando = ui.indicadorHablaLocal || ui.indicadorHablaRemoto;
    final escala = hablando ? 1.0 + (_pulso.value * 0.08) : 1.0;
    final scheme = Theme.of(context).colorScheme;
    final subtitulo = _leyendaConexionBreve(ui);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tituloAppBar),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (!ServicioLlamadas.soportaLlamadasVozNativo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Las llamadas de voz solo estan disponible para Android o iOS.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 16),
          Center(
            child: AnimatedScale(
              scale: escala,
              duration: const Duration(milliseconds: 200),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(inicial, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              receptor,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          if (subtitulo.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitulo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          _BarraEstadoLlamada(ui: ui, hablando: hablando),
          if (ui.textoError != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                ui.textoError!,
                style: TextStyle(color: scheme.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ControlesLlamada(
            servicio: _servicio,
            controladorIdReceptor: _controladorUidReceptor,
            onIniciarLlamada: _iniciarLlamada,
            ocultarCampoIdReceptor: _datosReceptorPrecargados,
          ),
        ],
      ),
    );
  }
}

class _BarraEstadoLlamada extends StatelessWidget {
  const _BarraEstadoLlamada({required this.ui, required this.hablando});

  final EstadoUiLlamada ui;
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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(width: 5),
          Text(label, style: base?.copyWith(color: activo ? scheme.onSurface : scheme.onSurfaceVariant)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              item(Icons.tune, ui.motorRtcListo ? 'Listo' : 'Motor', ui.motorRtcListo),
              Icon(Icons.fiber_manual_record, size: 6, color: scheme.outline),
              item(Icons.podcasts_rounded, ui.enCanalAgora ? 'Canal' : 'Fuera', ui.enCanalAgora),
              Icon(Icons.fiber_manual_record, size: 6, color: scheme.outline),
              item(Icons.person_outline, ui.remotoEnCanal ? 'Conectado' : 'Espera', ui.remotoEnCanal),
              Icon(Icons.fiber_manual_record, size: 6, color: scheme.outline),
              item(Icons.mic_none, hablando ? 'Voz' : 'Nada', hablando),
            ],
          ),
        ),
      ),
    );
  }
}
