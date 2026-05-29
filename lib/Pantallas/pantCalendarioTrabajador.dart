import 'package:flutter/material.dart';

import '../Servicios/laboratorio/calendarioService.dart';

class pantallaCalendarioTrabajador extends StatefulWidget {
  const pantallaCalendarioTrabajador({super.key});

  @override
  State<pantallaCalendarioTrabajador> createState() => _pantallaCalendarioTrabajadorState();
}

class _pantallaCalendarioTrabajadorState extends State<pantallaCalendarioTrabajador>
    with SingleTickerProviderStateMixin {
  final calendarioService _service = calendarioService();
  late DateTime _mesActual;
  late DateTime _diaSeleccionado;
  late TabController _tabController;

  TipoEventoCalendario? _filtroTipo;
  bool _cargando = true;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesActual = DateTime(now.year, now.month, 1);
    _diaSeleccionado = DateTime(now.year, now.month, now.day);
    _tabController = TabController(length: 2, vsync: this);
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    setState(() { _cargando = true; _errorCarga = null; });
    try {
      await _service.cargar();
      if (!mounted) return;
      setState(() => _cargando = false);
    } on ErrorCalendario catch (e) {
      if (!mounted) return;
      setState(() { _cargando = false; _errorCarga = e.mensaje; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _cargando = false; _errorCarga = 'Error al cargar eventos'; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<eventoCalendario> get _eventosDia {
    final todos = _service.eventosDelDia(_diaSeleccionado);
    if (_filtroTipo == null) return todos;
    return todos.where((e) => e.tipo == _filtroTipo).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          if (!_cargando)
            IconButton(
              onPressed: _cargarEventos,
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Actualizar',
            ),
        ],
        bottom: _cargando
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Mes'),
                  Tab(icon: Icon(Icons.upcoming_outlined), text: 'Proximos'),
                ],
              ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(_errorCarga!, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _cargarEventos,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _vistaCalendario(),
                    _vistaProximos(),
                  ],
                ),
      floatingActionButton: _cargando
          ? null
          : FloatingActionButton.extended(
              onPressed: _agregarBloqueoRapido,
              icon: const Icon(Icons.block_outlined),
              label: const Text('Nuevo bloqueo'),
            ),
    );
  }

  // ── Vista Mes ──────────────────────────────────────────────

  Widget _vistaCalendario() {
    return Column(
      children: [
        _headerMes(),
        const SizedBox(height: 4),
        _diasSemana(),
        _grillaMes(),
        const Divider(height: 1),
        _barraFiltros(),
        Expanded(child: _panelDia()),
      ],
    );
  }

  Widget _headerMes() {
    final mesLabel = '${_nombreMes(_mesActual.month)} ${_mesActual.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() {
              _mesActual = DateTime(_mesActual.year, _mesActual.month - 1, 1);
            }),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              mesLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _mesActual = DateTime(_mesActual.year, _mesActual.month + 1, 1);
            }),
            icon: const Icon(Icons.chevron_right),
          ),
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _mesActual = DateTime(now.year, now.month, 1);
                _diaSeleccionado = DateTime(now.year, now.month, now.day);
              });
            },
            child: const Text('Hoy'),
          ),
        ],
      ),
    );
  }

  Widget _diasSemana() {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: labels
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(d, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _grillaMes() {
    final firstWeekday = _mesActual.weekday;
    final firstGridDate = _mesActual.subtract(Duration(days: firstWeekday - 1));
    final hoy = DateTime.now();
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = (constraints.maxWidth - 16) / 7;
        final cellH = cellW.clamp(40.0, 64.0);
        return SizedBox(
          height: cellH * 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: cellH,
              ),
              itemBuilder: (context, index) {
                final day = firstGridDate.add(Duration(days: index));
                final inMonth = day.month == _mesActual.month;
                final selected = DateUtils.isSameDay(day, _diaSeleccionado);
                final esHoy = DateUtils.isSameDay(day, hoy);
                final eventos = _service.eventosDelDia(day);
                return InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => setState(() => _diaSeleccionado = day),
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: selected
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                          : null,
                      border: esHoy
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: (selected || esHoy) ? FontWeight.bold : FontWeight.w500,
                            color: inMonth
                                ? (esHoy ? Theme.of(context).colorScheme.primary : null)
                                : Colors.grey,
                          ),
                        ),
                        if (eventos.isNotEmpty) ...[
                          const SizedBox(height: 2),
                            Wrap(
                            spacing: 2,
                            children: eventos.take(3).map((e) => _dotEstado(e)).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _barraFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Text('Filtrar: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 4),
          FilterChip(
            label: const Text('Todos'),
            selected: _filtroTipo == null,
            onSelected: (_) => setState(() => _filtroTipo = null),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Servicios'),
            selected: _filtroTipo == TipoEventoCalendario.servicio,
            onSelected: (_) => setState(
              () => _filtroTipo = _filtroTipo == TipoEventoCalendario.servicio
                  ? null
                  : TipoEventoCalendario.servicio,
            ),
            avatar: const Icon(Icons.handyman_outlined, size: 14),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('Bloqueos'),
            selected: _filtroTipo == TipoEventoCalendario.bloqueo,
            onSelected: (_) => setState(
              () => _filtroTipo = _filtroTipo == TipoEventoCalendario.bloqueo
                  ? null
                  : TipoEventoCalendario.bloqueo,
            ),
            avatar: const Icon(Icons.block_outlined, size: 14),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _panelDia() {
    final fechaLabel = _fechaLegible(_diaSeleccionado);
    if (_eventosDia.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(fechaLabel, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('Sin eventos', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            fechaLabel,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            itemCount: _eventosDia.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final e = _eventosDia[index];
              final rango = '${_hhmm(e.inicio)} - ${_hhmm(e.fin)} · ${e.duracionFormateada}';
              return Card(
                child: ListTile(
                  leading: Icon(
                    e.tipo == TipoEventoCalendario.bloqueo
                        ? Icons.block_outlined
                        : Icons.handyman_outlined,
                    color: e.tipo == TipoEventoCalendario.bloqueo
                        ? Colors.red.shade300
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(e.titulo),
                  subtitle: Text(
                    e.tipo == TipoEventoCalendario.bloqueo ? rango : '${e.cliente}\n$rango',
                    maxLines: 2,
                  ),
                  isThreeLine: e.tipo != TipoEventoCalendario.bloqueo,
                  trailing: _chipEstado(e.estado),
                  onTap: () => _abrirDetalleEvento(e),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Vista Proximos ─────────────────────────────────────────

  Widget _vistaProximos() {
    final proximos = _service.eventosProximos(dias: 14);
    if (proximos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Sin eventos en los proximos 14 dias',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    // Agrupar por dia
    final Map<String, List<eventoCalendario>> porDia = {};
    for (final e in proximos) {
      final key = _fechaLegible(e.inicio);
      porDia.putIfAbsent(key, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: porDia.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            ...entry.value.map((e) {
              final rango = '${_hhmm(e.inicio)} - ${_hhmm(e.fin)} · ${e.duracionFormateada}';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    e.tipo == TipoEventoCalendario.bloqueo
                        ? Icons.block_outlined
                        : Icons.handyman_outlined,
                    color: e.tipo == TipoEventoCalendario.bloqueo
                        ? Colors.red.shade300
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(e.titulo),
                  subtitle: Text(
                    e.tipo == TipoEventoCalendario.bloqueo ? rango : '${e.cliente}\n$rango',
                    maxLines: 2,
                  ),
                  isThreeLine: e.tipo != TipoEventoCalendario.bloqueo,
                  trailing: _chipEstado(e.estado),
                  onTap: () => _abrirDetalleEvento(e),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  // ── Widgets auxiliares ─────────────────────────────────────

  Widget _chipEstado(EstadoEventoCalendario estado) {
    return Chip(
      avatar: Icon(_iconEstado(estado), size: 13, color: Colors.white),
      label: Text(_labelEstado(estado), style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: _colorEstado(estado),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  // Dot en el grid: indica tipo (servicio vs bloqueo), no estado
  Widget _dotEstado(eventoCalendario evento) {
    final color = evento.tipo == TipoEventoCalendario.bloqueo
        ? Colors.red.shade400
        : Colors.blue.shade500;
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Color _colorEstado(EstadoEventoCalendario estado) {
    switch (estado) {
      case EstadoEventoCalendario.pendiente:
        return Colors.amber.shade700;  // esperando confirmacion
      case EstadoEventoCalendario.confirmado:
        return Colors.blue.shade600;   // agendado
      case EstadoEventoCalendario.enCurso:
        return Colors.green.shade600;  // activo ahora
      case EstadoEventoCalendario.completado:
        return Colors.grey.shade500;   // terminado
      case EstadoEventoCalendario.cancelado:
        return Colors.red.shade400;    // no se realiza
    }
  }

  IconData _iconEstado(EstadoEventoCalendario estado) {
    switch (estado) {
      case EstadoEventoCalendario.pendiente:
        return Icons.schedule_outlined;      // reloj = esperando
      case EstadoEventoCalendario.confirmado:
        return Icons.event_available_outlined; // calendario check = agendado
      case EstadoEventoCalendario.enCurso:
        return Icons.play_arrow_outlined;    // play = en progreso
      case EstadoEventoCalendario.completado:
        return Icons.check_circle_outline;   // check = listo
      case EstadoEventoCalendario.cancelado:
        return Icons.cancel_outlined;        // x = cancelado
    }
  }

  // ── Acciones ───────────────────────────────────────────────

  Future<void> _agregarBloqueoRapido() async {
    final horaInicio = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Hora de inicio del bloqueo',
    );
    if (horaInicio == null) return;
    if (!mounted) return;
    final horaFin = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (horaInicio.hour + 1).clamp(0, 23), minute: horaInicio.minute),
      helpText: 'Hora de fin del bloqueo',
    );
    if (horaFin == null) return;
    final inicio = DateTime(
      _diaSeleccionado.year,
      _diaSeleccionado.month,
      _diaSeleccionado.day,
      horaInicio.hour,
      horaInicio.minute,
    );
    final fin = DateTime(
      _diaSeleccionado.year,
      _diaSeleccionado.month,
      _diaSeleccionado.day,
      horaFin.hour,
      horaFin.minute,
    );
    try {
      await _service.agregarBloqueo(inicio: inicio, fin: fin);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloqueo agregado')),
      );
    } on ErrorCalendario catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _abrirDetalleEvento(eventoCalendario evento) async {
    EstadoEventoCalendario estado = evento.estado;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          evento.titulo,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _chipEstado(evento.estado),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (evento.tipo != TipoEventoCalendario.bloqueo)
                    Text('Cliente: ${evento.cliente}'),
                  Text(
                    'Horario: ${_hhmm(evento.inicio)} - ${_hhmm(evento.fin)}  (${evento.duracionFormateada})',
                  ),
                  if (evento.notas.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Notas: ${evento.notas}', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EstadoEventoCalendario>(
                    initialValue: estado,
                    decoration: const InputDecoration(
                      labelText: 'Cambiar estado',
                      border: OutlineInputBorder(),
                    ),
                    items: EstadoEventoCalendario.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(_labelEstado(e))))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setModal(() => estado = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _reprogramarEvento(evento);
                            if (!mounted || !ctx.mounted) return;
                            Navigator.of(ctx).pop();
                          },
                          icon: const Icon(Icons.schedule_outlined),
                          label: const Text('Reprogramar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _service.actualizarEvento(evento.copyWith(estado: estado));
                              if (!mounted || !ctx.mounted) return;
                              setState(() {});
                              Navigator.of(ctx).pop();
                            } on ErrorCalendario catch (e) {
                              if (!mounted || !ctx.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.mensaje), backgroundColor: Colors.red),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                  if (evento.tipo == TipoEventoCalendario.bloqueo) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: ctx,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Eliminar bloqueo'),
                            content: const Text('¿Seguro que quieres eliminar este bloqueo?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dCtx).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(dCtx).pop(true),
                                child: const Text('Eliminar',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmar != true) return;
                        await _service.eliminarEvento(evento.id);
                        if (!mounted || !ctx.mounted) return;
                        setState(() {});
                        Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar bloqueo'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
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
    final dur = evento.fin.difference(evento.inicio);
    final nuevoFin = nuevoInicio.add(dur);
    try {
      await _service.actualizarEvento(evento.copyWith(inicio: nuevoInicio, fin: nuevoFin));
      if (!mounted) return;
      setState(() {
        _mesActual = DateTime(nuevoInicio.year, nuevoInicio.month, 1);
        _diaSeleccionado = DateTime(nuevoInicio.year, nuevoInicio.month, nuevoInicio.day);
      });
    } on ErrorCalendario catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje), backgroundColor: Colors.red),
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  String _hhmm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fechaLegible(DateTime d) {
    const dias = ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];
    return '${dias[d.weekday - 1]} ${d.day} de ${_nombreMes(d.month)}';
  }

  String _nombreMes(int month) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
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
