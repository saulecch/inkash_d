import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/deleted_movement.dart';
import '../../../../models/home_summary.dart';
import '../../../../models/movement_form_options.dart';
import '../../../../models/new_movement.dart';
import '../../../../repositories/accounts_repository.dart';
import '../../../../repositories/budgets_repository.dart';
import '../../../../repositories/categories_repository.dart';
import '../../../../repositories/movements_repository.dart';
import '../../../../repositories/savings_goals_repository.dart';
import '../../../../utils/clock.dart';
import '../../../accounts/account_balances_provider.dart';
import '../../../history/history_controller.dart';

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

  // S15-02: el Inicio muestra solo los últimos N movimientos.
  static const recentCount = 5;

  // build() corre la primera vez que alguien hace ref.watch y cada vez que
  // se invalida. Mientras el Future no termina, el estado es AsyncLoading;
  // si lanza, AsyncError. Ya no hace falta try/catch aquí.
  @override
  Future<HomeSummary> build() async {
    // S15-02: la fecha viene del reloj inyectable, no de DateTime.now().
    final today = ref.read(clockProvider)();
    final yearMonth = '${today.year}-${today.month.toString().padLeft(2, '0')}';

    // Consultas independientes EN PARALELO con un record + .wait.
    // A diferencia de Future.wait([...]), cada resultado conserva su tipo:
    // ya no hay results[0] as int. Si una falla, build falla (AsyncError).
    final (
      totalBalance,
      monthTotals,
      monthlyBudget,
      activeGoals,
      recent,
    ) = await (
      _accounts.getTotalBalance(),
      _movements.getMonthTotals(today),
      _budgets.getByMonth('$yearMonth-01').then((b) => b?.limitMinor ?? 0),
      _goals.getActiveCount(),
      _movements.getRecent(recentCount),
    ).wait;

    return HomeSummary(
      month: today,
      totalBalanceMinor: totalBalance,
      monthTotals: monthTotals,
      monthlyBudgetMinor: monthlyBudget,
      activeGoals: activeGoals,
      recentMovements: recent,
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
    await _refreshAll();
  }

  // S15-04: borrar y deshacer siguen la misma regla que guardar:
  // escribir en SQLite y volver a consultar todo lo que depende de eso.
  Future<DeletedMovement?> deleteMovement(int id) async {
    final deleted = await _movements.delete(id);
    await _refreshAll();
    return deleted;
  }

  Future<void> undoDelete(DeletedMovement deleted) async {
    await _movements.restore(deleted);
    await _refreshAll();
  }

  // Volvemos a consultar SQLite en vez de hacer lista.add(...): la base es
  // la única fuente de verdad (saldo, orden y totales salen de ahí).
  // El Historial también muestra movimientos: si no lo invalidamos,
  // seguiría con la lista vieja (y sin la categoría nueva).
  Future<void> _refreshAll() async {
    ref.invalidateSelf();
    ref.invalidate(historyProvider);
    ref.invalidate(usedCategoriesProvider);
    ref.invalidate(accountBalancesProvider); // S16-01: los saldos cambian
    await future;
  }
}
