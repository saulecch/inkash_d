import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../theme.dart';
import '../../widgets/app_icons.dart';
import '../budget/budget_provider.dart';
import '../history/history_controller.dart';
import '../home/presentation/controllers/home_controller.dart';
import 'categories_provider.dart';
import 'category_sheet.dart';

// S16-02: se abre desde Ajustes. Gastos / Ingresos / Archivadas.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openCategoryForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
      body: categories.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kLima)),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No pudimos leer las categorías.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(categoriesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (list) {
          // 'adjustment' (Saldo inicial) es de la app: no se muestra aquí.
          Iterable<Category> active(String classification) => list.where(
            (c) => c.classification == classification && !c.isArchived,
          );
          final archived = list.where(
            (c) => c.isArchived && c.classification != 'adjustment',
          );
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              _Section('Gastos', active('expense'), ref),
              _Section('Ingresos', active('income'), ref),
              if (archived.isNotEmpty) _Section('Archivadas', archived, ref),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.categories, this.ref);

  final String title;
  final Iterable<Category> categories;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: const TextStyle(color: kLima, fontSize: 12),
          ),
        ),
        for (final c in categories)
          ListTile(
            leading: Icon(
              iconFor(c.iconKey),
              color: c.isArchived ? kMuted : kLima,
            ),
            title: Text(
              c.name,
              style: TextStyle(color: c.isArchived ? kMuted : kTexto),
            ),
            trailing: const Icon(Icons.chevron_right, color: kMuted),
            onTap: () => openCategoryForm(context, ref, category: c),
          ),
      ],
    );
  }
}

/// S16-02: abre el formulario de categoría y devuelve la categoría guardada
/// (o null). Lo usan esta pantalla y el formulario de movimientos
/// ("+ Nueva"), así que vive aquí y no dentro de la página.
Future<Category?> openCategoryForm(
  BuildContext context,
  WidgetRef ref, {
  Category? category,
  String initialClassification = 'expense',
}) {
  final repository = ref.read(categoriesRepositoryProvider);
  // El nombre de la categoría aparece en movimientos, chips y presupuesto.
  void refresh() {
    ref.invalidate(categoriesProvider);
    ref.invalidate(homeControllerProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(usedCategoriesProvider);
    ref.invalidate(categoryBudgetsProvider); // S16-04: filas del presupuesto
  }

  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: kSuperficie,
    builder: (_) => CategorySheet(
      category: category,
      initialClassification: initialClassification,
      onSave: (data) async {
        final saved = await repository.save(
          id: category?.id,
          name: data.name,
          classification: data.classification,
          iconKey: data.iconKey,
        );
        refresh();
        return saved;
      },
      onToggleArchived: category == null
          ? null
          : () async {
              await repository.setArchived(
                category.id!,
                archived: !category.isArchived,
              );
              refresh();
            },
      onDelete: category == null
          ? null
          : () async {
              await repository.delete(category.id!);
              refresh();
            },
    ),
  );
}
