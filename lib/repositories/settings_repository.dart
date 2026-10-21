import '../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  SettingsRepository({AppDatabase? database})
    : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  static const _userNameKey = 'user_name';

  Future<String> getUserName() async {
    final db = await _db.database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [_userNameKey],
    );
    return rows.isEmpty ? '' : rows.single['value']! as String;
  }

  // Upsert: key es la llave primaria, REPLACE sustituye el valor anterior.
  Future<void> setUserName(String name) async {
    final db = await _db.database;
    await db.insert('app_settings', {
      'key': _userNameKey,
      'value': name.trim(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// "Borrar todos mis datos": lo que el USUARIO registró.
  /// Las categorías y las cuentas se quedan: son la estructura de la app
  /// (y todavía no hay pantalla para recrearlas).
  /// UNA transacción: o se borra todo, o nada (nunca "medio borrado").
  Future<void> deleteAllUserData() async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final table in [
        'movements',
        'monthly_budgets',
        'category_budgets',
        'savings_goals',
        'app_settings',
        'exchange_rate_cache',
      ]) {
        await txn.delete(table);
      }
    });
  }
}
