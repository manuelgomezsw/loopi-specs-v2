# Plan de Implementación: Unidades de Medida y Tabla de Equivalencias

**Branch**: `feature/004-unidades-medida` | **Fecha**: 2026-05-24 | **Spec**: [spec.md](spec.md)
**Entrada**: Especificación de feature desde `/specs/004-unidades-medida/spec.md`

---

## Resumen

Implementar el catálogo de unidades de medida con CRUD completo (crear, editar, inactivar,
listar), conversión automática entre unidades del mismo tipo mediante factor relativo a la
unidad base, y cache Ristretto para lecturas intensivas del catálogo. Solo el administrador
gestiona el catálogo; la conversión es una función pura reutilizada por todos los módulos
consumidores (recetas, compras, recepción). El backend expone 6 endpoints REST; el frontend
Angular provee pantallas de listado, creación y edición.

---

## Contexto Técnico

**Lenguaje/Versión**: Go (Golang), última versión estable del proyecto (ver `go.mod`) —
Angular latest (frontend)

**Dependencias Principales**:

- `go-sql-driver/mysql` — driver MySQL (ya en proyecto desde 001)
- `golang-migrate/migrate` — migraciones BD (ya en proyecto desde 001)
- `dgraph-io/ristretto` — caché en proceso para catálogo (ya referenciado en constitución)
- JWT library — extracción de claims (ya en proyecto desde 001-autenticacion)
- Angular latest + Tailwind CSS v4 — frontend

**Almacenamiento**: MySQL en GCP Cloud SQL — tabla `unidades_medida` + 2 migraciones de seed

**Testing**: `go test ./...` con mocks de BD; `ng test --watch=false` para frontend

**Plataforma Objetivo**: GCP App Engine (backend) + Firebase Hosting (frontend)

**Tipo de Proyecto**: API REST (Go) + SPA (Angular)

**Objetivos de Rendimiento**:

- Conversión automática: < 1 ms (función pura sin I/O, DECIMAL(12,4))
- Listado de catálogo: < 50 ms p95 (servido desde caché Ristretto TTL 5 min)
- Escrituras CRUD: < 200 ms p95 (BD directa + invalidación de caché)

**Restricciones**:

- `factor_conversion DECIMAL(12,4)` — hasta 4 decimales de precisión
- `activo TINYINT(1)` — sin DELETE físico; soft delete por inactivación
- Ristretto: TTL explícito 5 min para todo el catálogo; invalidar en cada write
- RBAC: solo `admin` modifica catálogo; `lider_tienda` y `barista` sin acceso al módulo
- Conversión solo entre unidades del mismo `tipo_medida`
- Inactivación: endpoint separado `/impacto` + confirmación en frontend antes de inactivar
- Bloqueo de transacciones con unidad canónica inactiva: responsabilidad de los módulos
  consumidores (007+, 008+); este módulo solo expone el estado `activo` de la unidad

**Escala/Alcance**: Catálogo compartido por marca; ~13 unidades en seed inicial (bases + estándar
gastronomía), puede crecer a ~50-100 a medida que la operación escale

---

## Verificación de Constitución

*GATE evaluado antes de Fase 0 y re-verificado tras diseño de Fase 1.*

| Principio | Estado | Evidencia |
|-----------|--------|-----------|
| **I. Spec-First** | ✅ PASS | `spec.md` clarificado y en rama `feature/004-unidades-medida` (5 Q&A registradas, 2026-05-24) |
| **II. Multi-Tienda** | ✅ PASS | Unidades de medida son catálogo compartido por marca — sin `tienda_id`. Ningún dato operacional aquí |
| **III. RBAC** | ✅ PASS | Solo `admin` gestiona el catálogo (middleware `solo_admin` en cada endpoint write); backend es la validación vinculante |
| **IV. Trazabilidad** | ✅ PASS | `unidad_origen` y `cantidad_origen` se almacenan en el registro transaccional del módulo consumidor (clarificado en spec RD-01) |
| **V. Prevención de Pérdidas** | ✅ PASS | Confirmación antes de inactivar (endpoint `/impacto`); bloqueo de writes sobre unidad base; validación de tipos incompatibles |
| **VI. Observabilidad** | ✅ PASS | OTel traces en todos los endpoints; logs JSON estructurados con `user_id`, `rol`, operación, `unidad_id` |

