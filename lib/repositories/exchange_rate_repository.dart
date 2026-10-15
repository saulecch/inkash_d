import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/exchange_rate.dart';
import '../services/exchange_rate_api.dart';

// Offline-first "ligero": primero la red; si falla, el último dato que sí
// llegó (tabla exchange_rate_cache, versión 4 de la base).
// La pantalla no sabe de dónde vino: solo ve ExchangeRate.fromCache.
class ExchangeRateRepository {
  ExchangeRateRepository({ExchangeRateApi? api, AppDatabase? database})
    : _api = api ?? ExchangeRateApi(),
      _db = database ?? AppDatabase.instance;

  final ExchangeRateApi _api;
  final AppDatabase _db;

  Future<ExchangeRate> getUsdRate() async {
    try {
      final rate = ExchangeRate(
        gtqPerUsdTenThousandths: await _api.fetchGtqPerUsdTenThousandths(),
        updatedAt: DateTime.now(),
      );
      await _saveCache(rate);
      return rate;
    } on ExchangeRateException {
      // Sin red: si tenemos un dato anterior, mejor eso que una pantalla vacía.
      final cached = await _readCache();
      if (cached != null) return cached;
      rethrow; // Nunca hubo dato: que la UI muestre el error.
    }
  }

  Future<void> _saveCache(ExchangeRate rate) async {
    final db = await _db.database;
    // Una sola fila por moneda: si ya existe, se reemplaza.
    await db.insert('exchange_rate_cache', {
      'currency': 'USD',
      'gtq_ten_thousandths': rate.gtqPerUsdTenThousandths,
      // Instante de descarga: epoch ms, igual que created_at_ms.
      'updated_at_ms': rate.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ExchangeRate?> _readCache() async {
    final db = await _db.database;
    final rows = await db.query(
      'exchange_rate_cache',
      where: 'currency = ?',
      whereArgs: ['USD'],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return ExchangeRate(
      gtqPerUsdTenThousandths: row['gtq_ten_thousandths']! as int,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at_ms']! as int,
      ),
      fromCache: true,
    );
  }
}
