import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../models/movement.dart';
import '../../utils/clock.dart';
import '../../utils/dates.dart';
import '../home/presentation/controllers/home_controller.dart';

// S15-03: qué quiere ver el usuario. Inmutable: cambiar el filtro = crear
// uno nuevo con copyWith (como HomeSummary, nunca se modifica en sitio).
class HistoryFilter {
  const HistoryFilter({required this.month, this.categoryId});

  final DateTime month; // siempre el día 1 del mes
  final int? categoryId; // null = todas

  // categoryId es una FUNCIÓN para poder pasar null a propósito ("Todas"):
  // con un int? normal, null significaría "no lo cambies".
  HistoryFilter copyWith({DateTime? month, int? Function()? categoryId}) {
    return HistoryFilter(
      month: month ?? this.month,
      categoryId: categoryId == null ? this.categoryId : categoryId(),
    );
  }

  // Con == por valor, tocar el chip que ya estaba elegido no repite la
  // consulta: Riverpod ve que el estado "nuevo" es igual al anterior.
  @override
  bool operator ==(Object other) =>
      other is HistoryFilter &&
      other.month == month &&
      other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(month, categoryId);
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterController, HistoryFilter>(
      HistoryFilterController.new,
    );

class HistoryFilterController extends Notifier<HistoryFilter> {
  // Empieza en el mes actual... según el reloj inyectable.
  @override
  HistoryFilter build() =>
      HistoryFilter(month: monthStart(ref.read(clockProvider)()));

  void previousMonth() => state = state.copyWith(
    month: DateTime(state.month.year, state.month.month - 1),
  );

  void nextMonth() => state = state.copyWith(
    month: DateTime(state.month.year, state.month.month + 1),
  );

  void selectCategory(int? categoryId) =>
      state = state.copyWith(categoryId: () => categoryId);
}

// LA IDEA DE LA CLASE: un provider que depende de otro.
// Este FutureProvider hace ref.watch del filtro; cuando el filtro cambia,
// Riverpod lo vuelve a ejecutar solo. No hay "if cambió, recargar".
final historyProvider = FutureProvider<List<Movement>>(
  (ref) {
    final filter = ref.watch(historyFilterProvider);
    return ref
        .watch(movementsRepositoryProvider)
        .getFiltered(month: filter.month, categoryId: filter.categoryId);
  },
  // Igual que en HomeController: el usuario decide con "Reintentar".
  retry: (_, _) => null,
);

final usedCategoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(movementsRepositoryProvider).getUsedCategories(),
  retry: (_, _) => null,
);
