import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  // S14-01: factory y path se pueden inyectar. En las pruebas usamos
  // sqflite_common_ffi y un archivo temporal; en la app, los valores reales.
  AppDatabase({this.factory, this.path});
  static final AppDatabase instance = AppDatabase();

  static const _dbName = 'inkash.db';

  // S16-01: el esquema es un MAPA versión -> migración.
  // - Instalación nueva (onCreate): se aplican todas, de la 1 a la última.
  // - Instalación existente (onUpgrade): solo las que le faltan.
  // Antes el esquema se escribía DOS veces (completo en onCreate y por
  // partes en onUpgrade) y nada garantizaba que coincidieran.
  // Regla de oro: una migración publicada NO se edita; se agrega otra.
  static final Map<int, Future<void> Function(DatabaseExecutor db)> migrations =
      {
        1: _v1BaseTables,
        2: _v2IntegerAmountAndOccurredOn,
        3: _v3DefaultAccount,
        4: _v4ExchangeRateCache,
        5: _v5UniqueAccountNames,
      };

  // Subir la versión es la ÚNICA forma de cambiar el esquema en teléfonos
  // que ya tienen la app instalada (onCreate no se vuelve a ejecutar).
  static int get currentVersion => migrations.length;

  // Se resuelve al ABRIR, no al construir: crear un repositorio en una
  // prueba de widget no debe exigir que sqflite esté inicializado.
  final DatabaseFactory? factory;
  final String? path;

  // Guardamos el Future (no la Database): si dos pantallas piden la base al
  // mismo tiempo, las dos esperan la MISMA apertura en vez de abrir dos.
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final dbFactory = factory ?? databaseFactory;
    try {
      final dbPath = path ?? join(await dbFactory.getDatabasesPath(), _dbName);
      return await dbFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: currentVersion,
          onConfigure: _onConfigure,
          // sqflite corre onCreate/onUpgrade dentro de una transacción:
          // si una migración falla, no queda un esquema a medias.
          onCreate: (db, version) => _migrate(db, from: 0, to: version),
          onUpgrade: (db, from, to) => _migrate(db, from: from, to: to),
        ),
      );
    } catch (_) {
      // Si falló, olvidamos el Future para que "Reintentar" vuelva a abrir.
      _database = null;
      rethrow;
    }
  }

  Future<void> close() async {
    final pending = _database;
    if (pending == null) return;
    _database = null;
    await (await pending).close();
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    await db.rawQuery('PRAGMA journal_mode = WAL;');
    await db.execute('PRAGMA synchronous = FULL;');
    await db.rawQuery('PRAGMA busy_timeout = 5000;');
  }

  static Future<void> _migrate(
    DatabaseExecutor db, {
    required int from,
    required int to,
  }) async {
    for (var version = from + 1; version <= to; version++) {
      await migrations[version]!(db);
    }
  }

  // v1 (S10): el esquema TAL COMO SE PUBLICÓ, con amount_minor y
  // occurred_on TEXT. Parece raro crear algo que la v2 cambia enseguida,
  // pero así un teléfono nuevo recorre el MISMO camino que uno viejo.
  static Future<void> _v1BaseTables(DatabaseExecutor db) async {
    // --- accounts ---
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('cash', 'bank', 'card')),
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
        created_at_ms INTEGER NOT NULL
      )
    ''');

    // --- categories ---
    await db.execute('''
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

    await db.execute('''
      CREATE UNIQUE INDEX idx_categories_unique
      ON categories(classification, name COLLATE NOCASE)
    ''');

    // --- movements ---
    await db.execute('''
      CREATE TABLE movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
        category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
        amount_minor INTEGER NOT NULL CHECK (amount_minor != 0),
        description TEXT NOT NULL,
        occurred_on TEXT NOT NULL,
        notes TEXT,
        created_at_ms INTEGER NOT NULL
      )
    ''');

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

    // --- monthly_budgets ---
    await db.execute('''
      CREATE TABLE monthly_budgets (
        month_start TEXT PRIMARY KEY,
        limit_minor INTEGER NOT NULL CHECK (limit_minor > 0),
        created_at_ms INTEGER NOT NULL
      )
    ''');

    // --- savings_goals ---
    await db.execute('''
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

    await db.execute('''
      CREATE INDEX idx_savings_goals_archived
      ON savings_goals(is_archived)
    ''');

    // --- seed: categorías iniciales ---
    // Escritas AQUÍ, no importadas de la app: una migración es una foto del
    // pasado y no debe cambiar si el código de hoy cambia.
    const categories = [
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
    for (final category in categories) {
      await db.insert('categories', {...category, 'is_archived': 0});
    }
  }

  // v2 (S11): amount entero con signo y occurred_on INTEGER de 17 dígitos.
  // SQLite no cambia el tipo de una columna: se crea la tabla nueva, se
  // copian los datos convertidos, se borra la vieja y se renombra.
  static Future<void> _v2IntegerAmountAndOccurredOn(DatabaseExecutor db) async {
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

  // v3 (S11): toda instalación tiene al menos la cuenta "Efectivo".
  // WHERE NOT EXISTS: si el usuario ya tenía cuentas, no se agrega otra.
  static Future<void> _v3DefaultAccount(DatabaseExecutor db) async {
    await db.rawInsert(
      '''
        INSERT INTO accounts (name, type, is_archived, created_at_ms)
        SELECT ?, ?, 0, ?
        WHERE NOT EXISTS (SELECT 1 FROM accounts)
      ''',
      ['Efectivo', 'cash', DateTime.now().millisecondsSinceEpoch],
    );
  }

  // v4 (S14-03): último tipo de cambio USD -> GTQ que sí llegó, para modo
  // sin conexión.
  // La tasa va en diezmilésimas (INTEGER), nunca REAL.
  static Future<void> _v4ExchangeRateCache(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE exchange_rate_cache (
        currency TEXT NOT NULL PRIMARY KEY,
        gtq_ten_thousandths INTEGER NOT NULL CHECK (gtq_ten_thousandths > 0),
        updated_at_ms INTEGER NOT NULL
      )
    ''');
  }

  // v5 (S16-01): ya se pueden crear cuentas desde la app, así que el nombre
  // debe ser único (sin importar mayúsculas). Un índice UNIQUE lo garantiza
  // la base, no solo la pantalla. Hasta la v4 no había forma de crear
  // cuentas (solo el seed "Efectivo"), así que no puede haber duplicados.
  static Future<void> _v5UniqueAccountNames(DatabaseExecutor db) async {
    await db.execute('''
      CREATE UNIQUE INDEX idx_accounts_name_unique
      ON accounts(name COLLATE NOCASE)
    ''');
  }
}
