# Plan de Implementación: 005-categorias-catalogo

**Branch**: `feature/005-categorias-catalogo` | **Fecha**: 2026-05-24 | **Spec**: [spec.md](spec.md)

**Input**: Especificación funcional de [specs/005-categorias-catalogo/spec.md](spec.md)

---

## Resumen

Implementar la gestión del catálogo de categorías y subcategorías de Loopi v2. El catálogo es
compartido por marca (sin `tienda_id`) y solo el rol `admin` puede crear, editar, inactivar y
reactivar entidades. Las categorías son el nivel raíz; cada item del catálogo pertenece
obligatoriamente a una subcategoría. El volumen esperado es pequeño (< 20 categorías,
< 100 subcategorías), lo que permite cachear el catálogo completo en Ristretto y renderizar
el listado sin paginación.

---

## Contexto Técnico

**Lenguaje/Versión**: Go (última estable) — backend; Angular (última estable) — frontend

**Dependencias principales**:

- `go-sql-driver/mysql` — Driver MySQL (ya en proyecto desde 001)
- `golang-migrate/migrate` — Migraciones de base de datos (ya en proyecto desde 001)
- `dgraph-io/ristretto` — Caché en proceso para catálogo (ya agregado en 004)
- JWT library — Extracción de `user_id` y `rol` del token (ya en proyecto desde 001)

**Almacenamiento**: MySQL en GCP Cloud SQL

**Testing**: `go test` con mocks para BD (backend); `ng test` unitario por componente (frontend)

**Plataforma objetivo**: GCP App Engine (backend), Firebase Hosting (frontend)

**Tipo de proyecto**: Aplicación web — Angular SPA + API REST Go

**Objetivos de performance**:

- Listado completo del catálogo: < 200 ms p95 (desde caché tras warm-up)
- Sin paginación: el catálogo completo (< 120 registros) se retorna en una sola respuesta

**Restricciones**:

- Sin paginación a nivel de BD: el volumen máximo conocido cabe en memoria sin
  impacto significativo
- Ristretto TTL 5 min; invalidación total en cualquier operación de escritura
- Nombres únicos case-insensitive: garantizado por collation `utf8mb4_unicode_ci`

**Escala/Alcance**: < 20 categorías, < 100 subcategorías por marca

---

## Constitution Check

*GATE: Evaluado antes de Phase 0. Re-evaluado tras Phase 1 diseño.*

| Principio | Estado | Notas |
|-----------|--------|-------|
| I. Spec-First | ✅ PASA | Spec aprobada y clarificada el 2026-05-24 |
| II. Multi-Tienda | ✅ PASA | Catálogo compartido por marca; correcto que no lleve `tienda_id` |
| III. RBAC | ✅ PASA | Solo `admin` escribe; todos los roles autenticados leen |
| IV. Trazabilidad | ✅ PASA | Soft delete `activo TINYINT(1)` + campos `creado_por`/`actualizado_por` |
| V. Prevención pérdidas | ✅ PASA | No aplica a catálogo de configuración |
| VI. Monitoreo | ✅ PASA | Endpoints instrumentados con OTel (trazas + métricas de latencia) |

**Re-check post-diseño**: sin violaciones introducidas en Phase 1.

---

## Estructura del Proyecto

### Documentación (esta feature)

```text
specs/005-categorias-catalogo/
├── plan.md          # Este archivo
├── research.md      # Decisiones técnicas Phase 0
├── data-model.md    # Modelo de datos Phase 1
├── quickstart.md    # Guía de validación Phase 1
├── contracts/
│   └── api.md       # Contratos de API REST Phase 1
└── tasks.md         # Generado por /speckit-tasks (no por /speckit-plan)
```

### Código fuente

#### Backend — `loopi-api-v2`

```text
internal/
└── categorias/
    ├── handler.go        # Handlers HTTP: categorías + subcategorías
    ├── service.go        # Lógica de negocio (cascade, validaciones)
    ├── repository.go     # Consultas MySQL con transacciones
    └── cache.go          # Caché Ristretto (invalidación total en writes)

db/migrations/
├── NNNN_crear_tabla_categorias.up.sql
├── NNNN_crear_tabla_categorias.down.sql
├── NNNN+1_crear_tabla_subcategorias.up.sql
└── NNNN+1_crear_tabla_subcategorias.down.sql
```

#### Frontend — `loopi-web-v2`

```text
src/app/
└── categorias/
    ├── categorias.component.ts        # Componente standalone principal
    ├── categorias.component.html      # Vista del catálogo (árbol cat + subcat)
    ├── categorias.component.spec.ts   # Tests unitarios
    ├── categorias.service.ts          # HTTP client para la API
    ├── categorias.service.spec.ts
    └── categorias.routes.ts           # Lazy-loaded routes
```

**Decisión de estructura**: Opción Web Application (backend Go + frontend Angular separados).
Categorías y subcategorías comparten el mismo paquete Go `internal/categorias/` dado que
el cascade de inactivación requiere transacciones que abarcan ambas tablas. En el frontend,
un único componente standalone gestiona el catálogo completo (listado + formularios inline).

---

## Complexity Tracking

> Sin violaciones a la constitución — tabla vacía.

| Violación | Por qué se necesita | Alternativa más simple descartada porque |
|-----------|---------------------|------------------------------------------|
| — | — | — |
