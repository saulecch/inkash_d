import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inkash_d/database/app_database.dart';
import 'package:inkash_d/models/exchange_rate.dart';
import 'package:inkash_d/repositories/exchange_rate_repository.dart';
import 'package:inkash_d/services/exchange_rate_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// MockClient = un "servidor" falso. Las pruebas no dependen de internet.
ExchangeRateApi apiReturning(int status, String body) => ExchangeRateApi(
  client: MockClient((_) async => http.Response(body, status)),
);

const okJson = '{"result":"success","rates":{"USD":1,"GTQ":7.6543}}';

void main() {
  group('ExchangeRateApi: las 4 formas de fallar', () {
    test('200 con JSON válido -> entero en diezmilésimas', () async {
      expect(
        await apiReturning(200, okJson).fetchGtqPerUsdTenThousandths(),
        76543,
      );
    });

    test('500 -> ExchangeRateException con el código', () async {
      await expectLater(
        apiReturning(500, 'error').fetchGtqPerUsdTenThousandths(),
        throwsA(
          isA<ExchangeRateException>().having(
            (e) => e.message,
            'message',
            contains('500'),
          ),
        ),
      );
    });

    test('200 pero JSON inesperado -> ExchangeRateException', () async {
      for (final body in ['{"rates":{}}', '<html>', '[]']) {
        await expectLater(
          apiReturning(200, body).fetchGtqPerUsdTenThousandths(),
          throwsA(isA<ExchangeRateException>()),
          reason: body,
        );
      }
    });

    test('sin internet -> "Sin conexión"', () async {
      final api = ExchangeRateApi(
        client: MockClient((_) => throw http.ClientException('offline')),
      );
      await expectLater(
        api.fetchGtqPerUsdTenThousandths(),
        throwsA(
          isA<ExchangeRateException>().having(
            (e) => e.message,
            'message',
            'Sin conexión a internet.',
          ),
        ),
      );
    });

    test('servidor lento -> timeout', () async {
      final api = ExchangeRateApi(
        timeout: const Duration(milliseconds: 50),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return http.Response(okJson, 200);
        }),
      );
      await expectLater(
        api.fetchGtqPerUsdTenThousandths(),
        throwsA(
          isA<ExchangeRateException>().having(
            (e) => e.message,
            'message',
            'El servidor tardó demasiado.',
          ),
        ),
      );
    });
  });

  test('centsPerUsd redondea con enteros', () {
    ExchangeRate rate(int value) =>
        ExchangeRate(gtqPerUsdTenThousandths: value, updatedAt: DateTime(2026));
    expect(rate(76543).centsPerUsd, 765);
    expect(rate(76550).centsPerUsd, 766);
  });

  group('ExchangeRateRepository: red primero, caché si falla', () {
    sqfliteFfiInit();
    late AppDatabase database;
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('inkash_d_rate_');
      database = AppDatabase(
        factory: databaseFactoryFfi,
        path: '${directory.path}/inkash.db',
      );
    });

    tearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    test('con red guarda en caché; sin red devuelve el último dato', () async {
      final online = await ExchangeRateRepository(
        api: apiReturning(200, okJson),
        database: database,
      ).getUsdRate();
      expect(online.fromCache, isFalse);

      final offline = await ExchangeRateRepository(
        api: apiReturning(503, 'caído'),
        database: database,
      ).getUsdRate();
      expect(offline.fromCache, isTrue);
      expect(offline.gtqPerUsdTenThousandths, 76543);
      expect(offline.centsPerUsd, 765);
    });

    test('sin red y sin caché -> el error llega a la UI', () async {
      await expectLater(
        ExchangeRateRepository(
          api: apiReturning(503, 'caído'),
          database: database,
        ).getUsdRate(),
        throwsA(isA<ExchangeRateException>()),
      );
    });
  });
}
