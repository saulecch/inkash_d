# ADR-0001: SQLite, dinero en centavos enteros y `occurredOn` local de 17 dígitos

- Estado: Aceptado
- Fecha: 2026-09-03 (tablas, S10) · 2026-09-17 (formato de fecha, S11) · 2026-10-15 (guardado endurecido, S14)
- Commits: `0e276f2`, `2faa973`, `s14-01-guardar`

## Contexto
Inkash registra gastos e ingresos por cuenta y categoría, con presupuesto
mensual y metas de ahorro. Si el usuario cierra la app, los datos deben seguir
ahí, sin cuenta ni servidor. Las consultas son relacionales: movimientos ↔
cuentas ↔ categorías, sumas por mes, orden por fecha.

## Decisión
- Usaremos **SQLite** vía `sqflite`, con una sola clase `AppDatabase` que abre
  la base una vez y la comparte. Solo `lib/repositories/` escribe SQL.
- El dinero es **entero en centavos** (`amount`, `*_minor`). En SQL el gasto
  es negativo, para que `SUM(amount)` sea el saldo. El signo lo decide la
  **categoría** (`classification`) dentro de la transacción de `insertNew`.
- `occurred_on` (cuándo pasó) es un **entero LOCAL de 17 dígitos**
  `yyyyMMddHHmmssSSS` (ej. `20261015081503007`).
- `created_at_ms` (cuándo se registró) es **epoch en milisegundos**.
- Los dos formatos conviven a propósito; no se "unifican" sin un ADR nuevo.

## Alternativas consideradas
- **SharedPreferences**: sirve para ajustes, no para listas que se filtran y suman.
- **Hive / Isar**: sin SQL ni llaves foráneas; el curso quiere el modelo relacional.
- **Firebase / backend**: requiere cuenta e internet; el MVP no lo necesita.
- **`double` para dinero**: `0.1 + 0.2 != 0.3`. Descartado.
- **`occurred_on` como TEXT ISO (`2026-09-17`)**: así empezó en S10. En S11 se
  cambió a entero para guardar también la hora y ordenar sin parsear texto.
- **`occurred_on` como epoch ms (igual que `created_at_ms`)**: más estándar y
  sin ambigüedad de zona, pero no se lee "a ojo" en la base y agrupar por mes
  exige convertir. El equipo prefirió legibilidad y `substr(occurred_on, 1, 6)`.

## Consecuencias
- ➕ Los datos sobreviven al cierre de la app; hay integridad con `FOREIGN KEY`.
- ➕ El mes sale con `substr(occurred_on, 1, 6)` y el orden numérico es el
  orden cronológico.
- ➕ Probamos con `sqflite_common_ffi` en la computadora, sin emulador.
- ➖ `occurred_on` **no guarda zona horaria**: es la hora del teléfono. Si el
  usuario viaja o cambia la zona, dos movimientos pueden quedar mal ordenados.
  Guatemala no tiene horario de verano, por eso lo aceptamos para el MVP.
- ➖ Es un formato propio: hay que usar siempre `encodeOccurredOn` (y no
  confundirlo con `created_at_ms`, que es epoch). Un error aquí no lo detecta
  SQLite: ambos son `INTEGER`.
- ➖ Cambiar el tipo de una columna exige **reconstruir la tabla** (la
  migración v1→v2 de S11 copió a `movements_v2`, borró la vieja y renombró).
  Para agregar cosas usamos solo `CREATE TABLE`/`ALTER TABLE ADD` (ADR-0003).
- ➖ `sqflite` **no funciona en Web**: el equipo prueba en Android/iOS/macOS.
- Señal de error: si aparecen reportes de movimientos "en el futuro" o mal
  ordenados por viajes, escribir un ADR que migre a epoch + zona.
