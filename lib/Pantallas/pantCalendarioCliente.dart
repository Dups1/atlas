import 'package:flutter/material.dart';

import '../Servicios/reservaciones/servicioReservaciones.dart';

class pantallaCalendarioCliente extends StatefulWidget {
  const pantallaCalendarioCliente({super.key});

  @override
  State<pantallaCalendarioCliente> createState() => _pantallaCalendarioClienteState();
}

class _pantallaCalendarioClienteState extends State<pantallaCalendarioCliente> {
  final servicioReservaciones _reservaciones = servicioReservaciones();
  late DateTime _mesActual;
  late DateTime _diaSeleccionado;
  bool _cargando = false;
  List<reservacionRemota> _reservasMes = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesActual = DateTime(now.year, now.month, 1);
    _diaSeleccionado = DateTime(now.year, now.month, now.day);
    _cargarMes();
  }

  List<reservacionRemota> get _reservasDia {
    return _reservasMes.where((r) => _mismoDia(r.fecha, _diaSeleccionado)).toList()
      ..sort((a, b) => (a.fecha ?? DateTime(2000)).compareTo(b.fecha ?? DateTime(2000)));
  }

  bool _mismoDia(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _cargarMes() async {
    setState(() => _cargando = true);
    try {
      final data = await _reservaciones.listarMias(rol: 'cliente', mes: _mesActual);
      if (!mounted) return;
      setState(() {
        _reservasMes = data;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo cargar calendario: $e')));
    }
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
        title: const Text('Mis reservas'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _cargando ? null : _cargarMes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFEFF3FB)],
          ),
        ),
        child: Column(
          children: [
            _headerMes(),
            _diasSemana(),
            _grillaMes(),
            const SizedBox(height: 4),
            Expanded(child: _panelDia()),
          ],
        ),
      ),
    );
  }

  Widget _headerMes() {
    final mesLabel = '${_nombreMes(_mesActual.month)} ${_mesActual.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            IconButton.filledTonal(
              onPressed: () {
                setState(() => _mesActual = DateTime(_mesActual.year, _mesActual.month - 1, 1));
                _cargarMes();
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                mesLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {
                setState(() => _mesActual = DateTime(_mesActual.year, _mesActual.month + 1, 1));
                _cargarMes();
              },
              icon: const Icon(Icons.chevron_right),
            ),
            const SizedBox(width: 4),
            FilledButton.tonal(
              onPressed: () {
                final now = DateTime.now();
                setState(() {
                  _mesActual = DateTime(now.year, now.month, 1);
                  _diaSeleccionado = DateTime(now.year, now.month, now.day);
                });
                _cargarMes();
              },
              child: const Text('Hoy'),
            ),
          ],
        ),
      ),
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
    final firstWeekday = _mesActual.weekday;
    final firstGridDate = _mesActual.subtract(Duration(days: firstWeekday - 1));
    return SizedBox(
      height: 320,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final day = firstGridDate.add(Duration(days: index));
              final inMonth = day.month == _mesActual.month;
              final selected = _mismoDia(day, _diaSeleccionado);
              final reservas = _reservasMes.where((r) => _mismoDia(r.fecha, day)).toList();
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _diaSeleccionado = day),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                        : (inMonth ? Colors.white : Colors.grey.shade100),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: inMonth ? Colors.blueGrey.shade900 : Colors.blueGrey.shade300,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (reservas.isNotEmpty)
                        Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: reservas.take(3).map((r) => _dotEstado(r.estadoTrabajo)).toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _panelDia() {
    final title =
        '${_diaSeleccionado.day}/${_diaSeleccionado.month}/${_diaSeleccionado.year}';
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            ListTile(
              title: const Text(
                'Reservas del dia',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(title),
              trailing: Text('${_reservasDia.length} reservas'),
            ),
            const Divider(height: 1),
            Expanded(
              child: _reservasDia.isEmpty
                  ? Center(
                      child: Text(
                        'Sin reservas para $title',
                        style: TextStyle(color: Colors.blueGrey.shade700),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: _reservasDia.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = _reservasDia[i];
                        final hora = r.fecha == null
                            ? '--:--'
                            : '${r.fecha!.hour.toString().padLeft(2, '0')}:${r.fecha!.minute.toString().padLeft(2, '0')}';
                        final puedeConfirmarPago =
                            r.estadoTrabajo == estadosTrabajo.completado && !r.pagado;
                        return Card(
                          child: ListTile(
                            title: Text(
                              r.trabajadorNombre,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${r.detalle.isEmpty ? 'Servicio' : r.detalle}\n$hora\nPago: ${r.metodoPago}',
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _chipEstado(r.estadoTrabajo),
                                const SizedBox(height: 4),
                                Text(
                                  r.pagado ? 'Pagado' : 'Sin pagar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: r.pagado ? Colors.green.shade700 : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                            onTap: puedeConfirmarPago ? () => _confirmarPago(r) : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarPago(reservacionRemota reserva) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar pago'),
        content: Text(
          'Vas a confirmar el pago de la reserva con ${reserva.trabajadorNombre}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _reservaciones.confirmarPago(reservacionId: reserva.id);
      if (!mounted) return;
      await _cargarMes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago confirmado, ya puedes calificar cuando aplique')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo confirmar pago: $e')));
    }
  }

  Widget _chipEstado(String estado) {
    final color = _colorEstado(estado);
    return Chip(
      label: Text(
        _labelEstado(estado),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.28)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _dotEstado(String estado) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: _colorEstado(estado), shape: BoxShape.circle),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case estadosTrabajo.confirmado:
        return const Color(0xFF0EA5E9);
      case estadosTrabajo.enCurso:
        return const Color(0xFF7C3AED);
      case estadosTrabajo.completado:
        return const Color(0xFF16A34A);
      case estadosTrabajo.cancelado:
        return const Color(0xFFDC2626);
      case estadosTrabajo.pendiente:
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case estadosTrabajo.pendiente:
        return 'Pendiente';
      case estadosTrabajo.confirmado:
        return 'Confirmado';
      case estadosTrabajo.enCurso:
        return 'En curso';
      case estadosTrabajo.completado:
        return 'Completado';
      case estadosTrabajo.cancelado:
        return 'Cancelado';
      default:
        return estado;
    }
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
}
