# Firma de la app (Android)

## Dos llaves, dos dueños
| Llave | Quién la guarda | Para qué |
|---|---|---|
| **Upload key** (la nuestra) | El equipo: `.jks` fuera del repo + respaldo | Firmar cada AAB que subimos a Play |
| **App signing key** | Google (Play App Signing) | Firmar lo que llega a los teléfonos |

Si perdemos la *upload key*, Play permite resetearla con un trámite de soporte.
Antes de Play App Signing, perder la llave era perder la app para siempre.

## Pasos (una vez por equipo)
1. Generar el keystore (fuera del repo):
   ```bash
   keytool -genkey -v -keystore ~/inkash-d-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copiar `android/key.properties.example` como `android/key.properties` y llenarlo.
3. Verificar que Git lo ignora: `git status` **no** debe mostrar `key.properties` ni el `.jks`
   (`android/.gitignore` ya ignora `key.properties`, `*.jks` y `*.keystore`).
4. Compilar: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.
5. Comprobar la firma:
   ```bash
   keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
   ```
   Debe mostrar **tu** certificado (el CN que pusiste), no `CN=Android Debug`.

Sin `key.properties` el release se firma con la llave de **debug** (así
`flutter run --release` funciona en cualquier compu), pero ese AAB Play lo rechaza.

## Errores típicos
| Síntoma | Causa |
|---|---|
| Play: *"You uploaded an APK or Android App Bundle that was signed in debug mode"* | No existía `key.properties` al compilar |
| Play: *"Version code 1 has already been used"* | No subiste el `+N` de `version` en `pubspec.yaml` |
| `Keystore was tampered with, or password was incorrect` | Contraseña equivocada en `key.properties` |
| Alguien subió el `.jks` a GitHub | **Rotar la llave** (Play Console → App integrity) y borrarlo del historial |

## En CI (S17-06): release con un tag
1. Cargar en *Settings → Secrets and variables → Actions*:
   | Secret | Valor |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | `base64 -i ~/inkash-d-upload.jks \| pbcopy` (macOS) o `base64 -w0 inkash-d-upload.jks` (Linux) |
   | `ANDROID_KEYSTORE_PASSWORD` | contraseña del keystore |
   | `ANDROID_KEY_PASSWORD` | contraseña de la llave |
   | `ANDROID_KEY_ALIAS` | `upload` |
2. Subir `version` en `pubspec.yaml` (p. ej. `0.9.0+2`) por PR.
3. En `main` actualizado: `git tag v0.9.0 && git push origin v0.9.0`.
4. El workflow **Release** (`.github/workflows/release.yml`) verifica que el tag
   coincida con el pubspec, corre las pruebas, compila, **rechaza un AAB firmado con
   debug** y adjunta el AAB a un GitHub Release.

Los secretos no aparecen en los logs (GitHub los enmascara) y **no** están disponibles
en PRs que vienen de forks.

> Ojo: los tags `s14-…`/`s17-…` del curso **no** disparan el release; solo `v*`.
