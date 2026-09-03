import '../database/app_database.dart';
import '../models/savings_goal.dart';

class SavingsGoalsRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<SavingsGoal>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('savings_goals', orderBy: 'created_at_ms DESC');
    return maps.map(SavingsGoal.fromMap).toList();
  }

  Future<List<SavingsGoal>> getActive() async {
    final db = await _db.database;
    final maps = await db.query(
      'savings_goals',
      where: 'is_archived = 0',
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(SavingsGoal.fromMap).toList();
  }

  Future<SavingsGoal?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SavingsGoal.fromMap(maps.first);
  }

  Future<int> getActiveCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM savings_goals
      WHERE is_archived = 0 AND saved_amount_minor < target_amount_minor
    ''');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> insert(SavingsGoal goal) async {
    final db = await _db.database;
    return db.insert('savings_goals', goal.toMap());
  }

  Future<void> update(SavingsGoal goal) async {
    final db = await _db.database;
    await db.update(
      'savings_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  /// Aporta o retira de una meta de forma atómica.
  Future<void> addContribution(int goalId, int amountMinor) async {
    final db = await _db.database;
    await db.rawUpdate('''
      UPDATE savings_goals
      SET saved_amount_minor = saved_amount_minor + ?
      WHERE id = ?
    ''', [amountMinor, goalId]);
  }

  Future<void> archive(int id) async {
    final db = await _db.database;
    await db.update(
      'savings_goals',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
