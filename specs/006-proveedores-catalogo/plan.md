# Implementation Plan: 006-proveedores-catalogo

**Branch**: `feature/006-proveedores-catalogo` | **Date**: 2026-05-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-proveedores-catalogo/spec.md`

---

## Summary

Implementación del módulo **Proveedores del Catálogo** para Loopi v2. Permite al
administrador registrar, editar, inactivar y reactivar proveedores de insumos. El catálogo
es compartido entre todas las tiendas de la marca; solo el `admin` puede gestionarlo.

Enfoque técnico: CRUD full-stack con backend en Go (`internal/proveedores/`) y frontend
Angular standalone. Con caché Ristretto (TTL 24 h, patrón decorador) según tabla normativa
de la constitución. Búsqueda de texto con `LIKE` sobre `razon_social` y `nit`. Filtro de
estado vía `?estado=activo|inactivo|todos`. Paginación server-side. Tabla MySQL `proveedores`
con unique constraint en `nit` y soft delete con flag `activo`.

---

## Technical Context

**Language/Version**: Go 1.22+ (backend) / TypeScript + Angular latest stable (frontend)

**Primary Dependencies**:

- Backend: `go-sql-driver/mysql`, `golang-migrate/migrate`, JWT middleware (ya en proyecto),
  `dgraph-io/ristretto` (ya en proyecto desde 004); paquete compartido `internal/cache/`
  (`EntityCache[T]`, `ReadThrough[T]`) ya existe en `develop` desde 004/005
- Frontend: Angular standalone components, Tailwind CSS v4 (ya en proyecto)

**Storage**: MySQL 8.0 en GCP Cloud SQL — tabla `proveedores` con unique constraint en `nit`

**Testing**:

- Backend: `go test ./internal/proveedores/...` con mocks de repositorio
- Frontend: `ng test --watch=false` por componente standalone

**Target Platform**: GCP App Engine (backend) + Firebase Hosting (frontend)

**Project Type**: Web application full-stack (módulo de administración)

**Performance Goals**: < 500 ms p95 en listado con búsqueda (catálogo de decenas de registros)

**Constraints**: Caché Ristretto TTL 24 h obligatoria (tabla normativa §Caché Transversal);
invalidación selectiva por entidad; paginación server-side obligatoria (constitución)

**Scale/Scope**: Catálogo de decenas a bajos cientos de proveedores por marca; 1 pantalla admin

---

## Constitution Check

*GATE: Evaluado antes de Phase 0 research. Re-evaluado post-Phase 1.*

| Principio | Estado | Verificación |
|-----------|--------|--------------|
| I. Spec-First | ✅ | spec.md con clarificaciones completadas (2026-05-24) |
| II. Multi-Tienda | ✅ | Catálogo compartido por marca; sin `tienda_id` en proveedores |
| III. RBAC | ✅ | Solo `admin` accede; validación en cada endpoint backend |
| IV. Trazabilidad | ✅ | No DELETE físico; flag `activo`; historial de pedidos intacto |
| V. Prevención Pérdidas | ✅ | Solo admin crea/edita/inactiva; NIT único previene duplicados |
| VI. Monitoreo | ✅ | OTel en handler (latencia y errores por endpoint); sección Observabilidad en spec.md |
| UX/UI (§1.4.0) | ✅ | Empty state RF-PROV-04.4; estados carga/error; mobile-first |
| Caché Ristretto (§Stack Técnico) | ✅ | TTL 24 h, patrón decorador `cached_repository.go` (tabla normativa: Proveedores = feature 006) |
| Componentes Transversales (§Diseño de Interfaz) | ✅ | `ListCardComponent`, `FilterBarComponent`, `StatusBadgeComponent`, `DataTableComponent`, `EmptyStateComponent`, `PaginationComponent`, `PageHeaderComponent`, `FormCardComponent`, `DangerZoneComponent`, `FilterStateService`, `FormModeService` |

**Re-evaluación post-Phase 1**: Sin violaciones. No se requiere Complexity Tracking.

---

## Project Structure

### Documentation (this feature)

```text
specs/006-proveedores-catalogo/
├── plan.md              # Este archivo
├── research.md          # Decisiones técnicas (Phase 0)
├── data-model.md        # Modelo de datos MySQL + estructura de directorios (Phase 1)
├── quickstart.md        # Guía de smoke tests y rollback (Phase 1)
├── contracts/
│   └── api.md           # Contratos REST + modelos TypeScript (Phase 1)
└── tasks.md             # Tareas de implementación (Phase 2 — /speckit-tasks)
```

### Source Code (repositorios)

#### Backend (`loopi-api`)

```text
internal/proveedores/
├── model.go                  # Tipos de dominio: Proveedor, requests, responses, filtros
├── repository.go             # Queries SQL: Crear, Listar, ObtenerPorID, Actualizar,
│                             #              CambiarEstado, ExisteNIT
├── cached_repository.go      # Decorador Ristretto TTL 24 h (patrón constitucional)
├── cached_repository_test.go # Tests del decorador ≥ 90% (gate CI)
├── service.go                # Lógica de negocio: validaciones, unicidad de NIT, reglas RF-PROV-*
└── handler.go                # HTTP handlers (6 endpoints) + registro de rutas

db/migrations/
├── NNNN_crear_tabla_proveedores.up.sql
└── NNNN_crear_tabla_proveedores.down.sql
```

#### Frontend (`loopi-web`)

```text
src/app/features/proveedores/
├── components/
│   ├── lista-proveedores/          # Listado con FilterBarComponent (default Estado=Activo) + búsqueda
│   └── form-proveedor/             # Crear + editar (modo vía @Input); en modo editar incluye
│                                    # items_asignados (solo lectura) y Zona de precaución
│                                    # (inactivar/reactivar) — patrón Lista-Formulario, sin vista de detalle separada
├── models/
│   └── proveedor.model.ts          # Interfaces TypeScript (ver contracts/api.md)
├── services/
│   └── proveedores.service.ts      # HTTP client + manejo de errores
└── proveedores.routes.ts           # Lazy routes: /proveedores, /proveedores/:id, /proveedores/nuevo
```

**Componentes Angular transversales obligatorios** (catálogo normativo, spec 000-design-system;
prohibido reimplementar ad-hoc): `ListCardComponent`, `FilterBarComponent`,
`StatusBadgeComponent`, `DataTableComponent`, `EmptyStateComponent`, `PaginationComponent`,
`PageHeaderComponent`, `FormCardComponent`, `DangerZoneComponent`, `FilterStateService`,
`FormModeService`.

**Structure Decision**: Opción web application full-stack. Backend en `loopi-api/internal/`
y frontend en `loopi-web/src/app/features/`. Implementación secuencial: contrato API →
backend → frontend (según constitución §Estructura de Repositorios).

---

## Complexity Tracking

> No aplica — la Constitution Check no reporta violaciones.
