import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkash_d/database/app_database.dart';
import 'package:inkash_d/models/account.dart';
import 'package:inkash_d/models/account_balance.dart';
import 'package:inkash_d/models/new_movement.dart';
import 'package:inkash_d/repositories/accounts_repository.dart';
import 'package:inkash_d/repositories/movements_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkash_d_accounts_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/inkash.db',
    );
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

  test(
    'saldo por cuenta con LEFT JOIN: también las cuentas sin movimientos',
    () async {
      final accounts = AccountsRepository(database: database);
      final movements = MovementsRepository(database: database);
      // 'Efectivo' viene del seed (v3); agregamos dos cuentas más.
      final banco = await accounts.insert(
        const Account(name: 'Banco', type: 'bank', createdAtMs: 1),
      );
      await accounts.insert(
        const Account(name: 'Tarjeta', type: 'card', createdAtMs: 2),
      );
      final efectivo = (await accounts.getWithBalances())
          .firstWhere((a) => a.name == 'Efectivo')
          .id;

      Future<void> mov(String category, int amountMinor, int accountId) async =>
          movements.insertNew(
            NewMovement(
              accountId: accountId,
              categoryId: await categoryId(category),
              amountMinor: amountMinor,
              description: 'x',
              occurredAt: DateTime(2026, 10, 20),
            ),
          );
      // El saldo inicial es un movimiento de la categoría 'Saldo inicial'.
      await mov('Saldo inicial', 100000, banco);
      await mov('Salario', 420000, banco);
      await mov('Supermercado', 28550, banco);
      await mov('Transporte', 1250, efectivo);

      final balances = {
        for (final a in await accounts.getWithBalances())
          a.name: a.balanceMinor,
      };
      // Tarjeta no tiene movimientos y aun así aparece, con 0.
      expect(balances, {'Efectivo': -1250, 'Banco': 491450, 'Tarjeta': 0});

      // El total del Inicio coincide con la suma de las cuentas.
      expect(await accounts.getTotalBalance(), 490200);

      // El movimiento trae "Categoría · Cuenta" por JOIN.
      final latest = (await movements.getRecent(1)).single;
      expect(
        [latest.categoryName, latest.accountName],
        ['Transporte', 'Efectivo'],
      );
    },
  );

  test(
    'crear y editar con saldo inicial; reglas de nombre y borrado',
    () async {
      final accounts = AccountsRepository(database: database);
      final db = await database.database;
      Future<List<Map<String, Object?>>> initialRows(int accountId) => db.query(
        'movements',
        where: "account_id = ? AND description = 'Saldo inicial'",
        whereArgs: [accountId],
      );
      AccountBalance byName(List<AccountBalance> list, String name) =>
          list.firstWhere((a) => a.name == name);

      // Crear: la cuenta y su movimiento 'Saldo inicial' en una transacción.
      final card = await accounts.save(
        name: '  Tarjeta Visa ',
        type: 'card',
        initialBalanceMinor: -50000, // "Debo"
      );
      var visa = byName(await accounts.getWithBalances(), 'Tarjeta Visa');
      expect(visa.type, 'card');
      expect(visa.initialBalanceMinor, -50000);
      expect(visa.balanceMinor, -50000);
      final created = (await initialRows(card)).single;
      expect(created['occurred_on'].toString(), hasLength(17)); // local

      // Editar el saldo actualiza la MISMA fila (no crea otra).
      await accounts.save(
        id: card,
        name: 'Tarjeta Visa',
        type: 'card',
        initialBalanceMinor: -42000,
      );
      expect((await initialRows(card)).single['id'], created['id']);
      visa = byName(await accounts.getWithBalances(), 'Tarjeta Visa');
      expect(visa.balanceMinor, -42000);

      // Saldo 0 = sin fila (amount tiene CHECK != 0).
      await accounts.save(
        id: card,
        name: 'Tarjeta Visa',
        type: 'card',
        initialBalanceMinor: 0,
      );
      expect(await initialRows(card), isEmpty);

      // Nombre repetido (sin importar mayúsculas): mensaje claro.
      await expectLater(
        accounts.save(name: 'efectivo', type: 'cash', initialBalanceMinor: 0),
        throwsA(
          isA<AccountException>().having(
            (e) => e.message,
            'message',
            'Ya existe una cuenta llamada "efectivo".',
          ),
        ),
      );
      await expectLater(
        accounts.save(name: '   ', type: 'cash', initialBalanceMinor: 0),
        throwsA(isA<AccountException>()),
      );

      // Con solo su saldo inicial, la cuenta SÍ se borra (y el saldo con ella).
      final savings = await accounts.save(
        name: 'Ahorro',
        type: 'bank',
        initialBalanceMinor: 100000,
      );
      await accounts.delete(savings);
      expect(await initialRows(savings), isEmpty);
      expect(
        (await accounts.getWithBalances()).map((a) => a.name),
        isNot(contains('Ahorro')),
      );

      // Con un movimiento real, NO se borra y no se toca nada.
      await MovementsRepository(database: database).insertNew(
        NewMovement(
          accountId: card,
          categoryId: await categoryId('Supermercado'),
          amountMinor: 28550,
          description: 'Súper',
          occurredAt: DateTime(2026, 10, 20),
        ),
      );
      await expectLater(
        accounts.delete(card),
        throwsA(isA<AccountException>()),
      );
      expect(
        byName(await accounts.getWithBalances(), 'Tarjeta Visa'),
        isNotNull,
      );
    },
  );
}
