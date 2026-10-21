# Checklist de publicación (Google Play, prueba interna)

## Antes de compilar
- [ ] `applicationId` propio (no `com.example`)
- [ ] `version` del pubspec: `+N` mayor que el último AAB subido
- [ ] Ícono y nombre visibles correctos ("Inkash D", `gt.edu.umes.inkashd`)
- [ ] Permiso `INTERNET` en `android/app/src/main/AndroidManifest.xml` (si usa red)
- [ ] `flutter test` en verde

## Compilar y firmar
- [ ] Keystore de subida creado y respaldado **fuera** del repo (`docs/publicacion/firma.md`)
- [ ] Secrets cargados en GitHub (`ANDROID_KEYSTORE_BASE64`, contraseñas y alias)
- [ ] `git tag v0.9.0 && git push origin v0.9.0` → workflow **Release** en verde
- [ ] Descargar `app-release.aab` del GitHub Release

## Play Console
- [ ] Crear la app (nombre, idioma, app gratuita)
- [ ] Ficha de tienda (`ficha.md`) + capturas
- [ ] Política de privacidad publicada (URL)
- [ ] Cuestionarios: contenido, público objetivo, seguridad de los datos, anuncios
- [ ] **Pruebas → Prueba interna** → crear versión → subir el AAB → testers (correos)
- [ ] Compartir el enlace de prueba e instalar desde Play en un teléfono real

## Para producción (fuera del alcance del curso)
- [ ] Cuentas personales nuevas: prueba cerrada con ≥12 testers durante 14 días
      (confirmar la regla vigente en la ayuda de Play Console)
- [ ] Revisión de Google (puede tardar días)

## iOS (proceso, sin Mac)
- [ ] Apple Developer Program (USD 99/año)
- [ ] Codemagic o GitHub Actions con runner macOS: `flutter build ipa`
- [ ] Certificado de distribución + provisioning profile (Codemagic los puede administrar)
- [ ] Subir a App Store Connect → TestFlight
