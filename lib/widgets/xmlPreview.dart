import 'package:flutter/material.dart';

class XmlPreview extends StatelessWidget {
  const XmlPreview({super.key, required this.xml, required this.title});

  final String xml;
  final String title;

  String _formatearXml(String value) {
    final buffer = StringBuffer();
    var indentLevel = 0;

    for (final rawLine in value.split(RegExp(r'\r?\n'))) {
      var line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      if (line.startsWith('</')) {
        indentLevel = (indentLevel - 1).clamp(0, 1000);
      }

      buffer.write('${'  ' * indentLevel}$line\n');

      final isOpeningTag = line.startsWith('<') &&
          !line.startsWith('</') &&
          !line.endsWith('/>') &&
          !line.contains('?>') &&
          !line.startsWith('<!');
      if (isOpeningTag) {
        indentLevel += 1;
      }
    }

    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted = _formatearXml(xml);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 240, maxHeight: 640),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                formatted,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.35,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}