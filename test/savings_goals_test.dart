import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkash_d/database/app_database.dart';
import 'package:inkash_d/repositories/savings_goals_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late Directory directory;
  late SavingsGoalsRepository goals;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkash_d_goals_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/inkash.db',
    );
    goals = SavingsGoalsRepository(database: database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('10 aportes en paralelo no se pierden (UPDATE atómico)', () async {
    final id = await goals.create('Viaje a Tikal', 200000);

    // 10 aportes "a la vez". Con leer-sumar-escribir en Dart se perderían.
    await Future.wait([
      for (var i = 0; i < 10; i++) goals.contribute(id, 1000),
    ]);

    expect((await goals.getById(id))!.savedAmountMinor, 10000);
  });

  test('no se puede retirar más de lo ahorrado', () async {
    final id = await goals.create('Laptop', 800000);
    await goals.contribute(id, 5000);

    await expectLater(
      goals.withdraw(id, 5001),
      throwsA(
        isA<SavingsGoalException>().having(
          (e) => e.message,
          'message',
          'No puedes retirar más de lo ahorrado.',
        ),
      ),
    );
    expect((await goals.getById(id))!.savedAmountMinor, 5000); // intacto

    await goals.withdraw(id, 5000); // exacto: sí se puede
    expect((await goals.getById(id))!.savedAmountMinor, 0);
  });

  test(
    'última defensa: un UPDATE directo en negativo choca con el CHECK',
    () async {
      final id = await goals.create('Celular', 150000);
      final db = await database.database;

      // Aunque alguien se salte el repositorio, la base no lo acepta.
      await expectLater(
        db.update(
          'savings_goals',
          {'saved_amount_minor': -1},
          where: 'id = ?',
          whereArgs: [id],
        ),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test('las completadas van al final; el conteo solo cuenta activas', () async {
    final phone = await goals.create('Celular', 1000);
    await goals.create('Fondo de emergencia', 500000);
    await goals.contribute(phone, 1000); // completada

    final list = await goals.getActive();
    expect([for (final g in list) g.name], ['Fondo de emergencia', 'Celular']);
    expect(list.last.isCompleted, isTrue);
    expect(await goals.getActiveCount(), 1);
  });

  test('editar nombre y objetivo conserva lo ahorrado; eliminar', () async {
    final id = await goals.create('Laptop', 800000);
    await goals.contribute(id, 12345);

    await goals.edit(id, '  Laptop nueva ', 900000);
    final edited = (await goals.getById(id))!;
    expect(edited.name, 'Laptop nueva');
    expect(edited.targetAmountMinor, 900000);
    expect(edited.savedAmountMinor, 12345); // intacto

    await expectLater(
      goals.edit(id, '   ', 900000),
      throwsA(isA<SavingsGoalException>()),
    );

    await goals.delete(id);
    expect(await goals.getById(id), isNull);
  });
}
