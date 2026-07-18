# Plan de Implementación: 009-inventario-conteo

**Fecha**: 2026-07-18  
**Branch**: `feature/009-inventario-conteo` → `develop`  
**Estado**: En Ejecución (Fase 2 en corrección)

---

## Visión General

El módulo de inventario proporciona la capacidad de realizar conteos físicos de items en tienda, registrar diferencias entre stock esperado y real, y ajustar automáticamente el inventario. Este plan describe la arquitectura y fases de implementación.

### Arquitectura General

```text
Backend (Go):
  loopi-api-v2/internal/inventarios/
  ├── models.go (Inventario, DetalleInventario DTOs)
  ├── handler.go (8 endpoints REST)
  ├── service.go (orquestación de lógica)
  ├── repository.go (acceso a BD)

Frontend (Angular):
  loopi-web-v2/src/app/inventario/
  ├── inventario.service.ts (HTTP client)
  ├── error-mapper.service.ts (traducción de errores)
  ├── inventario-conteo.component.ts (UI de conteo)
  ├── inventario-historial.component.ts (UI de historial)
  ├── inventario-detalle.component.ts (UI de detalle)

Data (MySQL):
  ├── inventarios (tienda_id, tipo, horario, estado, responsable_id, timestamps)
  ├── detalle_inventario (inventario_id, item_id, valor_sugerido, valor_real, diferencia)
  ├── stock_actual (valor_snapshot para cada item al inicio del conteo)
  ├── stock_movimientos (audit trail de movimientos)
```

---

## Fases de Implementación

### Fase 1: Core API & DB (✅ Completo)

**Propósito**: Infraestructura de base de datos y estructuras Go

- Migrations: tablas inventarios, detalle_inventario, stock_actual, stock_movimientos
- Modelos: Go structs (Inventario, DetalleInventario, request/response DTOs)
- Constantes: enums para tipo, estado, horario
- Handlers: stubs para 8 endpoints
- Repository: stubs con interfaces

**Deliverable**: BD lista, rutas HTTP registradas

---

### Fase 2: Flujo Correcto de Iniciar Conteo (EN CORRECCIÓN — BUG-016)

**Propósito**: Implementar Service.Iniciar() con orden correcto de operaciones

**Problema**: Service.Iniciar() crea inventario ANTES de consultar items → respuesta con 0 items

**Solución Correcta** (5 pasos):

1. **GetItemsActivosPorTipo(tiendaID, tipo)**: Query items WHERE activo=1 AND frecuencia_inventario=tipo
2. **Validar hay items**: Si 0 items, retornar 422 `sin_items_contabilizar`
3. **CreateInventario()**: INSERT en tabla inventarios, estado=en_progreso
4. **GetStockSnapshot(tiendaID, itemIDs)**: Query stock_actual.valor_snapshot para cada item
5. **CreateDetalleInventario()**: INSERT detalle_inventario con valor_sugerido mapeado

**Tareas**:

- Implementar GetItemsActivosPorTipo() (nueva función en repository)
- Implementar GetStockSnapshot() (nueva función en repository)
- Refactorizar Service.Iniciar() en 3 pasos secuenciales
- Tests unitarios e integración para funciones nuevas
- Mapeo de error code `sin_items_contabilizar` → HTTP 422 en handler

**Deliverable**: POST /inventarios retorna 201 con items siempre, o 422 si no hay items

---

### Fase 3: Registrar Valores & Confirmar (Pendiente)

**Propósito**: Permitir al líder ingresar cantidad real de cada item y confirmar conteo

- PATCH /inventarios/{id}/items/{item_id} con autosave
- POST /inventarios/{id}/confirmar con validación
- Manejo de interrupciones (recuperar sesión)
- Cálculo de diferencias en tiempo real

**Deliverable**: Conteo completo de item a item hasta confirmación

---

### Fase 4: Historial & Audit (Pendiente)

**Propósito**: Consultas de inventarios completados para auditoría

- GET /inventarios con paginación, filtros, ordenamiento
- GET /inventarios/{id} detalle completo
- Autorización por rol (admin any tienda, lider_tienda own tienda)

**Deliverable**: Historial auditable con trazabilidad completa

---

### Fase 5: Admin Functions & Blocking (Pendiente)

**Propósito**: Correcciones admin y bloqueo de movimientos durante conteo

- Admin puede modificar valores de conteo completado
- Admin puede eliminar conteo en_progreso
- Bloqueo de compras, mermas, venta batch mientras conteo activo
- Retorno de error 409 `inventario_activo` en operaciones bloqueadas

**Deliverable**: Control administrativo + prevención de inconsistencias

---

## Arquitectura de Servicio: Service.Iniciar()

