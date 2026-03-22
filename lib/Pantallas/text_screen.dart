import 'package:flutter/material.dart';

import '../servicios/firestore_service.dart';
  final _service = FirestoreService();

class TextScreen extends StatefulWidget {
  const TextScreen({super.key});

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  bool _inserting = false;
  String? _status;

  Future<void> _injectExamples() async {
    setState(() {
      _inserting = true;
      _status = null;
    });

    try {
      final message = await _service.injectExamples();
      if (mounted) {
        setState(() {
          _status = message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _status = 'Error: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _inserting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Presiona para inyectar ejemplos en Firestore',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _inserting ? null : _injectExamples,
              child: _inserting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Inyectar ejemplos'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(
                _status!,
                style: TextStyle(
                  color: _status!.startsWith('Error') ? Colors.red : Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
