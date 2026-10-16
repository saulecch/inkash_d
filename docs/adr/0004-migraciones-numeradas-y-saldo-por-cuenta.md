# ADR-0004: Migraciones numeradas, cuentas administrables y saldo inicial como movimiento

- Estado: Aceptado
- Fecha: 2026-10-29
- Commit: `s16-01-cuentas`

## Contexto
Hasta S15 el esquema se escribía dos veces: completo en `onCreate` (ya en
su forma final) y por partes en `onUpgrade` (`if (oldVersion < N)`). Nada
garantizaba que un teléfono nuevo y uno actualizado terminaran con la misma
base, y cada versión nueva obligaba a tocar los dos lugares.
Además, la tarjeta "Cuentas" del Inicio solo mostraba un total, no había
forma de crear cuentas (Banco, Tarjeta) ni de indicar con cuánto empezaba
cada una, y los movimientos no decían de qué cuenta salían.

## Decisión
- El esquema es un mapa `versión -> migración` (`AppDatabase.migrations`).
  `onCreate` aplica de la 1 a la última; `onUpgrade`, solo las que faltan.
  `currentVersion = migrations.length`.
- La v1 es el esquema de S10 **tal como se publicó** (`amount_minor`,
  `occurred_on` TEXT), recuperado del historial de git. Una instalación nueva
  pasa por la v2 (reconstrucción de `movements`) igual que una vieja.
  Verificado: el esquema resultante es idéntico al del `onCreate` anterior.
- Una migración publicada **no se edita**: los cambios van en una nueva.
  Los datos sembrados (categorías, "Efectivo") van escritos dentro de la
  migración, no importados del código actual.
- El saldo de una cuenta = `COALESCE(SUM(amount), 0)` con `LEFT JOIN` +
  `GROUP BY`, para que las cuentas sin movimientos también aparezcan.
- **Saldo inicial = un movimiento**, no una columna: desde S10 existe la
  categoría `Saldo inicial` (`adjustment`). El formulario de cuenta tiene
  "Tengo / Debo" y un monto; al guardar, en **una transacción** se crea,
  actualiza (misma fila, misma fecha) o borra (si es 0) ese movimiento.
  Así el saldo inicial ya está dentro del `SUM` y no cuenta como ingreso
  ni gasto del mes (los totales filtran por `classification`).
- Pantalla **Cuentas** (push desde la tarjeta del Inicio): crear y editar
  con nombre, tipo (Efectivo / Banco / Tarjeta: la columna `type` con CHECK
  hace de icono) y saldo inicial.
- **v5**: índice `UNIQUE` sobre `accounts(name COLLATE NOCASE)`; el
  repositorio traduce el error a "Ya existe una cuenta llamada…". Antes de
  la v5 no se podían crear cuentas, así que no puede haber duplicados.
- Una cuenta con movimientos **no se borra** (se revisa y borra en la misma
  transacción); su 'Saldo inicial' no cuenta como uso y se borra con ella.
- **No** se siembran cuentas extra (Banco, Tarjeta): sería inventar cuentas
  en teléfonos que ya tienen datos; ahora el usuario las crea. Toda
  instalación tiene al menos "Efectivo" (v3, solo si no había ninguna).

## Alternativas consideradas
- **Mantener onCreate + onUpgrade separados**: más corto hoy, pero la deuda
  crece con cada versión. Descartado.
- **v1 = esquema actual** (sin pasar por la v2): más rápido en instalaciones
  nuevas, pero la v1 ya no sería la que recibieron los teléfonos de S10 y
  romperíamos la regla de no editar migraciones publicadas.
- **Columna `initial_balance_minor` en `accounts`** (como en inkash):
  duplicaría el concepto de "Saldo inicial" que ya existe como categoría y
  obligaría a sumar dos fuentes para el saldo.
- **Columna `icon` en `accounts`**: el tipo ya distingue Efectivo, Banco y
  Tarjeta; otra columna podría contradecirlo.

## Consecuencias
- ➕ Prueba automática: esquema de instalación nueva == esquema actualizado
  desde la v1 (`sqlite_master` + `PRAGMA table_info`).
- ➕ Agregar una versión es agregar una entrada al mapa.
- ➖ Una instalación nueva crea `movements` y la reconstruye enseguida (v2):
  trabajo inútil, pero sobre una tabla vacía.
- ➖ El 'Saldo inicial' aparece en el Historial como un movimiento más (se
  edita desde Cuentas, no desde el formulario de movimientos).
- ➖ Si alguien borra ese movimiento desde el Historial, la cuenta queda con
  saldo inicial 0 (es coherente, pero hay que saberlo).
