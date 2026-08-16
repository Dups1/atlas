import 'package:flutter/material.dart';

import 'navegacionChat.dart';
import 'pantReservaCliente.dart';

class pantallaPerfilTrabajadorPublico extends StatelessWidget {
  final Map<String, dynamic> data;

  const pantallaPerfilTrabajadorPublico({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = (data['nombre'] ?? 'Trabajador').toString();
    final foto = (data['foto'] ?? '').toString();
    final categoria = (data['categoria'] ?? 'Sin categoria').toString();
    final subcategoria = (data['subcategoria'] ?? 'Sin subcategoria').toString();
    final descripcion = (data['descripcion'] ?? 'Sin descripcion').toString();
    final rating = double.tryParse((data['calificacion'] ?? '4.0').toString()) ?? 4.0;
    final galeriaRaw = data['galeria'];
    final galeria = galeriaRaw is List
        ? galeriaRaw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil trabajador'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                      child: foto.isEmpty ? const Icon(Icons.person, size: 46) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nombre,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(categoria, style: TextStyle(color: Colors.grey.shade700)),
                    Text(subcategoria, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sobre el trabajador',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(descripcion),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Portafolio',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (galeria.isEmpty)
                      const Text('Sin trabajos publicados aun')
                    else
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: galeria.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              galeria[i],
                              width: 150,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final uid = uidDesdeMapaUsuario(data);
                      if (uid.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Este perfil no tiene id de usuario')),
                        );
                        return;
                      }
                      abrirChatClienteConTrabajador(
                        context,
                        trabajadorUid: uid,
                        tituloMostrar: nombre,
                      );
                    },
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Contactar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const pantallaReservaCliente()),
                      );
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Reservar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
