# Plan de Implementación: Gestión de Empleados

**Branch**: `003-gestion-empleados` | **Fecha**: 2026-05-24 | **Spec**: [spec.md](spec.md)
**Entrada**: Especificación de feature desde `/specs/003-gestion-empleados/spec.md`

---

## Resumen

Implementar el CRUD completo de empleados (crear, editar, activar/inactivar, reset de contraseña,
listar con búsqueda y paginación), protegido exclusivamente para el rol `admin`, con audit log
inmutable de cada operación y hash `bcrypt` cost-12 para contraseñas. El backend expone
6 endpoints REST; el frontend Angular provee pantallas de listado, creación y edición.

---

## Contexto Técnico

**Lenguaje/Versión**: Go (Golang), última versión estable del proyecto (ver `go.mod`)
**Dependencias Principales**:

- `golang.org/x/crypto/bcrypt` — hash de contraseñas (cost 12 prod / cost 4 tests)
- `go-sql-driver/mysql` — driver MySQL (ya en proyecto)
- `golang-migrate/migrate` — migraciones BD (ya en proyecto)
- JWT library — extracción de claims (ya en proyecto desde 001-autenticacion)
- Angular latest + Tailwind CSS v4 — frontend

**Almacenamiento**: MySQL en GCP Cloud SQL — tablas `empleados` + `log_auditoria_empleados`
**Testing**: `go test ./...` con mocks de BD; `ng test --watch=false` para frontend
**Plataforma Objetivo**: GCP Cloud Run (backend) + Firebase Hosting (frontend)
**Tipo de Proyecto**: API REST (Go) + SPA (Angular)
**Objetivos de Rendimiento**: Creación de empleado completa en <3 min (UX admin). Latencia de
API REST no definida en spec — usar target sistémico del proyecto como referencia.
**Restricciones**: Paginación siempre server-side; sin DELETE físico; bcrypt cost 12; RBAC en cada endpoint
**Escala/Alcance**: Multi-tienda; decenas de empleados por tienda; volumen bajo en escrituras

---

## Verificación de Constitución

*GATE evaluado antes de Fase 0 y re-verificado tras diseño de Fase 1.*

| Principio | Estado | Evidencia |
|-----------|--------|-----------|
| **I. Spec-First** | ✅ PASS | `spec.md` aprobado y mergeado a `develop` (PR #36) |
| **II. Multi-Tienda** | ✅ PASS | `tienda_id` FK explícita en `empleados`; admins sin tienda fija; empleados operativos aislados a su tienda |
| **III. RBAC** | ✅ PASS | Solo `admin` accede a todos los endpoints; middleware `solo_admin` en cada ruta; validación en backend es vinculante |
| **IV. Trazabilidad** | ✅ PASS | `log_auditoria_empleados` inmutable cubre CREAR, EDITAR, INACTIVAR, REACTIVAR, RESET_CONTRASENA |
| **V. Prevención de Pérdidas** | ✅ PASS | Audit log visible para admin; RF-EMP-03.5 impide lockout de último admin; sin edición silenciosa |
| **VI. Observabilidad** | ✅ PASS | Logs JSON estructurados con `user_id`, `rol`, `tienda_id`, timestamp, operación; audit log como trazabilidad operacional |

**Resultado**: Sin violaciones. No se requiere Registro de Complejidad.

---

## Estructura del Proyecto

### Documentación (esta feature)

```text
specs/003-gestion-empleados/
├── spec.md              # Especificación funcional (fuente de verdad)
├── plan.md              # Este archivo
├── research.md          # Decisiones técnicas RD-01 a RD-07
├── data-model.md        # DDL tablas + diagrama de relaciones
├── quickstart.md        # Guía de arranque y smoke tests
├── contracts/
│   └── api.md           # Contratos REST + modelos TypeScript
└── tasks.md             # Output de /speckit-tasks (pendiente)
```

### Código Fuente — Backend (`loopi-api-v2`)

```text
internal/
  empleados/
    handler.go            # HTTP handlers: crear, listar, detalle, editar, estado, contrasena
    service.go            # Lógica de negocio: validaciones, protección último admin, audit
    repository.go         # Queries MySQL: CRUD + búsqueda ILIKE + paginación
    model.go              # Structs Go: Empleado, CrearEmpleadoRequest, ListarEmpleadosParams
  auditoria/
    empleados_log.go      # Helper: registrar entrada en log_auditoria_empleados
  config/
    hash.go               # Constantes: BcryptCostProd=12, BcryptCostTests=4

db/migrations/
  NNNN_crear_tabla_empleados.up.sql
  NNNN_crear_tabla_empleados.down.sql
  NNNN+1_crear_tabla_log_auditoria_empleados.up.sql
  NNNN+1_crear_tabla_log_auditoria_empleados.down.sql

middleware/
  solo_admin.go           # Middleware RBAC: valida rol=admin en JWT claims
  (autenticacion.go ya existe desde 001-autenticacion)
```

### Código Fuente — Frontend (`loopi-web-v2`)

```text
src/app/features/empleados/
  empleados.routes.ts                         # Rutas lazy-loaded
  pages/
    lista-empleados/
      lista-empleados.component.ts
      lista-empleados.component.html
    formulario-empleado/
      formulario-empleado.component.ts        # Modo crear + editar
      formulario-empleado.component.html
  services/
    empleados.service.ts                      # HTTP client → /api/v1/empleados
  models/
    empleado.model.ts                         # Interfaces TypeScript (ver contracts/api.md)
```

**Decisión de Estructura**: Backend modular por dominio en `internal/`; frontend feature-based
en `src/app/features/`. Patrón ya establecido en 001 y 002.

---

## Artefactos Generados

| Artefacto | Ruta | Estado |
|-----------|------|--------|
| Spec | `specs/003-gestion-empleados/spec.md` | ✅ Completo (clarificado 2026-05-24) |
| Plan | `specs/003-gestion-empleados/plan.md` | ✅ Este archivo |
| Research | `specs/003-gestion-empleados/research.md` | ✅ Completo (7 decisiones) |
| Data Model | `specs/003-gestion-empleados/data-model.md` | ✅ Completo (2 tablas + DDL) |
| Contratos API | `specs/003-gestion-empleados/contracts/api.md` | ✅ Completo (6 endpoints) |
| Quickstart | `specs/003-gestion-empleados/quickstart.md` | ✅ Completo |
| Tasks | `specs/003-gestion-empleados/tasks.md` | ✅ Completo (44 tareas, 7 fases) |
