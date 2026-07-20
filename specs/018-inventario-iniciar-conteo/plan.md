# Implementation Plan: 018 — Iniciar Conteo de Inventario

**Branch**: `feature/018-inventario-iniciar-conteo` | **Date**: 2026-07-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/018-inventario-iniciar-conteo/spec.md`

**Nature**: Migración de código existente desde monolito (009) hacia nueva arquitectura de sub-dominios (BE-ARCH-02).

## Summary

Feature 018 captura la capacidad de iniciar un conteo físico de inventario en una tienda. El lider, barista o admin inician el proceso; el sistema sugiere el tipo de conteo (diario/semanal/mensual/inicial) automáticamente basándose en si es el primer conteo de la tienda, determina el horario (apertura/mediodía/cierre para diarios), carga la lista de items a contar según tipo, y valida que no exista conteo duplicado en esa tienda/tipo/horario/fecha.

**Enfoque técnico**: Migración ordenada del código ya implementado y funcional en 009 hacia la estructura de sub-dominios `internal/inventarios/iniciar/` (backend) e `iniciar-conteo.component.ts` (frontend), sin cambiar comportamiento observable. Base de arquitectura: enmienda BE-ARCH-02 que habilita sub-dominios dentro de un dominio grande.

## Technical Context

**Language/Version**: Go 1.26.5 (backend) + Angular 18 (frontend)

**Primary Dependencies**:

- Backend: `chi` (router HTTP), `database/sql` (MySQL driver), OpenTelemetry SDK, `go-sqlmock` (testing)
- Frontend: Angular Material, RxJS, TypeScript, Tailwind CSS v4

**Storage**: MySQL 8.0+ (GCP Cloud SQL) — tablas `inventarios`, `detalle_inventario`, `stock_actual`, `items`, `tiendas`, `empleados`

**Testing**:

- Backend: `go test` + mocks (interface-based), `go-sqlmock` para BD, `httptest` para HTTP
- Frontend: `ng test` (Jasmine), `ng e2e` (Cypress, si aplica)

**Target Platform**:

- Backend: GCP App Engine (Linux)
- Frontend: Firebase Hosting (SPA, GCP)

**Project Type**: Full-stack web service (SPA + REST API)

**Performance Goals**: Inicio de conteo < 500ms p95 (desde POST `/inventarios` hasta respuesta completa)

**Constraints**:

- Latencia de lectura desde `stock_actual` < 100ms p95
- Validación de duplicados < 50ms p95
- Capacidad: 20 tiendas × 50 items/conteo = 1000 items/día en peak

**Scale/Scope**: 20 tiendas operativas, ~500 items en catálogo compartido, ~200 empleados

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Principios (siempre)** — fuente: `constitution.md`

| ID | Principio | Estado | Nota |
|----|-----------|--------|------|
| P-I | Spec-First | ✅ | Spec 018 aprobada, source of truth para implementación |
| P-II | Arquitectura Multi-Tienda | ✅ | Todas las operaciones requieren `tienda_id` explícito; validación de permisos por tienda |
| P-III | RBAC | ✅ | Endpoint valida rol (admin/lider_tienda/barista); solo lider_tienda/barista pueden iniciar en su tienda |
| P-IV | Trazabilidad de Inventario | ✅ | Inventario registra `responsable_id`, `iniciado_en`; historial en `detalle_inventario` |
| P-V | Prevención de Pérdidas | ✅ | Bloqueo de movimientos simultáneos (RF-INV-05, `core/repository.go`) |
| P-VI | Monitoreo Preventivo | ✅ | Sección Observabilidad con spans (inventario.iniciar.crear, inventario.iniciar.determinar_tipo) y métricas (latencia, total) |

**Backend** — fuente: `standards/backend.md` v1.1.0

| ID | Regla | Estado | Nota |
|----|-------|--------|------|
| BE-ARCH-01 | Separación de capas Handler/Service/Repository | ✅ | `iniciar/handler.go`, `iniciar/service.go`, `iniciar/repository.go` con responsabilidades exclusivas |
| BE-ARCH-02 | Sub-dominios dentro de dominio grande | ✅ | Feature 018 = sub-dominio `iniciar/` dentro de `internal/inventarios/`, con sus 3 capas propias |
| BE-CACHE-01 | Patrón decorador Ristretto | N/A | Datos operacionales (inventarios, stock_actual) — sin caché (volatilidad alta) |
| BE-TEST-01 | Técnica de test por capa + thresholds | ✅ | service_test.go ≥95%, repository_test.go ≥90% (mock para iniciar, sqlmock para crear) |
| BE-API-01 | Convenciones REST + `?estado` + formato error | ✅ | POST `/api/v1/inventarios`, respuestas 200/201/409/422, formato error estándar |
| BE-DATA-01 | Convenciones: PKs, timestamps, soft delete, nomenclatura | ✅ | PKs BIGINT, `creado_en`/`actualizado_en` DATETIME, tabla `inventarios` (snake_case) |
| BE-JOBS-01 | Patrón de jobs programados | N/A | No hay jobs en esta feature |
| BE-OBS-01 | Nomenclatura OTel: spans + métricas | ✅ | Spans con atributo `resultado`, métricas con etiqueta `tienda_id`, formato según estándar |

**Frontend** — fuente: `standards/frontend.md`

| ID | Regla | Estado | Nota |
|----|-------|--------|------|
| FE-COMP-01 | Usa componentes transversales | ✅ | Usa componentes de FE-COMP-01 si existen; define nuevos en `iniciar-conteo.component` solo si no existe |
| FE-LIST-01 / FE-FORMSURF-01 | 3-layer visual hierarchy | ✅ | `iniciar-conteo.component`: Header (título) → Form (selección tipo, sugerencia horario, botón) → Items (tabla items) |
| FE-FILTER-01 | FilterBarComponent | N/A | No hay filtrado en iniciar (no es un listado) |
| FE-LISTFORM-01 | Patrón lista → formulario | N/A | Iniciar es solo formulario de entrada, no clickeable |
| FE-A11Y-01 | WCAG 2.1 AA | ✅ | Componente cumple etiquetas `aria-*`, contraste, focus visible |
| FE-RESP-01 | Responsive mobile-first | ✅ | Tailwind v4, grid responsive, stack vertical en mobile |

**Ambientes / CI** — fuente: `standards/environments-ci.md`

| ID | Regla | Estado | Nota |
|----|-------|--------|------|
| CI-01 | Gitflow (branch correcto) | ✅ | Branch `feature/018-inventario-iniciar-conteo` desde `develop` |

## Project Structure

### Documentation (this feature)

```text
specs/018-inventario-iniciar-conteo/
├── spec.md              # User stories, requirements, entities, success criteria
├── plan.md              # This file
├── research.md          # Decisions & clarifications (Phase 0)
├── data-model.md        # Entities: Inventario, DetalleInventario (Phase 1)
├── quickstart.md        # Test scenarios & manual verification steps (Phase 1)
├── contracts/           # API contracts if needed (Phase 1)
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code — Backend (`loopi-api-v2`)

