import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkash_d/database/app_database.dart';
import 'package:inkash_d/models/monthly_budget.dart';
import 'package:inkash_d/models/new_movement.dart';
import 'package:inkash_d/repositories/budgets_repository.dart';
import 'package:inkash_d/repositories/category_budgets_repository.dart';
import 'package:inkash_d/repositories/movements_repository.dart';
import 'package:inkash_d/repositories/savings_goals_repository.dart';
import 'package:inkash_d/repositories/settings_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late Directory directory;
  late SettingsRepository settings;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkash_d_settings_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/inkash.db',
    );
    settings = SettingsRepository(database: database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('el nombre se guarda (upsert) y sin guardar es ""', () async {
    expect(await settings.getUserName(), '');
    await settings.setUserName('  Ana ');
    await settings.setUserName('Ana María');
    expect(await settings.getUserName(), 'Ana María');
    final db = await database.database;
    expect(await db.query('app_settings'), hasLength(1));
  });

  test('el límite vigente es el del mes o el último anterior', () async {
    final budgets = BudgetsRepository(database: database);
    await budgets.upsert(
      const MonthlyBudget(
        monthStart: '2026-09-01',
        limitMinor: 500000,
        createdAtMs: 0,
      ),
    );
    // Octubre no tiene fila propia: sigue valiendo el de septiembre.
    expect((await budgets.getLatestUpTo('2026-10-01'))!.limitMinor, 500000);
    expect(await budgets.getLatestUpTo('2026-08-01'), isNull);

    await budgets.upsert(
      const MonthlyBudget(
        monthStart: '2026-10-01',
        limitMinor: 650000,
        createdAtMs: 0,
      ),
    );
    expect((await budgets.getLatestUpTo('2026-10-01'))!.limitMinor, 650000);
    // La historia de septiembre no cambia.
    expect((await budgets.getLatestUpTo('2026-09-01'))!.limitMinor, 500000);
  });

  test(
    'borrar mis datos vacía lo del usuario y conserva la estructura',
    () async {
      final db = await database.database;
      final transporte =
          (await db.query(
                'categories',
                where: 'name = ?',
                whereArgs: ['Transporte'],
              )).single['id']!
              as int;
      await MovementsRepository(database: database).insertNew(
        NewMovement(
          accountId: 1,
          categoryId: transporte,
          amountMinor: 1250,
          description: 'Bus',
          occurredAt: DateTime(2026, 10, 15),
        ),
      );
      await BudgetsRepository(database: database).upsert(
        const MonthlyBudget(
          monthStart: '2026-10-01',
          limitMinor: 650000,
          createdAtMs: 0,
        ),
      );
      await CategoryBudgetsRepository(
        database: database,
      ).setLimit(transporte, 10000);
      await SavingsGoalsRepository(database: database).create('Viaje', 100000);
      await settings.setUserName('Ana');
      final categoriesBefore = await db.query('categories');

      await settings.deleteAllUserData();

      for (final table in [
        'movements',
        'monthly_budgets',
        'category_budgets',
        'savings_goals',
        'app_settings',
        'exchange_rate_cache',
      ]) {
        expect(await db.query(table), isEmpty, reason: table);
      }
      expect(await db.query('categories'), categoriesBefore);
      expect(await db.query('accounts'), hasLength(1)); // 'Efectivo'
    },
  );
}
