import '../database/app_database.dart';
import '../models/category.dart';
import '../models/deleted_movement.dart';
import '../models/month_totals.dart';
import '../models/movement.dart';
import '../models/new_movement.dart';
import '../utils/dates.dart';
import '../utils/occurred_on.dart';

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

  // S15-02: el Inicio solo pide los últimos N. El número también es un
  // valor, así que va como `?` (db.query lo pegaría dentro del texto SQL).
  Future<List<Movement>> getRecent(int limit) => getFiltered(limit: limit);

  /// S15-03: una sola consulta para el Inicio y el Historial, con filtros
  /// opcionales. El WHERE se arma con PIEZAS de texto fijo, pero los
  /// VALORES (mes, categoría, límite) siempre van como `?`: nunca se
  /// concatena lo que elige el usuario.
  Future<List<Movement>> getFiltered({
    DateTime? month,
    int? categoryId,
    int? limit,
  }) async {
    final conditions = <String>[];
    final args = <Object>[];
    if (month != null) {
      // Mismo rango medio abierto que getMonthTotals.
      conditions.add('m.occurred_on >= ? AND m.occurred_on < ?');
      args.addAll([
        encodeOccurredOn(monthStart(month)),
        encodeOccurredOn(nextMonthStart(month)),
      ]);
    }
    if (categoryId != null) {
      conditions.add('m.category_id = ?');
      args.add(categoryId);
    }
    if (limit != null) args.add(limit); // el último `?` es el del LIMIT

    final db = await _db.database;
    // S16-01: JOIN para mostrar "Categoría · Cuenta". Aquí JOIN normal
    // basta: category_id y account_id son NOT NULL con FOREIGN KEY, así que
    // todo movimiento tiene su pareja (a diferencia del saldo por cuenta).
    final maps = await db.rawQuery('''
      SELECT m.*, c.name AS category_name, a.name AS account_name
      FROM movements m
      JOIN categories c ON c.id = m.category_id
      JOIN accounts a ON a.id = m.account_id
      ${conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}'}
      ORDER BY m.occurred_on DESC, m.id DESC
      ${limit == null ? '' : 'LIMIT ?'}
    ''', args);
    return maps.map(Movement.fromMap).toList();
  }

  /// S15-03: las categorías que YA tienen movimientos (chips del filtro).
  /// DISTINCT: una categoría con 50 movimientos aparece una sola vez.
  Future<List<Category>> getUsedCategories() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT c.*
      FROM categories c
      JOIN movements m ON m.category_id = c.id
      ORDER BY c.name
    ''');
    return maps.map(Category.fromMap).toList();
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

  /// S15-04: borrar devuelve la fila borrada, para poder deshacer.
  /// Leer + borrar en UNA transacción: nadie cambia la fila en medio.
  Future<DeletedMovement?> delete(int id) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'movements',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return null; // ya no existía: nada que deshacer
      await txn.delete('movements', where: 'id = ?', whereArgs: [id]);
      return DeletedMovement(Map.of(rows.single));
    });
  }

  /// Reinserta la fila idéntica (con su id original).
  Future<void> restore(DeletedMovement deleted) async {
    final db = await _db.database;
    await db.insert('movements', deleted.row);
  }

  /// S15-02: gastos e ingresos del mes en UNA consulta: SUM + CASE.
  /// Sumar en SQL no trae todas las filas a memoria solo para sumarlas.
  ///
  /// Antes: dos consultas con `substr(occurred_on, 1, 6) = ?`. Funciona,
  /// pero convierte cada fila a texto y no aprovecha el índice de
  /// occurred_on. Ahora: rango medio abierto [inicio de mes, inicio del
  /// siguiente) codificado igual que occurredOn (local, 17 dígitos).
  Future<MonthTotals> getMonthTotals(DateTime month) async {
    final db = await _db.database;
    final row = (await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN c.classification = 'expense'
                          THEN -m.amount END), 0) AS expenses,
        COALESCE(SUM(CASE WHEN c.classification = 'income'
                          THEN m.amount END), 0) AS income
      FROM movements m
      JOIN categories c ON c.id = m.category_id
      WHERE m.occurred_on >= ? AND m.occurred_on < ?
    ''',
      [
        encodeOccurredOn(monthStart(month)),
        encodeOccurredOn(nextMonthStart(month)),
      ],
    )).single;
    // COALESCE: un mes sin movimientos da 0, no null.
    // 'adjustment' (saldo inicial) no es gasto ni ingreso: queda fuera.
    return MonthTotals(
      expensesMinor: row['expenses']! as int,
      incomeMinor: row['income']! as int,
    );
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
