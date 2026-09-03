import '../database/app_database.dart';
import '../models/movement.dart';

class MovementsRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Movement>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('movements', orderBy: 'occurred_on DESC, id DESC');
    return maps.map(Movement.fromMap).toList();
  }

  Future<List<Movement>> getByMonth(String yearMonth) async {
    final db = await _db.database;
    final maps = await db.query(
      'movements',
      where: 'occurred_on LIKE ?',
      whereArgs: ['$yearMonth%'],
      orderBy: 'occurred_on DESC, id DESC',
    );
    return maps.map(Movement.fromMap).toList();
  }

  Future<List<Movement>> getRecent(int limit) async {
    final db = await _db.database;
    final maps = await db.query(
      'movements',
      orderBy: 'occurred_on DESC, id DESC',
      limit: limit,
    );
    return maps.map(Movement.fromMap).toList();
  }

  Future<Movement?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('movements', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Movement.fromMap(maps.first);
  }

  Future<int> insert(Movement movement) async {
    final db = await _db.database;
    return db.insert('movements', movement.toMap());
  }

  Future<void> update(Movement movement) async {
    final db = await _db.database;
    await db.update(
      'movements',
      movement.toMap(),
      where: 'id = ?',
      whereArgs: [movement.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('movements', where: 'id = ?', whereArgs: [id]);
  }

  /// Gastos totales del mes (negativos).
  Future<int> getMonthlyExpenses(String yearMonth) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(m.amount_minor), 0) AS total
      FROM movements m
      JOIN categories c ON c.id = m.category_id
      WHERE c.classification = 'expense'
        AND m.occurred_on LIKE ?
    ''', ['$yearMonth%']);
    return (result.first['total'] as int?) ?? 0;
  }

  /// Ingresos totales del mes (positivos).
  Future<int> getMonthlyIncome(String yearMonth) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(m.amount_minor), 0) AS total
      FROM movements m
      JOIN categories c ON c.id = m.category_id
      WHERE c.classification = 'income'
        AND m.occurred_on LIKE ?
    ''', ['$yearMonth%']);
    return (result.first['total'] as int?) ?? 0;
  }

  /// Inserta movimiento + saldo inicial en una sola transacción.
  Future<void> createWithInitialBalance({
    required int accountId,
    required int amountMinor,
    required int categoryId,
    required String description,
    required String occurredOn,
  }) async {
    final db = await _db.database;
    await db.transaction((tx) async {
      await tx.insert('movements', {
        'account_id': accountId,
        'category_id': categoryId,
        'amount_minor': amountMinor,
        'description': description,
        'occurred_on': occurredOn,
        'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }
}
