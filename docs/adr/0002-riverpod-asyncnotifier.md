# ADR-0002: Estado asíncrono con Riverpod `AsyncNotifier`

- Estado: Aceptado (reemplaza el `ChangeNotifier` + `ProviderContainer` manual de S09–S11)
- Fecha: 2026-10-15
- Commit: `s14-02-leer-async`

## Contexto
Desde S11 el dashboard ya leía SQLite, pero con un `ChangeNotifier`
(`MovimientosController`) que manejaba a mano `loading`, `error` y `summary`,
un `ProviderContainer` creado en `main.dart` y un `FutureBuilder` para abrir la
base. Tres banderas independientes se pueden desincronizar (cargando **y**
con error), y si la base no abría la única salida era reiniciar la app.
Leer de disco (y luego de internet) **tarda**, **puede fallar** y **puede
estar vacío**: la pantalla tiene que modelar los cuatro casos.

## Decisión
- Usaremos `flutter_riverpod` con `ProviderScope` en la raíz.
- Los datos que se leen y modifican viven en un `AsyncNotifier`
  (`HomeController` → `HomeSummary`). Los que solo se leen, en un
  `FutureProvider` (`exchangeRateProvider`).
- La UI usa `AsyncValue.when(loading, error, data)` y diseña también el
  estado **vacío**. El error trae un botón **Reintentar** (`ref.invalidate`).
- Tras guardar, el controlador **reconsulta** (`invalidateSelf`) en vez de
  modificar la lista a mano: SQLite es la única fuente de verdad.
- Los repositorios se exponen como providers para reemplazarlos
  (`overrideWithValue`) en las pruebas.
- Desactivamos el reintento automático de Riverpod 3 (`retry: (_, _) => null`):
  el usuario decide cuándo reintentar.

## Alternativas consideradas
- **Mantener el `ChangeNotifier`**: funciona, pero repite el patrón
  loading/error/data en cada pantalla y no se puede sustituir en pruebas sin
  pasar dependencias por constructores.
- **`setState` + `FutureBuilder`**: válido para una pantalla, pero el estado no
  se comparte con el bottom sheet.
- **BLoC**: más ceremonia (eventos + estados) para el tamaño del equipo.

## Consecuencias
- ➕ Cada estado de la pantalla es explícito y está probado (`test/widget_test.dart`).
- ➕ Las pruebas de widget no tocan SQLite ni internet.
- ➖ Curva de aprendizaje: `watch` vs `read`, `ref.invalidate`, `.notifier`,
  y en Riverpod 3 el tipo `Override` vive en `misc.dart`.
- ➖ Las pruebas de widget necesitan un falso por cada repositorio que usa
  `HomeController` (cinco). Si crece, conviene un repositorio de "resumen".
- ➖ Reconsultar todo el resumen tras cada guardado no escala a miles de
  filas; aceptable para el MVP.
