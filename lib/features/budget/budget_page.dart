import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category_budget.dart';
import '../../theme.dart';
import '../../utils/clock.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../../widgets/amount_sheet.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/ui/page_header.dart';
import '../../widgets/ui/section.dart';
import 'budget_provider.dart';

// S16-04: la pestaña Presupuesto. Gastado vs límite por categoría.
class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(categoryBudgetsProvider);
    final month = ref.watch(clockProvider)();

    return SafeArea(
      child: budgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No pudimos leer el presupuesto.'),
              const SizedBox(height: Spacing.m),
              OutlinedButton(
                onPressed: () => ref.invalidate(categoryBudgetsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        // S17-01: encabezado, resumen y una Sección, como las demás pestañas.
        data: (rows) => ListView(
          padding: const EdgeInsets.only(bottom: Spacing.xxl),
          children: [
            PageHeader(title: 'Presupuesto', subtitle: monthName(month)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.l,
                0,
                Spacing.l,
                Spacing.xl,
              ),
              child: _Summary(rows: rows),
            ),
            Section(
              title: 'Toca una categoría para definir su límite mensual',
              children: [
                for (final row in rows)
                  _BudgetRow(
                    budget: row,
                    onTap: () => _editLimit(context, ref, row),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editLimit(
    BuildContext context,
    WidgetRef ref,
    CategoryBudget budget,
  ) async {
    // askAmount: hoja inferior dueña de su controller (ver amount_sheet).
    final answer = await askAmount(
      context,
      title: 'Límite para ${budget.name}',
      help: 'Cuánto quieres gastar como máximo cada mes.',
      initialMinor: budget.limitMinor,
      actions: [if (budget.limitMinor != null) 'Quitar límite', 'Guardar'],
    );
    if (answer == null) return; // se cerró sin elegir
    await ref
        .read(categoryBudgetsRepositoryProvider)
        .setLimit(
          budget.categoryId,
          answer.action == 'Guardar' ? answer.amountMinor : null,
        );
    ref.invalidate(categoryBudgetsProvider);
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.budget, required this.onTap});

  final CategoryBudget budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final limit = budget.limitMinor;
    final color = budget.isExceeded ? kPeligro : kLima;
    return ListTile(
      onTap: onTap,
      leading: Icon(iconFor(budget.iconKey), color: color),
      title: Text(budget.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.s),
          if (budget.progress != null)
            LinearProgressIndicator(
              value: budget.progress,
              minHeight: 6,
              color: color,
              borderRadius: BorderRadius.circular(Spacing.xs),
            ),
          const SizedBox(height: Spacing.xs),
          Text(
            limit == null
                ? 'Gastado ${formatQuetzales(budget.spentMinor)} · sin límite'
                : '${formatQuetzales(budget.spentMinor)} de '
                      '${formatQuetzales(limit)}'
                      '${budget.isExceeded ? ' · excedido' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontFeatures: kTabularFigures,
              color: budget.isExceeded ? kPeligro : kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// S16-04: total de lo presupuestado y lo gastado en ESAS categorías.
class _Summary extends StatelessWidget {
  const _Summary({required this.rows});

  final List<CategoryBudget> rows;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final withLimit = rows.where((r) => r.limitMinor != null);
    if (withLimit.isEmpty) {
      return Text(
        'Aún no tienes límites. Empieza por la categoría donde más gastas.',
        style: text.bodySmall,
      );
    }
    final limit = withLimit.fold(0, (t, r) => t + r.limitMinor!);
    final spent = withLimit.fold(0, (t, r) => t + r.spentMinor);
    final exceeded = withLimit.where((r) => r.isExceeded).length;
    final left = limit - spent;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // S17-01: excedido = "Te pasaste por …" en rojo, sin signo menos.
            Text(
              left >= 0
                  ? 'Te quedan ${formatQuetzales(left)}'
                  : 'Te pasaste por ${formatQuetzales(left)}',
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontFeatures: kTabularFigures,
                color: left >= 0 ? kTexto : kPeligro,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              '${formatQuetzales(spent)} de ${formatQuetzales(limit)}'
              '${exceeded > 0 ? ' · $exceeded excedida${exceeded > 1 ? 's' : ''}' : ''}',
              style: text.bodySmall?.copyWith(
                fontFeatures: kTabularFigures,
                color: exceeded > 0 ? kPeligro : kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
