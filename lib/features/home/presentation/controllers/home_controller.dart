import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/home_summary.dart';
import '../../../../models/movement_form_options.dart';
import '../../../../models/new_movement.dart';
import '../../../../repositories/accounts_repository.dart';
import '../../../../repositories/budgets_repository.dart';
import '../../../../repositories/categories_repository.dart';
import '../../../../repositories/movements_repository.dart';
import '../../../../repositories/savings_goals_repository.dart';

// --- Providers de repositories (singletons) ---
// S14-02: además de compartir una instancia, permiten que las pruebas de
// widget los reemplacen por repositorios falsos (`overrideWithValue`).

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository();
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository();
});

final movementsRepositoryProvider = Provider<MovementsRepository>((ref) {
  return MovementsRepository();
});

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository();
});

final savingsGoalsRepositoryProvider = Provider<SavingsGoalsRepository>((ref) {
  return SavingsGoalsRepository();
});

// --- Provider principal del controller ---

// AsyncNotifier = estado que se obtiene con un Future.
// La pantalla recibe un AsyncValue<HomeSummary>: cargando · error · datos.
final homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeSummary>(
      HomeController.new,
      // Riverpod 3 reintenta solo los errores. Lo apagamos para que el
      // usuario vea el error y decida con el botón "Reintentar".
      retry: (_, _) => null,
    );

// --- Controller ---

// S14-02: antes era un ChangeNotifier con loading/error/summary a mano.
// Ahora esos tres estados los modela AsyncValue y no se pueden desincronizar.
class HomeController extends AsyncNotifier<HomeSummary> {
  // read (no watch): los repositorios no cambian durante la vida de la app.
  AccountsRepository get _accounts => ref.read(accountsRepositoryProvider);
  CategoriesRepository get _categories =>
      ref.read(categoriesRepositoryProvider);
  MovementsRepository get _movements => ref.read(movementsRepositoryProvider);
  BudgetsRepository get _budgets => ref.read(budgetsRepositoryProvider);
  SavingsGoalsRepository get _goals => ref.read(savingsGoalsRepositoryProvider);

  // build() corre la primera vez que alguien hace ref.watch y cada vez que
  // se invalida. Mientras el Future no termina, el estado es AsyncLoading;
  // si lanza, AsyncError. Ya no hace falta try/catch aquí.
  @override
  Future<HomeSummary> build() async {
    final now = DateTime.now();
    final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final results = await Future.wait([
      _accounts.getTotalBalance(),
      _movements.getMonthlyExpenses(yearMonth),
      _budgets.getByMonth('$yearMonth-01').then((b) => b?.limitMinor ?? 0),
      _goals.getActiveCount(),
      _movements.getRecent(5),
    ]);

    final totalBalance = results[0] as int;
    final monthlyExpenses = results[1] as int;
    final monthlyBudget = results[2] as int;
    final activeGoals = results[3] as int;
    final recentMovements = results[4] as List<dynamic>;

    return HomeSummary(
      totalBalanceMinor: totalBalance,
      monthlySpentMinor: monthlyExpenses.abs(),
      monthlyBudgetMinor: monthlyBudget,
      activeGoals: activeGoals,
      recentMovements: recentMovements.cast(),
    );
  }

  // El formulario no toca repositorios: pide opciones y guarda por aquí.
  Future<MovementFormOptions> loadFormOptions() async {
    return (
      accounts: await _accounts.getActive(),
      categories: await _categories.getAll(),
    );
  }

  // Si el INSERT falla, la excepción sube al formulario (que muestra el
  // error y conserva lo escrito) y NO se recarga nada.
  Future<void> saveMovement(NewMovement newMovement) async {
    await _movements.insertNew(newMovement);
    // Volvemos a consultar SQLite en vez de hacer lista.add(...): la base es
    // la única fuente de verdad (saldo, orden y totales salen de ahí).
    ref.invalidateSelf();
    await future;
  }
}
