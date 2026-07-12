# Spec-Kit Finalize Extension (Loopi v2, interna)

Cierra formalmente una feature ya implementada: confirma el estado real de sus tareas,
el estado de sus Pull Requests en todos los repos que toca, obtiene del usuario una
confirmación explícita de cualquier tarea que el agente no pueda verificar por sí mismo,
y deja los repos locales sincronizados con `develop`.

Extensión interna del proyecto Loopi v2 — no publicada en el catálogo comunitario de
spec-kit. Nace de la necesidad observada al cerrar `007-items-catalogo`: el agente
implementó, pero cerrar la feature (estado de PRs multi-repo, verificar tareas que
dependían de una BD real, limpiar branches) se hizo a mano, paso a paso, en la misma
conversación.

## Instalación

Ya instalada localmente en este repo (`.specify/extensions/finalize/`). Para
reinstalar tras cambios:

```bash
specify extension add .specify/extensions/finalize --dev --force
```

## Uso

Después de que `/speckit-implement` terminó y los PRs de la feature están abiertos
(o ya en revisión/CI corriendo):

```text
/speckit-finalize-run 007-items-catalogo
```

Sin argumento, resuelve la feature desde el branch actual.

El comando:

1. Lee `tasks.md` y clasifica las tareas pendientes en "verificables por el agente" y
   "requieren verificación externa" (BD real, staging, smoke test manual, etc.).
2. Consulta el estado de PRs en `loopi-specs-v2`, `loopi-api-v2` y `loopi-web-v2` (los que
   la feature toque).
3. Presenta un plan de cierre y **pregunta explícitamente** por cada tarea de verificación
   externa y por cada PR abierto con CI verde — nunca asume ni infiere.
4. Solo tras confirmación: marca tareas, mergea los PRs aprobados, sincroniza los repos
   locales a `develop`, borra branches ya mergeados, y commitea la actualización de
   `tasks.md` siguiendo el flujo de Gitflow del proyecto (branch propio + PR).
5. Reporta el cierre — o lo que quedó pendiente y por qué.

## Principio de diseño

El agente **nunca** marca como completada una tarea que dependa de algo que
estructuralmente no puede comprobar desde su entorno de sesión (base de datos real,
ambiente de staging, validación manual). Esas tareas siempre requieren una confirmación
explícita del usuario, registrada en `tasks.md` como atestiguada por el usuario, no
verificada por el agente. Del mismo modo, nunca mergea un PR sin aprobación individual
para ese PR específico.

## Changelog

Ver [CHANGELOG.md](CHANGELOG.md).

Versión de la extensión: 1.0.0
