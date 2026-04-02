import 'package:flutter/material.dart';
import '../Servicios/api_service.dart';

class PantallaCrud extends StatefulWidget {
  const PantallaCrud({super.key});

  @override
  State<PantallaCrud> createState() => _PantallaCrudState();
}

class _PantallaCrudState extends State<PantallaCrud> {
  final api = ApiService();
  List datos = [];
  final TextEditingController controller = TextEditingController();

  int? selectedId;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  void cargarDatos() async {
    final res = await api.getDatos();
    setState(() {
      datos = res;
    });
  }

  void crear() async {
    if (controller.text.isEmpty) return;

    await api.crearDato(controller.text);
    controller.clear();
    cargarDatos();
  }

  void actualizar() async {
    if (selectedId == null || controller.text.isEmpty) return;

    await api.actualizarDato(selectedId!, controller.text);
    controller.clear();
    selectedId = null;
    cargarDatos();
  }

  void eliminar(int id) async {
    await api.eliminarDato(id);
    cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pruebas'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // INPUT
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // BOTONES
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: crear,
                    child: const Text("Crear"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: actualizar,
                    child: const Text("Actualizar"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // LISTA
            Expanded(
              child: ListView.builder(
                itemCount: datos.length,
                itemBuilder: (context, index) {
                  final item = datos[index];

                  return Card(
                    child: ListTile(
                      title: Text(item['nombre'].toString()),
                      subtitle: Text("ID: ${item['id']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // EDITAR
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              controller.text = item['nombre'];
                              selectedId = item['id'];
                            },
                          ),

                          // ELIMINAR
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => eliminar(item['id']),
                          ),
                        ],
                      ),
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
}