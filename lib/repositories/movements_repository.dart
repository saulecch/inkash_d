import '../database/app_database.dart';
import '../models/movement.dart';
import '../models/new_movement.dart';

class MovementsRepository {
  // S14-01: la base se inyecta para probar con un archivo temporal.
  MovementsRepository({AppDatabase? database})
    : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<List<Movement>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'movements',
      orderBy: 'occurred_on DESC, id DESC',
    );
    return maps.map(Movement.fromMap).toList();
  }

  Future<List<Movement>> getByMonth(String yearMonth) async {
    final db = await _db.database;
    final maps = await db.query(
      'movements',
      where: 'substr(occurred_on, 1, 6) = ?',
      whereArgs: [yearMonth.replaceAll('-', '')],
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

  /// Guarda lo que llega del formulario. Leer la categoría e insertar van en
  /// UNA transacción: si alguien archiva la categoría entre la lectura y el
  /// INSERT, no queda un movimiento con el signo equivocado.
  Future<int> insertNew(NewMovement newMovement) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'categories',
        columns: ['classification'],
        where: 'id = ? AND is_archived = 0', // Siempre con ?, nunca concatenar.
        whereArgs: [newMovement.categoryId],
      );
      if (rows.isEmpty) {
        throw StateError('La categoría ya no está disponible.');
      }
      // El gasto se guarda NEGATIVO: así SUM(amount) es el saldo.
      // La fuente de verdad del signo es la categoría, no la pantalla.
      final isExpense = rows.single['classification'] == 'expense';
      final movement = newMovement.toMovement(
        signedAmount: isExpense
            ? -newMovement.amountMinor
            : newMovement.amountMinor,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      return txn.insert('movements', movement.toMap());
    });
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
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(m.amount), 0) AS total
      FROM movements m
      JOIN categories c ON c.id = m.category_id
      WHERE c.classification = 'expense'
        AND substr(m.occurred_on, 1, 6) = ?
    ''',
      [yearMonth.replaceAll('-', '')],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Ingresos totales del mes (positivos).
  Future<int> getMonthlyIncome(String yearMonth) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(m.amount), 0) AS total
      FROM movements m
      JOIN categories c ON c.id = m.category_id
      WHERE c.classification = 'income'
        AND substr(m.occurred_on, 1, 6) = ?
    ''',
      [yearMonth.replaceAll('-', '')],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Inserta movimiento + saldo inicial en una sola transacción.
  Future<void> createWithInitialBalance({
    required int accountId,
    required int amount,
    required int categoryId,
    required String description,
    required int occurredOn,
  }) async {
    final db = await _db.database;
    await db.transaction((tx) async {
      await tx.insert('movements', {
        'account_id': accountId,
        'category_id': categoryId,
        'amount': amount,
        'description': description,
        'occurred_on': occurredOn,
        'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }
}
