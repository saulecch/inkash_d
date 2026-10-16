import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/category_budget.dart';
import '../utils/dates.dart';
import '../utils/occurred_on.dart';

class CategoryBudgetsRepository {
  CategoryBudgetsRepository({AppDatabase? database})
    : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  /// Las categorías de gasto ACTIVAS (no archivadas), con su límite (si tiene) y lo gastado
  /// en el mes de [month].
  ///
  /// LA IDEA DE LA CLASE: el filtro del mes va en el ON del LEFT JOIN, NO en
  /// el WHERE. En el WHERE, `m.occurred_on >= ?` es falso cuando m es NULL
  /// (categoría sin gastos este mes)... y esa categoría desaparecería de la
  /// lista, justo la que el usuario quiere presupuestar.
  Future<List<CategoryBudget>> getForMonth(DateTime month) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT c.id, c.name, c.icon_key, b.limit_minor,
             COALESCE(SUM(-m.amount), 0) AS spent
      FROM categories c
      LEFT JOIN category_budgets b ON b.category_id = c.id
      LEFT JOIN movements m ON m.category_id = c.id
        AND m.occurred_on >= ? AND m.occurred_on < ?
      WHERE c.classification = 'expense' AND c.is_archived = 0
      GROUP BY c.id
      ORDER BY b.limit_minor IS NULL, c.name
    ''',
      [
        encodeOccurredOn(monthStart(month)),
        encodeOccurredOn(nextMonthStart(month)),
      ],
    );
    return [
      for (final row in rows)
        CategoryBudget(
          categoryId: row['id']! as int,
          name: row['name']! as String,
          iconKey: row['icon_key'] as String?,
          limitMinor: row['limit_minor'] as int?,
          spentMinor: row['spent']! as int,
        ),
    ];
  }

  /// "Upsert": si la categoría ya tenía límite, REPLACE sustituye la fila
  /// (category_id es la llave primaria). null quita el límite.
  Future<void> setLimit(int categoryId, int? limitMinor) async {
    final db = await _db.database;
    if (limitMinor == null) {
      await db.delete(
        'category_budgets',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
      return;
    }
    await db.insert('category_budgets', {
      'category_id': categoryId,
      'limit_minor': limitMinor,
      'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
