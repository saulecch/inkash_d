# Política de privacidad de Inkash D

*Última actualización: 12 de noviembre de 2026*

Inkash D es una aplicación de finanzas personales desarrollada como proyecto académico
en la Universidad Mesoamericana (Quetzaltenango, Guatemala).

## Qué datos guarda la app
Todo se guarda **solo en tu dispositivo**, en una base de datos local (SQLite):

- Tus **movimientos** (monto, descripción, categoría, cuenta, fecha y notas).
- Tus **cuentas** y **categorías**.
- Tu **límite mensual** y tus **límites por categoría**.
- Tus **metas de ahorro** y lo que llevas ahorrado.
- Tu **nombre**, si lo escribes en Ajustes (solo se usa para saludarte).
- El **último tipo de cambio** recibido, para mostrarlo sin conexión.

Nada de esto se envía a un servidor del equipo ni a terceros.

## Qué se conecta a internet
- **Tipo de cambio**: la app consulta `https://open.er-api.com/v6/latest/USD` para
  obtener la tasa USD→GTQ. Esa petición **no incluye** ninguno de tus datos; el
  servidor solo recibe la petición técnica (como cualquier sitio web, ve la dirección
  IP de la conexión). Es la única conexión de la app.

## Copias de seguridad del sistema
Si tienes activada la copia de seguridad de tu teléfono (copia automática de Android
en tu cuenta de Google, o iCloud en iPhone), el sistema puede incluir la base de datos
de la app en esa copia. Esa copia la administra Google o Apple con tu cuenta; el equipo
de Inkash D no tiene acceso a ella.

## Qué NO hace
- No pide crear una cuenta ni iniciar sesión.
- No muestra anuncios.
- No usa servicios de analítica, de errores ni de seguimiento.
- No vende ni comparte datos.

## Cómo borrar tus datos
En **Ajustes → Borrar todos mis datos** (borra movimientos, presupuestos, metas,
ajustes y el tipo de cambio guardado; se conservan las categorías y los nombres de
las cuentas, que quedan en saldo 0, y la bienvenida vuelve a aparecer), o
desinstalando la app (borra todo).

## Contacto
(correo del equipo)

---

## Para el formulario "Seguridad de los datos" de Play Console
| Pregunta | Respuesta | Por qué |
|---|---|---|
| ¿La app recopila o comparte datos del usuario? | **No** | Los datos no salen del dispositivo; la consulta del tipo de cambio no lleva datos del usuario |
| ¿Los datos están cifrados en tránsito? | Sí (HTTPS) | La única conexión es HTTPS |
| ¿El usuario puede pedir que se borren? | Sí | Ajustes → Borrar todos mis datos, o desinstalar |

> Si en el futuro se agrega telemetría, un backend o inicio de sesión, **esta tabla
> cambia** y hay que actualizar la política antes de publicar esa versión.
