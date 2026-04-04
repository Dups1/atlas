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
      backgroundColor: Colors.transparent, // 👈 importante
      appBar: AppBar(
        title: const Text('Pruebas'),
        centerTitle: true,
        backgroundColor: const Color(0xB2000000),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/orange.jpeg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: const Color(0x4D000000), // 👈 overlay
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // INPUT
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: const Color(0x33FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                        color: const Color(0xD9FFFFFF), // 👈 transparencia
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
        ),
      ),
    );
  }
}