import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkash_d/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkash_d_db_');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('instalación nueva: última versión con la tabla de caché', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/nueva.db',
    );
    final db = await database.database;

    expect(await db.getVersion(), AppDatabase.currentVersion);
    expect(await db.query('exchange_rate_cache'), isEmpty);
    expect(await db.query('accounts'), hasLength(1)); // seed 'Efectivo'
    await database.close();
  });

  // La prueba más importante de una migración: el usuario que ya tenía la
  // app (versión 3) actualiza y NO pierde sus movimientos.
  test('migra de la versión 3 a la 4 sin perder datos', () async {
    final path = '${directory.path}/v3.db';
    // Esquema v3 tal como lo dejó S11 (solo las tablas que usa la prueba).
    final v3 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE accounts (
              id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
              type TEXT NOT NULL, is_archived INTEGER NOT NULL DEFAULT 0,
              created_at_ms INTEGER NOT NULL)
          ''');
          await db.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
              classification TEXT NOT NULL, icon_key TEXT, color_value INTEGER,
              is_archived INTEGER NOT NULL DEFAULT 0)
          ''');
          await db.execute('''
            CREATE TABLE movements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              account_id INTEGER NOT NULL REFERENCES accounts(id),
              category_id INTEGER NOT NULL REFERENCES categories(id),
              amount INTEGER NOT NULL, description TEXT NOT NULL,
              occurred_on INTEGER NOT NULL, notes TEXT,
              created_at_ms INTEGER NOT NULL)
          ''');
          await db.insert('accounts', {
            'name': 'Efectivo',
            'type': 'cash',
            'created_at_ms': 1760000000000,
          });
          await db.insert('categories', {
            'name': 'Transporte',
            'classification': 'expense',
          });
          await db.insert('movements', {
            'account_id': 1,
            'category_id': 1,
            'amount': -1250,
            'description': 'Bus',
            'occurred_on': 20260917111822027,
            'created_at_ms': 1758129502027,
          });
        },
      ),
    );
    await v3.close();

    final upgraded = AppDatabase(factory: databaseFactoryFfi, path: path);
    final db = await upgraded.database;

    expect(await db.getVersion(), AppDatabase.currentVersion);
    // El movimiento sigue ahí, con sus formatos intactos.
    expect(await db.query('movements'), [
      {
        'id': 1,
        'account_id': 1,
        'category_id': 1,
        'amount': -1250,
        'description': 'Bus',
        'occurred_on': 20260917111822027,
        'notes': null,
        'created_at_ms': 1758129502027,
      },
    ]);
    expect(await db.query('accounts'), hasLength(1)); // sin seed repetido
    expect(await db.query('exchange_rate_cache'), isEmpty);
    await upgraded.close();
  });

  // S16-01: una base EXACTAMENTE como la dejaba la app en la versión 1
  // (S10): amount_minor y occurred_on como texto ISO.
  Future<String> createV1Database() async {
    final path = '${directory.path}/v1.db';
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => AppDatabase.migrations[1]!(db),
      ),
    );
    await v1.insert('accounts', {
      'name': 'Mi efectivo',
      'type': 'cash',
      'created_at_ms': 1756900000000,
    });
    await v1.insert('movements', {
      'account_id': 1,
      'category_id': 3, // Transporte, del seed de v1
      'amount_minor': -1250,
      'description': 'Bus',
      'occurred_on': '2026-09-03',
      'created_at_ms': 1756900000000,
    });
    await v1.close();
    return path;
  }

  test('migra de la versión 1 a la actual y convierte los datos', () async {
    final upgraded = AppDatabase(
      factory: databaseFactoryFfi,
      path: await createV1Database(),
    );
    final db = await upgraded.database;

    expect(await db.getVersion(), AppDatabase.currentVersion);
    final row = (await db.query('movements')).single;
    expect(row['amount'], -1250);
    expect(row['occurred_on'], 20260903000000000); // texto -> 17 dígitos
    // v3 no agrega "Efectivo" si el usuario ya tenía una cuenta.
    expect(await db.query('accounts'), hasLength(1));
    await upgraded.close();
  });

  // Si la instalación nueva y la actualización divergen, un usuario nuevo y
  // uno viejo tendrían bases distintas. Esta prueba lo detecta.
  test('instalación nueva y actualizada tienen el mismo esquema', () async {
    Future<List<Object?>> schema(AppDatabase base) async {
      final db = await base.database;
      final objects = await db.rawQuery(
        "SELECT type, name, tbl_name FROM sqlite_master "
        "WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name",
      );
      final columns = [
        for (final table in objects.where((o) => o['type'] == 'table'))
          for (final column in await db.rawQuery(
            'PRAGMA table_info(${table['name']})',
          ))
            '${table['name']}.${column['name']} ${column['type']} '
                'notnull=${column['notnull']} default=${column['dflt_value']}',
      ];
      return [...objects, ...columns];
    }

    final fresh = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/nueva.db',
    );
    final upgraded = AppDatabase(
      factory: databaseFactoryFfi,
      path: await createV1Database(),
    );
    expect(await schema(upgraded), await schema(fresh));
    await fresh.close();
    await upgraded.close();
  });
}
