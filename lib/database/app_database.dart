import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'inkash.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    await db.rawQuery('PRAGMA journal_mode = WAL;');
    await db.execute('PRAGMA synchronous = FULL;');
    await db.rawQuery('PRAGMA busy_timeout = 5000;');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final columns = await db.rawQuery('PRAGMA table_info(movements)');
      final columnNames = columns.map((column) => column['name']).toSet();
      final amountColumn = columnNames.contains('amount')
          ? 'amount'
          : 'amount_minor';

      await db.execute('''
        CREATE TABLE movements_v2 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
          category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
          amount INTEGER NOT NULL CHECK (amount != 0),
          description TEXT NOT NULL,
          occurred_on INTEGER NOT NULL,
          notes TEXT,
          created_at_ms INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        INSERT INTO movements_v2 (
          id,
          account_id,
          category_id,
          amount,
          description,
          occurred_on,
          notes,
          created_at_ms
        )
        SELECT
          id,
          account_id,
          category_id,
          $amountColumn,
          description,
          CASE
            WHEN typeof(occurred_on) = 'integer' THEN occurred_on
            WHEN occurred_on LIKE '____-__-__%' THEN CAST(
              replace(substr(occurred_on, 1, 10), '-', '') || '000000000'
              AS INTEGER
            )
            ELSE CAST(occurred_on AS INTEGER)
          END,
          notes,
          created_at_ms
        FROM movements
      ''');

      await db.execute('DROP TABLE movements');
      await db.execute('ALTER TABLE movements_v2 RENAME TO movements');
      await db.execute('''
        CREATE INDEX idx_movements_occurred_on
        ON movements(occurred_on)
      ''');
      await db.execute('''
        CREATE INDEX idx_movements_account_id
        ON movements(account_id)
      ''');
      await db.execute('''
        CREATE INDEX idx_movements_category_id
        ON movements(category_id)
      ''');
      await db.execute('''
        CREATE INDEX idx_movements_kind_date
        ON movements(category_id, occurred_on)
      ''');
    }

    if (oldVersion < 3) await _seedDefaultAccount(db);
  }

  Future<void> _seedDefaultAccount(DatabaseExecutor db) async {
    await db.rawInsert(
      '''
        INSERT INTO accounts (name, type, is_archived, created_at_ms)
        SELECT ?, ?, 0, ?
        WHERE NOT EXISTS (SELECT 1 FROM accounts)
      ''',
      ['Efectivo', 'cash', DateTime.now().millisecondsSinceEpoch],
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((tx) async {
      // --- accounts ---
      await tx.execute('''
        CREATE TABLE accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL CHECK (type IN ('cash', 'bank', 'card')),
          is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
          created_at_ms INTEGER NOT NULL
        )
      ''');

      await _seedDefaultAccount(tx);

      // --- categories ---
      await tx.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          classification TEXT NOT NULL
            CHECK (classification IN ('income', 'expense', 'adjustment')),
          icon_key TEXT,
          color_value INTEGER,
          is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1))
        )
      ''');

      await tx.execute('''
        CREATE UNIQUE INDEX idx_categories_unique
        ON categories(classification, name COLLATE NOCASE)
      ''');

      // --- movements ---
      await tx.execute('''
        CREATE TABLE movements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
          category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
          amount INTEGER NOT NULL CHECK (amount != 0),
          description TEXT NOT NULL,
          occurred_on INTEGER NOT NULL,
          notes TEXT,
          created_at_ms INTEGER NOT NULL
        )
      ''');
      // (año, mes, dia, hora, minutos, segundos, milisegundos)
      // (2026,09,17,11,18,22,27,100).aentero
      // 2026091711182227100
      // UTC -6
      // 2026091711182227100 06
      // zona horaria

      await tx.execute('''
        CREATE INDEX idx_movements_occurred_on
        ON movements(occurred_on)
      ''');

      await tx.execute('''
        CREATE INDEX idx_movements_account_id
        ON movements(account_id)
      ''');

      await tx.execute('''
        CREATE INDEX idx_movements_category_id
        ON movements(category_id)
      ''');

      await tx.execute('''
        CREATE INDEX idx_movements_kind_date
        ON movements(category_id, occurred_on)
      ''');

      // --- monthly_budgets ---
      await tx.execute('''
        CREATE TABLE monthly_budgets (
          month_start TEXT PRIMARY KEY,
          limit_minor INTEGER NOT NULL CHECK (limit_minor > 0),
          created_at_ms INTEGER NOT NULL
        )
      ''');

      // --- savings_goals ---
      await tx.execute('''
        CREATE TABLE savings_goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          target_amount_minor INTEGER NOT NULL CHECK (target_amount_minor > 0),
          saved_amount_minor INTEGER NOT NULL DEFAULT 0
            CHECK (saved_amount_minor >= 0),
          target_date TEXT,
          is_archived INTEGER NOT NULL DEFAULT 0
            CHECK (is_archived IN (0, 1)),
          created_at_ms INTEGER NOT NULL
        )
      ''');

      await tx.execute('''
        CREATE INDEX idx_savings_goals_archived
        ON savings_goals(is_archived)
      ''');

      // --- seed: categorías iniciales ---
      final categorias = <Map<String, dynamic>>[
        {'name': 'Salario', 'classification': 'income'},
        {'name': 'Ingreso extra', 'classification': 'income'},
        {'name': 'Transporte', 'classification': 'expense'},
        {'name': 'Supermercado', 'classification': 'expense'},
        {'name': 'Comida', 'classification': 'expense'},
        {'name': 'Servicios', 'classification': 'expense'},
        {'name': 'Entretenimiento', 'classification': 'expense'},
        {'name': 'Higiene', 'classification': 'expense'},
        {'name': 'Saldo inicial', 'classification': 'adjustment'},
      ];

      for (final cat in categorias) {
        await tx.insert('categories', {...cat, 'is_archived': 0});
      }
    });
  }
}
