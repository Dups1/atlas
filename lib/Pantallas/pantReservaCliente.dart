import 'package:flutter/material.dart';

class PantallaReservaCliente extends StatefulWidget {
  const PantallaReservaCliente({super.key});

  @override
  State<PantallaReservaCliente> createState() => _PantallaReservaClienteState();
}

class _PantallaReservaClienteState extends State<PantallaReservaCliente> {
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _referenciasController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _detalleController = TextEditingController();

  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  String _urgencia = 'Normal';
  String _pago = 'Efectivo';
  bool _aceptaCondiciones = false;
  bool _loading = false;

  @override
  void dispose() {
    _direccionController.dispose();
    _referenciasController.dispose();
    _telefonoController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fechaLabel = _fechaSeleccionada == null
        ? 'Seleccionar fecha'
        : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}';
    final horaLabel = _horaSeleccionada == null
        ? 'Seleccionar hora'
        : _horaSeleccionada!.format(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reserva')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Resumen del servicio'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Trabajador: Samuel Ruiz', style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Text('Categoria: Instalaciones'),
                    Text('Subcategoria: Montaje IoT'),
                    SizedBox(height: 6),
                    Text('Precio estimado: MXN 700 - 1200'),
                    Text('Duracion estimada: 2 - 3 horas'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _sectionTitle('Fecha y hora'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(fechaLabel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(horaLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _sectionTitle('Ubicacion'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Direccion',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _referenciasController,
                      decoration: const InputDecoration(
                        labelText: 'Referencias',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefono de contacto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _sectionTitle('Detalles del problema'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _detalleController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Describe lo que necesitas',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _urgencia,
                      decoration: const InputDecoration(
                        labelText: 'Nivel de urgencia',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'Urgente', child: Text('Urgente')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _urgencia = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _sectionTitle('Pago y confirmacion'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _pago,
                      decoration: const InputDecoration(
                        labelText: 'Metodo de pago',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                        DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                        DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _pago = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _aceptaCondiciones,
                      title: const Text('Acepto condiciones y politica de cancelacion'),
                      onChanged: (value) => setState(() => _aceptaCondiciones = value ?? false),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _confirmarReserva,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(_loading ? 'Confirmando...' : 'Confirmar reserva'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date != null) {
      setState(() => _fechaSeleccionada = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null) {
      setState(() => _horaSeleccionada = time);
    }
  }

  Future<void> _confirmarReserva() async {
    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha y hora')),
      );
      return;
    }
    if (_direccionController.text.trim().isEmpty || _telefonoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Direccion y telefono son requeridos')),
      );
      return;
    }
    if (!_aceptaCondiciones) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar las condiciones')),
      );
      return;
    }

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reserva creada con estado pendiente')),
    );
    Navigator.of(context).pop();
  }
}
