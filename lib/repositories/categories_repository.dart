import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/category.dart';

// S16-02: error de negocio con un mensaje para humanos.
class CategoryException implements Exception {
  const CategoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CategoriesRepository {
  // S16-02: la base se inyecta para probar con un archivo temporal.
  CategoriesRepository({AppDatabase? database})
    : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(Category.fromMap).toList();
  }

  /// S16-02: crear (id == null) o editar una categoría de gasto o ingreso.
  /// Las de 'adjustment' (Saldo inicial) son de la app: no se administran.
  Future<Category> save({
    int? id,
    required String name,
    required String classification,
    required String iconKey,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const CategoryException('El nombre no puede quedar vacío.');
    }
    if (classification != 'expense' && classification != 'income') {
      throw const CategoryException('Solo categorías de gasto o ingreso.');
    }
    final db = await _db.database;
    final row = {
      'name': cleanName,
      'classification': classification,
      'icon_key': iconKey,
    };
    try {
      final savedId =
          id ?? await db.insert('categories', {...row, 'is_archived': 0});
      if (id != null) {
        await db.update(
          'categories',
          row,
          where: "id = ? AND classification <> 'adjustment'",
          whereArgs: [id],
        );
      }
      return (await getById(savedId))!;
    } on DatabaseException catch (e) {
      // El índice UNIQUE (classification, name NOCASE) existe desde la v1.
      if (e.isUniqueConstraintError()) {
        throw CategoryException('Ya existe la categoría "$cleanName".');
      }
      rethrow;
    }
  }

  /// S16-02: archivar = dejar de ofrecerla sin perder los movimientos que
  /// ya la usan. Restaurar = archived false.
  Future<void> setArchived(int id, {required bool archived}) async {
    final db = await _db.database;
    await db.update(
      'categories',
      {'is_archived': archived ? 1 : 0},
      where: "id = ? AND classification <> 'adjustment'",
      whereArgs: [id],
    );
  }

  /// S16-02: solo se borra si NUNCA se usó; si tiene movimientos, se
  /// sugiere archivar. Revisar y borrar en la MISMA transacción.
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final used = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM movements WHERE category_id = ?',
          [id],
        ),
      )!;
      if (used > 0) {
        throw CategoryException(
          'Tiene $used movimiento${used == 1 ? '' : 's'}. '
          'Archívala para dejar de verla.',
        );
      }
      await txn.delete(
        'categories',
        where: "id = ? AND classification <> 'adjustment'",
        whereArgs: [id],
      );
    });
  }

  Future<List<Category>> getByClassification(String classification) async {
    final db = await _db.database;
    final maps = await db.query(
      'categories',
      where: 'classification = ? AND is_archived = 0',
      whereArgs: [classification],
      orderBy: 'name ASC',
    );
    return maps.map(Category.fromMap).toList();
  }

  Future<Category?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<int> insert(Category category) async {
    final db = await _db.database;
    return db.insert('categories', category.toMap());
  }
}
