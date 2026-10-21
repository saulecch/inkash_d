import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/money.dart';
import '../utils/parse_amount.dart';
import 'ui/form_sheet.dart';

/// Resultado de [askAmount]: qué botón se tocó y el monto en centavos.
typedef AmountAnswer = ({String action, int? amountMinor});

/// S16-04: pide un monto en una hoja inferior (en vez de un AlertDialog).
/// La última acción es la principal y solo se habilita con un monto válido;
/// las demás (p. ej. "Quitar límite", "Retirar") no lo exigen.
///
/// ¿Por qué un StatefulWidget? El State es dueño del TextEditingController
/// y lo libera cuando la hoja realmente desaparece. Si el controller se
/// crea en la función y se hace dispose() al volver de showModalBottomSheet,
/// la hoja todavía se anima al cerrarse y usa un controller destruido
/// ("TextEditingController used after being disposed").
Future<AmountAnswer?> askAmount(
  BuildContext context, {
  required String title,
  String? help,
  int? initialMinor,
  List<String> actions = const ['Guardar'],
}) {
  return showFormSheet<AmountAnswer>(
    context,
    (_) => _AmountSheet(
      title: title,
      help: help,
      initialMinor: initialMinor,
      actions: actions,
    ),
  );
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.help,
    required this.initialMinor,
    required this.actions,
  });

  final String title;
  final String? help;
  final int? initialMinor;
  final List<String> actions;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final _controller = TextEditingController(
    text: switch (widget.initialMinor) {
      null => '',
      final minor => amountInputText(minor),
    },
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // El mismo parser sin double de todo el proyecto.
  int? get _amountMinor => parseAmountMinor(_controller.text);

  @override
  Widget build(BuildContext context) {
    final main = widget.actions.last;
    // S17-01: FormSheet pone título, márgenes y espacio del teclado.
    return FormSheet(
      title: widget.title,
      description: widget.help,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixText: 'Q ',
            hintText: '0.00',
            errorText: _controller.text.isNotEmpty && _amountMinor == null
                ? 'Mayor que 0 y hasta 2 decimales'
                : null,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Row(
          children: [
            for (final action in widget.actions.take(widget.actions.length - 1))
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, (
                    action: action,
                    amountMinor: _amountMinor,
                  )),
                  child: Text(action),
                ),
              ),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _amountMinor == null
                    ? null
                    : () => Navigator.pop(context, (
                        action: main,
                        amountMinor: _amountMinor,
                      )),
                child: Text(main),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
