import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkash_d/database/app_database.dart';
import 'package:inkash_d/models/new_movement.dart';
import 'package:inkash_d/repositories/category_budgets_repository.dart';
import 'package:inkash_d/repositories/movements_repository.dart';
import 'package:inkash_d/utils/occurred_on.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late Directory directory;
  late CategoryBudgetsRepository budgets;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkash_d_budgets_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/inkash.db',
    );
    budgets = CategoryBudgetsRepository(database: database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<int> categoryId(String name) async {
    final db = await database.database;
    final rows = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );
    return rows.single['id']! as int;
  }

  Future<void> movement(String category, int amountMinor, DateTime at) async =>
      MovementsRepository(database: database).insertNew(
        NewMovement(
          accountId: 1,
          categoryId: await categoryId(category),
          amountMinor: amountMinor,
          description: 'x',
          occurredAt: at,
        ),
      );

  test(
    'lista TODAS las categorías de gasto: filtro del mes en el ON',
    () async {
      await movement('Transporte', 3800, DateTime(2026, 10, 3));
      // Otro mes: último instante de septiembre.
      await movement(
        'Transporte',
        1200,
        DateTime(2026, 9, 30, 23, 59, 59, 999),
      );
      await movement('Supermercado', 28550, DateTime(2026, 10, 5));
      await movement('Salario', 420000, DateTime(2026, 10, 14)); // ingreso
      // Archivada: ya no se presupuesta (S16-02).
      final db0 = await database.database;
      await db0.update(
        'categories',
        {'is_archived': 1},
        where: 'name = ?',
        whereArgs: ['Higiene'],
      );

      final rows = await budgets.getForMonth(DateTime(2026, 10, 15));
      // Las categorías de gasto ACTIVAS del seed; las que no tienen gastos
      // en octubre aparecen con 0. Salario (ingreso) e Higiene (archivada)
      // no se presupuestan.
      expect(
        {for (final r in rows) r.name: r.spentMinor},
        {
          'Comida': 0,
          'Entretenimiento': 0,
          'Servicios': 0,
          'Supermercado': 28550,
          'Transporte': 3800,
        },
      );

      // El error clásico: la MISMA consulta con el filtro en el WHERE.
      // Las filas con m NULL no pasan "m.occurred_on >= ?" y desaparecen.
      final db = await database.database;
      final wrong = await db.rawQuery(
        '''
      SELECT c.name FROM categories c
      LEFT JOIN movements m ON m.category_id = c.id
      WHERE c.classification = 'expense'
        AND m.occurred_on >= ? AND m.occurred_on < ?
      GROUP BY c.id
    ''',
        [
          encodeOccurredOn(DateTime(2026, 10)),
          encodeOccurredOn(DateTime(2026, 11)),
        ],
      );
      expect(wrong, hasLength(2)); // solo Transporte y Supermercado
    },
  );

  test('definir, exceder, reemplazar (upsert) y quitar un límite', () async {
    await movement('Supermercado', 60000, DateTime(2026, 10, 10));
    final october = DateTime(2026, 10);
    final supermercado = await categoryId('Supermercado');

    await budgets.setLimit(supermercado, 50000);
    var row = (await budgets.getForMonth(october)).first;
    // Las categorías con límite salen primero.
    expect(row.name, 'Supermercado');
    expect(row.limitMinor, 50000);
    expect(row.isExceeded, isTrue);
    expect(row.progress, 1.0); // la barra no se desborda

    // Upsert: la segunda vez REEMPLAZA (category_id es PK), no duplica.
    await budgets.setLimit(supermercado, 80000);
    row = (await budgets.getForMonth(october)).first;
    expect(row.limitMinor, 80000);
    expect(row.isExceeded, isFalse);
    final db = await database.database;
    expect(await db.query('category_budgets'), hasLength(1));

    await budgets.setLimit(supermercado, null);
    expect(
      (await budgets.getForMonth(october)).every((r) => r.limitMinor == null),
      isTrue,
    );
  });

  test('el CHECK impide un límite de 0', () async {
    await expectLater(
      budgets.setLimit(await categoryId('Comida'), 0),
      throwsA(isA<DatabaseException>()),
    );
  });
}
