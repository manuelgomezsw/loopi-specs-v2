# Plan de Implementación: 007-items-catalogo

**Branch**: `feature/007-items-catalogo` | **Fecha**: 2026-05-24 | **Spec**: [spec.md](spec.md)

**Input**: Especificación funcional de [specs/007-items-catalogo/spec.md](spec.md)

---

## Resumen

Implementar la gestión del catálogo de items de Loopi v2. Los items son la entidad central
del sistema y el prerequisito operativo de toda la Ola 3 en adelante (inventarios, recetas,
pedidos). El catálogo es compartido por marca (sin `tienda_id` en la tabla `items`), solo el
rol `admin` puede crear, editar, inactivar y reactivar items. El costo unitario tiene un valor
por defecto global, pero cada tienda puede sobreescribirlo mediante la entidad
`items_costos_tienda` (historial append-only). El listado requiere paginación del lado del
servidor dado que el catálogo es ilimitado por diseño. Se cachean en Ristretto las consultas
de alta frecuencia: items por ID, por código y por frecuencia de inventario.

---

## Contexto Técnico

**Lenguaje/Versión**: Go (última estable) — backend; Angular (última estable) — frontend

**Dependencias principales**:

- `go-sql-driver/mysql` — Driver MySQL (ya en proyecto desde 001)
- `golang-migrate/migrate` — Migraciones de base de datos (ya en proyecto desde 001)
- `dgraph-io/ristretto` — Caché en proceso para catálogo (ya en `go.mod` desde 004)
- JWT library — Extracción de `user_id` y `rol` del token (ya en proyecto desde 001)

**Almacenamiento**: MySQL en GCP Cloud SQL

**Testing**: `go test` con mocks para BD (backend); `ng test` unitario por componente (frontend)

**Plataforma objetivo**: GCP App Engine (backend), Firebase Hosting (frontend)

**Tipo de proyecto**: Aplicación web — Angular SPA + API REST Go

**Objetivos de performance**:

- Listado paginado del catálogo: < 300 ms p95 (con filtros, desde BD con índices)
- Lookup por ID / código desde caché: < 5 ms p95 (Ristretto, post warm-up)
- Consulta de items por frecuencia (para inventarios): < 5 ms p95 (desde caché)

**Restricciones**:

- Paginación del lado del servidor (LIMIT/OFFSET), página por defecto 50, máximo 200
- Ristretto TTL 5 min; invalidación total del módulo en cualquier operación de escritura
- El catálogo de items no se elimina físicamente; soft delete con flag `activo`
- No existe importación masiva de items en esta versión (queda diferida)

**Escala/Alcance**: catálogo ilimitado por diseño; cientos de items esperados a mediano plazo

---

## Constitution Check

*GATE: Evaluado antes de Phase 0. Re-evaluado tras Phase 1 diseño.*

| Principio | Estado | Notas |
|-----------|--------|-------|
| I. Spec-First | ✅ PASA | Spec aprobada y clarificada el 2026-05-24 |
| II. Multi-Tienda | ✅ PASA | Catálogo compartido (items sin `tienda_id`); `items_costos_tienda` lleva `tienda_id` explícito para datos de costo por tienda |
| III. RBAC | ✅ PASA | Solo `admin` escribe; todos los roles autenticados leen el catálogo, **excepto** el historial de costos por tienda (lectura y escritura exclusivas de `admin`, matriz `§2.5`); validación en backend |
| IV. Trazabilidad | ✅ PASA | Soft delete `activo TINYINT(1)` + `creado_por`/`actualizado_por`; `items_costos_tienda` es append-only para trazabilidad de precios |
| V. Prevención pérdidas | ✅ PASA | Código inmutable una vez en uso; no eliminación física; costo por tienda es historial sin posibilidad de borrado |
| VI. Monitoreo | ✅ PASA | Endpoints instrumentados con OTel (trazas + métricas de latencia y tasa de errores); ver `spec.md §Observabilidad` |

**Re-check post-diseño**: sin violaciones introducidas en Phase 1.

---

## Estructura del Proyecto

### Documentación (esta feature)

```text
specs/007-items-catalogo/
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
└── items/
    ├── models.go         # Structs Item, ItemCostoTienda y DTOs de request/response
    ├── handler.go        # Handlers HTTP: items + costos por tienda
    ├── service.go        # Lógica de negocio (estaEnUso, validaciones, historial costos)
    ├── repository.go     # Consultas MySQL con transacciones
    └── cache.go          # Caché Ristretto (por ID, por código, por frecuencia)

db/migrations/
├── NNNN_crear_tabla_items.up.sql
├── NNNN_crear_tabla_items.down.sql
├── NNNN+1_crear_tabla_items_costos_tienda.up.sql
└── NNNN+1_crear_tabla_items_costos_tienda.down.sql
```

#### Frontend — `loopi-web-v2`

```text
src/app/
└── items/
    ├── items.component.ts              # Componente standalone — listado paginado con filtros
    ├── items.component.html
    ├── items.component.spec.ts
    ├── item-form.component.ts          # Formulario crear / editar (reutilizable)
    ├── item-form.component.html
    ├── item-form.component.spec.ts
    ├── item-detalle.component.ts       # Vista detalle + gestión de costos por tienda
    ├── item-detalle.component.html
    ├── item-detalle.component.spec.ts
    ├── items.service.ts                # HTTP client para la API de items
    ├── items.service.spec.ts
    └── items.routes.ts                 # Lazy-loaded routes del módulo
```

**Decisión de estructura**: Opción Web Application (backend Go + frontend Angular separados).
El paquete Go `internal/items/` agrupa toda la lógica del módulo en cinco archivos cohesivos.
En el frontend, tres componentes standalone cubren las tres vistas distintas: listado,
formulario (crear/editar) y detalle con gestión de costos por tienda.

---

## Complexity Tracking

> Sin violaciones a la constitución — tabla vacía.

| Violación | Por qué se necesita | Alternativa más simple descartada porque |
|-----------|---------------------|------------------------------------------|
| — | — | — |
