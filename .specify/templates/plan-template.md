# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]

**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]

**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]

**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]

**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]

**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]

**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]

**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]

**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

<!--
  INSTRUCCIONES DE LLENADO (Loopi v2):
  1. Determina el tipo de tarea: backend-only, frontend-only, o full-stack.
  2. Marca cada ID como ✅ Cumple / ⚠️ Requiere justificación (ver Complexity Tracking) / N/A.
  3. Los IDs P-* vienen de .specify/memory/constitution.md — SIEMPRE se evalúan.
  4. Los IDs BE-* vienen de .specify/memory/standards/backend.md — solo si hay tarea backend.
  5. Los IDs FE-* vienen de .specify/memory/standards/frontend.md — solo si hay tarea frontend.
  6. No dejes ningún ID de la lista aplicable sin marcar. No inventes IDs nuevos aquí — si una
     regla no tiene ID, es una señal de que constitution.md o standards/*.md necesitan una enmienda.
  7. NO cites la regla de memoria: abre el archivo standards/*.md correspondiente y confirma el
     texto exacto (TTL, nombre de parámetro, threshold, clases CSS) antes de marcar ✅.
-->

**Principios (siempre)** — fuente: `constitution.md`

| ID | Principio | Estado | Nota |
|----|-----------|--------|------|
| P-I | Spec-First | | |
| P-II | Arquitectura Multi-Tienda | | |
| P-III | RBAC | | |
| P-IV | Trazabilidad de Inventario | | |
| P-V | Prevención de Pérdidas | | |
| P-VI | Monitoreo Preventivo | | |

**Backend** (solo si la feature toca `loopi-api-v2`) — fuente: `standards/backend.md`

| ID | Regla | Estado | Nota |
|----|-------|--------|------|
| BE-ARCH-01 | Separación de capas Handler/Service/Repository | | |
| BE-CACHE-01 | Patrón decorador Ristretto (si la entidad es catálogo) | | |
| BE-TEST-01 | Técnica de test por capa + thresholds de cobertura | | |
| BE-API-01 | Convenciones REST (`?estado`, formato de error, códigos HTTP) | | |
| BE-DATA-01 | Convenciones de datos (PKs, timestamps, soft delete, nomenclatura) | | |
| BE-JOBS-01 | Patrón de jobs programados (si aplica) | | |
| BE-OBS-01 | Nomenclatura de métricas y logs | | |

**Frontend** (solo si la feature toca `loopi-web-v2`) — fuente: `standards/frontend.md`

| ID | Regla | Estado | Nota |
|----|-------|--------|------|
| FE-COMP-01 | Usa componentes transversales del catálogo (no reimplementa) | | |
| FE-LIST-01 / FE-FORMSURF-01 | Jerarquía visual de 3 capas (listado / formulario) | | |
| FE-FILTER-01 | Filtros con `FilterBarComponent`, default Estado=Activo | | |
| FE-LISTFORM-01 | Patrón lista clickeable → formulario, zona de precaución | | |
| FE-A11Y-01 | Accesibilidad WCAG 2.1 AA | | |
| FE-RESP-01 | Responsive mobile-first | | |

**Ambientes / CI** — fuente: `standards/environments-ci.md`

| ID | Regla | Estado | Nota |
|----|-------|--------|------|
| CI-01 | Gitflow (branch correcto para esta feature) | | |

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

<!--
  NOTA PARA PROYECTOS GO (loopi-api):
  Cuando el árbol de archivos lista los archivos del dominio (handler.go, service.go,
  repository.go), documentar la responsabilidad de CADA archivo siguiendo la separación
  de capas de standards/backend.md#BE-ARCH-01:

  - handler.go   → HTTP: parsear request, llamar service, escribir response. Sin SQL.
  - service.go   → Lógica de negocio. Sin SQL ni dependencia a *sql.DB.
  - repository.go → TODO el SQL del dominio, incluyendo consultas a tablas de otros
                    dominios cuando sean necesarias para la lógica de autenticación,
                    permisos o datos de contexto. Si el service necesita un dato de BD,
                    la solución es agregar el método al repositorio, no agregar un
                    dbQuerier al service.

  Ejemplo correcto de descripción en el árbol:
    repository.go  # Cloud SQL: usuarios (buscar, actualizar intentos), tokens_revocados (insert/select)
  Ejemplo incorrecto (genera SQL en el service):
    repository.go  # Cloud SQL: tokens_revocados INSERT/SELECT   ← scope demasiado estrecho
-->


## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
