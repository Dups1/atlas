import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../Servicios/facturacion/servicioFacturapi.dart';
import '../Servicios/laboratorio/calendarioMockService.dart';
import '../widgets/platformAdapters.dart';
import '../widgets/xmlPreview.dart';

class pantallaCalendarioTrabajador extends StatefulWidget {
  const pantallaCalendarioTrabajador({super.key});

  @override
  State<pantallaCalendarioTrabajador> createState() =>
      _pantallaCalendarioTrabajadorState();
}

class _pantallaCalendarioTrabajadorState
    extends State<pantallaCalendarioTrabajador> {
  final calendarioMockService _service = calendarioMockService.instance;
  final servicioFacturapi _facturacion = servicioFacturapi();
  final Map<String, String> _facturaPorEvento = {};
  final Map<String, bool> _facturacionActivaPorEvento = {};
  late DateTime _mesActual;
  late DateTime _diaSeleccionado;
  String? _eventoFacturandoId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesActual = DateTime(now.year, now.month, 1);
    _diaSeleccionado = DateTime(now.year, now.month, now.day);
  }

  List<eventoCalendario> get _eventosDia =>
      _service.eventosDelDia(_diaSeleccionado);

  ButtonStyle _estiloBotonTonal() {
    return FilledButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      minimumSize: const Size(40, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  ButtonStyle _estiloBotonOutlined() {
    return OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      minimumSize: const Size(40, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  ButtonStyle _estiloBotonElevated() {
    return ElevatedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      minimumSize: const Size(40, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  ButtonStyle _estiloBotonTexto() {
    return TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      minimumSize: const Size(40, 34),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Calendario de servicios'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFEFF3FB)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layoutEscritorio = constraints.maxWidth >= 1080;
            if (layoutEscritorio) {
              return Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Column(
                            children: [
                              _headerMes(),
                              _diasSemana(),
                              _grillaMes(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(flex: 12, child: _panelDia()),
                ],
              );
            }

            return Column(
              children: [
                _headerMes(),
                _diasSemana(),
                _grillaMes(),
                const SizedBox(height: 4),
                Expanded(child: _panelDia()),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarBloqueoRapido,
        elevation: 4,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 14),
        extendedIconLabelSpacing: 6,
        icon: const Icon(Icons.block_outlined),
        label: const Text('Nuevo bloqueo'),
      ),
    );
  }

  Widget _headerMes() {
    final mesLabel = '${_nombreMes(_mesActual.month)} ${_mesActual.year}';
    void irAHoy() {
      final now = DateTime.now();
      setState(() {
        _mesActual = DateTime(now.year, now.month, 1);
        _diaSeleccionado = DateTime(now.year, now.month, now.day);
      });
    }

    Widget botonHoy() {
      return FilledButton.tonal(
        style: _estiloBotonTonal(),
        onPressed: irAHoy,
        child: const Text('Hoy'),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < 540;
            final controlesMes = Row(
              children: [
                _botonNavegacionMes(
                  icon: Icons.chevron_left,
                  onPressed: () => setState(() {
                    _mesActual = DateTime(
                      _mesActual.year,
                      _mesActual.month - 1,
                      1,
                    );
                  }),
                ),
                Expanded(
                  child: Text(
                    mesLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                _botonNavegacionMes(
                  icon: Icons.chevron_right,
                  onPressed: () => setState(() {
                    _mesActual = DateTime(
                      _mesActual.year,
                      _mesActual.month + 1,
                      1,
                    );
                  }),
                ),
                if (!compacto) ...[
                  const SizedBox(width: 4),
                  botonHoy(),
                  const SizedBox(width: 2),
                ],
              ],
            );

            if (!compacto) return controlesMes;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                controlesMes,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: botonHoy()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _botonNavegacionMes({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        minimumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 20),
    );
  }

  Widget _diasSemana() {
    const labels = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Row(
        children: labels
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _grillaMes() {
    const filas = 6;
    const altoCelda = 48.0;
    const espacioFilas = 4.0;
    const espacioColumnas = 4.0;
    const paddingInterno = 8.0;
    const altoGrilla =
        (filas * altoCelda) +
        ((filas - 1) * espacioFilas) +
        (paddingInterno * 2);
    final firstWeekday = _mesActual.weekday; // lunes=1
    final firstGridDate = _mesActual.subtract(Duration(days: firstWeekday - 1));
    return SizedBox(
      height: altoGrilla,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: espacioFilas,
                crossAxisSpacing: espacioColumnas,
                mainAxisExtent: altoCelda,
              ),
              itemBuilder: (context, index) {
                final day = firstGridDate.add(Duration(days: index));
                final inMonth = day.month == _mesActual.month;
                final selected = DateUtils.isSameDay(day, _diaSeleccionado);
                final hoy = DateUtils.isSameDay(day, DateTime.now());
                final eventos = _service.eventosDelDia(day);
                final estadoColor = eventos.isEmpty
                    ? Colors.blueGrey
                    : _colorEstado(eventos.first.estado);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _diaSeleccionado = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.6)
                            : (hoy
                                  ? Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.25)
                                  : Colors.transparent),
                      ),
                      color: selected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12)
                          : (inMonth ? Colors.white : Colors.grey.shade100),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 25,
                          height: 25,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.16)
                                : (hoy
                                      ? Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.08)
                                      : Colors.transparent),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: inMonth
                                  ? Colors.blueGrey.shade900
                                  : Colors.blueGrey.shade300,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (eventos.isNotEmpty)
                          Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            alignment: WrapAlignment.center,
                            children: eventos
                                .take(3)
                                .map((e) => _dotEstado(e.estado))
                                .toList(),
                          )
                        else
                          Container(
                            width: 16,
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              color: Colors.blueGrey.withValues(alpha: 0.08),
                            ),
                          ),
                        if (eventos.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              '+${eventos.length - 3}',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: estadoColor.withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _panelDia() {
    final title =
        '${_diaSeleccionado.day}/${_diaSeleccionado.month}/${_diaSeleccionado.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.event_note_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agenda del dia',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_eventosDia.length} eventos',
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _eventosDia.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 30,
                              color: Colors.blueGrey.withValues(alpha: 0.65),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sin eventos para $title',
                              style: TextStyle(color: Colors.blueGrey.shade700),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _eventosDia.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final e = _eventosDia[index];
                          final rango = '${_hhmm(e.inicio)} - ${_hhmm(e.fin)}';
                          final estadoColor = _colorEstado(e.estado);
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.blueGrey.withValues(alpha: 0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: estadoColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  e.tipo == TipoEventoCalendario.bloqueo
                                      ? Icons.block_outlined
                                      : Icons.handyman_outlined,
                                  color: estadoColor,
                                ),
                              ),
                              title: Text(
                                e.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${e.cliente}\n$rango',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade700,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              isThreeLine: true,
                              trailing: _chipEstado(e.estado),
                              onTap: () => _abrirDetalleEvento(e),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipEstado(EstadoEventoCalendario estado) {
    final label = _labelEstado(estado);
    final color = _colorEstado(estado);
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.28)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _dotEstado(EstadoEventoCalendario estado) {
    final color = _colorEstado(estado);
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Color _colorEstado(EstadoEventoCalendario estado) {
    switch (estado) {
      case EstadoEventoCalendario.pendiente:
        return const Color(0xFFF59E0B);
      case EstadoEventoCalendario.confirmado:
        return const Color(0xFF0EA5E9);
      case EstadoEventoCalendario.enCurso:
        return const Color(0xFF7C3AED);
      case EstadoEventoCalendario.completado:
        return const Color(0xFF16A34A);
      case EstadoEventoCalendario.cancelado:
        return const Color(0xFFDC2626);
    }
  }

  Future<void> _agregarBloqueoRapido() async {
    final inicio = DateTime(
      _diaSeleccionado.year,
      _diaSeleccionado.month,
      _diaSeleccionado.day,
      9,
      0,
    );
    final fin = inicio.add(const Duration(hours: 1));
    await _service.agregarBloqueo(
      inicio: inicio,
      fin: fin,
      notas: 'Bloqueo rapido',
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bloqueo agregado')));
  }

  Future<void> _abrirDetalleEvento(eventoCalendario evento) async {
    EstadoEventoCalendario estado = evento.estado;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  8,
                  8,
                  8,
                  8 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.blueGrey.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFEEF4FF), Color(0xFFF7F9FF)],
                            ),
                            border: Border.all(
                              color: Colors.blueGrey.withValues(alpha: 0.12),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                evento.titulo,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: Colors.blueGrey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(evento.cliente)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_outlined,
                                    size: 16,
                                    color: Colors.blueGrey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_hhmm(evento.inicio)} - ${_hhmm(evento.fin)}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<EstadoEventoCalendario>(
                          initialValue: estado,
                          decoration: InputDecoration(
                            labelText: 'Estado',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.blueGrey.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                          items: EstadoEventoCalendario.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(_labelEstado(e)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setModal(() => estado = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _panelFacturacionEvento(
                          modalContext: ctx,
                          setModal: setModal,
                          evento: evento,
                          estado: estado,
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final botonReprogramar = OutlinedButton.icon(
                              style: _estiloBotonOutlined(),
                              onPressed: () async {
                                await _reprogramarEvento(evento);
                                if (!mounted || !ctx.mounted) return;
                                Navigator.of(ctx).pop();
                              },
                              icon: const Icon(Icons.schedule_outlined),
                              label: const Text('Reprogramar'),
                            );

                            final botonGuardar = ElevatedButton.icon(
                              style: _estiloBotonElevated(),
                              onPressed: () async {
                                await _service.actualizarEvento(
                                  evento.copyWith(estado: estado),
                                );
                                if (!mounted || !ctx.mounted) return;
                                setState(() {});
                                Navigator.of(ctx).pop();
                              },
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Guardar'),
                            );

                            return OverflowBar(
                              alignment: MainAxisAlignment.end,
                              overflowAlignment: OverflowBarAlignment.end,
                              spacing: 8,
                              overflowSpacing: 8,
                              children: [botonReprogramar, botonGuardar],
                            );
                          },
                        ),
                        if (evento.tipo == TipoEventoCalendario.bloqueo) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            style: _estiloBotonTexto(),
                            onPressed: () async {
                              await _service.eliminarEvento(evento.id);
                              if (!mounted || !ctx.mounted) return;
                              setState(() {});
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Eliminar bloqueo'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _panelFacturacionEvento({
    required BuildContext modalContext,
    required void Function(void Function()) setModal,
    required eventoCalendario evento,
    required EstadoEventoCalendario estado,
  }) {
    final facturaId = _facturaPorEvento[evento.id];
    final facturacionActiva = _facturacionActivaPorEvento[evento.id] ?? false;
    final ocupado = _eventoFacturandoId == evento.id;
    final esServicio = evento.tipo == TipoEventoCalendario.servicio;
    final servicioCompletado = estado == EstadoEventoCalendario.completado;
    final puedeEmitir = esServicio && servicioCompletado;
    final mostrarAccionesFacturacion = servicioCompletado && facturacionActiva;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.16)),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: Colors.blueGrey.shade700,
              ),
              const SizedBox(width: 6),
              const Text(
                'Facturación',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!esServicio)
            const Text('Este evento no es de tipo servicio.')
          else if (!servicioCompletado)
            const Text(
              'Facturación disponible solo cuando el servicio esté en estado "Completado".',
            )
          else if (!mostrarAccionesFacturacion)
            LayoutBuilder(
              builder: (context, constraints) {
                final boton = OutlinedButton.icon(
                  style: _estiloBotonOutlined(),
                  onPressed: () {
                    setState(() {
                      _facturacionActivaPorEvento[evento.id] = true;
                    });
                    setModal(() {});
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: Text(facturaId == null ? 'Facturar' : 'Abrir'),
                );
                final texto = Text(
                  facturaId == null
                      ? 'Facturación opcional para este servicio completado.'
                      : 'Ya existe una factura emitida para este servicio.',
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    texto,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: boton),
                  ],
                );
              },
            )
          else ...[
            Text(
              facturaId == null
                  ? (servicioCompletado
                        ? 'Aún no se ha emitido factura para este servicio.'
                        : 'Marca el servicio como "Completado" para habilitar emisión.')
                  : 'Factura emitida: $facturaId',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  style: _estiloBotonElevated(),
                  onPressed: (ocupado || !puedeEmitir)
                      ? null
                      : () async {
                          await _emitirFacturaEvento(evento);
                          if (!modalContext.mounted) return;
                          setModal(() {});
                        },
                  icon: const Icon(Icons.receipt_long),
                  label: Text(
                    facturaId == null ? 'Emitir factura' : 'Reemitir',
                  ),
                ),
                OutlinedButton.icon(
                  style: _estiloBotonOutlined(),
                  onPressed: (ocupado || facturaId == null)
                      ? null
                      : () async {
                          await _consultarFacturaEvento(
                            evento,
                            formato: 'detalle',
                          );
                        },
                  icon: const Icon(Icons.search),
                  label: const Text('Ver factura'),
                ),
                OutlinedButton.icon(
                  style: _estiloBotonOutlined(),
                  onPressed: (ocupado || facturaId == null)
                      ? null
                      : () async {
                          await _consultarFacturaEvento(evento, formato: 'pdf');
                        },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Ver PDF'),
                ),
                OutlinedButton.icon(
                  style: _estiloBotonOutlined(),
                  onPressed: (ocupado || facturaId == null)
                      ? null
                      : () async {
                          await _descargarFacturaPdfEvento(evento);
                        },
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Descargar PDF'),
                ),
                OutlinedButton.icon(
                  style: _estiloBotonOutlined(),
                  onPressed: (ocupado || facturaId == null)
                      ? null
                      : () async {
                          await _consultarFacturaEvento(evento, formato: 'xml');
                        },
                  icon: const Icon(Icons.code),
                  label: const Text('Ver XML'),
                ),
                TextButton(
                  style: _estiloBotonTexto(),
                  onPressed: () {
                    setState(() {
                      _facturacionActivaPorEvento[evento.id] = false;
                    });
                    setModal(() {});
                  },
                  child: const Text('Ocultar facturación'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _emitirFacturaEvento(eventoCalendario evento) async {
    final monto = await _solicitarMonto(evento);
    if (monto == null) return;

    await _ejecutarAccionFacturacion(evento.id, () async {
      final payload = _payloadFacturaServicio(evento, monto);
      final respuesta = await _facturacion.crearFactura(payload);
      final facturaId = _extraerFacturaId(respuesta);

      if (mounted && facturaId != null) {
        setState(() {
          _facturaPorEvento[evento.id] = facturaId;
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            facturaId == null
                ? 'Factura emitida (sin id en respuesta)'
                : 'Factura emitida: $facturaId',
          ),
        ),
      );
      await _mostrarResultadoFacturacion(
        titulo: 'Factura emitida',
        respuesta: _normalizarRespuestaFacturacion(respuesta),
      );
    });
  }

  Future<void> _consultarFacturaEvento(
    eventoCalendario evento, {
    required String formato,
  }) async {
    final facturaId = _facturaPorEvento[evento.id];
    if (facturaId == null || facturaId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero emite la factura para este servicio'),
        ),
      );
      return;
    }

    await _ejecutarAccionFacturacion(evento.id, () async {
      late final String titulo;
      switch (formato) {
        case 'detalle':
          titulo = 'Detalle de factura';
          final respuesta = await _facturacion.obtenerFactura(facturaId);
          if (!mounted) return;
          await _mostrarResultadoFacturacion(
            titulo: '$titulo ($facturaId)',
            respuesta: _normalizarRespuestaFacturacion(respuesta),
          );
          break;
        case 'pdf':
          titulo = 'Vista PDF';
          final respuesta = await _facturacion.obtenerFacturaPdf(facturaId);
          final bytes = _extraerPdfBytes(respuesta);
          if (bytes == null) {
            if (!mounted) return;
            await _mostrarResultadoFacturacion(
              titulo: 'Documento PDF ($facturaId)',
              respuesta: _normalizarRespuestaFacturacion(respuesta),
            );
            return;
          }
          if (!mounted) return;
          await _mostrarVistaPdfFactura(
            facturaId: facturaId,
            bytes: bytes,
            titulo: titulo,
          );
          break;
        case 'xml':
          titulo = 'Vista XML';
          final respuesta = await _facturacion.obtenerFacturaXml(facturaId);
          final xml = _extraerXmlTexto(respuesta);
          if (xml == null || xml.isEmpty) {
            if (!mounted) return;
            await _mostrarResultadoFacturacion(
              titulo: 'Documento XML ($facturaId)',
              respuesta: _normalizarRespuestaFacturacion(respuesta),
            );
            return;
          }
          if (!mounted) return;
          await _mostrarVistaXmlFactura(
            facturaId: facturaId,
            xml: xml,
            titulo: titulo,
          );
          break;
        default:
          return;
      }
    });
  }

  Future<void> _descargarFacturaPdfEvento(eventoCalendario evento) async {
    final facturaId = _facturaPorEvento[evento.id];
    if (facturaId == null || facturaId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero emite la factura para este servicio'),
        ),
      );
      return;
    }

    await _ejecutarAccionFacturacion(evento.id, () async {
      final respuesta = await _facturacion.obtenerFacturaPdf(facturaId);
      final bytes = _extraerPdfBytes(respuesta);
      if (bytes == null) {
        if (!mounted) return;
        await _mostrarResultadoFacturacion(
          titulo: 'PDF sin contenido ($facturaId)',
          respuesta: _normalizarRespuestaFacturacion(respuesta),
        );
        return;
      }
      if (!mounted) return;
      final ok = await PdfDownload.descargar(
        context: context,
        bytes: bytes,
        filename: 'factura_$facturaId.pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'PDF descargado: factura_$facturaId.pdf'
                : 'Descarga no disponible en esta plataforma',
          ),
        ),
      );
    });
  }

  Future<void> _ejecutarAccionFacturacion(
    String eventoId,
    Future<void> Function() accion,
  ) async {
    if (!mounted) return;
    setState(() => _eventoFacturandoId = eventoId);
    try {
      await accion();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Facturación: $error')));
    } finally {
      if (mounted) {
        setState(() => _eventoFacturandoId = null);
      }
    }
  }

  Future<void> _mostrarResultadoFacturacion({
    required String titulo,
    required Map<String, dynamic> respuesta,
  }) async {
    if (!mounted) return;
    final texto = const JsonEncoder.withIndent('  ').convert(respuesta);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(
              texto,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            style: _estiloBotonTexto(),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarVistaPdfFactura({
    required String facturaId,
    required Uint8List bytes,
    required String titulo,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 920,
          height: 720,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: PdfPreview(
                    bytes: bytes,
                    title: '$titulo ($facturaId)',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: _estiloBotonOutlined(),
                      onPressed: () async {
                        final ok = await PdfDownload.descargar(
                          context: dialogContext,
                          bytes: bytes,
                          filename: 'factura_$facturaId.pdf',
                        );
                        if (!mounted || !dialogContext.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'PDF descargado: factura_$facturaId.pdf'
                                  : 'Descarga no disponible en esta plataforma',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Descargar PDF'),
                    ),
                    TextButton(
                      style: _estiloBotonTexto(),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarVistaXmlFactura({
    required String facturaId,
    required String xml,
    required String titulo,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 920,
          height: 720,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: XmlPreview(xml: xml, title: '$titulo ($facturaId)'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: _estiloBotonTexto(),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<double?> _solicitarMonto(eventoCalendario evento) async {
    final controller = TextEditingController(text: '700');
    final monto = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Emitir factura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Servicio: ${evento.titulo}'),
            const SizedBox(height: 4),
            Text('Cliente: ${evento.cliente}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monto (MXN)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: _estiloBotonTexto(),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: _estiloBotonElevated(),
            onPressed: () {
              final raw = controller.text.trim().replaceAll(',', '.');
              final value = double.tryParse(raw);
              if (value == null || value <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa un monto válido mayor a 0'),
                  ),
                );
                return;
              }
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return monto;
  }

  Map<String, dynamic> _payloadFacturaServicio(
    eventoCalendario evento,
    double monto,
  ) {
    final day = evento.inicio.day.toString().padLeft(2, '0');
    final month = evento.inicio.month.toString().padLeft(2, '0');
    final year = evento.inicio.year.toString();
    final fecha = '$day/$month/$year';

    return {
      'payment_form': '08',
      'use': 'S01',
      'customer': {
        'legal_name': evento.cliente,
        'email': 'cliente@ejemplo.com',
        'tax_id': 'XAXX010101000',
        'tax_system': '616',
        'address': {'zip': '06000'},
      },
      'items': [
        {
          'quantity': 1,
          'product': {
            'description': '${evento.titulo} ($fecha)',
            'price': monto,
            'product_key': '90111800',
            'unit_key': 'DAY',
          },
        },
      ],
    };
  }

  Uint8List? _extraerPdfBytes(Map<String, dynamic> respuesta) {
    final base64 = respuesta['base64'];
    if (base64 is String && base64.trim().isNotEmpty) {
      try {
        return Uint8List.fromList(base64Decode(base64.trim()));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String? _extraerXmlTexto(Map<String, dynamic> respuesta) {
    final texto = respuesta['texto'];
    if (texto is String && texto.trim().isNotEmpty) {
      return texto.trim();
    }
    final base64 = respuesta['base64'];
    if (base64 is String && base64.trim().isNotEmpty) {
      try {
        return utf8.decode(base64Decode(base64.trim()));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String? _extraerFacturaId(Map<String, dynamic> respuesta) {
    final id = respuesta['id'];
    if (id is String && id.trim().isNotEmpty) return id.trim();

    final uuid = respuesta['uuid'];
    if (uuid is String && uuid.trim().isNotEmpty) return uuid.trim();

    return null;
  }

  Map<String, dynamic> _normalizarRespuestaFacturacion(
    Map<String, dynamic> respuesta,
  ) {
    final normalizada = Map<String, dynamic>.from(respuesta);
    final base64 = normalizada['base64'];
    if (base64 is String && base64.length > 220) {
      normalizada['base64'] = '${base64.substring(0, 220)}...';
      normalizada['base64Recortado'] = true;
    }
    final texto = normalizada['texto'];
    if (texto is String && texto.length > 1200) {
      normalizada['texto'] = '${texto.substring(0, 1200)}...';
      normalizada['textoRecortado'] = true;
    }
    return normalizada;
  }

  Future<void> _reprogramarEvento(eventoCalendario evento) async {
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: evento.inicio,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (nuevaFecha == null) return;
    if (!mounted) return;
    final nuevaHora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(evento.inicio),
    );
    if (nuevaHora == null) return;

    final nuevoInicio = DateTime(
      nuevaFecha.year,
      nuevaFecha.month,
      nuevaFecha.day,
      nuevaHora.hour,
      nuevaHora.minute,
    );
    final duracion = evento.fin.difference(evento.inicio);
    final nuevoFin = nuevoInicio.add(duracion);
    await _service.actualizarEvento(
      evento.copyWith(inicio: nuevoInicio, fin: nuevoFin),
    );
    if (!mounted) return;
    setState(() {
      _mesActual = DateTime(nuevoInicio.year, nuevoInicio.month, 1);
      _diaSeleccionado = DateTime(
        nuevoInicio.year,
        nuevoInicio.month,
        nuevoInicio.day,
      );
    });
  }

  String _hhmm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _nombreMes(int month) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return meses[month - 1];
  }

  String _labelEstado(EstadoEventoCalendario estado) {
    switch (estado) {
      case EstadoEventoCalendario.pendiente:
        return 'Pendiente';
      case EstadoEventoCalendario.confirmado:
        return 'Confirmado';
      case EstadoEventoCalendario.enCurso:
        return 'En curso';
      case EstadoEventoCalendario.completado:
        return 'Completado';
      case EstadoEventoCalendario.cancelado:
        return 'Cancelado';
    }
  }
}