**Migración estructura monolítica → sub-dominios (BE-ARCH-02):**

```text
internal/inventarios/
├── core/                          # Métodos compartidos (2+ consumidores reales)
│   ├── models.go                  # Inventario, DetalleInventario (tipos compartidos)
│   └── repository.go              # SnapshotStockActual, GetInventarioDetalle
│
├── iniciar/                       # Feature 018: Iniciar conteo (sub-dominio autónomo)
│   ├── handler.go                 # HTTP: parsear POST /api/v1/inventarios, llamar service
│   ├── service.go                 # Lógica: determinar tipo automático, sugerir horario, validar duplicados
│   ├── repository.go              # Cloud SQL: crear inventario, cargar items, validar tienda/tipo/fecha
│   ├── handler_test.go            # HTTP tests: httptest + mock service
│   ├── service_test.go            # Lógica tests: mock repository, ≥95% cobertura
│   └── repository_test.go         # SQL tests: go-sqlmock, ≥90% cobertura
│
├── realizar/                      # Feature 019 (futura): Registrar valores
│   ├── handler.go                 # HTTP: PUT /api/v1/inventarios/{id}/detalles
│   ├── service.go                 # Lógica: validación valor≥0, recuperación sesión
│   └── repository.go              # Cloud SQL: update detalle_inventario
│
└── ...                            # Otros sub-dominios (020-023)
```

**Responsabilidades por archivo (BE-ARCH-01)**:

- `iniciar/handler.go` → HTTP parsing, status codes, response serialization. Sin lógica.
- `iniciar/service.go` → Lógica de negocio (determinación de tipo, sugerencia, validación). Sin SQL.
- `iniciar/repository.go` → Cloud SQL: `inventarios` (crear, validar duplicados), `items` (cargar por frecuencia), `stock_actual` (lookup), `tiendas` (validación), `empleados` (validación responsable).

### Source Code — Frontend (`loopi-web-v2`)

```text
src/app/inventario/
├── core/
│   ├── inventario-api.service.ts  # HTTP client (migración de inventario.service.ts)
│   └── error-mapper.service.ts    # Mapeo de errores
│
├── iniciar-conteo/                # Feature 018: Formulario de inicio
│   ├── iniciar-conteo.component.ts
│   ├── iniciar-conteo.component.html
│   ├── iniciar-conteo.component.scss
│   ├── iniciar-conteo.component.spec.ts  # Unit + integration tests
│   └── iniciar-conteo.service.ts  # Lógica local del componente
│
├── realizar-conteo/               # Feature 019 (futura)
│   └── ...
│
└── ...
```

**Composición (3-layer visual hierarchy)**:

1. **Header**: Título "Iniciar conteo", información de tienda actual
2. **Form**: Selección tipo (sugerencia automática), horario sugerido, botón "Iniciar"
3. **Items Preview**: Tabla items a contar con valor_esperado (readonly)

## Complexity Tracking

**No violations to Constitution Check detected.** Feature 018 complies fully with P-I through P-VI (principles) and BE-*/FE-* standards. The architectural choice to use sub-domains (BE-ARCH-02) is justified by:

1. **Separation of concerns**: Iniciar, Realizar, Completar, Historial, Editar, Eliminar are 6 independent user stories with separate lifecycle in 009, now getting separate specs (018–023) and separate code paths.
2. **Maintainability**: Each sub-domain is independently testable, reviewable, and deployable.
3. **Strangler fig pattern**: Incremental migration from monolith to sub-domains without breaking existing functionality.
