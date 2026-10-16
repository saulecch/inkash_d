import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/account.dart';
import '../models/account_balance.dart';
import '../utils/occurred_on.dart';

// S16-01: error de negocio con un mensaje para humanos.
class AccountException implements Exception {
  const AccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AccountsRepository {
  // S16-01: la base se inyecta para probar con un archivo temporal.
  AccountsRepository({AppDatabase? database})
    : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<List<Account>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('accounts', orderBy: 'created_at_ms DESC');
    return maps.map(Account.fromMap).toList();
  }

  Future<List<Account>> getActive() async {
    final db = await _db.database;
    final maps = await db.query(
      'accounts',
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(Account.fromMap).toList();
  }

  Future<Account?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<int> insert(Account account) async {
    final db = await _db.database;
    return db.insert('accounts', account.toMap());
  }

  Future<void> update(Account account) async {
    final db = await _db.database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> archive(int id) async {
    final db = await _db.database;
    await db.update(
      'accounts',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Saldo de una cuenta individual.
  Future<int> getBalance(int accountId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM movements WHERE account_id = ?',
      [accountId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Saldo total de todas las cuentas activas.
  Future<int> getTotalBalance() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(m.amount), 0) AS total
      FROM movements m
      JOIN accounts a ON a.id = m.account_id
      WHERE a.is_archived = 0
    ''');
    return (result.first['total'] as int?) ?? 0;
  }

  /// S16-01: saldo de CADA cuenta activa, calculado en SQL.
  /// LEFT JOIN, no JOIN: una cuenta SIN movimientos también debe aparecer
  /// (con saldo 0). Con JOIN "normal" desaparecería de la lista.
  /// GROUP BY a.id: un SUM por cuenta. COALESCE: SUM de nada es NULL.
  /// El saldo inicial es un movimiento 'Saldo inicial' (classification
  /// 'adjustment'), así que ya está en el SUM; aparte lo separamos con CASE
  /// para mostrarlo en el formulario.
  Future<List<AccountBalance>> getWithBalances() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT a.id, a.name, a.type,
             COALESCE(SUM(m.amount), 0) AS balance,
             COALESCE(SUM(CASE WHEN c.classification = 'adjustment'
                               THEN m.amount END), 0) AS initial_balance
      FROM accounts a
      LEFT JOIN movements m ON m.account_id = a.id
      LEFT JOIN categories c ON c.id = m.category_id
      WHERE a.is_archived = 0
      GROUP BY a.id
      ORDER BY a.created_at_ms, a.id
    ''');
    return [
      for (final row in rows)
        AccountBalance(
          id: row['id']! as int,
          name: row['name']! as String,
          type: row['type']! as String,
          balanceMinor: row['balance']! as int,
          initialBalanceMinor: row['initial_balance']! as int,
        ),
    ];
  }

  /// S16-01: crear (id == null) o editar una cuenta, con su saldo inicial.
  ///
  /// En inkash_d el saldo inicial NO es una columna: desde S10 es un
  /// movimiento de la categoría 'Saldo inicial'. Guardar la cuenta y ese
  /// movimiento va en UNA transacción: nunca queda una cuenta nueva sin su
  /// saldo, ni un saldo apuntando a una cuenta que no se creó.
  Future<int> save({
    int? id,
    required String name,
    required String type,
    required int initialBalanceMinor,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const AccountException('El nombre no puede quedar vacío.');
    }
    final db = await _db.database;
    try {
      return await db.transaction((txn) async {
        final now = DateTime.now();
        final accountId =
            id ??
            await txn.insert('accounts', {
              'name': cleanName,
              'type': type,
              'is_archived': 0,
              'created_at_ms': now.millisecondsSinceEpoch,
            });
        if (id != null) {
          await txn.update(
            'accounts',
            {'name': cleanName, 'type': type},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
        await _setInitialBalance(txn, accountId, initialBalanceMinor, now);
        return accountId;
      });
    } on DatabaseException catch (e) {
      // El índice UNIQUE (v5) es quien detecta el nombre repetido.
      if (e.isUniqueConstraintError()) {
        throw AccountException('Ya existe una cuenta llamada "$cleanName".');
      }
      rethrow;
    }
  }

  // Crea, actualiza o borra el movimiento 'Saldo inicial' de la cuenta.
  Future<void> _setInitialBalance(
    Transaction txn,
    int accountId,
    int amountMinor,
    DateTime now,
  ) async {
    final category = await txn.query(
      'categories',
      columns: ['id'],
      where: "classification = 'adjustment' AND name = ?",
      whereArgs: ['Saldo inicial'],
    );
    if (category.isEmpty) {
      throw const AccountException('Falta la categoría "Saldo inicial".');
    }
    final categoryId = category.single['id']! as int;
    final existing = await txn.query(
      'movements',
      columns: ['id'],
      where: 'account_id = ? AND category_id = ?',
      whereArgs: [accountId, categoryId],
    );
    if (amountMinor == 0) {
      // amount tiene CHECK (amount != 0): "sin saldo inicial" = sin fila.
      await txn.delete(
        'movements',
        where: 'account_id = ? AND category_id = ?',
        whereArgs: [accountId, categoryId],
      );
    } else if (existing.isEmpty) {
      await txn.insert('movements', {
        'account_id': accountId,
        'category_id': categoryId,
        'amount': amountMinor,
        'description': 'Saldo inicial',
        // Mismos formatos de siempre: local de 17 dígitos y epoch ms.
        'occurred_on': encodeOccurredOn(now),
        'created_at_ms': now.millisecondsSinceEpoch,
      });
    } else {
      // Editar el saldo no cambia su fecha: solo el monto.
      await txn.update(
        'movements',
        {'amount': amountMinor},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  /// S16-01: una cuenta con movimientos NO se borra: se perdería de dónde
  /// salió el dinero. El 'Saldo inicial' no cuenta (es parte de la cuenta)
  /// y se borra con ella. Revisar y borrar en la MISMA transacción.
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final used = Sqflite.firstIntValue(
        await txn.rawQuery(
          '''
          SELECT COUNT(*) FROM movements m
          JOIN categories c ON c.id = m.category_id
          WHERE m.account_id = ? AND c.classification <> 'adjustment'
        ''',
          [id],
        ),
      )!;
      if (used > 0) {
        throw AccountException(
          'Tiene $used movimiento${used == 1 ? '' : 's'}. '
          'Muévelos a otra cuenta o bórralos primero.',
        );
      }
      await txn.delete('movements', where: 'account_id = ?', whereArgs: [id]);
      await txn.delete('accounts', where: 'id = ?', whereArgs: [id]);
    });
  }
}
