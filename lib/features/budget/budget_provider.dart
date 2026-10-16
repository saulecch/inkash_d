import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category_budget.dart';
import '../../repositories/category_budgets_repository.dart';
import '../../utils/clock.dart';

final categoryBudgetsRepositoryProvider = Provider<CategoryBudgetsRepository>(
  (ref) => CategoryBudgetsRepository(),
);

// S16-04: el mes sale del reloj inyectable (en pruebas, octubre 2026).
// Se invalida al definir un límite y al guardar/borrar/deshacer.
final categoryBudgetsProvider = FutureProvider<List<CategoryBudget>>(
  (ref) => ref
      .watch(categoryBudgetsRepositoryProvider)
      .getForMonth(ref.watch(clockProvider)()),
  retry: (_, _) => null,
);
