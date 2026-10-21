import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/movement.dart';
import '../../theme.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../../utils/occurred_on.dart';
import '../home/presentation/controllers/home_controller.dart';
import '../home/presentation/widgets/movement_tile.dart';
import '../home/presentation/widgets/open_movement_form.dart';
import '../../widgets/ui/empty_state.dart';
import '../../widgets/ui/page_header.dart';
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
          // S17-01: el mismo encabezado que las demás pestañas; el selector
          // de mes es su acción.
          PageHeader(
            title: 'Historial',
            subtitle: monthName(filter.month),
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.outlined(
                  tooltip: 'Mes anterior',
                  onPressed: controller.previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                const SizedBox(width: Spacing.s),
                IconButton.outlined(
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: kPeligro, size: 40),
                    const SizedBox(height: Spacing.m),
                    const Text('No pudimos leer el historial.'),
                    const SizedBox(height: Spacing.m),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(historyProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (list) => list.isEmpty
                  // S17-01: el vacío invita a hacer algo.
                  ? Center(
                      child: SingleChildScrollView(
                        child: EmptyState(
                          icon: Icons.event_busy_outlined,
                          title:
                              'Sin movimientos en ${monthName(filter.month)}',
                          message: filter.categoryId == null
                              ? null
                              : 'Prueba con "Todas" las categorías.',
                          action: 'Registrar movimiento',
                          onAction: () => openMovementForm(context, ref),
                        ),
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
      padding: const EdgeInsets.only(right: Spacing.s),
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
        padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
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

    final text = Theme.of(context).textTheme;
    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: Spacing.m, bottom: Spacing.s),
        child: Text(
          'Gastos ${formatQuetzales(expenses)} · '
          'Ingresos ${formatQuetzales(income)}',
          style: text.bodySmall?.copyWith(fontFeatures: kTabularFigures),
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
            padding: const EdgeInsets.only(top: Spacing.l, bottom: Spacing.xs),
            child: Text(
              dayLabel(decodeOccurredOn(m.occurredOn)),
              style: text.bodySmall?.copyWith(
                color: kLima,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        previousDay = day;
      }
      rows.add(_SwipeToDelete(movement: m));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xxl),
      children: rows,
    );
  }
}

// S15-04: deslizar a la izquierda para borrar, con "Deshacer".
class _SwipeToDelete extends ConsumerWidget {
  const _SwipeToDelete({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      // La key debe ser el id: con el índice, al borrar la fila 2 la 3
      // heredaría su key y Flutter confundiría las filas.
      key: ValueKey(movement.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacing.xl),
        decoration: BoxDecoration(
          color: kPeligro.withValues(alpha: .25),
          borderRadius: BorderRadius.circular(Corners.control),
        ),
        child: const Icon(Icons.delete_outline, color: kPeligro),
      ),
      // confirmDismiss: PRIMERO borramos en SQLite. Si falla, devolvemos
      // false y la fila regresa a su lugar (no "desaparece" en falso).
      confirmDismiss: (_) async {
        // Se toman antes del await: después, el context puede ya no estar.
        final messenger = ScaffoldMessenger.of(context);
        final controller = ref.read(homeControllerProvider.notifier);
        try {
          final deleted = await controller.deleteMovement(movement.id!);
          messenger.hideCurrentSnackBar(); // sin fila de avisos viejos
          messenger.showSnackBar(
            SnackBar(
              content: Text('"${movement.description}" eliminado'),
              action: deleted == null
                  ? null
                  : SnackBarAction(
                      label: 'Deshacer',
                      onPressed: () => controller.undoDelete(deleted),
                    ),
            ),
          );
          return true;
        } catch (_) {
          messenger.showSnackBar(
            const SnackBar(content: Text('No se pudo eliminar.')),
          );
          return false;
        }
      },
      child: MovementTile(
        movement: movement,
        onTap: () => openMovementForm(context, ref, edit: movement),
      ),
    );
  }
}
