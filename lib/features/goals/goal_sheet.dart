import 'package:flutter/material.dart';

import '../../models/savings_goal.dart';
import '../../repositories/savings_goals_repository.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../../utils/parse_amount.dart';

typedef GoalData = ({String name, int targetMinor});

// S16-05: crear (goal == null) o editar el nombre y el objetivo de una meta
// en una hoja inferior. Lo ahorrado NO se edita aquí: solo cambia con
// aportes y retiros (UPDATE atómico).
class GoalSheet extends StatefulWidget {
  const GoalSheet({required this.onSave, this.goal, this.onDelete, super.key});

  final SavingsGoal? goal;
  final Future<void> Function(GoalData data) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<GoalSheet> {
  late final _name = TextEditingController(text: widget.goal?.name);
  late final _target = TextEditingController(
    text: switch (widget.goal?.targetAmountMinor) {
      null => '',
      final minor => amountInputText(minor),
    },
  );
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _target.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  int? get _targetMinor => parseAmountMinor(_target.text); // sin double

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return; // guard de doble toque
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } on SavingsGoalException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final valid = _name.text.trim().isNotEmpty && _targetMinor != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            goal == null ? 'Nueva meta' : 'Editar meta',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            autofocus: goal == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej. Viaje a Tikal',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Objetivo',
              prefixText: 'Q ',
              helperText: goal == null
                  ? null
                  : 'Llevas ${formatQuetzales(goal.savedAmountMinor)} '
                        'ahorrados (no cambia al editar).',
              errorText: _target.text.isNotEmpty && _targetMinor == null
                  ? 'Mayor que 0 y hasta 2 decimales'
                  : null,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: kPeligro)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: valid && !_busy
                ? () => _run(
                    () => widget.onSave((
                      name: _name.text,
                      targetMinor: _targetMinor!,
                    )),
                  )
                : null,
            child: Text(goal == null ? 'Crear meta' : 'Guardar cambios'),
          ),
          if (widget.onDelete != null)
            TextButton(
              onPressed: _busy ? null : () => _run(widget.onDelete!),
              style: TextButton.styleFrom(foregroundColor: kPeligro),
              child: const Text('Eliminar meta'),
            ),
        ],
      ),
    );
  }
}
