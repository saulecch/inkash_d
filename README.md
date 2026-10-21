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

## Qué hace
- **Bienvenida** (la primera vez): tu nombre, tu límite mensual y el saldo de hoy en
  cada cuenta, en 3 pasos.
- **Inicio**: saludo con tu nombre, cuánto te queda este mes frente a tu límite (o
  "Te pasaste del límite por…" en rojo), total de cuentas, metas activas, tipo de
  cambio y últimos 5 movimientos.
- **(+)**: registrar gasto o ingreso desde cualquier pestaña, con categoría (chips con
  icono y "+ Nueva" sin salir del formulario) y cuenta.
- **Editar movimientos**: tocar un movimiento (Inicio o Historial) abre el mismo
  formulario lleno; "Guardar cambios" o "Eliminar movimiento" con *Deshacer*.
- **Historial**: por mes y categoría, agrupado por día; deslizar para borrar con *Deshacer*.
- **Presupuesto**: límite por categoría con avance y resumen ("Te quedan…", excedidas).
- **Cuentas**: Efectivo, bancos y tarjetas con saldo inicial (Tengo/Debo); el saldo
  inicial es un movimiento "Saldo inicial" ([ADR-0004](docs/adr/0004-migraciones-numeradas-y-saldo-por-cuenta.md)).
- **Categorías**: gastos e ingresos con icono; archivar las que ya no usas.
- **Metas de ahorro**: crear, editar, aportar y retirar (desde la tarjeta del Inicio).
- **Ajustes**: perfil, límite mensual, Cuentas, Categorías y borrar todos los datos.
- Diseño: tokens, tema y componentes en [`docs/diseno.md`](docs/diseno.md).

## Publicar
Ver [`docs/publicacion/firma.md`](docs/publicacion/firma.md) y
[`docs/tienda/checklist-play.md`](docs/tienda/checklist-play.md). En resumen:
subir `version` en el pubspec y `git push origin vX.Y.Z`; el workflow
**Release** firma el AAB y lo adjunta a un GitHub Release.
Identidad: `gt.edu.umes.inkashd`, nombre visible "Inkash D".

## Arquitectura

```
lib/
  database/          AppDatabase: abre inkash.db y aplica AppDatabase.migrations
  models/            Movement, NewMovement, Account, Category, HomeSummary, ExchangeRate…
  repositories/      ÚNICO lugar con SQL (movements, accounts, categories, exchange rate…)
  services/          ÚNICO lugar con HTTP (ExchangeRateApi)
  utils/             parseAmountMinor (centavos sin double), encodeOccurredOn
  features/home/presentation/
    controllers/     HomeController (Riverpod AsyncNotifier) + exchangeRateProvider
    widgets/         MovementBottomSheet, MovementTile, ExchangeRateCard
  features/          navigation/ history/ accounts/ categories/ budget/ goals/
                     settings/ welcome/
  widgets/ui/        componentes del sistema de diseño (PageHeader, Section…)
  theme.dart         tokens (Spacing, Corners), tipografía y tema central
  shell.dart         barra inferior + IndexedStack (una pantalla por pestaña)
  home.dart          dashboard (ConsumerWidget con AsyncValue.when)
```

Decisiones documentadas en [`docs/adr/`](docs/adr/README.md).
Cómo colaborar: [`CONTRIBUTING.md`](CONTRIBUTING.md). Uso de IA: [`docs/bitacora-ia.md`](docs/bitacora-ia.md).

## Base de datos local

`inkash.db` (versión 8) se abre la primera vez que un provider la necesita. El esquema
es un mapa `versión -> migración` (`AppDatabase.migrations`,
[ADR-0004](docs/adr/0004-migraciones-numeradas-y-saldo-por-cuenta.md)).

- `accounts`, `categories` (con `classification` income/expense/adjustment),
  `movements`, `monthly_budgets`, `savings_goals`.
- `movements.amount` en **centavos enteros** con signo: negativo para gastos.
  El signo lo decide la categoría al guardar.
- `movements.occurred_on`: entero **local** de 17 dígitos `yyyyMMddHHmmssSSS`.
  `created_at_ms`: **epoch** en milisegundos. Son formatos distintos a propósito
  ([ADR-0001](docs/adr/0001-sqlite-centavos-y-occurred-on.md)).
- `exchange_rate_cache` (v4): último tipo de cambio USD→GTQ en diezmilésimas,
  para modo sin conexión ([ADR-0003](docs/adr/0003-api-tipo-cambio-con-cache.md)).
- v5: nombre de cuenta único (índice `UNIQUE`); v6: iconos de las categorías base.
- `category_budgets` (v7): un límite por categoría.
- `app_settings` (v8): ajustes clave/valor (nombre, bandera de la bienvenida). El
  límite mensual vive en `monthly_budgets`.
