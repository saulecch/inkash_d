import 'package:flutter/material.dart';

import '../../../../models/account.dart';
import '../../../../models/category.dart';
import '../../../../models/movement.dart';
import '../../../../models/movement_form_options.dart';
import '../../../../models/new_movement.dart';
import '../../../../theme.dart';
import '../../../../utils/money.dart';
import '../../../../utils/occurred_on.dart';
import '../../../../utils/parse_amount.dart';
import '../../../../widgets/app_icons.dart';
import '../../../../widgets/ui/form_sheet.dart';

// S14-01: el sheet ya no recibe el controller completo, solo dos funciones.
// No sabe que existen SQLite ni los repositorios, y en las pruebas se le
// pasan funciones falsas.
// S16-03: devuelve 'saved' o 'deleted' (o null si se cerró sin cambios).
Future<String?> showMovementBottomSheet({
  required BuildContext context,
  required Future<MovementFormOptions> Function() loadOptions,
  required Future<void> Function(NewMovement newMovement) onSave,
  Future<Category?> Function(String classification)? onNewCategory,
  Movement? initial,
  Future<void> Function()? onDelete,
}) {
  // S17-01: fondo, esquinas, asa y ancho máximo salen del tema.
  return showFormSheet<String>(
    context,
    (_) => MovementBottomSheet(
      loadOptions: loadOptions,
      onSave: onSave,
      onNewCategory: onNewCategory,
      initial: initial,
      onDelete: onDelete,
    ),
  );
}

class MovementBottomSheet extends StatefulWidget {
  const MovementBottomSheet({
    required this.loadOptions,
    required this.onSave,
    this.onNewCategory,
    this.initial,
    this.onDelete,
    super.key,
  });

  // S16-03: con `initial`, el MISMO formulario sirve para editar.
  // Reutilizarlo evita que "crear" y "editar" validen distinto.
  final Movement? initial;
  final Future<void> Function()? onDelete;

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
            // Al editar, su categoría actual se muestra aunque esté archivada.
            (!category.isArchived ||
                category.id == widget.initial?.categoryId) &&
            category.classification == _classification,
      )
      .toList();

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m != null) {
      // Centavos -> texto SIN double: -1250 -> "12.50" (el signo lo pone
      // la categoría al guardar, igual que al crear).
      _amountController.text = amountInputText(m.amount.abs());
      _descriptionController.text = m.description;
      _notesController.text = m.notes ?? '';
      _occurredOn = decodeOccurredOn(m.occurredOn);
      _classification =
          m.categoryClassification ?? (m.amount > 0 ? 'income' : 'expense');
    }
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
        _accountId =
            widget.initial?.accountId ?? options.accounts.firstOrNull?.id;
        _categoryId =
            widget.initial?.categoryId ?? _availableCategories.firstOrNull?.id;
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
      if (mounted) Navigator.of(context).pop('saved');
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
      padding: EdgeInsets.fromLTRB(
        Spacing.xl,
        0,
        Spacing.xl,
        bottomInset + Spacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initial == null
                        ? 'Nuevo movimiento'
                        : 'Editar movimiento',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: Spacing.l),
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
              showSelectedIcon: false, // conserva las flechas de cada tipo
              onSelectionChanged: _saving
                  ? null
                  : (selection) => _changeClassification(selection.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity(vertical: 2),
              ),
            ),
            const SizedBox(height: Spacing.l),
            TextFormField(
              controller: _amountController,
              autofocus: true,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 30,
                fontFeatures: kTabularFigures,
              ),
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
            const SizedBox(height: Spacing.m),
            TextFormField(
              controller: _descriptionController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Descripción'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe una descripción.'
                  : null,
            ),
            const SizedBox(height: Spacing.m),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(Spacing.xl),
                  child: CircularProgressIndicator(),
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
              const SizedBox(height: Spacing.m),
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
            const SizedBox(height: Spacing.m),
            InkWell(
              onTap: _saving ? null : _selectDate,
              borderRadius: BorderRadius.circular(Corners.control),
              child: InputDecorator(
                decoration: _decoration('Fecha'),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: Spacing.s),
                    Text(_formatDate(_occurredOn)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.m),
            TextFormField(
              controller: _notesController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: _decoration('Notas (opcional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: Spacing.m),
              Text(_error!, style: const TextStyle(color: kPeligro)),
            ],
            const SizedBox(height: Spacing.xl),
            FilledButton(
              onPressed: _loading || _saving ? null : _save,
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
                        SizedBox(width: Spacing.s),
                        Text('Guardando…'),
                      ],
                    )
                  : Text(
                      widget.initial == null
                          ? 'Guardar movimiento'
                          : 'Guardar cambios',
                    ),
            ),
            // S16-03: borrar también desde aquí (en escritorio deslizar en
            // el Historial no es obvio). El Deshacer lo muestra quien abrió.
            if (widget.onDelete != null) ...[
              const SizedBox(height: Spacing.s),
              TextButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        await widget.onDelete!();
                        if (context.mounted) {
                          Navigator.of(context).pop('deleted');
                        }
                      },
                style: TextButton.styleFrom(foregroundColor: kPeligro),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar movimiento'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // S17-01: relleno, bordes y colores vienen de inputDecorationTheme.
  InputDecoration _decoration(String label) =>
      InputDecoration(labelText: label);

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
