import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkash_d/database/app_database.dart';
import 'package:inkash_d/models/new_movement.dart';
import 'package:inkash_d/repositories/categories_repository.dart';
import 'package:inkash_d/repositories/movements_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late Directory directory;
  late CategoriesRepository categories;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkash_d_categories_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/inkash.db',
    );
    categories = CategoriesRepository(database: database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'v6: las categorías base ya traen icono; hay de gasto e ingreso',
    () async {
      final all = await categories.getAll();
      expect(all.every((c) => c.iconKey != null), isTrue);
      expect(
        all.firstWhere((c) => c.name == 'Transporte').iconKey,
        'directions_bus',
      );
      // D ya sembraba ingresos desde S10: no hace falta sembrar de nuevo.
      expect(
        all.where((c) => c.classification == 'income').map((c) => c.name),
        containsAll(['Salario', 'Ingreso extra']),
      );
    },
  );

  test('crear, renombrar, archivar y borrar con sus reglas', () async {
    final pets = await categories.save(
      name: ' Mascotas ',
      classification: 'expense',
      iconKey: 'pets',
    );
    expect(pets.name, 'Mascotas');
    expect(pets.isArchived, isFalse);

    // Nombre repetido en el MISMO tipo (sin importar mayúsculas): mensaje.
    await expectLater(
      categories.save(
        name: 'transporte',
        classification: 'expense',
        iconKey: 'home',
      ),
      throwsA(
        isA<CategoryException>().having(
          (e) => e.message,
          'message',
          'Ya existe la categoría "transporte".',
        ),
      ),
    );
    // 'adjustment' es de la app: no se crea desde aquí.
    await expectLater(
      categories.save(
        name: 'Ajuste',
        classification: 'adjustment',
        iconKey: 'home',
      ),
      throwsA(isA<CategoryException>()),
    );

    final renamed = await categories.save(
      id: pets.id,
      name: 'Mascota',
      classification: 'expense',
      iconKey: 'pets',
    );
    expect(renamed.id, pets.id);
    expect(renamed.name, 'Mascota');

    // Usada: no se borra, pero sí se archiva (y se puede restaurar).
    await MovementsRepository(database: database).insertNew(
      NewMovement(
        accountId: 1,
        categoryId: pets.id!,
        amountMinor: 5000,
        description: 'Croquetas',
        occurredAt: DateTime(2026, 10, 20),
      ),
    );
    await expectLater(
      categories.delete(pets.id!),
      throwsA(isA<CategoryException>()),
    );
    await categories.setArchived(pets.id!, archived: true);
    expect((await categories.getById(pets.id!))!.isArchived, isTrue);
    await categories.setArchived(pets.id!, archived: false);
    expect((await categories.getById(pets.id!))!.isArchived, isFalse);

    // Sin usar: sí se borra.
    final gifts = await categories.save(
      name: 'Regalos',
      classification: 'income',
      iconKey: 'gift',
    );
    await categories.delete(gifts.id!);
    expect(await categories.getById(gifts.id!), isNull);
  });
}
