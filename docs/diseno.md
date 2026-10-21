# Sistema de diseño de Inkash D (S17-01)

Un sistema de diseño es un conjunto pequeño de **decisiones con nombre** que todas las
pantallas reutilizan. Vive en `lib/theme.dart` (tokens + tema) y `lib/widgets/ui/`
(componentes).

## Tokens

| Token | Valores | Regla |
|---|---|---|
| Colores | `kFondo`, `kSuperficie`, `kBorde`, `kTexto`, `kMuted`, `kLima`, `kIconoFondo`, `kPeligro` | Lima = acción principal o algo bueno; rojo = error, exceso o borrar |
| `Spacing` | xs 4 · s 8 · m 12 · l 16 · xl 24 · xxl 32 | Nada de 10, 14 o 22 sueltos |
| `Corners` | control 12 · card 20 · sheet 28 | Jerarquía: lo grande se redondea más. (No se llama `Radius`: esa clase ya existe en Flutter.) |
| Tipografía | Space Grotesk (OFL, en `assets/fonts`) con números tabulares (`kTabularFigures`) | Una familia; cada tamaño tiene un rol en `TextTheme` |

| Estilo | Uso |
|---|---|
| `displayLarge` 52 | La cifra principal del Inicio |
| `headlineSmall` 26 | Título de pestaña |
| `titleLarge` 20 | Títulos de sección y de hojas |
| `titleMedium` 16 | Filas, saludo |
| `bodySmall` 12 (secundario) | Contexto, ayudas, subtítulos |

El tema centraliza campos (rellenos, borde lima al enfocar), `FilledButton` (alto 52),
`TextButton`, `SegmentedButton`, chips, hojas inferiores (asa, esquina 28, ancho máximo
640), barra inferior (etiquetas en 11 para que "Presupuesto" quepa), `ListTile`
(título/subtítulo), snackbars flotantes y `AppBar` alineado a la izquierda.

## Componentes (`lib/widgets/ui/`)

| Componente | Para qué |
|---|---|
| `PageHeader` | Título + contexto + acción de cada pestaña |
| `Section` | Grupo de filas sobre una superficie (Ajustes, Cuentas, Categorías, Metas, Presupuesto) |
| `EmptyState` | Sin datos = invitación con una acción |
| `FormSheet` + `showFormSheet` | Hojas inferiores con formulario (título, márgenes, teclado) |
| `SummaryCard` | Tarjetas del Inicio (Cuentas, Metas) |
| `MoneyText` | Dinero con números tabulares; signo escrito y, si se pide, color por signo |

## Reglas de escritura
- Frases con minúscula después de la primera palabra, sin MAYÚSCULAS sostenidas
  ("Te quedan este mes", no "TE QUEDAN DISPONIBLES").
- Pasarse del límite se dice con palabras y en rojo: "Te pasaste por Q100.00",
  no "−Q100.00".
- El signo de un monto siempre se escribe; el color solo lo refuerza.
- Los botones dicen lo que pasa: "Guardar cambios", "Crear cuenta", "Registrar movimiento".
- Un vacío o un error siempre dice qué hacer después.

## Cómo se revisó
Además de las pruebas, cada pantalla se dibujó a PNG con una prueba de golden
**temporal** (fuentes cargadas con `FontLoader`, incluidos los iconos de Material) y se
revisó a ojo. Así se encontraron el texto secundario pintado de blanco (`apply()` del
`TextTheme`), la sombra negra de la barra inferior y el aro negro del botón flotante.
Esa prueba y sus PNG **no** se versionan.