**Resultado**: Sin violaciones. No se requiere Registro de Complejidad.

---

## Estructura del Proyecto

### Documentación (esta feature)

```text
specs/004-unidades-medida/
├── spec.md              # Especificación funcional (fuente de verdad, clarificada 2026-05-24)
├── plan.md              # Este archivo
├── research.md          # Decisiones técnicas RD-01 a RD-05
├── data-model.md        # DDL tabla + seed + transiciones de estado
├── quickstart.md        # Guía de arranque y smoke tests
├── contracts/
│   └── api.md           # Contratos REST + modelos TypeScript
└── tasks.md             # Output de /speckit-tasks (pendiente)
```

### Código Fuente — Backend (`loopi-api-v2`)

```text
internal/
  unidades_medida/
    handler.go      # HTTP handlers: listar, detalle, crear, editar, inactivar, impacto
    service.go      # Lógica de negocio: validaciones, protección unidad base, confirmación
    repository.go   # Queries MySQL: CRUD + filtros por tipo/activo + paginación
    model.go        # Structs: UnidadMedida, CrearUMRequest, EditarUMRequest, ImpactoResponse
  conversion/
    conversion.go   # Función pura: Convertir(cantidad float64, desde, hacia *UnidadMedida)
    conversion_test.go

db/migrations/
  NNNN_crear_tabla_unidades_medida.up.sql
  NNNN_crear_tabla_unidades_medida.down.sql
  NNNN+1_seed_unidades_medida.up.sql
  NNNN+1_seed_unidades_medida.down.sql

middleware/
  autenticacion.go  (ya existe desde 001-autenticacion)
  solo_admin.go     (ya existe desde 003-gestion-empleados)
```

### Código Fuente — Frontend (`loopi-web-v2`)

```text
src/app/features/unidades-medida/
  unidades-medida.routes.ts                             # Rutas lazy-loaded
  pages/
    lista-unidades/
      lista-unidades.component.ts                       # Listado con filtros por tipo
      lista-unidades.component.html
    formulario-unidad/
      formulario-unidad.component.ts                    # Modo crear + editar
      formulario-unidad.component.html
    detalle-unidad/
      detalle-unidad.component.ts                       # Vista de detalle + items que la usan
      detalle-unidad.component.html
  services/
    unidades-medida.service.ts                          # HTTP client → /api/v1/unidades_medida
  models/
    unidad-medida.model.ts                              # Interfaces TypeScript (ver contracts/api.md)
```

**Decisión de Estructura**: Backend modular en `internal/unidades_medida/` + paquete compartido
`internal/conversion/` para la función pura de conversión. Frontend feature-based en
`src/app/features/`. Patrón consistente con 001, 002 y 003.

---

## Artefactos Generados

| Artefacto | Ruta | Estado |
|-----------|------|--------|
| Spec | `specs/004-unidades-medida/spec.md` | ✅ Completo (clarificado 2026-05-24, 5 Q&A) |
| Plan | `specs/004-unidades-medida/plan.md` | ✅ Este archivo |
| Research | `specs/004-unidades-medida/research.md` | ✅ Completo (5 decisiones) |
| Data Model | `specs/004-unidades-medida/data-model.md` | ✅ Completo (1 tabla + 2 migraciones seed) |
| Contratos API | `specs/004-unidades-medida/contracts/api.md` | ✅ Completo (6 endpoints) |
| Quickstart | `specs/004-unidades-medida/quickstart.md` | ✅ Completo |
| Tasks | `specs/004-unidades-medida/tasks.md` | ⏳ Pendiente (`/speckit-tasks`) |
