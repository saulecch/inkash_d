import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/monthly_budget.dart';

class BudgetsRepository {
  // S17-02: la base se inyecta para probar con un archivo temporal.
  BudgetsRepository({AppDatabase? database})
    : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

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

  /// S17-02: el límite VIGENTE para [monthStart]: el de ese mes o, si no
  /// hay, el último definido antes. Así el límite que el usuario pone en
  /// Ajustes sigue valiendo el mes siguiente, y cada mes guarda su historia.
  /// month_start es texto 'yyyy-MM-01': el orden de texto es el cronológico.
  Future<MonthlyBudget?> getLatestUpTo(String monthStart) async {
    final db = await _db.database;
    final maps = await db.query(
      'monthly_budgets',
      where: 'month_start <= ?',
      whereArgs: [monthStart],
      orderBy: 'month_start DESC',
      limit: 1,
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
