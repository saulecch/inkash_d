import '../database/app_database.dart';
import '../models/category.dart';

class CategoriesRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(Category.fromMap).toList();
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

  Future<void> archive(int id) async {
    final db = await _db.database;
    await db.update(
      'categories',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
