# Architecture Decision Records (ADR)

Un ADR registra **una** decisión de arquitectura: qué se decidió, por qué y qué
costo aceptamos. Se escribe cuando la decisión se toma, no al final del curso.

Regla: un ADR aceptado no se edita. Si cambiamos de opinión, se escribe uno
nuevo que lo **reemplaza** ("Estado: Reemplazado por ADR-000X").

| # | Decisión | Estado |
|---|---|---|
| [0001](0001-sqlite-centavos-y-occurred-on.md) | SQLite, dinero en centavos enteros y `occurredOn` local de 17 dígitos | Aceptado |
| [0002](0002-riverpod-asyncnotifier.md) | Estado asíncrono con Riverpod `AsyncNotifier` | Aceptado |
| [0003](0003-api-tipo-cambio-con-cache.md) | Datos remotos: red primero, caché local si falla | Aceptado |

## Plantilla

```markdown
# ADR-000X: <decisión en una frase>

- Estado: Propuesto | Aceptado | Reemplazado por ADR-000Y
- Fecha: AAAA-MM-DD
- Autores: @usuario

## Contexto
¿Qué problema o fuerza nos obliga a decidir? Datos, restricciones, usuarios.

## Decisión
Lo que haremos, en voz activa: "Usaremos…".

## Alternativas consideradas
- Opción A — por qué no.
- Opción B — por qué no.

## Consecuencias
- Positivas: …
- Negativas / costo que aceptamos: …
- Cómo sabremos si fue un error: …
```
