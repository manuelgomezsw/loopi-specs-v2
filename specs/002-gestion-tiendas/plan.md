# Plan de Implementación: Gestión de Tiendas

**Branch**: `002-gestion-tiendas` | **Fecha**: 2026-05-23 | **Spec**: [spec.md](./spec.md)
**Entrada**: Especificación de feature desde `/specs/002-gestion-tiendas/spec.md`

## Resumen

Implementación del módulo de Gestión de Tiendas para Loopi v2. Permite al `admin`
crear, editar, inactivar y reactivar puntos de venta físicos con trazabilidad de auditoría
completa. Es la feature fundacional de la arquitectura multi-tienda: sin al menos una tienda
activa, ningún módulo operacional puede funcionar.

Enfoque técnico: API REST en Go con MySQL (tabla `tiendas`), migración versionada,
validación de unicidad case-insensitive a nivel de BD (collation), RBAC estricto solo para
`admin`, e interfaz Angular con listado filtrable por estado y formulario de creación/edición.

## Contexto Técnico

**Lenguaje/Versión Backend**: Go 1.22+
**Lenguaje/Versión Frontend**: TypeScript 5.x, Angular (última versión estable)
**Dependencias Principales Backend**: chi (router HTTP), golang-migrate (migraciones MySQL),
OpenTelemetry (trazas y métricas), sqlx (query builder), golang-jwt/jwt/v5 (middleware JWT)
**Dependencias Principales Frontend**: Angular Standalone Components, Signals, Tailwind CSS v4
**Almacenamiento**: MySQL 8.0+ en GCP Cloud SQL — tabla `tiendas` (nueva, sin dependencias
de datos previos; sí depende de `usuarios` para FK de auditoría de `001-autenticacion`)
**Testing Backend**: `go test` + testify/assert; sqlmock (database/sql mock) para mocks de BD
**Testing Frontend**: Karma/Jasmine (unitarios por componente)
**Plataforma Objetivo**: GCP Cloud Run (backend) + Firebase Hosting (frontend)
**Tipo de Proyecto**: Servicio web — API REST + SPA Angular
**Objetivos de Rendimiento**: Operaciones CRUD de admin < 500 ms p95; listado completo < 200 ms p95
**Restricciones**: Paginación server-side obligatoria (constitución). Sin DELETE físico.
Unicidad de nombre con `utf8mb4_unicode_ci` (collation). Campos de auditoría en toda operación.
`codigo` inmutable tras creación.
**Escala/Alcance**: 10–50 tiendas por instalación. Feature de admin exclusiva; baja concurrencia.

## Verificación de Constitución

*GATE: Debe pasar antes de la investigación de Fase 0. Re-verificado tras el diseño de Fase 1.*

| Principio | Estado | Evidencia |
|-----------|--------|-----------|
| **I. Spec-First** | ✅ PASA | `spec.md` con clarificaciones mergeadas al PR #33 antes del plan |
| **II. Multi-Tienda** | ✅ PASA | Feature que define la entidad `tiendas`; toda operación futura lleva `tienda_id` explícito |
| **III. RBAC** | ✅ PASA | Solo `admin` gestiona tiendas (RF-TDA-01.1, 02.1, 03.1). Denegado para `lider_tienda` y `barista` |
| **IV. Trazabilidad** | ✅ PASA | RF-TDA-06: `creado_por`, `creado_en`, `actualizado_por`, `actualizado_en` en toda operación |
| **V. Prevención de Pérdidas** | ✅ PASA | RF-TDA-03.5: solo inactivación, sin borrado físico. Historial siempre accesible para el admin |
| **VI. Observabilidad** | ✅ PASA | Logs estructurados JSON con `user_id`, `rol`, `tienda_id`, `operacion` en todos los endpoints |

**Resultado**: Sin violaciones. No se requiere Registro de Complejidad.

## Estructura del Proyecto

### Documentación (esta feature)

```text
specs/002-gestion-tiendas/
├── plan.md              ← este archivo
├── research.md          ← Fase 0
├── data-model.md        ← Fase 1
├── quickstart.md        ← Fase 1
├── contracts/
│   └── api-tiendas.md   ← Fase 1
└── tasks.md             ← Fase 2 (/speckit-tasks — NO creado aquí)
```

### Código Fuente

**Backend** (`loopi-api-v2/`):

```text
loopi-api-v2/
├── cmd/
│   └── api/
│       └── main.go                        # Bootstrap: router, middleware, inyección deps
├── internal/
│   ├── tiendas/
│   │   ├── model.go                       # Structs Tienda, TiendaRequest, TiendaResponse
│   │   ├── repository.go                  # Queries SQL (crear, editar, listar, buscar por id/codigo)
│   │   ├── service.go                     # Lógica de negocio + validaciones de unicidad
│   │   └── handler.go                     # HTTP handlers chi + logging + respuestas JSON
│   └── middleware/
│       └── auth.go                        # Validación JWT + extracción rol/user_id
├── migrations/
│   ├── 002_tiendas.up.sql                 # Crear tabla tiendas
│   └── 002_tiendas.down.sql               # DROP TABLE tiendas
└── go.mod
```

**Frontend** (`loopi-web-v2/`):

```text
loopi-web-v2/src/app/
└── tiendas/
    ├── tiendas-lista/
    │   ├── tiendas-lista.component.ts     # Lista con filtro activa/inactiva/todas
    │   └── tiendas-lista.component.html
    ├── tienda-form/
    │   ├── tienda-form.component.ts       # Formulario creación/edición
    │   └── tienda-form.component.html
    └── tiendas.service.ts                 # HttpClient wrapper — CRUD + inactivar/reactivar
```

**Decisión de Estructura**: Opción multi-proyecto (API Go + SPA Angular separados).
La feature vive en `internal/tiendas/` en el backend y en `src/app/tiendas/` en el frontend.
Ambos proyectos tienen sus propios repositorios (`loopi-api-v2`, `loopi-web-v2`).
