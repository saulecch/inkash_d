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

  test('instalación nueva: versión 4 con la tabla de caché', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/nueva.db',
    );
    final db = await database.database;

    expect(await db.getVersion(), 4);
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

    expect(await db.getVersion(), 4);
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
}
