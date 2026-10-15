import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../models/home_summary.dart';
import '../../../../models/movement_form_options.dart';
import '../../../../models/new_movement.dart';
import '../../../../repositories/accounts_repository.dart';
import '../../../../repositories/budgets_repository.dart';
import '../../../../repositories/categories_repository.dart';
import '../../../../repositories/movements_repository.dart';
import '../../../../repositories/savings_goals_repository.dart';

// --- Providers de repositories (singletons) ---

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

final movimientosControllerProvider = Provider<MovimientosController>((ref) {
  return MovimientosController(
    accounts: ref.read(accountsRepositoryProvider),
    categories: ref.read(categoriesRepositoryProvider),
    movements: ref.read(movementsRepositoryProvider),
    budgets: ref.read(budgetsRepositoryProvider),
    goals: ref.read(savingsGoalsRepositoryProvider),
  );
});

// --- Controller ---

class MovimientosController extends ChangeNotifier {
  MovimientosController({
    required this.accounts,
    required this.categories,
    required this.movements,
    required this.budgets,
    required this.goals,
  });

  final AccountsRepository accounts;
  final CategoriesRepository categories;
  final MovementsRepository movements;
  final BudgetsRepository budgets;
  final SavingsGoalsRepository goals;

  HomeSummary? _summary;
  HomeSummary? get summary => _summary;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> loadHomeData() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        accounts.getTotalBalance(),
        movements.getMonthlyExpenses(yearMonth),
        budgets.getByMonth('$yearMonth-01').then((b) => b?.limitMinor ?? 0),
        goals.getActiveCount(),
        movements.getRecent(5),
      ]);

      final totalBalance = results[0] as int;
      final monthlyExpenses = results[1] as int;
      final monthlyBudget = results[2] as int;
      final activeGoals = results[3] as int;
      final recentMovements = results[4] as List<dynamic>;

      _summary = HomeSummary(
        totalBalanceMinor: totalBalance,
        monthlySpentMinor: monthlyExpenses.abs(),
        monthlyBudgetMinor: monthlyBudget,
        activeGoals: activeGoals,
        recentMovements: recentMovements.cast(),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // S14-01: el formulario ya no toca repositorios. Pide opciones y guarda
  // a través del controller (formulario -> controller -> repository -> SQL).
  Future<MovementFormOptions> loadFormOptions() async {
    return (
      accounts: await accounts.getActive(),
      categories: await categories.getAll(),
    );
  }

  // Si el INSERT falla, la excepción sube al formulario (que muestra el
  // error y conserva lo escrito) y NO se recarga nada.
  Future<void> saveMovement(NewMovement newMovement) async {
    await movements.insertNew(newMovement);
    await loadHomeData();
  }
}
