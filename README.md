# Inkash (sección D)

![CI](https://github.com/saulecch/inkash_d/actions/workflows/ci.yml/badge.svg)

App de finanzas personales en Flutter — proyecto de clase de Programación de
Dispositivos Móviles (UMES 2026), versión de la sección D.

## Cómo correrla

```bash
flutter pub get
flutter run            # Android, iOS o macOS. NO Chrome: sqflite no soporta Web.
flutter test           # pruebas (SQLite corre en la compu con sqflite_common_ffi)
```

## Arquitectura

```
lib/
  database/          AppDatabase: abre inkash.db (versión 4) y migra
  models/            Movement, NewMovement, Account, Category, HomeSummary, ExchangeRate…
  repositories/      ÚNICO lugar con SQL (movements, accounts, categories, exchange rate…)
  services/          ÚNICO lugar con HTTP (ExchangeRateApi)
  utils/             parseAmountMinor (centavos sin double), encodeOccurredOn
  features/home/presentation/
    controllers/     HomeController (Riverpod AsyncNotifier) + exchangeRateProvider
    widgets/         MovementBottomSheet, ExchangeRateCard
  home.dart          dashboard (ConsumerWidget con AsyncValue.when)
```

Decisiones documentadas en [`docs/adr/`](docs/adr/README.md).
Cómo colaborar: [`CONTRIBUTING.md`](CONTRIBUTING.md). Uso de IA: [`docs/bitacora-ia.md`](docs/bitacora-ia.md).

## Base de datos local

`inkash.db` (versión 4) se abre la primera vez que un provider la necesita.

- `accounts`, `categories` (con `classification` income/expense/adjustment),
  `movements`, `monthly_budgets`, `savings_goals`.
- `movements.amount` en **centavos enteros** con signo: negativo para gastos.
  El signo lo decide la categoría al guardar.
- `movements.occurred_on`: entero **local** de 17 dígitos `yyyyMMddHHmmssSSS`.
  `created_at_ms`: **epoch** en milisegundos. Son formatos distintos a propósito
  ([ADR-0001](docs/adr/0001-sqlite-centavos-y-occurred-on.md)).
- `exchange_rate_cache` (v4): último tipo de cambio USD→GTQ en diezmilésimas,
  para modo sin conexión ([ADR-0003](docs/adr/0003-api-tipo-cambio-con-cache.md)).
