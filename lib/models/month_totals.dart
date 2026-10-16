// S15-02: totales de un mes, ya sumados por SQLite (no en Dart).
class MonthTotals {
  const MonthTotals({required this.expensesMinor, required this.incomeMinor});

  // Ambos positivos: el signo es cosa de la base de datos.
  final int expensesMinor;
  final int incomeMinor;
}