```go
func (s *Service) Iniciar(ctx, tiendaID, tipo, horario) (*InventarioResp, error) {
  // 1. Validar tipo/horario
  if !ValidarTipo(tipo) { return nil, NewError("tipo_invalido", ...) }
  
  // 2. Consultar items activos para tipo
  itemIDs, err := s.repo.GetItemsActivosPorTipo(ctx, tiendaID, tipo)
  if len(itemIDs) == 0 { return nil, NewError("sin_items_contabilizar", ...) }
  
  // 3. Crear inventario
  inv, err := s.repo.CreateInventario(ctx, &CreateInventarioReq{...})
  
  // 4. Obtener snapshot de stock
  stocks, err := s.repo.GetStockSnapshot(ctx, tiendaID, itemIDs)
  
  // 5. Crear detalles con valor_sugerido mapeado
  err := s.repo.CreateDetalleInventario(ctx, inv.ID, itemIDs, stocks)
  
  // 6. Obtener inventario completo con items
  return s.repo.GetInventarioDetalle(ctx, inv.ID)
}
```

---

## Stack Tecnológico

| Componente | Tecnología | Notas |
|-----------|-----------|-------|
| Backend | Go 1.21 + chi router | API REST, middleware JWT |
| Base de datos | MySQL 8.0 | Transacciones ACID, constraints UNIQUE |
| Frontend | Angular 17 (standalone) | Componentes reactivos, ChangeDetectionStrategy.OnPush |
| HTTP Client | HttpClient Angular | Interceptors para auth |
| UI Components | Transversales (FE-COMP-01) | ListCard, FilterBar, Pagination, FormCard, StatusBadge |

---

## Responsabilidades por Capa

### Handler (loopi-api-v2/internal/inventarios/handler.go)

- Parse JWT token (extraer userID, roleID)
- Parse path parameters ({inventarioID}, {itemID})
- Parse query parameters (tienda_id, tipo, estado, pagina, etc.)
- Validar autorización per RF (admin → any tienda, lider_tienda/barista → own tienda)
- Llamar service.Iniciar() / RegistrarValor() / Confirmar() / Listar() / Buscar()
- Retornar HTTP status codes correctos (200, 201, 204, 400, 403, 404, 409, 422)
- Mapear error codes a status codes

### Service (loopi-api-v2/internal/inventarios/service.go)

- Orquestar lógica de negocio: validar, llamar repository, retornar DTOs
- Verificar permisos (responsable_id match, role checks)
- Calcular diferencias (valor_real - valor_esperado)
- Implementar sugerencias automáticas de tipo/horario

### Repository (loopi-api-v2/internal/inventarios/repository.go)

- Acceso EXCLUSIVO a base de datos
- Operaciones CRUD: CreateInventario, UpdateDetalle, ConfirmarInventario, DeleteInventario, ListInventarios
- Funciones de consulta: GetInventarioDetalle, GetItemsActivosPorTipo, GetStockSnapshot
- Helpers: SnapshotStockActual, RecordMovimiento, CanRecordMovimiento

### Angular Service (loopi-web-v2/src/app/inventario/inventario.service.ts)

- Métodos HTTP para cada endpoint (/sugerencia, POST /inventarios, PATCH /{id}/items/{id}, etc.)
- Tipos TypeScript para respuestas (InventarioResp, ItemDetailResp, ErrorResp)
- Mapeo de errores HTTP a códigos de error del backend

### Angular Components

- **inventario-conteo.component**: Formulario de tipo/horario + lista de items para ingresar valores
- **inventario-historial.component**: Tabla/lista de conteos completados con filtros y paginación
- **inventario-detalle.component**: Vista detallada de un conteo (lectura o admin edit)

---

## Dependencias Externas

| Feature | Módulo | Tipo | Impacto |
|---------|--------|------|---------|
| Autenticación | 001 | Hard | JWT token requerido en todos los endpoints |
| Tiendas | 002 | Hard | Validación tienda_id, RBAC por tienda |
| Items & Catálogo | 007 | Hard | Frecuencia_inventario de items determina conteos |
| Compras | 010/011 | Hard | Stock caja menor se suma en valor_sugerido; bloqueado durante conteo |
| Mermas | 010 | Hard | Mermas se restan en valor_sugerido; bloqueado durante conteo |
| Unidades de Medida | 004 | Soft | Conversión de unidades si movimientos en unidades mixtas |
| Ventas/POS | 012/015 | Hard | Ventas se restan en valor_sugerido; venta batch bloqueado durante conteo |

---

## Convenciones Adoptadas

### Nomenclatura

- **Go structs**: CamelCase (Inventario, DetalleInventario)
- **DB columns**: snake_case_español (tienda_id, valor_sugerido, inventario_activo)
- **Error codes**: snake_case_ingles (sin_items_contabilizar, conteo_bloqueado, items_sin_registrar)
- **Span names**: `inventario.conteos.{operacion}` (inventario.conteos.iniciar, inventario.conteos.registrar)

### REST Conventions

- Base URL: `/api/v1/inventarios`
- Status codes: 200 (OK), 201 (Created), 204 (No Content), 400 (Bad Request), 403 (Forbidden), 404 (Not Found), 409 (Conflict), 422 (Unprocessable Entity)
- Query params: ?tienda_id, ?tipo, ?estado, ?desde, ?hasta, ?pagina, ?por_pagina
- Error format: `{error: string, mensaje: string, campo?: string, detalles?: object}`

