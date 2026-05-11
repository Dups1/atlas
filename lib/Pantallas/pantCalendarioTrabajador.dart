import 'package:flutter/material.dart';

import '../Servicios/calendarioMockService.dart';

class PantallaCalendarioTrabajador extends StatefulWidget {
  const PantallaCalendarioTrabajador({super.key});

  @override
  State<PantallaCalendarioTrabajador> createState() => _PantallaCalendarioTrabajadorState();
}

class _PantallaCalendarioTrabajadorState extends State<PantallaCalendarioTrabajador> {
  final CalendarioMockService _service = CalendarioMockService.instance;
  late DateTime _mesActual;
  late DateTime _diaSeleccionado;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesActual = DateTime(now.year, now.month, 1);
    _diaSeleccionado = DateTime(now.year, now.month, now.day);
  }

  List<EventoCalendario> get _eventosDia => _service.eventosDelDia(_diaSeleccionado);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
      ),
      body: Column(
        children: [
          _headerMes(),
          const SizedBox(height: 8),
          _diasSemana(),
          _grillaMes(),
          const Divider(height: 1),
          Expanded(child: _panelDia()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarBloqueoRapido,
        icon: const Icon(Icons.block_outlined),
        label: const Text('Nuevo bloqueo'),
      ),
    );
  }

  Widget _headerMes() {
    final mesLabel = '${_nombreMes(_mesActual.month)} ${_mesActual.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
                  child: Text(d, style: TextStyle(color: Colors.grey.shade700)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _grillaMes() {
    final firstWeekday = _mesActual.weekday; // lunes=1
    final firstGridDate = _mesActual.subtract(Duration(days: firstWeekday - 1));
    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final day = firstGridDate.add(Duration(days: index));
            final inMonth = day.month == _mesActual.month;
            final selected = DateUtils.isSameDay(day, _diaSeleccionado);
            final eventos = _service.eventosDelDia(day);
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _diaSeleccionado = day),
              child: Container(
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        color: inMonth ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (eventos.isNotEmpty)
                      Wrap(
                        spacing: 2,
                        children: eventos.take(3).map((e) => _dotEstado(e.estado)).toList(),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _panelDia() {
    final title = '${_diaSeleccionado.day}/${_diaSeleccionado.month}/${_diaSeleccionado.year}';
    if (_eventosDia.isEmpty) {
      return Center(
        child: Text('Sin eventos para $title'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _eventosDia.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final e = _eventosDia[index];
        final rango = '${_hhmm(e.inicio)} - ${_hhmm(e.fin)}';
        return Card(
          child: ListTile(
            leading: Icon(
              e.tipo == TipoEventoCalendario.bloqueo ? Icons.block_outlined : Icons.handyman_outlined,
            ),
            title: Text(e.titulo),
            subtitle: Text('${e.cliente}\n$rango'),
            isThreeLine: true,
            trailing: _chipEstado(e.estado),
            onTap: () => _abrirDetalleEvento(e),
          ),
        );
      },
    );
  }

  Widget _chipEstado(EstadoEventoCalendario estado) {
    final label = _labelEstado(estado);
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _dotEstado(EstadoEventoCalendario estado) {
    Color color;
    switch (estado) {
      case EstadoEventoCalendario.pendiente:
        color = Colors.orange;
        break;
      case EstadoEventoCalendario.confirmado:
        color = Colors.blue;
        break;
      case EstadoEventoCalendario.enCurso:
        color = Colors.purple;
        break;
      case EstadoEventoCalendario.completado:
        color = Colors.green;
        break;
      case EstadoEventoCalendario.cancelado:
        color = Colors.red;
        break;
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
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
    await _service.agregarBloqueo(inicio: inicio, fin: fin, notas: 'Bloqueo rapido');
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloqueo agregado')),
      );
    }
  }

  Future<void> _abrirDetalleEvento(EventoCalendario evento) async {
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
                  Text(evento.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Cliente: ${evento.cliente}'),
                  Text('Horario: ${_hhmm(evento.inicio)} - ${_hhmm(evento.fin)}'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EstadoEventoCalendario>(
                    value: estado,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    items: EstadoEventoCalendario.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(_labelEstado(e))))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModal(() => estado = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _reprogramarEvento(evento);
                            if (mounted) {
                              Navigator.of(ctx).pop();
                            }
                          },
                          icon: const Icon(Icons.schedule_outlined),
                          label: const Text('Reprogramar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _service.actualizarEvento(evento.copyWith(estado: estado));
                            if (mounted) {
                              setState(() {});
                              Navigator.of(ctx).pop();
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
                    TextButton(
                      onPressed: () async {
                        await _service.eliminarEvento(evento.id);
                        if (mounted) {
                          setState(() {});
                          Navigator.of(ctx).pop();
                        }
                      },
                      child: const Text('Eliminar bloqueo'),
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

  Future<void> _reprogramarEvento(EventoCalendario evento) async {
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: evento.inicio,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (nuevaFecha == null) return;
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
    if (mounted) {
      setState(() {
        _mesActual = DateTime(nuevoInicio.year, nuevoInicio.month, 1);
        _diaSeleccionado = DateTime(nuevoInicio.year, nuevoInicio.month, nuevoInicio.day);
      });
    }
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
