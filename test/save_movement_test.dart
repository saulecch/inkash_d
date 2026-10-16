import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkash_d/database/app_database.dart';
import 'package:inkash_d/features/home/presentation/widgets/movement_bottom_sheet.dart';
import 'package:inkash_d/models/account.dart';
import 'package:inkash_d/models/category.dart';
import 'package:inkash_d/models/new_movement.dart';
import 'package:inkash_d/repositories/movements_repository.dart';
import 'package:inkash_d/utils/occurred_on.dart';
import 'package:inkash_d/utils/parse_amount.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('parseAmountMinor (sin double)', () {
    test('convierte texto a centavos enteros', () {
      expect(parseAmountMinor('12.5'), 1250);
      expect(parseAmountMinor('12.50'), 1250);
      expect(parseAmountMinor('12,50'), 1250); // coma decimal, como en S11
      expect(parseAmountMinor('0.05'), 5);
      expect(parseAmountMinor(' 38 '), 3800);
    });

    test('rechaza cero, negativos, 3 decimales, basura y desbordes', () {
      for (final invalid in [
        '',
        '0',
        '0.00',
        '-1',
        '12.345',
        'abc',
        '1.2.3',
        '12.',
        // Antes de S14 este texto lanzaba FormatException en el validator.
        '99999999999999999999',
      ]) {
        expect(parseAmountMinor(invalid), isNull, reason: invalid);
      }
    });
  });

  test('encodeOccurredOn: entero local de 17 dígitos yyyyMMddHHmmssSSS', () {
    final encoded = encodeOccurredOn(DateTime(2026, 10, 15, 8, 15, 3, 7));
    expect(encoded, 20261015081503007);
    expect(encoded.toString(), hasLength(17));
    // S15-03: y de regreso, sin perder nada.
    expect(decodeOccurredOn(encoded), DateTime(2026, 10, 15, 8, 15, 3, 7));
  });

  group('MovementsRepository.insertNew', () {
    sqfliteFfiInit();
    late AppDatabase database;
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('inkash_d_save_');
      database = AppDatabase(
        factory: databaseFactoryFfi,
        path: '${directory.path}/inkash.db',
      );
    });

    tearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    // Las categorías vienen del seed de onCreate; las buscamos por nombre.
    Future<int> categoryId(String name) async {
      final db = await database.database;
      final rows = await db.query(
        'categories',
        where: 'name = ?',
        whereArgs: [name],
      );
      return rows.single['id']! as int;
    }

    Future<NewMovement> bus() async => NewMovement(
      accountId: 1, // 'Efectivo', creada por el seed
      categoryId: await categoryId('Transporte'),
      amountMinor: 1250,
      description: 'Bus demo',
      occurredAt: DateTime(2026, 10, 15, 8, 15),
    );

    test('gasto negativo, formatos de fecha intactos y persiste', () async {
      final repository = MovementsRepository(database: database);
      await repository.insertNew(await bus());

      // "Cerrar la app": se cierra el archivo y se vuelve a abrir.
      await database.close();
      final db = await database.database;

      final row = (await db.query('movements')).single;
      expect(row['amount'], -1250);
      expect(row['occurred_on'], 20261015081500000); // local, 17 dígitos
      // created_at_ms es epoch: un número de 13 dígitos, no yyyyMMdd...
      expect((row['created_at_ms']! as int).toString(), hasLength(13));
    });

    test('ingreso positivo según la categoría', () async {
      final repository = MovementsRepository(database: database);
      await repository.insertNew(
        NewMovement(
          accountId: 1,
          categoryId: await categoryId('Salario'),
          amountMinor: 420000,
          description: 'Quincena',
          occurredAt: DateTime(2026, 10, 15),
        ),
      );

      final db = await database.database;
      expect((await db.query('movements')).single['amount'], 420000);
    });

    test('getMonthTotals suma con SQL solo el mes pedido', () async {
      final repository = MovementsRepository(database: database);
      final transporte = await categoryId('Transporte');
      final salario = await categoryId('Salario');
      Future<void> mov(int category, int amountMinor, DateTime at) =>
          repository.insertNew(
            NewMovement(
              accountId: 1,
              categoryId: category,
              amountMinor: amountMinor,
              description: 'x',
              occurredAt: at,
            ),
          );
      // Primer y último instante de octubre: SÍ cuentan.
      await mov(transporte, 1000, DateTime(2026, 10));
      await mov(transporte, 2550, DateTime(2026, 10, 31, 23, 59, 59, 999));
      await mov(salario, 50000, DateTime(2026, 10, 15));
      // Bordes: último instante de septiembre y primero de noviembre, NO.
      await mov(transporte, 9999, DateTime(2026, 9, 30, 23, 59, 59, 999));
      await mov(transporte, 9999, DateTime(2026, 11));

      final october = await repository.getMonthTotals(DateTime(2026, 10, 20));
      expect(october.expensesMinor, 3550); // positivo, aunque se guarda -
      expect(october.incomeMinor, 50000);

      final empty = await repository.getMonthTotals(DateTime(2026, 1));
      expect(empty.expensesMinor, 0); // COALESCE: 0, no null
      expect(empty.incomeMinor, 0);

      // LIMIT ?: los 2 más recientes (noviembre y el 31 de octubre).
      final recent = await repository.getRecent(2);
      expect(
        [for (final m in recent) m.occurredOn],
        [20261101000000000, 20261031235959999],
      );
    });

    test('getFiltered filtra por mes y categoría; categorías usadas', () async {
      final repository = MovementsRepository(database: database);
      final transporte = await categoryId('Transporte');
      final comida = await categoryId('Comida');
      Future<void> mov(String description, int category, DateTime at) =>
          repository.insertNew(
            NewMovement(
              accountId: 1,
              categoryId: category,
              amountMinor: 100,
              description: description,
              occurredAt: at,
            ),
          );
      await mov('Bus', transporte, DateTime(2026, 10, 2));
      await mov('Almuerzo', comida, DateTime(2026, 10, 3));
      await mov('Bus sept', transporte, DateTime(2026, 9, 28));

      Future<List<String>> titles({DateTime? month, int? category}) async => [
        for (final m in await repository.getFiltered(
          month: month,
          categoryId: category,
        ))
          m.description,
      ];
      expect(await titles(month: DateTime(2026, 10)), ['Almuerzo', 'Bus']);
      expect(await titles(category: transporte), ['Bus', 'Bus sept']);
      expect(await titles(month: DateTime(2026, 9), category: transporte), [
        'Bus sept',
      ]);
      // Sin filtros: todos, el más reciente primero.
      expect(await titles(), ['Almuerzo', 'Bus', 'Bus sept']);

      // DISTINCT: Transporte tiene 2 movimientos pero sale una vez.
      // Las categorías sin movimientos (Salario...) no salen.
      final used = await repository.getUsedCategories();
      expect([for (final c in used) c.name], ['Comida', 'Transporte']);
    });

    test('categoría archivada: error y no se inserta nada', () async {
      final repository = MovementsRepository(database: database);
      final transporte = await categoryId('Transporte');
      final db = await database.database;
      await db.update(
        'categories',
        {'is_archived': 1},
        where: 'id = ?',
        whereArgs: [transporte],
      );

      await expectLater(
        repository.insertNew(await bus()),
        throwsA(isA<StateError>()),
      );
      expect(await db.query('movements'), isEmpty);
    });
  });

  group('MovementBottomSheet', () {
    Future<void> pumpSheet(
      WidgetTester tester,
      Future<void> Function(NewMovement) onSave,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovementBottomSheet(
              // Opciones falsas: la prueba no toca SQLite.
              loadOptions: () async => (
                accounts: const [
                  Account(
                    id: 1,
                    name: 'Efectivo',
                    type: 'cash',
                    createdAtMs: 0,
                  ),
                ],
                categories: const [
                  Category(
                    id: 3,
                    name: 'Transporte',
                    classification: 'expense',
                  ),
                ],
              ),
              onSave: onSave,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> fillForm(WidgetTester tester, String amount) async {
      await tester.enterText(find.byType(TextFormField).at(0), amount);
      await tester.enterText(find.byType(TextFormField).at(1), 'Bus demo');
      // El botón queda abajo del scroll: hay que traerlo a la vista.
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pump();
    }

    testWidgets('monto inválido: muestra el error y no guarda', (tester) async {
      var calls = 0;
      await pumpSheet(tester, (_) async => calls++);
      await fillForm(tester, '12.345');

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(calls, 0);
      expect(
        find.text('Monto inválido: mayor que 0 y hasta 2 decimales.'),
        findsOneWidget,
      );
    });

    testWidgets('doble toque guarda una sola vez y muestra Guardando…', (
      tester,
    ) async {
      var calls = 0;
      // El Completer deja el guardado "colgado" para simular una base lenta.
      final pending = Completer<void>();
      await pumpSheet(tester, (newMovement) {
        calls++;
        expect(newMovement.amountMinor, 1250);
        expect(newMovement.categoryId, 3);
        return pending.future;
      });
      await fillForm(tester, '12,50');

      // Dos toques en el mismo frame: el segundo choca con el guard.
      await tester.tap(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();

      expect(calls, 1);
      expect(find.text('Guardando…'), findsOneWidget);
      pending.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('si guardar falla, muestra el error y conserva lo escrito', (
      tester,
    ) async {
      await pumpSheet(tester, (_) async => throw Exception('disco lleno'));
      await fillForm(tester, '12.50');

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.text('No fue posible guardar el movimiento. Intenta otra vez.'),
        findsOneWidget,
      );
      expect(find.text('12.50'), findsOneWidget);
    });
  });
}
