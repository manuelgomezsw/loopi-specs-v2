# Changelog

Todos los cambios notables de esta extensión se documentan en este archivo.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto sigue [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-12

### Added

- Primera versión de la extensión Finalize.
- Comando: `/speckit-finalize-run [feature-id]` — cierre de feature post-implementación.
- Clasificación de tareas pendientes en "verificables por el agente" vs "requieren
  verificación externa" (BD real, staging, smoke test manual, hardware específico).
- Consulta de estado de PRs multi-repo (`loopi-specs-v2`, `loopi-api-v2`, `loopi-web-v2`).
- Plan de cierre con confirmación explícita obligatoria por cada tarea de verificación
  externa y por cada merge de PR — nunca automático, nunca inferido.
- Sincronización de repos locales a `develop` y limpieza de branches ya mergeados.
- Commit de cierre de `tasks.md` siguiendo el flujo de Gitflow del proyecto.
- Hook opcional `after_implement` (sugerido, no automático).

### Requirements

- Spec Kit: >=0.4.0
- `gh` CLI autenticado contra los repos de la organización.
