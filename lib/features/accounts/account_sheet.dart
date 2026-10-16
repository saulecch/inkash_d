import 'package:flutter/material.dart';

import '../../models/account_balance.dart';
import '../../repositories/accounts_repository.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../../utils/parse_amount.dart';
import '../../widgets/icon_picker.dart';

// Lo que devuelve el formulario al guardar.
typedef AccountData = ({String name, String type, int initialBalanceMinor});

// S16-01: crear (account == null) o editar una cuenta en una hoja inferior.
// Igual que el formulario de movimientos: recibe funciones, no conoce
// SQLite ni providers.
class AccountSheet extends StatefulWidget {
  const AccountSheet({
    required this.onSave,
    this.account,
    this.onDelete,
    super.key,
  });

  final AccountBalance? account;
  final Future<void> Function(AccountData data) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<AccountSheet> {
  // El State es dueño de sus controllers y los libera en dispose().
  late final _name = TextEditingController(text: widget.account?.name);
  late final _initial = TextEditingController(
    text: switch (widget.account?.initialBalanceMinor.abs()) {
      null || 0 => '',
      final minor => amountInputText(minor),
    },
  );
  late String _type = widget.account?.type ?? 'bank';
  late bool _isDebt = (widget.account?.initialBalanceMinor ?? 0) < 0;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _initial.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _initial.dispose();
    super.dispose();
  }

  // Vacío o "0" = sin saldo inicial; si no, el mismo parser sin double.
  int? get _initialMinor {
    final text = _initial.text.trim();
    if (text.isEmpty || RegExp(r'^0+([.,]0*)?$').hasMatch(text)) return 0;
    final minor = parseAmountMinor(text);
    if (minor == null) return null;
    return _isDebt ? -minor : minor; // "Debo" = negativo
  }

  bool get _valid => _name.text.trim().isNotEmpty && _initialMinor != null;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return; // guard de doble toque, como en movimientos
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.account != null;
    final typeByIcon = {
      for (final e in AccountBalance.typeIcons.entries) e.value: e.key,
    };

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
            editing ? 'Editar cuenta' : 'Nueva cuenta',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            autofocus: !editing,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej. Banco Industrial',
            ),
          ),
          const SizedBox(height: 16),
          // En D el icono es el TIPO de cuenta (columna type con CHECK).
          IconPicker(
            options: AccountBalance.typeIcons.values.toList(),
            selected: AccountBalance.typeIcons[_type]!,
            labels: {
              for (final e in AccountBalance.typeIcons.entries)
                e.value: AccountBalance.typeLabels[e.key]!,
            },
            onSelected: (icon) => setState(() => _type = typeByIcon[icon]!),
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Tengo')),
              ButtonSegment(value: true, label: Text('Debo')),
            ],
            selected: {_isDebt},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _isDebt = s.single),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _initial,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _isDebt ? 'Deuda al empezar' : 'Saldo al empezar',
              prefixText: 'Q ',
              helperText: 'Lo que había antes de registrar movimientos',
              errorText: _initialMinor == null ? 'Monto inválido' : null,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: kPeligro)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _valid && !_busy
                ? () => _run(
                    () => widget.onSave((
                      name: _name.text,
                      type: _type,
                      initialBalanceMinor: _initialMinor!,
                    )),
                  )
                : null,
            child: Text(editing ? 'Guardar cambios' : 'Crear cuenta'),
          ),
          if (widget.onDelete != null)
            TextButton(
              onPressed: _busy ? null : () => _run(widget.onDelete!),
              style: TextButton.styleFrom(foregroundColor: kPeligro),
              child: const Text('Eliminar cuenta'),
            ),
        ],
      ),
    );
  }
}
