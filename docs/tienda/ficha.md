# Ficha de tienda — Google Play

> Se llena en Play Console → *Main store listing*. Los límites de caracteres son de Play.

| Campo | Límite | Texto |
|---|---|---|
| Nombre de la app | 30 | Inkash D: gastos en quetzales |
| Descripción corta | 80 | Registra gastos e ingresos en Q, con presupuesto, metas y sin crear cuenta. |
| Categoría | — | Finanzas |
| Correo de contacto | — | (correo del equipo) |
| Política de privacidad | URL | Publicar `politica-privacidad.md` (GitHub Pages o el README del repo) |

## Descripción larga (máx. 4000)

Inkash D te ayuda a saber cuánto te queda este mes, en quetzales y sin complicaciones.

• Registra un gasto o ingreso en segundos: monto, categoría y cuenta (efectivo,
  bancos o tarjetas, cada una con su saldo inicial).
• Corrige o borra cualquier movimiento, y crea tus propias categorías.
• Mira cuánto llevas gastado del mes frente a tu límite mensual.
• Revisa tu historial por mes y por categoría; desliza para borrar y deshaz si te equivocaste.
• Define un límite por categoría y entérate cuando te pasas.
• Ahorra para tus metas: aporta, retira y sigue tu avance.
• Consulta el tipo de cambio del dólar, incluso sin conexión (último dato guardado).

Tus datos se quedan en tu teléfono: no hay cuentas, ni anuncios, ni servidores propios.

Proyecto de la carrera de Ingeniería en Sistemas, Universidad Mesoamericana, Quetzaltenango
(sección D del curso de Programación de Dispositivos Móviles).

> Honestidad en la ficha: la app empieza con una sola cuenta ("Efectivo"); bancos y
> tarjetas los crea el usuario en Cuentas. Por eso no se muestran cuentas que la
> app no trae.

## Recursos gráficos
| Recurso | Requisito | Estado |
|---|---|---|
| Ícono | 512×512 PNG, 32 bits | `docs/tienda/icono-512.png` (generado desde `assets/icon/icon.png` con `sips -z 512 512`) |
| Gráfico de funciones | 1024×500 PNG/JPG | Pendiente |
| Capturas de teléfono | 2 a 8; lado corto ≥ 320 px | Inicio, Historial, Presupuesto, Metas (datos de prueba, nunca reales) |

## Cuestionarios obligatorios en Play Console
- **Clasificación de contenido** (IARC): app de utilidades sin contenido sensible.
- **Público objetivo**: 18+ (es una app de finanzas; evita los requisitos de apps para niños).
- **Seguridad de los datos**: ver `politica-privacidad.md`, sección "Para el formulario de Play".
- **Anuncios**: No contiene anuncios.
- **Acceso a la app**: Todas las funciones disponibles sin credenciales.
