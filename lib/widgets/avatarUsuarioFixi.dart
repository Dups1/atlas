import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AvatarUsuarioFixi extends StatefulWidget {
  final String? uid;
  final String? urlFoto;
  final String nombre;
  final double radio;

  const AvatarUsuarioFixi({
    super.key,
    this.uid,
    this.urlFoto,
    required this.nombre,
    this.radio = 20,
  });

  static final Map<String, String> _cacheFotos = {};

  @override
  State<AvatarUsuarioFixi> createState() => _AvatarUsuarioFixiState();
}

class _AvatarUsuarioFixiState extends State<AvatarUsuarioFixi> {
  String? _foto;

  @override
  void initState() {
    super.initState();
    _resolverFoto();
  }

  @override
  void didUpdateWidget(covariant AvatarUsuarioFixi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urlFoto != widget.urlFoto || oldWidget.uid != widget.uid) {
      _resolverFoto();
    }
  }

  void _resolverFoto() {
    final direct = widget.urlFoto?.trim();
    if (direct != null && direct.isNotEmpty) {
      _foto = direct;
      if (widget.uid != null && widget.uid!.isNotEmpty) {
        AvatarUsuarioFixi._cacheFotos[widget.uid!] = direct;
      }
      return;
    }

    final id = widget.uid?.trim();
    if (id != null && id.isNotEmpty) {
      if (AvatarUsuarioFixi._cacheFotos.containsKey(id)) {
        _foto = AvatarUsuarioFixi._cacheFotos[id];
        return;
      }

      // Consultar Firestore
      FirebaseFirestore.instance.collection('usuarios').doc(id).get().then((doc) {
        if (!mounted) return;
        final data = doc.data();
        final f = data?['foto']?.toString().trim() ?? '';
        AvatarUsuarioFixi._cacheFotos[id] = f;
        setState(() {
          _foto = f;
        });
      }).catchError((_) {});
    }
  }

  Color _colorInicial(String s) {
    if (s.isEmpty) return Colors.blueGrey;
    final code = s.codeUnitAt(0);
    const colores = [
      Colors.indigo,
      Colors.teal,
      Colors.blue,
      Colors.deepPurple,
      Colors.cyan,
      Colors.blueGrey,
    ];
    return colores[code % colores.length];
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = _foto?.trim();
    final tieneFoto = fotoUrl != null && fotoUrl.isNotEmpty;
    final color = _colorInicial(widget.nombre);
    final inicial = widget.nombre.trim().isNotEmpty
        ? widget.nombre.trim().substring(0, 1).toUpperCase()
        : '?';

    if (tieneFoto) {
      return CircleAvatar(
        radius: widget.radio,
        backgroundColor: color.withValues(alpha: 0.15),
        backgroundImage: NetworkImage(fotoUrl),
        onBackgroundImageError: (_, _) {
          if (mounted) setState(() => _foto = '');
        },
      );
    }

    return CircleAvatar(
      radius: widget.radio,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        inicial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: widget.radio * 0.85,
        ),
      ),
    );
  }
}
