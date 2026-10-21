# ADR-0005: Publicar por prueba interna de Play con release automatizado

- Estado: Aceptado
- Fecha: 2026-11-12
- Commits: `s17-04-identidad` … `s17-07-tienda`

## Contexto
El curso cierra el 19 de noviembre. Las cuentas personales nuevas de Play Console
necesitan una prueba cerrada con al menos 12 testers durante 14 días antes de poder
publicar en producción (confirmar la regla vigente). No hay Macs para todos los
equipos, así que iOS no se puede compilar de forma regular.

## Decisión
- Identidad permanente: `gt.edu.umes.inkashd` en Android, iOS y macOS (sin `_`,
  que iOS no acepta), nombre visible "Inkash D", versión `0.9.0+N` (beta).
- Firma con *upload key* propia; Play App Signing guarda la llave final.
- El AAB se produce **solo por CI** (`release.yml`, tag `v*`), nunca desde una laptop,
  para que cualquier integrante pueda publicar sin tener la llave.
- Canal: **prueba interna** de Play. La producción queda fuera del alcance del curso.
- iOS: solo se documenta el proceso (Codemagic / TestFlight).
- Política de privacidad: los datos no salen del teléfono (salvo la copia de seguridad
  del propio sistema); ver `docs/tienda/`.

## Alternativas consideradas
- **Compilar y firmar a mano**: depende de una sola laptop y de que nadie suba el `.jks`.
- **Producción directa**: inviable en el calendario por la regla de los 14 días.
- **Distribuir el APK por WhatsApp**: no enseña el proceso real y los teléfonos lo bloquean.
- **Conservar `inkash_d` como id**: Play no acepta `com.example.*` y los ids de Apple
  no aceptan `_`; tener ids distintos por plataforma confunde.

## Consecuencias
- ➕ Publicar = subir `version` y `git push origin v0.9.0`. Reproducible y auditable.
- ➖ Si se pierde la upload key, hay que pedir el reseteo a soporte de Play.
- ➖ En macOS el cambio de bundle id crea un contenedor nuevo: la base de datos
  empieza vacía (la anterior queda en el contenedor viejo).
- ➖ Agregar telemetría o un backend obliga a actualizar la política y el formulario
  de seguridad de los datos **antes** de publicar esa versión.
