import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../models/monthly_budget.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/clock.dart';
import '../accounts/account_balances_provider.dart';
import '../budget/budget_provider.dart';
import '../goals/goals_provider.dart';
import '../history/history_controller.dart';
import '../home/presentation/controllers/exchange_rate_provider.dart';
import '../home/presentation/controllers/home_controller.dart'
    show budgetsRepositoryProvider;

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

// S17-02: el Inicio hace ref.watch de este provider. Cambiar el nombre o el
// límite en Ajustes recalcula el Inicio SIN que Ajustes sepa que el Inicio
// existe (las pantallas no se conocen entre sí, solo comparten estado).
final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
  retry: (_, _) => null,
);

class SettingsController extends AsyncNotifier<AppSettings> {
  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  // El límite vive en monthly_budgets (una fila por mes, desde S10).
  String get _currentMonthStart {
    final today = ref.read(clockProvider)();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-01';
  }

  @override
  Future<AppSettings> build() async {
    final (userName, budget) = await (
      _settings.getUserName(),
      ref.read(budgetsRepositoryProvider).getLatestUpTo(_currentMonthStart),
    ).wait;
    return AppSettings(
      userName: userName,
      monthlyLimitMinor: budget?.limitMinor ?? 0,
    );
  }

  Future<void> changeUserName(String name) async {
    await _settings.setUserName(name);
    ref.invalidateSelf();
    await future;
  }

  // Se guarda como el límite del mes ACTUAL; los meses pasados no cambian.
  Future<void> changeMonthlyLimit(int limitMinor) async {
    await ref
        .read(budgetsRepositoryProvider)
        .upsert(
          MonthlyBudget(
            monthStart: _currentMonthStart,
            limitMinor: limitMinor,
            createdAtMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteAllUserData() async {
    await _settings.deleteAllUserData();
    // Todo lo que lee las tablas borradas debe volver a leer. La lista es
    // EXPLÍCITA a propósito: si mañana se agrega una pantalla, hay que
    // decidir aquí si sus datos son "del usuario".
    // El Inicio NO va en la lista: hace ref.watch(settingsProvider), así que
    // invalidateSelf() ya lo recalcula. Invalidarlo desde aquí es un ciclo
    // (Riverpod 3 lanza CircularDependencyError: el Inicio depende de este).
    ref.invalidate(historyProvider);
    ref.invalidate(usedCategoriesProvider);
    ref.invalidate(accountBalancesProvider);
    ref.invalidate(categoryBudgetsProvider);
    ref.invalidate(savingsGoalsProvider);
    ref.invalidate(exchangeRateProvider);
    ref.invalidateSelf();
    await future;
  }
}
