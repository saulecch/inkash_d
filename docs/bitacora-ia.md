# Bitácora de uso de IA

Cada uso de IA que termina en el repo se registra aquí (el más reciente arriba).
El objetivo no es justificar el uso, sino demostrar **criterio**:
qué especificaste, qué revisaste y qué rechazaste.

| Campo | Qué escribir |
|---|---|
| Fecha / autor | `2026-10-15 · @usuario` |
| Herramienta | Claude, Copilot, ChatGPT, Big Pickle… |
| Especificación | Qué pediste y con qué restricciones (pegar el prompt o resumirlo) |
| Resultado | Qué devolvió, en una frase |
| Aceptado | Qué quedó en el código y por qué |
| Rechazado / corregido | Qué cambiaste y por qué. **Esta es la columna más importante.** |
| Verificación | Cómo comprobaste que funciona (pruebas, dispositivo) |
| Commit / PR | Enlace |

---

## 2026-10-21 · @saulecch (docente) — S15 a S17 en la sección D (y por qué se rehicieron S16 y S17)

- **Herramienta:** Claude (asistente de código).
- **Especificación:** "Replicar en inkash_d los pasos de inkash (`s15-01` … `s17-07`),
  adaptados a lo que D ya tiene. Un commit por tema; `dart format`, `flutter analyze` y
  `flutter test` en verde antes de cada commit; solo local."
- **Por qué se rehicieron S16 y S17:** la primera versión pasaba todas las pruebas, pero
  al usar la app el docente encontró que **no se podía terminar el trabajo real**: no había
  forma de crear categorías ni cuentas, el saldo inicial no tenía pantalla, los movimientos
  y las metas no se podían editar y los diálogos eran `AlertDialog` sueltos. Lección: una
  prueba verde dice que el código hace lo que la prueba pregunta, no que la app esté
  completa. Las ramas viejas quedaron como `respaldo/s16-v1` y `respaldo/s17-v1`.
- **Aceptado:** totales del mes con `SUM + CASE` sobre el rango de `occurred_on` (17
  dígitos); migraciones como mapa `versión -> función` con la v1 **real** de S10
  (recuperada de git); saldo inicial como movimiento 'Saldo inicial' guardado en la misma
  transacción que la cuenta; `LEFT JOIN` con el filtro del mes en el `ON`; `UPDATE`
  atómico en metas; sistema de diseño con tokens y componentes; Ajustes que el Inicio
  observa con `ref.watch`.
- **Rechazado / corregido durante el trabajo:**
  - **Ciclo de providers.** "Borrar todos mis datos" invalidaba el Inicio desde
    `SettingsController`, pero el Inicio hace `ref.watch(settingsProvider)`: la prueba
    falló con `CircularDependencyError`. Se quitó esa línea; `invalidateSelf()` ya
    recalcula el Inicio.
  - **Revisión visual (s17-01).** Las pruebas pasaban, pero al dibujar las pantallas a PNG
    se vio que todo el texto secundario salía blanco (`TextTheme.apply` pisa el color de
    `bodySmall`), una sombra negra sobre la barra inferior y un aro negro alrededor del
    botón flotante. Se corrigió en el tema. La prueba de captura no se versiona.
  - **Avisos en fila.** Al editar y luego borrar, el SnackBar "Movimiento eliminado"
    esperaba detrás de "Cambios guardados" (la prueba no lo encontraba). Ahora se cierra el
    aviso anterior antes de mostrar el nuevo.
  - **Pruebas que dependían del tamaño de pantalla.** Con SnackBar flotante y la barra
    inferior, algunas filas quedaban tapadas en la pantalla de prueba de 800×600; se cerró
    el aviso o se usó una pantalla de teléfono en esa prueba.
  - **Valor `null` en `whereArgs` (s16-03).** sqflite avisó que no acepta `null` como
    argumento; la consulta se arma según haya o no movimiento que editar.
  - **Prueba que dependía del orden (s16-01).** La prueba de saldos tomaba `first` como
    "Efectivo", pero el seed usa `DateTime.now()` y queda al final. Se busca por nombre.
  - **Archivo temporal en la suite (s16-01).** La prueba de volcado del esquema (para
    comparar antes/después del mapa de migraciones) se coló en la suite completa; se borró
    antes del commit y nunca entró al historial.
  - **Verificación por mutación sin `git checkout`.** Para comprobar que una prueba no
    pasa en falso se quitó la línea que prueba y se restauró desde una **copia**, aplicando
    la lección del incidente de `git checkout --` registrado en S14.
  - **Decisiones para no inventar datos:** sin columna de saldo inicial ni cuentas
    sembradas (ADR-0004); el límite mensual usa `monthly_budgets` (ya existía) en vez de
    duplicarlo en la tabla de ajustes.
