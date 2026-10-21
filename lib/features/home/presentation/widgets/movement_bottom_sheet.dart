import 'package:flutter/material.dart';

import '../../../../models/account.dart';
import '../../../../models/category.dart';
import '../../../../models/movement_form_options.dart';
import '../../../../models/new_movement.dart';
import '../../../../theme.dart';
import '../../../../utils/parse_amount.dart';
import '../../../../widgets/app_icons.dart';

// S14-01: el sheet ya no recibe el controller completo, solo dos funciones.
// No sabe que existen SQLite ni los repositorios, y en las pruebas se le
// pasan funciones falsas.
Future<bool?> showMovementBottomSheet({
  required BuildContext context,
  required Future<MovementFormOptions> Function() loadOptions,
  required Future<void> Function(NewMovement newMovement) onSave,
  Future<Category?> Function(String classification)? onNewCategory,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: kSuperficie,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => MovementBottomSheet(
      loadOptions: loadOptions,
      onSave: onSave,
      onNewCategory: onNewCategory,
    ),
  );
}

class MovementBottomSheet extends StatefulWidget {
  const MovementBottomSheet({
    required this.loadOptions,
    required this.onSave,
    this.onNewCategory,
    super.key,
  });

  final Future<MovementFormOptions> Function() loadOptions;
  final Future<void> Function(NewMovement newMovement) onSave;

  // S16-02: "+ Nueva" crea una categoría sin salir del formulario. Devuelve
  // la categoría creada (ya con id de la base) o null si se canceló.
  // Sigue siendo una función: el formulario no conoce SQLite ni providers.
  final Future<Category?> Function(String classification)? onNewCategory;

  @override
  State<MovementBottomSheet> createState() => _MovementBottomSheetState();
}

class _MovementBottomSheetState extends State<MovementBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  List<Account> _accounts = const [];
  List<Category> _categories = const [];
  String _classification = 'expense';
  int? _accountId;
  int? _categoryId;
  DateTime _occurredOn = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<Category> get _availableCategories => _categories
      .where(
        (category) =>
            !category.isArchived && category.classification == _classification,
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await widget.loadOptions();
      if (!mounted) return;

      setState(() {
        _accounts = options.accounts;
        _categories = options.categories;
        _accountId = options.accounts.firstOrNull?.id;
        _categoryId = _availableCategories.firstOrNull?.id;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No fue posible cargar las cuentas y categorías.';
        _loading = false;
      });
    }
  }

  Future<void> _newCategory() async {
    final created = await widget.onNewCategory!(_classification);
    if (created == null || !mounted) return;
    setState(() {
      _categories = [..._categories, created];
      // Si la crearon de otro tipo, el formulario cambia a ese tipo.
      _classification = created.classification;
      _categoryId = created.id;
    });
  }

  void _changeClassification(String classification) {
    setState(() {
      _classification = classification;
      _categoryId = _availableCategories.firstOrNull?.id;
    });
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _occurredOn,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _occurredOn = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _occurredOn.hour,
        _occurredOn.minute,
        _occurredOn.second,
        _occurredOn.millisecond,
      );
    });
  }

  Future<void> _save() async {
    // Guard contra doble toque: se revisa ANTES del primer await.
    // El botón se deshabilita en el siguiente frame; dos toques en el mismo
    // frame llegarían los dos aquí. Antes de S14 se guardaba dos veces.
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final notes = _notesController.text.trim();
    try {
      await widget.onSave(
        NewMovement(
          accountId: _accountId!,
          categoryId: _categoryId!,
          // Positivo: el repositorio pone el signo según la categoría.
          amountMinor: parseAmountMinor(_amountController.text)!,
          description: _descriptionController.text.trim(),
          occurredAt: _occurredOn,
          notes: notes.isEmpty ? null : notes,
        ),
      );
      // Después de un await la pantalla pudo cerrarse: siempre preguntar.
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      // El formulario conserva lo escrito para que el usuario reintente.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No fue posible guardar el movimiento. Intenta otra vez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: kMuted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nuevo movimiento',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'expense',
                  label: Text('Gasto'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('Ingreso'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_classification},
              onSelectionChanged: _saving
                  ? null
                  : (selection) => _changeClassification(selection.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity(vertical: 2),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              autofocus: true,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              decoration: _decoration(
                'Monto',
              ).copyWith(prefixText: 'Q ', hintText: '0.00'),
              validator: (value) {
                if (parseAmountMinor(value ?? '') == null) {
                  return 'Monto inválido: mayor que 0 y hasta 2 decimales.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Descripción'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe una descripción.'
                  : null,
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: kLima),
                ),
              )
            else ...[
              DropdownButtonFormField<int>(
                initialValue: _accountId,
                decoration: _decoration('Cuenta'),
                items: _accounts
                    .map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _accountId = value),
                validator: (value) => value == null
                    ? 'Crea o selecciona una cuenta activa.'
                    : null,
              ),
              const SizedBox(height: 14),
              // S16-02: chips con icono en vez de una lista desplegable:
              // se ve todo de un vistazo y cabe el chip "+ Nueva".
              FormField<int>(
                key: ValueKey('$_classification-$_categoryId'),
                initialValue: _categoryId,
                validator: (_) => _categoryId == null
                    ? 'Selecciona una categoría disponible.'
                    : null,
                builder: (field) => InputDecorator(
                  decoration: _decoration(
                    'Categoría',
                  ).copyWith(errorText: field.errorText),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in _availableCategories)
                        ChoiceChip(
                          avatar: Icon(
                            iconFor(category.iconKey),
                            size: 18,
                            color: _categoryId == category.id ? kLima : kMuted,
                          ),
                          label: Text(category.name),
                          selected: _categoryId == category.id,
                          selectedColor: kIconoFondo,
                          showCheckmark: false,
                          onSelected: _saving
                              ? null
                              : (_) =>
                                    setState(() => _categoryId = category.id),
                        ),
                      if (widget.onNewCategory != null)
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18, color: kLima),
                          label: const Text('Nueva'),
                          onPressed: _saving ? null : _newCategory,
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            InkWell(
              onTap: _saving ? null : _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _decoration('Fecha'),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(_formatDate(_occurredOn)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: _decoration('Notas (opcional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: kPeligro)),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _loading || _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: kLima,
                foregroundColor: kFondo,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              // Mientras guarda, el botón dice qué está pasando (no solo gira).
              child: _saving
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kFondo,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Guardando…',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    )
                  : const Text(
                      'Guardar movimiento',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: kFondo,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorde),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
