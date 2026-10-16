import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/movement.dart';
import '../../theme.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../../utils/occurred_on.dart';
import '../home/presentation/widgets/movement_tile.dart';
import 'history_controller.dart';

// S15-03: la pestaña Historial. Solo pinta: el filtro vive en
// historyFilterProvider y la consulta en historyProvider.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(historyFilterProvider);
    final controller = ref.read(historyFilterProvider.notifier);
    final movements = ref.watch(historyProvider);

    return SafeArea(
      child: Column(
        children: [
          // Selector de mes: ‹ Octubre 2026 ›
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Mes anterior',
                  onPressed: controller.previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    monthName(filter.month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  tooltip: 'Mes siguiente',
                  onPressed: controller.nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          _CategoryChips(selectedId: filter.categoryId),
          Expanded(
            // Al cambiar el filtro (un "reload") se ve el indicador de carga;
            // tras guardar (un "refresh") se queda la lista anterior mientras
            // llega la nueva. Son los valores por defecto de when().
            child: movements.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: kLima)),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: kPeligro, size: 40),
                    const SizedBox(height: 12),
                    const Text('No pudimos leer el historial.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(historyProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (list) => list.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin movimientos en este mes.',
                        style: TextStyle(color: kMuted),
                      ),
                    )
                  : _GroupedList(movements: list),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.selectedId});

  final int? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si las categorías fallan o están cargando, mostramos solo "Todas":
    // un filtro no debe tumbar la pantalla.
    final categories = ref.watch(usedCategoriesProvider).value ?? const [];
    final controller = ref.read(historyFilterProvider.notifier);

    Widget chip(String label, int? id) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedId == id,
        onSelected: (_) => controller.selectCategory(id),
      ),
    );

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          chip('Todas', null),
          for (final category in categories) chip(category.name, category.id),
        ],
      ),
    );
  }
}

// Lista con un encabezado por día y, arriba, los totales del filtro.
class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.movements});

  final List<Movement> movements;

  @override
  Widget build(BuildContext context) {
    // Aquí sí sumamos en Dart: la lista ya está en memoria y filtrada
    // (puede ser una sola categoría, que getMonthTotals no cubre).
    var expenses = 0;
    var income = 0;
    for (final m in movements) {
      if (m.amount < 0) {
        expenses -= m.amount; // el gasto viene negativo
      } else {
        income += m.amount;
      }
    }

    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text(
          'Gastos ${formatQuetzales(expenses)} · '
          'Ingresos ${formatQuetzales(income)}',
          style: const TextStyle(color: kMuted, fontSize: 12),
        ),
      ),
    ];
    int? previousDay;
    for (final m in movements) {
      // Los primeros 8 dígitos de occurredOn son yyyyMMdd: el día exacto.
      final day = m.occurredOn ~/ 1000000000;
      // Vienen ordenados por fecha: basta comparar con el anterior.
      if (day != previousDay) {
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              dayLabel(decodeOccurredOn(m.occurredOn)),
              style: const TextStyle(color: kLima, fontSize: 12),
            ),
          ),
        );
        previousDay = day;
      }
      rows.add(MovementTile(movement: m));
    }
    return ListView(children: rows);
  }
}