### Angular Patterns

- Components: standalone + ChangeDetectionStrategy.OnPush
- Observables: manual unsubscribe via takeUntil(destroy$)
- Forms: FormBuilder + FormGroup + Validators
- Components transversales: ListCard, FilterBar, Pagination, FormCard, StatusBadge

---

## Checkpoints de Validación

| Checkpoint | Condición | Quién | Cuándo |
|-----------|-----------|------|--------|
| BD Ready | Migrations ejecutadas, tablas existentes | DBA/Backend | Después Fase 1 |
| Endpoints Accessible | 8 rutas HTTP registradas y responden | Backend | Después Foundational Phase |
| HU1 Flow | POST /inventarios retorna items, no 0 | Backend + Frontend | Después Fase 2 |
| HU1-3 MVP | Conteo completo: iniciar → registrar → confirmar | Full Stack | Después Fase 3 |
| HU4 Ready | Historial filtra, pagina, detalle muestra | Full Stack | Después Fase 4 |
| Admin Complete | Modificar completado + delete en_progreso | Full Stack | Después Fase 5 |
| Blocking Works | Compras/mermas/venta bloqueados durante conteo | Full Stack | Después Fase 5 |

---

## Observabilidad

### Spans OpenTelemetry

- `inventario.conteos.iniciar` — POST /inventarios (crear nuevo conteo)
- `inventario.conteos.registrar` — PATCH /inventarios/{id}/items/{id} (registrar valor)
- `inventario.conteos.confirmar` — POST /inventarios/{id}/confirmar (confirmar conteo)
- `inventario.conteos.modificar` — PATCH completado (admin only)
- `inventario.conteos.eliminar` — DELETE /inventarios/{id} (admin only)
- `inventario.conteos.listar` — GET /inventarios (historial con filtros)

### Métricas Prometheus

| Métrica | Tipo | Etiquetas | Propósito |
|---------|------|-----------|-----------|
| inventario_iniciar_duration_ms | Histogram | tienda_id, resultado | Latencia de crear nuevo conteo |
| inventario_registrar_duration_ms | Histogram | tienda_id, resultado | Latencia de registrar valor |
| inventario_confirmar_duration_ms | Histogram | tienda_id, resultado | Latencia de confirmar conteo |
| inventario_operaciones_total | Counter | tienda_id, tipo_operacion, resultado | Total operaciones por tienda |
| inventario_errores_total | Counter | tienda_id, codigo_error | Errores por código |

**Nota**: NUNCA user_id como etiqueta (cardinalidad unbounded). Usar en span attributes si es necesario.

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|--------|-----------|
| Race condition: 2 conteos simultáneos | Medio | Alto | UNIQUE constraint (tienda_id, tipo, horario_norm, fecha) en BD |
| Pérdida de datos durante conteo | Bajo | Crítico | Transacciones ACID, recuperación de sesión, no soft-delete |
| Items sin registrar en confirmar | Medio | Medio | Validación pre-confirm (422 items_sin_registrar), UI bloquea submit |
| Movimientos durante conteo | Alto | Alto | Bloqueo pre-check (409 inventario_activo), pruebas E2E |
| Memory leaks en Angular | Medio | Medio | takeUntil en todas subscripciones, tests de unsubscribe |

---

## Decisiones Técnicas

| Decisión | Rationale |
|----------|-----------|
| **Stock snapshot inmutable** | Evita inconsistencias por operaciones concurrentes; valor_sugerido NUNCA cambia durante conteo |
| **Bloqueo de movimientos** | Garantiza que RF-INV-02.2 (fórmula stock) permanece válida; previene pérdidas silenciosas |
| **No soft-delete** | Inventarios confirmados NUNCA se elimina (auditoría); en_progreso sí se puede eliminar (admin) |
| **RBAC por tienda** | Admin accede cualquier tienda; líder/barista solo propia tienda (security boundary) |
| **Atomic confirmation** | BEGIN TRANSACTION → UPDATE inventario + detalle → COMMIT (all or nothing) |
| **GetInventarioDetalle siempre completo** | Mismo endpoint para "detalles durante conteo" y "detalles historial" |

---

## Próximos Pasos

1. ✅ Fase 2 Corrección: Implementar GetItemsActivosPorTipo + GetStockSnapshot
2. ✅ Fase 2 Corrección: Refactorizar Service.Iniciar con nuevo orden
3. ⏳ Fase 3: RegistrarValor + autosave en Angular
4. ⏳ Fase 4: Historial + filtros + paginación
5. ⏳ Fase 5: Admin modificar/eliminar + bloqueos en otros módulos
6. ⏳ Observabilidad: Spans + métricas + logging
7. ⏳ Tests: 95%+ coverage backend, E2E tests 4+ flows

---

**Última actualización**: 2026-07-18 — Iteration para corrección de flujo (BUG-016)
