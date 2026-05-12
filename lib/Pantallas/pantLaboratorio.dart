import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Config/configAgora.dart';
import '../Servicios/servicioLaboratorio.dart';
import '../widgets/controlesLlamada.dart';

/// Pantalla de integracion del sistema de llamadas de voz (Agora + Firestore + FCM).
class PantallaLaboratorio extends StatefulWidget {
  const PantallaLaboratorio({super.key});

  @override
  State<PantallaLaboratorio> createState() => _PantallaLaboratorioState();
}

class _PantallaLaboratorioState extends State<PantallaLaboratorio> with SingleTickerProviderStateMixin {
  late final ServicioLaboratorio _servicio;
  final TextEditingController _controladorUidReceptor = TextEditingController();
  final TextEditingController _controladorNombreRemoto = TextEditingController();
  final TextEditingController _controladorNombreLocal = TextEditingController();
  late final AnimationController _pulso;

  @override
  void initState() {
    super.initState();
    _servicio = ServicioLaboratorio();
    _servicio.addListener(_repintar);
    _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _servicio.prepararMensajeriaYAutenticacion();
    });
  }

  void _repintar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulso.dispose();
    _servicio.removeListener(_repintar);
    _servicio.dispose();
    _controladorUidReceptor.dispose();
    _controladorNombreRemoto.dispose();
    _controladorNombreLocal.dispose();
    super.dispose();
  }

  Future<void> _iniciarLlamada() async {
    final id = _controladorUidReceptor.text.trim();
    if (id.isEmpty) return;
    await _servicio.iniciarLlamada(
      idReceptor: id,
      nombreRemoto: _controladorNombreRemoto.text.trim().isEmpty ? null : _controladorNombreRemoto.text.trim(),
      nombreLocal: _controladorNombreLocal.text.trim().isEmpty ? null : _controladorNombreLocal.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = _servicio.estadoUi;
    final user = FirebaseAuth.instance.currentUser;
    final nombreMostrar = user?.displayName ?? user?.email ?? user?.uid ?? 'Sin sesion';
    final inicial = nombreMostrar.isNotEmpty ? nombreMostrar.substring(0, 1).toUpperCase() : '?';
    final hablando = ui.indicadorHablaLocal || ui.indicadorHablaRemoto;
    final escala = hablando ? 1.0 + (_pulso.value * 0.08) : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratorio llamadas'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (!ConfigAgora.configurado)
            Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Define AGORA_APP_ID al compilar: flutter run --dart-define=AGORA_APP_ID=tu_id',
                  ),
                ),
              ),
            ),
          if (!ServicioLaboratorio.soportaLlamadasVozNativo)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Plataforma actual: sin motor nativo Agora (usa Android o iOS).'),
            ),
          const SizedBox(height: 8),
          Center(
            child: AnimatedScale(
              scale: escala,
              duration: const Duration(milliseconds: 200),
              child: CircleAvatar(
                radius: 56,
                child: Text(inicial, style: const TextStyle(fontSize: 40)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              nombreMostrar,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Conexion: ${ui.etiquetaConexion}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Chip(
                  label: Text(ui.motorRtcListo ? 'Motor listo' : 'Motor apagado'),
                  avatar: Icon(ui.motorRtcListo ? Icons.check_circle : Icons.circle_outlined),
                ),
                Chip(
                  label: Text(ui.enCanalAgora ? 'En canal' : 'Fuera de canal'),
                  avatar: Icon(ui.enCanalAgora ? Icons.link : Icons.link_off),
                ),
                Chip(
                  label: Text(ui.remotoEnCanal ? 'Remoto conectado' : 'Esperando remoto'),
                  avatar: Icon(ui.remotoEnCanal ? Icons.person : Icons.person_outline),
                ),
                Chip(
                  label: Text(hablando ? 'Hablando' : 'Silencio'),
                  avatar: Icon(hablando ? Icons.graphic_eq : Icons.volume_off),
                ),
              ],
            ),
          ),
          if (ui.textoError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                ui.textoError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _controladorNombreLocal,
              decoration: const InputDecoration(
                labelText: 'Tu nombre (opcional, Firestore)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _controladorNombreRemoto,
              decoration: const InputDecoration(
                labelText: 'Nombre del receptor (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ControlesLlamada(
            servicio: _servicio,
            controladorIdReceptor: _controladorUidReceptor,
            onIniciarLlamada: _iniciarLlamada,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Backend: POST /llamadas/iniciar, /aceptar, /rechazar, /finalizar, /cancelar-emisor, '
              '/marcar-perdida, /agora-token. Variables AGORA_APP_ID y AGORA_APP_CERTIFICATE en el servidor. '
              'Firestore llamadas solo se escribe desde el backend. FCM: tokens_llamadas/{uid}. '
              'El handler en segundo plano solo registra en debug; CallKit y pantalla completa en Android '
              'requieren codigo nativo extra (no incluido aqui).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
