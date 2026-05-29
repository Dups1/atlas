import 'package:flutter/material.dart';

import 'navegacionChat.dart';
import 'pantReservaCliente.dart';

class pantallaPerfilTrabajadorPublico extends StatelessWidget {
  final Map<String, dynamic> data;

  const pantallaPerfilTrabajadorPublico({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final nombre = (data['nombre'] ?? 'Trabajador').toString();
    final foto = (data['foto'] ?? '').toString();
    final categoria = (data['categoria'] ?? 'Sin categoria').toString();
    final subcategoria = (data['subcategoria'] ?? 'Sin subcategoria')
        .toString();
    final descripcion = (data['descripcion'] ?? 'Sin descripcion').toString();
    final rating =
        double.tryParse((data['calificacion'] ?? '4.0').toString()) ?? 4.0;
    final galeriaRaw = data['galeria'];
    final galeria = galeriaRaw is List
        ? galeriaRaw
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList()
        : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Perfil trabajador'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFEEF3FB)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _panelCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.14),
                      backgroundImage: foto.isNotEmpty
                          ? NetworkImage(foto)
                          : null,
                      child: foto.isEmpty
                          ? const Icon(Icons.person, size: 46)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < rating.round().clamp(0, 5)
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _chipInfo(context, categoria, Icons.badge_outlined),
                        _chipInfo(
                          context,
                          subcategoria,
                          Icons.category_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _panelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tituloSeccion('Sobre el trabajador'),
                    const SizedBox(height: 8),
                    Text(
                      descripcion,
                      style: TextStyle(
                        color: Colors.blueGrey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _panelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tituloSeccion('Portafolio'),
                    const SizedBox(height: 10),
                    if (galeria.isEmpty)
                      Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blueGrey.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Sin trabajos publicados aun',
                            style: TextStyle(color: Colors.blueGrey.shade700),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 114,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: galeria.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.network(
                                  galeria[i],
                                  width: 154,
                                  height: 114,
                                  fit: BoxFit.cover,
                                ),
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.2),
                                        ],
                                        stops: const [0.6, 1],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        side: BorderSide(
                          color: Colors.blueGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      onPressed: () {
                        final uid = uidDesdeMapaUsuario(data);
                        if (uid.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Este perfil no tiene id de usuario',
                              ),
                            ),
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
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const pantallaReservaCliente(),
                          ),
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
      ),
    );
  }

  Widget _panelCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  Widget _tituloSeccion(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
    );
  }

  Widget _chipInfo(BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blueGrey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
