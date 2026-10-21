import 'package:flutter/material.dart';

import '../theme.dart';
import 'ui/form_sheet.dart';

/// S17-02: pide un texto corto en una hoja inferior. Devuelve el texto o
/// null si se cerró sin guardar. Igual que askAmount: el State es dueño de
/// su TextEditingController y lo libera cuando la hoja desaparece de verdad
/// (si se hiciera dispose() al volver de showModalBottomSheet, la hoja aún
/// se anima y usaría un controller destruido).
Future<String?> askText(
  BuildContext context, {
  required String title,
  String? description,
  String initial = '',
  String label = '',
  String action = 'Guardar',
}) {
  return showFormSheet<String>(
    context,
    (_) => _TextSheet(
      title: title,
      description: description,
      initial: initial,
      label: label,
      action: action,
    ),
  );
}

class _TextSheet extends StatefulWidget {
  const _TextSheet({
    required this.title,
    required this.description,
    required this.initial,
    required this.label,
    required this.action,
  });

  final String title;
  final String? description;
  final String initial;
  final String label;
  final String action;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: widget.title,
      description: widget.description,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: widget.label),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: Spacing.xl),
        FilledButton(onPressed: _save, child: Text(widget.action)),
      ],
    );
  }
}
