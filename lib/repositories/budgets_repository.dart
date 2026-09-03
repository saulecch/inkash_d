import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/monthly_budget.dart';

class BudgetsRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<MonthlyBudget?> getByMonth(String monthStart) async {
    final db = await _db.database;
    final maps = await db.query(
      'monthly_budgets',
      where: 'month_start = ?',
      whereArgs: [monthStart],
    );
    if (maps.isEmpty) return null;
    return MonthlyBudget.fromMap(maps.first);
  }

  Future<void> upsert(MonthlyBudget budget) async {
    final db = await _db.database;
    await db.insert(
      'monthly_budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String monthStart) async {
    final db = await _db.database;
    await db.delete(
      'monthly_budgets',
      where: 'month_start = ?',
      whereArgs: [monthStart],
    );
  }
}
