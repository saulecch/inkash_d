import '../database/app_database.dart';
import '../models/account.dart';

class AccountsRepository {
  final AppDatabase _db = AppDatabase.instance;

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
      'SELECT COALESCE(SUM(amount_minor), 0) AS total FROM movements WHERE account_id = ?',
      [accountId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Saldo total de todas las cuentas activas.
  Future<int> getTotalBalance() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(m.amount_minor), 0) AS total
      FROM movements m
      JOIN accounts a ON a.id = m.account_id
      WHERE a.is_archived = 0
    ''');
    return (result.first['total'] as int?) ?? 0;
  }
}
