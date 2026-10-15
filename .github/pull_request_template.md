<!-- GitHub llena este texto en cada Pull Request nuevo. Borra lo que no aplique. -->

## Qué cambia
<!-- Una o dos frases. El "por qué" importa más que el "qué". -->

Cierra #<!-- número del issue: al hacer merge, GitHub lo cierra solo -->

## Cómo probarlo
1.
2.

## Capturas
<!-- Antes / después si cambia la UI. -->

## Checklist del autor
- [ ] `flutter analyze` sin observaciones y `flutter test` en verde (el CI lo revisa).
- [ ] Probé en un dispositivo o emulador (no en Chrome: sqflite no funciona en Web).
- [ ] Sin SQL ni `http` dentro de widgets (SQL solo en `lib/repositories/`).
- [ ] Dinero en centavos `int`, nunca `double`.
- [ ] `occurredOn` con `encodeOccurredOn` (local, 17 dígitos); `createdAtMs` en epoch ms.
- [ ] Si cambié el esquema: subí la versión de `AppDatabase` y agregué la prueba de migración.
- [ ] Si usé IA: entrada en `docs/bitacora-ia.md` (qué pedí, qué acepté, qué rechacé).
- [ ] Si tomé una decisión de arquitectura: ADR en `docs/adr/`.

## Para quien revisa
<!-- ¿Dónde quieres que miren con más cuidado? -->
