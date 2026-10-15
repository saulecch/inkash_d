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
