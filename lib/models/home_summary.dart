import 'month_totals.dart';
import 'movement.dart';

class HomeSummary {
  // S15-02: el mes que se muestra (lo da el reloj, no 'Julio 2026' fijo).
  final DateTime month;
  final int totalBalanceMinor;
  // Totales DEL MES, sumados por SQLite.
  final MonthTotals monthTotals;
  final int monthlyBudgetMinor;
  final int activeGoals;
  final List<Movement> recentMovements;

  const HomeSummary({
    required this.month,
    required this.totalBalanceMinor,
    required this.monthTotals,
    required this.monthlyBudgetMinor,
    required this.activeGoals,
    required this.recentMovements,
  });

  int get monthlySpentMinor => monthTotals.expensesMinor;

  int get availableBudgetMinor => monthlyBudgetMinor - monthlySpentMinor;

  double get budgetProgress {
    if (monthlyBudgetMinor == 0) return 0;
    return (monthlySpentMinor / monthlyBudgetMinor).clamp(0.0, 1.0);
  }

  String formatQuetzales(int centavos) {
    final abs = centavos.abs();
    final entero = abs ~/ 100;
    final decimales = (abs % 100).toString().padLeft(2, '0');
    final miles = entero.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    final prefix = centavos < 0 ? '-' : '';
    return '$prefix Q$miles.$decimales';
  }
}
