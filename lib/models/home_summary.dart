import 'movement.dart';

class HomeSummary {
  final int totalBalanceMinor;
  final int monthlySpentMinor;
  final int monthlyBudgetMinor;
  final int activeGoals;
  final List<Movement> recentMovements;

  const HomeSummary({
    required this.totalBalanceMinor,
    required this.monthlySpentMinor,
    required this.monthlyBudgetMinor,
    required this.activeGoals,
    required this.recentMovements,
  });

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
