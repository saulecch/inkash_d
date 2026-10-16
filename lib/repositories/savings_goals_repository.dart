import '../database/app_database.dart';
import '../models/savings_goal.dart';

// S16-05: error de negocio con un mensaje para humanos (la pantalla lo
// muestra tal cual en un SnackBar).
class SavingsGoalException implements Exception {
  const SavingsGoalException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SavingsGoalsRepository {
  // S16-05: la base se inyecta para probar con un archivo temporal.
  SavingsGoalsRepository({AppDatabase? database})
    : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<List<SavingsGoal>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('savings_goals', orderBy: 'created_at_ms DESC');
    return maps.map(SavingsGoal.fromMap).toList();
  }

  // S16-05: las no archivadas; las que siguen en curso primero y las ya
  // completadas al final (una comparación en SQL vale 0 o 1).
  Future<List<SavingsGoal>> getActive() async {
    final db = await _db.database;
    final maps = await db.query(
      'savings_goals',
      where: 'is_archived = 0',
      orderBy: 'saved_amount_minor >= target_amount_minor, created_at_ms, id',
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

  /// S16-05: crea una meta nueva (sin ahorro todavía).
  Future<int> create(String name, int targetAmountMinor) {
    if (name.trim().isEmpty) {
      throw const SavingsGoalException('El nombre no puede quedar vacío.');
    }
    return insert(
      SavingsGoal(
        name: name.trim(),
        targetAmountMinor: targetAmountMinor,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// S16-05: editar nombre y objetivo SIN tocar lo ahorrado (eso solo
  /// cambia con aportes y retiros atómicos).
  Future<void> edit(int goalId, String name, int targetAmountMinor) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const SavingsGoalException('El nombre no puede quedar vacío.');
    }
    final db = await _db.database;
    await db.update(
      'savings_goals',
      {'name': cleanName, 'target_amount_minor': targetAmountMinor},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<void> delete(int goalId) async {
    final db = await _db.database;
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [goalId]);
  }

  Future<void> contribute(int goalId, int amountMinor) =>
      _move(goalId, amountMinor);

  Future<void> withdraw(int goalId, int amountMinor) =>
      _move(goalId, -amountMinor);

  /// Aporta (+) o retira (−) con UN solo UPDATE: la suma la hace SQLite.
  ///
  /// La versión "leer, sumar en Dart y escribir" pierde aportes si dos
  /// llegan a la vez (dos pantallas, doble toque): ambos leen 100, ambos
  /// escriben 150 en vez de 200.
  ///
  /// El WHERE también valida: si el retiro dejaría la meta en negativo, no
  /// cambia ninguna fila (rowsAffected = 0) y lo traducimos a un mensaje.
  /// El CHECK (saved_amount_minor >= 0) de la tabla, que existe desde la
  /// v1, queda como última línea de defensa.
  Future<void> _move(int goalId, int deltaMinor) async {
    final db = await _db.database;
    final rowsAffected = await db.rawUpdate(
      '''
      UPDATE savings_goals
      SET saved_amount_minor = saved_amount_minor + ?
      WHERE id = ? AND saved_amount_minor + ? >= 0
    ''',
      [deltaMinor, goalId, deltaMinor],
    );
    if (rowsAffected == 0) {
      throw const SavingsGoalException('No puedes retirar más de lo ahorrado.');
    }
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
