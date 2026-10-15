# ADR-0003: Datos remotos — red primero, caché local si falla

- Estado: Aceptado
- Fecha: 2026-10-15
- Commit: `s14-03-api`

## Contexto
Los usuarios pagan suscripciones y compras en dólares. Mostrar el tipo de
cambio del día ayuda a decidir. El dato viene de internet, y en Guatemala la
conexión móvil es intermitente (bus, interior del país).

## Decisión
- Consumiremos `https://open.er-api.com/v6/latest/USD` (gratuita, sin API key)
  con `package:http`, **timeout de 5 s** y un `http.Client` inyectable.
- Toda falla se traduce a `ExchangeRateException` con un mensaje para humanos:
  sin red · timeout · status ≠ 200 · JSON inesperado.
- La tasa se convierte a **entero (diezmilésimas)** en la frontera
  (`lib/services/exchange_rate_api.dart`); el resto de la app usa enteros.
- **Red primero, caché si falla**: cada respuesta buena se guarda en la tabla
  `exchange_rate_cache`. Sin red, mostramos el último dato **y lo decimos**
  ("Sin conexión · último dato 14/10 18:05").
- La tabla llega con la **versión 4** de la base (`onUpgrade`, `oldVersion < 4`),
  sin borrar ni reconstruir tablas existentes. `onCreate` también la crea.
- Permiso `INTERNET` en el `AndroidManifest.xml` principal (no solo en debug) y
  `com.apple.security.network.client` en los dos entitlements de macOS.

## Alternativas consideradas
- **Banguat (tipo de cambio oficial)**: el servicio es SOAP/XML; más trabajo
  para la clase. Candidato a reemplazo en un ADR futuro.
- **Sin caché**: con mala señal el usuario vería solo errores.
- **Caché primero, red después (stale-while-revalidate)**: mejor UX pero más
  complejo; lo dejamos como mejora.

## Consecuencias
- ➕ La tarjeta tiene sus propios estados: si la API cae, el dashboard sigue.
- ➕ Pruebas sin internet con `MockClient`, y prueba de migración v3 → v4.
- ➖ Dependemos de un tercero gratuito (límite de peticiones, puede cambiar el JSON).
- ➖ El dato en caché puede tener horas; por eso se muestra la hora y en otro color.
- Señal de error: si vemos muchos `fromCache`, revisar el proveedor.