- **Pendiente / no verificado:** no se abrió la app en un dispositivo (se usaría la base
  real); el CI de release no se ha corrido en GitHub.
- **Verificación:** `flutter analyze` sin observaciones y `flutter test` en verde en cada
  commit; capturas PNG revisadas a ojo; la firma del AAB se comprueba con
  `keytool -printcert` en s17-05.

## 2026-10-15 · @saulecch (docente) — preparación de S14 para la sección D

- **Herramienta:** Claude (asistente de código).
- **Especificación:** "Llevar inkash_d desde `2faa973` (S11) por los mismos seis pasos que
  inkash (`s14-01` … `s14-06`), adaptados a su código y nombres en inglés. Primero leer qué
  ya existe. `occurredOn` es local de 17 dígitos y `createdAtMs` es epoch ms: no cambiarlos.
  Dinero en centavos, nunca `double`. Cada commit con `dart format`, `flutter analyze` y
  `flutter test` en verde. Solo local, sin push."
- **Resultado:** commits `s14-01-guardar` a `s14-06-ci`.
- **Aceptado:** `parseAmountMinor` sin `double`, guard de doble toque antes del `await`,
  signo decidido por la categoría dentro de una transacción, `AsyncNotifier` con
  `retry: null`, migración v3→v4 que solo agrega una tabla.
- **Rechazado / corregido durante el trabajo:**
  - Al leer el código se vio que S11 **ya guardaba** desde el bottom sheet y el dashboard
    **ya leía** SQLite. Se descartó copiar los pasos de inkash al pie de la letra: `s14-01`
    endurece lo existente y `s14-02` cambia el `ChangeNotifier` por `AsyncNotifier`.
  - La regex de S11 (`\d+`) aceptaba 20 dígitos y `int.parse` lanzaba **dentro del
    validator**. Se limitó a 9 dígitos con un máximo y quedó una prueba.
  - Para comprobar que la prueba de doble toque **no pasa en falso**, la IA quitó el guard
    a propósito (la prueba falló: 2 llamadas). Al restaurar usó `git checkout` sobre el
    archivo y **borró también los cambios aún sin commit**; se recuperó de una copia
    hecha justo antes. Lección: para experimentos, `git stash` o una copia, nunca
    `git checkout -- archivo` con trabajo pendiente.
  - Misma verificación con Riverpod 3: sin `retry: (_, _) => null`, la prueba de error
    vio **11 lecturas** en vez de 1 (Riverpod reintentaba solo y escondía el error).
  - La primera versión de las pruebas usó `List<Override>` y no compilaba: en Riverpod 3
    `Override` se importa de `package:flutter_riverpod/misc.dart`.
  - La referencia redondeaba la tasa con `(x / 100).round()` (pasa por `double`); aquí se
    usó `(x + 50) ~/ 100`, solo enteros.
  - El commit de ADRs se hizo antes de correr `format/analyze/test` (era solo
    documentación); se corrieron después y siguieron en verde, pero el orden fue incorrecto.
- **Pendiente / no verificado:** la app compila (`flutter build macos --debug`), pero no se
  abrió en un dispositivo para no migrar la base real del equipo; tampoco se corrió el CI
  en GitHub (no hubo push). `formatQuetzales` de `HomeSummary` deja un espacio inicial
  (`' Q4,162.00'`); se dejó igual porque no es parte de S14.
- **Verificación:** `flutter analyze` sin observaciones y `flutter test` en verde en cada commit.
