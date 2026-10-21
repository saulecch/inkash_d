import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../repositories/categories_repository.dart';
import '../../theme.dart';
import '../../widgets/icon_picker.dart';

typedef CategoryData = ({String name, String classification, String iconKey});

// S16-02: crear (category == null) o editar una categoría en una hoja.
// Al guardar hace pop(categoría guardada) para que quien la abrió (p. ej.
// el formulario de movimientos) pueda seleccionarla de inmediato.
class CategorySheet extends StatefulWidget {
  const CategorySheet({
    required this.onSave,
    this.category,
    this.initialClassification = 'expense',
    this.onToggleArchived,
    this.onDelete,
    super.key,
  });

  final Category? category;
  final String initialClassification;
  final Future<Category> Function(CategoryData data) onSave;
  final Future<void> Function()? onToggleArchived;
  final Future<void> Function()? onDelete;

  static const icons = [
    'directions_bus',
    'shopping_cart',
    'restaurant',
    'local_cafe',
    'movie',
    'bolt',
    'home',
    'school',
    'health',
    'soap',
    'pets',
    'phone',
    'gift',
    'work',
    'arrow_upward',
    'attach_money',
  ];

  @override
  State<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<CategorySheet> {
  late final _name = TextEditingController(text: widget.category?.name);
  late String _icon = widget.category?.iconKey ?? CategorySheet.icons.first;
  late String _classification =
      widget.category?.classification ?? widget.initialClassification;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  // El resultado (si lo hay) es lo que recibe quien abrió la hoja.
  Future<void> _run(Future<Object?> Function() action) async {
    if (_busy) return; // guard de doble toque
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await action();
      if (mounted) Navigator.of(context).pop(result);
    } on CategoryException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
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
            category == null ? 'Nueva categoría' : 'Editar categoría',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Gasto')),
              ButtonSegment(value: 'income', label: Text('Ingreso')),
            ],
            selected: {_classification},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                setState(() => _classification = s.single),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: category == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej. Mascotas',
            ),
          ),
          const SizedBox(height: 16),
          IconPicker(
            options: CategorySheet.icons,
            selected: _icon,
            onSelected: (icon) => setState(() => _icon = icon),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: kPeligro)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _name.text.trim().isEmpty || _busy
                ? null
                : () => _run(
                    () => widget.onSave((
                      name: _name.text,
                      classification: _classification,
                      iconKey: _icon,
                    )),
                  ),
            child: Text(
              category == null ? 'Crear categoría' : 'Guardar cambios',
            ),
          ),
          if (category != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.onToggleArchived != null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await widget.onToggleArchived!();
                            return null;
                          }),
                    child: Text(category.isArchived ? 'Restaurar' : 'Archivar'),
                  ),
                if (widget.onDelete != null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await widget.onDelete!();
                            return null;
                          }),
                    style: TextButton.styleFrom(foregroundColor: kPeligro),
                    child: const Text('Eliminar'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
