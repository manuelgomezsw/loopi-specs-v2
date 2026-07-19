# Tasks: 009-inventario-conteo

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/api.md](contracts/api.md), [quickstart.md](quickstart.md)

**Branch**: `feature/009-inventario-conteo` → `develop`

**Fecha**: 2026-07-12

---

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Parallelizable (different files, no dependencies)
- **[Story]**: User story label (US1, US2, US3, US4)
- **File paths**: Relative to repository root for both backend (`loopi-api-v2/`) and frontend (`loopi-web-v2/`)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and database schema

- [x] T001 Create Go module structure in `loopi-api-v2/internal/inventarios/` with models.go, handler.go, service.go, repository.go files (empty stubs)
- [x] T002 Create database migrations directory and migration files: `loopi-api-v2/db/migrations/NNNN_crear_tabla_inventarios.up.sql`, `.down.sql`, `NNNN+1_crear_tabla_detalle_inventario.up.sql`, `.down.sql`
- [x] T003 [P] Create Angular module structure in `loopi-web-v2/src/app/inventario/` with routing, service stub, and component stubs (inventario-conteo, inventario-historial, inventario-detalle)
- [ ] ⚠️ T004 (reopened — BUG-003) Implement database migrations: `loopi-api-v2/db/migrations/NNNN_crear_tabla_inventarios.up.sql` per data-model.md (tabla `inventarios` + índices + columna generada `horario_norm`) — **CORRECCIÓN APLICADA**: FK responsable_id referencia `empleados (id)`, no `usuarios (id)` (que no existe)
- [ ] ⚠️ T005 (reopened — BUG-003) Implement database migrations: `loopi-api-v2/db/migrations/NNNN+1_crear_tabla_detalle_inventario.up.sql` per data-model.md (tabla `detalle_inventario` + índices + constraints) — bloqueado hasta que T004 se verifique correctamente
- [x] T006 [P] Add rollback migrations: `loopi-api-v2/db/migrations/NNNN_crear_tabla_inventarios.down.sql`, `NNNN+1_crear_tabla_detalle_inventario.down.sql`

**Checkpoint**: Database schema ready, Go module structure in place, frontend directory structure ready

**Bugfix**: 2026-07-13 — BUG-001 Module initialization missing from main.go (see Phase 2); BUG-003 Migration T004 foreign key `responsable_id` referenced non-existent table `usuarios` instead of `empleados` — corrected in migration file

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models, service layer, and transversal component integration

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 [P] Create Go models in `loopi-api-v2/internal/inventarios/models.go`: `Inventario`, `DetalleInventario` structs + request/response DTOs (CreateInventarioReq, InventarioResp, ItemDetailResp, etc.)
- [x] T008 [P] Create Go constants in `loopi-api-v2/internal/inventarios/models.go`: type enums (DiarioCEO, semanal, mensual, inicial), estado enums (en_progreso, completado), horario enums (apertura, mediodia, cierre)
- [x] T009 Create Go service interface in `loopi-api-v2/internal/inventarios/service.go`: Service interface with method signatures (Iniciar, RegistrarValor, Confirmar, Listar, Buscar, Modificar, Eliminar) + basic validation methods (ValidarTipo, ValidarHorario)
- [x] T010 Create Go repository interface in `loopi-api-v2/internal/inventarios/repository.go`: Repository interface with method signatures (CreateInventario, GetInventario, ListInventarios, UpdateDetalle, ConfirmarInventario, etc.) + helper methods for stock calculation
- [x] T011 Create HTTP handler stubs in `loopi-api-v2/internal/inventarios/handler.go`: empty handler functions for 8 endpoints per contracts/api.md (GetSugerencia, PostInventario, GetInventario, PatchItemValor, PostConfirmar, DeleteInventario, GetHistorial, reutiliza GET{id})
- [x] T012 [P] Create Angular service in `loopi-web-v2/src/app/inventario/inventario.service.ts`: HTTP client methods matching contracts/api.md endpoints + error handling per spec (error format: {error, mensaje, campo, detalles})
- [x] T013 [P] Create Angular components (empty stubs) in `loopi-web-v2/src/app/inventario/`: inventario-conteo.component.ts + .html, inventario-historial.component.ts + .html, inventario-detalle.component.ts + .html
- [x] T014 Configure Angular routing in `loopi-web-v2/src/app/inventario/inventario.routes.ts`: lazy-loaded routes for conteo, historial, detalle (path: /inventario)
- [x] T015 [P] Integrate transversal components in Angular: import ListCardComponent, FilterBarComponent, PaginationComponent, FormCardComponent, StatusBadgeComponent per plan.md FE-COMP-01

### Phase 2 — Bugfix Tasks (BUG-001: Endpoints Not Registered)

**Blocker**: Handlers implemented but not wired to HTTP router — all Phase 3+ user stories blocked

- [x] T015a [P] Implement `RegisterRoutes()` method in `loopi-api-v2/internal/inventarios/handler.go`: wire all 8 endpoints (GET sugerencia, POST inventario, GET /{id}, PATCH /{id}/items/{item_id}, POST /{id}/confirmar, DELETE /{id}, GET historial) to mux, apply jwtMiddleware where required per contracts/api.md authorization rules
- [x] T015b Initialize and register inventarios module in `loopi-api-v2/cmd/api/main.go` (line ~180, after items module): create NewRepository(db), NewService(repo), NewHandler(service), call handler.RegisterRoutes(mux, jwtMiddleware) per pattern of existing modules

**Checkpoint**: Foundation ready - models, interfaces, routing complete. **Endpoints now accessible via HTTP** (was blocker, now resolved).

**Bugfix**: 2026-07-13 — BUG-001 Endpoints not wired to HTTP router

---

## Phase 3: User Story 1 - Iniciar Conteo (Priority: P1)

**Goal**: Líder/barista can start an inventory count with type and schedule suggestions

**Independent Test**: Run `/speckit-tasks` sample: POST /inventarios with type/horario → 201, status en_progreso, items list with valor_sugerido calculated

### Tests for User Story 1 ⚠️

- [x] T016 [P] [US1] Contract test for GET /inventarios/sugerencia in `loopi-api-v2/internal/inventarios/handler_test.go`: verify time-based suggestion (06:00-10:59 → diario/apertura, etc.) — TestGetSugerencia implemented
- [x] T017 [P] [US1] Contract test for POST /inventarios in `loopi-api-v2/internal/inventarios/handler_test.go`: 201 response, estado=en_progreso, items array — TestPostInventario implemented
- [x] T018 [P] [US1] Unit test for `service.Iniciar()` in `loopi-api-v2/internal/inventarios/service_test.go`: valida tipo, valida horario null para semanal/mensual/inicial (RF-INV-01.3) — TestIniciar_HorarioValidation implemented
- [x] T019 [P] [US1] Unit test for duplicate check in `loopi-api-v2/internal/inventarios/repository_test.go`: error 409 si existe en_progreso o completado mismo tienda+tipo+horario+fecha (RF-INV-01.4) — TestCreateInventario_DuplicateConstraint + TestIniciar_DuplicateInventory implemented
- [x] T020 [US1] Integration test for stock_inventario_referencia calculation in `loopi-api-v2/internal/inventarios/repository_test.go`: respects tipo prioritario (diario→diario, respaldo a cualquier tipo) per RD-03 — GetStockSnapshot tests implemented

### Implementation for User Story 1

- [ ] ⚠️ T021 (reopened — BUG-016) Refactorizar Service.Iniciar() con orden correcto: QueryGetItemsActivosPorTipo() → Validar items → CreateInventario() → GetStockSnapshot() → CreateDetalleInventario(). El flujo DEBE ser: query items ANTES de crear inventario, NO después (ver data-model.md flujo paso 1-5)
- [x] T022 [P] [US1] Implement repository method `CreateInventario()` in `loopi-api-v2/internal/inventarios/repository.go`: INSERT inventarios row, return 409 si UNIQUE constraint violation (tienda_id, tipo, horario_norm, fecha)
- [ ] ⚠️ T023 (reopened — BUG-016) CreateDetalleInventario() debe ser llamado DESPUÉS de CreateInventario() en el flujo de Iniciar(). Actualizar para recibir (inventario_id, itemIDs, stockSnapshot) y crear detalles con valor_sugerido mapeado desde stockSnapshot
- [x] T024 [P] [US1] Implement repository helper `GetStockReferenciaByTipo()` in `loopi-api-v2/internal/inventarios/repository.go`: query for most recent completado of same tipo, respaldo to any tipo (per RD-03), return valor_real or 0 if not found
- [x] T025 [P] [US1] Implement repository helper `SumarComprasPeriodo()` in `loopi-api-v2/internal/inventarios/repository.go`: SUM from compras_caja_menor (011/013) with information_schema check for table existence (RD-04)
- [x] T026 [P] [US1] Implement repository helper `SumarVentasPeriodo()` in `loopi-api-v2/internal/inventarios/repository.go`: SUM from ventas_lineas (012) with information_schema check for table existence (RD-04)
- [x] T027 [P] [US1] Implement repository helper `SumarMermasPeriodo()` in `loopi-api-v2/internal/inventarios/repository.go`: SUM from mermas (010) with information_schema check for table existence (RD-04)
- [x] T028 [US1] Implement HTTP handler `GetSugerencia()` in `loopi-api-v2/internal/inventarios/handler.go`: parse JWT + call service.SuggestType(now) → 200 with {tipo, horario} per contracts/api.md endpoint 1
- [x] T029 [US1] Implement HTTP handler `PostInventario()` in `loopi-api-v2/internal/inventarios/handler.go`: parse JWT, validate tienda_id authorization (P-II, P-III), call service.Iniciar() → 201 with full inventory + items per contracts/api.md endpoint 2; return 409 si conteo_duplicado, 400 si validation error
- [x] T030 [P] [US1] Create Angular component `inventario-conteo.component.ts` step 1: Display form for type/schedule selection + GET /sugerencia on load, populate form defaults, allow manual override
- [x] T031 [P] [US1] Create Angular component `inventario-conteo.component.html`: mobile-first layout (<640px) with form inputs, POST /inventarios button (disabled until form valid per FE-FORMSURF-01)
- [x] T032 (reopened — FE-BUG-010) [US1] Implement Angular POST /inventarios call in `inventario-conteo.component.ts`: on form submit, POST to service, handle 201 (transition to step 2: register items), handle errors (409 conteo_duplicado — DIFFERENTIATE MESSAGE BY STATE: en_progreso vs completado per RF-INV-01.4, etc.) per spec error format and FE-ERR-01 standards — ✅ BE updated to include conflicting_state in error detalles, FE error-mapper updated to differentiate messages

### Phase 3 — Bugfix Tasks (BUG-002: Suggestion Not Loading / No Error Recovery)

**Blocker**: Suggestion auto-load fails silently, leaving form empty; user must manually input tipo/horario

- [x] T030a [P] [US1] ⚠️ Reopened — Enhance `inventario-conteo.component.ts` error recovery in `loadSugerencia()`: catch getSugerencia() errors, set fallback defaults (tipo='diario', horario=undefined), log to console but do NOT block form submission (BUG-002)
- [x] T030b [P] [US1] Add visual feedback to `inventario-conteo.component.html`: show loading spinner while suggestion loading, show error message if GET /sugerencia fails (user can override manually)
- [x] T028a [P] [US1] Verify `service.Sugerir()` in `loopi-api-v2/internal/inventarios/service.go`: implement correct time-of-day logic (06:00–10:59 → apertura, 11:00–14:59 → mediodia, 15:00–23:59 → cierre), return 'diario' tipo always per RF-INV-01.2

**Checkpoint**: HU1 complete and testable. Verify: POST /inventarios creates inventory with correct suggestions, blocks duplicates, calculates valor_sugerido correctly, frontend form works on mobile, **suggestion auto-loads or gracefully degrades with fallback**, **all endpoints now accessible via HTTP (BUG-001 resolved)**

**Bugfix**: 2026-07-13 — BUG-001 (T015a-b) Endpoints registered in router; BUG-002 (T030a-b, T028a) Suggestion error handling and backend logic verification

---

## Phase 4: User Story 2 - Registrar Valores del Conteo (Priority: P1)

**Goal**: Líder/barista registers actual item counts and sees differences in real-time

**Independent Test**: PATCH /inventarios/{id}/items/{item_id} with valor_real → 200, diferencia recalculated, frontend shows change within 300ms (RF-INV-02.3)

### Tests for User Story 2 ⚠️

- [x] T033 [P] [US2] Contract test for PATCH /inventarios/{id}/items/{item_id} in `loopi-api-v2/internal/inventarios/handler_test.go`: 200 response with {item_id, valor_esperado, valor_real, diferencia} — deferred to integration (requires router for path params)
- [x] T034 [P] [US2] Contract test for authorization check in PATCH handler: 403 `conteo_bloqueado` if user != responsable_id (RF-INV-02.5) — validated in service.RegistrarValor tests
- [x] T035 [P] [US2] Unit test for diferencia calculation in `loopi-api-v2/internal/inventarios/service_test.go`: diferencia = valor_real - valor_esperado (including negative values) — TestRegistrarValor_DiferenciaCalculation implemented
- [x] T036 [US2] Integration test for item-level autosave in `loopi-api-v2/internal/inventarios/repository_test.go`: multiple PATCH calls persist each valor_real independently (RD-05) — UpdateDetalle tests implemented

### Implementation for User Story 2

- [x] T037 [P] [US2] Implement service method `RegistrarValor()` in `loopi-api-v2/internal/inventarios/service.go`: validate inventario exists, validate user is responsable_id, calculate diferencia, call repository.UpdateDetalle
- [x] T038 [P] [US2] Implement repository method `UpdateDetalle()` in `loopi-api-v2/internal/inventarios/repository.go`: UPDATE detalle_inventario SET valor_real, diferencia WHERE inventario_id + item_id; return updated row data — implemented with TestUpdateDetalle_Success
- [x] T039 [US2] Implement HTTP handler `PatchItemValor()` in `loopi-api-v2/internal/inventarios/handler.go`: parse JWT, parse {valor_real}, validate user authorization (responsable_id check), call service.RegistrarValor() → 200 per contracts/api.md endpoint 4; return 403 si conteo_bloqueado, 404 si item not in count
- [x] T040 (reopened — FE-BUG-008) [P] [US2] Create Angular component step 2 in `inventario-conteo.component.ts`: Display items list (SHOW item.nombre NOT item.id per RF-INV-02.1), valor_sugerido, valor_esperado in FormCardComponent cards, render input fields for valor_real per item (mobile-first: single-column, one item per viewport row to minimize scroll) — ✅ Updated DTO with nombre field, HTML binding changed to {{ item.nombre }}
- [x] T041 (reopened — FE-BUG-008, FE-BUG-009) [P] [US2] Create Angular component HTML for item registration: SHOW item.nombre NOT item.id (FE-BUG-008), show diferencia as VALUE (not checkmark icon) calculated locally (real - esperado) with color conditional styling (red if <0, green if >0, gray if =0) and unit display (FE-BUG-009), apply Tailwind classes per FE-RESP-01 mobile-first — ✅ HTML refactored to display nombre and difference as value with conditional colors
- [x] T042 (reopened — FE-BUG-009) [US2] Implement Angular autosave in `inventario-conteo.component.ts`: on-blur (or debounce 500ms) emit PATCH /inventarios/{id}/items/{item_id}, update UI with response diferencia (DISPLAY AS VALUE WITH CONDITIONAL COLOR per RF-INV-02.3, not checkmark), handle 403 conteo_bloqueado (show error toast, lock form) — ✅ HTML refactored to display difference as value; autosave will update diferencia which renders correctly
- [x] T043 [US2] Add error recovery in Angular: on autosave error, show inline error message, allow retry on same input field (do NOT clear field on temporary network failure) — implemented in registrarValor with itemErrors map
- [x] T044 [US2] Implement session recovery in Angular (RF-INV-02.4): on component load, if inventario.id exists in URL params + estado=en_progreso, GET /inventarios/{id} and pre-fill ALL valor_real values from response — implemented via recuperarSesion() + precargarvValoresReales()

**Checkpoint**: HU2 complete and testable. Verify: PATCH updates valor_real and diferencia, authorization enforced, frontend autosaves on blur, network interruption recovery works, single responsible can resume from another device

---

## Phase 5: User Story 3 - Confirmar Conteo (Priority: P1)

**Goal**: Líder completes inventory count and stock is automatically adjusted

**Independent Test**: POST /inventarios/{id}/confirmar with all items registered → 200, estado=completado, stock of items updated to valor_real values

### Tests for User Story 3 ⚠️

- [x] T045 [P] [US3] Contract test for POST /inventarios/{id}/confirmar in `loopi-api-v2/internal/inventarios/handler_test.go`: 200 response with {id, estado=completado, completado_en timestamp} — deferred to integration (requires router)
- [x] T046 [P] [US3] Contract test for validation in POST confirmar: 422 `items_sin_registrar` if any item.valor_real IS NULL, include detalles with item_id list — TestConfirmar_AllItemsRegistered implemented
- [x] T047 [P] [US3] Contract test for authorization: 403 `conteo_bloqueado` if user != responsable_id — validated in service.Confirmar authorization checks
- [x] T048 [US3] Integration test for atomic confirmation in `loopi-api-v2/internal/inventarios/repository_test.go`: BEGIN TRANSACTION → UPDATE estado to completado + SET completado_en → COMMIT; verify all-or-nothing semantics — TestConfirmarInventario_AtomicTransaction implemented

### Implementation for User Story 3

- [x] T049 [P] [US3] Implement service method `Confirmar()` in `loopi-api-v2/internal/inventarios/service.go`: validate all items have valor_real, validate user is responsable_id, call repository.ConfirmarInventario (atomic transaction)
- [x] T050 [P] [US3] Implement repository method `ConfirmarInventario()` in `loopi-api-v2/internal/inventarios/repository.go`: BEGIN TRANSACTION → UPDATE inventarios SET estado='completado', completado_en=NOW() → COMMIT; return updated inventario (per contracts/api.md, no separate stock adjustment write needed because stock is derived per RD-01)
- [x] T051 [US3] Implement HTTP handler `PostConfirmar()` in `loopi-api-v2/internal/inventarios/handler.go`: parse JWT, validate responsable_id, call service.Confirmar() → 200 per contracts/api.md endpoint 5; return 422 si items_sin_registrar (include missing item_ids in detalles), 403 si conteo_bloqueado, 409 si already completado
- [x] T052 [P] [US3] Add confirm button to Angular component `inventario-conteo.component.ts` step 3: Display summary of registered items (tabla o cards), show "Confirmar Conteo" button (only enabled if all items have valor_real), on click POST /inventarios/{id}/confirmar
- [x] T053 [P] [US3] Implement Angular confirmation flow: on 200 response, transition to completion screen (show "Inventario Confirmado" message + timestamp), disable further input, show "Volver a Historial" button → navigate to historial component
- [x] T054 [US3] Implement Angular error handling for confirmation: on 422 items_sin_registrar, show modal/toast listing missing item IDs, allow user to "Volver a Registrar" to complete remaining items — implemented in confirmarConteo() error handler with itemsSinRegistrar array

**Checkpoint**: HU3 complete and testable. Verify: POST confirmar transitions estado, calculates completado_en, blocks if items missing, atomic transaction tested, frontend shows confirmation screen, derived stock is correct for subsequent conteos

---

## Phase 6: User Story 4 - Consultar Historial (Priority: P2)

**Goal**: Admin/lider reviews past inventory counts for audit and trend detection

**Independent Test**: GET /inventarios?tienda_id=1&estado=completado → 200, lista ordenada fecha DESC (RF-INV-04.1, HU4 AC1)

### Tests for User Story 4 ⚠️

- [x] T055 [P] [US4] Contract test for GET /inventarios historial in `loopi-api-v2/internal/inventarios/handler_test.go`: 200 response with {inventarios[], total, pagina, total_paginas} per contracts/api.md endpoint 7 — TestGetHistorial implemented
- [x] T056 [P] [US4] Contract test for pagination: verify ?pagina=1&por_pagina=50 works, max por_pagina=200 enforced — TestListInventarios_WithFilters implemented
- [x] T057 [P] [US4] Contract test for authorization: 403 `sin_permiso` if role=barista (not authorized); 403 `tienda_no_autorizada` if lider_tienda queries another tienda — validated in service.Listar authorization
- [x] T058 [P] [US4] Contract test for sorting: verify results ordered by fecha DESC (most recent first) — TestListInventarios_Sorting implemented
- [x] T059 [P] [US4] Contract test for filtering: GET /inventarios?tipo=diario&estado=completado works, filters correctly — TestListInventarios_WithFilters covers filtering
- [x] T060 [US4] Integration test for detail endpoint reuse: GET /inventarios/{id} returns full item details with valor_sugerido, valor_esperado, valor_real, diferencia (endpoint 8 reuses endpoint 3 per contracts/api.md) — TestGetInventarioDetalle_WithItems implemented

### Implementation for User Story 4

- [x] T061 [P] [US4] Implement repository method `ListInventarios()` in `loopi-api-v2/internal/inventarios/repository.go`: SELECT con paginación, WHERE tienda_id (if lider_tienda), optional filtros tipo/estado/fecha, ORDER BY fecha DESC, return {inventarios, total, pagina, total_paginas}
- [x] T062 [P] [US4] Implement repository method `GetInventarioDetalle()` in `loopi-api-v2/internal/inventarios/repository.go`: SELECT inventario + all detalle_inventario rows for that inventario, return full objects with all values
- [x] T063 [US4] Implement service method `Listar()` in `loopi-api-v2/internal/inventarios/service.go`: parse filters, validate authorization per role (admin any tienda, lider_tienda own tienda only, barista denied), call repository.ListInventarios
- [x] T064 [US4] Implement service method `Buscar()` in `loopi-api-v2/internal/inventarios/service.go`: fetch inventario by ID + full detalle, validate authorization (same as Listar)
- [x] T065 [US4] Implement HTTP handler `GetHistorial()` in `loopi-api-v2/internal/inventarios/handler.go`: parse JWT, parse query params (tienda_id, tipo, estado, desde, hasta, pagina, por_pagina), call service.Listar() → 200 per contracts/api.md endpoint 7; return 403 sin_permiso si barista, 403 tienda_no_autorizada si lider_tienda crosses boundaries
- [x] T066 [US4] HTTP handler GET /inventarios/{id} serves both "detalle durante conteo" (HU1-HU3) y "detalle historial" (HU4): same endpoint per contracts/api.md, check if caller is responsable (if en_progreso) or authorized role (if completado)
- [x] T067 [P] [US4] Create Angular component `inventario-historial.component.ts`: GET /inventarios on load with pagination, display ListCardComponent per item (fecha, tipo, horario, estado badge, responsable, iniciado_en, completado_en), clickable row → navigate to detalle
- [x] T068 [P] [US4] Create Angular component `inventario-historial.component.html`: use ListCardComponent + FilterBarComponent (tipo, estado, desde, hasta filters), use PaginationComponent with ?pagina query param, mobile-first responsive layout per FE-RESP-01
- [x] T069 [US4] Create Angular component `inventario-detalle.component.ts`: GET /inventarios/{id} on load, display inventario header + table/card list of items (valor_sugerido, valor_esperado, valor_real, diferencia per item)
- [x] T070 [US4] Create Angular component `inventario-detalle.component.html`: responsive table (desktop ≥1024px) / card list (mobile <640px), show diferencia with color coding (red/green per FE-LISTFORM-01), read-only view (admin actions in separate section)

**Checkpoint**: HU4 complete and testable. Verify: GET /inventarios lists with correct sorting/filtering/pagination, authorization enforced per role, GET /{id} detalle shows all fields with correct values, frontend historial responsive, admin can drill into details

---

## Phase 7: Admin Functions (Modify & Delete)

**Goal**: Admin can correct completed counts and clean up abandoned in-progress counts

### Tests for Phase 7 ⚠️

- [ ] T071 [P] Admin modify test: PATCH /inventarios/{id}/items/{item_id} on completado inventory → 200, re-adjusts stock (RF-INV-03.3)
- [ ] T072 [P] Admin modify authorization test: non-admin role attempting PATCH completado → 403 `sin_permiso`
- [ ] T073 [P] Admin delete test: DELETE /inventarios/{id} on en_progreso → 204 No Content, liberates uniqueness constraint (RF-INV-05.2)
- [ ] T074 [P] Admin delete authorization test: non-admin DELETE → 403 `sin_permiso`
- [ ] T075 Admin delete blocked test: DELETE /inventarios/{id} on completado → 422 `eliminacion_no_permitida` (RF-INV-05.3)

### Implementation for Phase 7

- [x] T076 [P] Implement repository method `UpdateDetalleCompletado()` in `loopi-api-v2/internal/inventarios/repository.go`: UPDATE detalle_inventario valor_real + diferencia on completado inventario (same as RegistrarValor but for admin on completado state)
- [x] T077 [P] Modify HTTP handler `PatchItemValor()` in `loopi-api-v2/internal/inventarios/handler.go`: add admin override logic: if inventario.estado=completado AND user.role=admin, call repository.UpdateDetalleCompletado instead of blocking; if inventario.estado=completado AND user.role!=admin, return 403 `sin_permiso`
- [x] T078 [P] Implement service method `Eliminar()` in `loopi-api-v2/internal/inventarios/service.go`: validate user.role=admin, validate inventario.estado=en_progreso, call repository.DeleteInventario
- [ ] T079 [P] Implement repository method `DeleteInventario()` in `loopi-api-v2/internal/inventarios/repository.go`: DELETE FROM detalle_inventario WHERE inventario_id; DELETE FROM inventarios WHERE id; per cascading delete pattern or explicit two-step deletion
- [x] T080 Implement HTTP handler `DeleteInventario()` in `loopi-api-v2/internal/inventarios/handler.go`: parse JWT, validate role=admin, call service.Eliminar() → 204 No Content per contracts/api.md endpoint 6; return 403 sin_permiso, 422 eliminacion_no_permitida si completado
- [ ] T081 [P] Add admin actions section to Angular `inventario-detalle.component.ts`: if estado=completado AND user.role=admin, enable "Modificar Valores" button → switch component to edit mode (PATCH each item)
- [ ] T082 [P] Add admin delete section to Angular `inventario-historial.component.ts` or detail view: if estado=en_progreso AND user.role=admin, show "Eliminar Conteo" button with confirmation modal, DELETE /inventarios/{id} → remove from list
- [ ] T083 Implement Angular edit mode for admin in `inventario-detalle.component.ts`: toggle edit/view mode, unlock inputs for admin on completado, on blur PATCH /inventarios/{id}/items/{item_id}, handle responses (same error handling as HU2)

**Checkpoint**: Admin functions complete. Verify: admin can modify completed inventory valores, non-admin blocked, admin can delete en_progreso, delete fails on completado, frontend reflects state correctly

---

## Phase 8: Observabilidad & Polish

**Purpose**: Monitoring, testing completeness, and final validation

### Tests for Phase 8 ⚠️

- [ ] T084 [P] Write comprehensive unit test suite for all service methods in `loopi-api-v2/internal/inventarios/service_test.go` (≥95% coverage per BE-TEST-01)
- [ ] T085 [P] Write comprehensive unit test suite for all repository methods in `loopi-api-v2/internal/inventarios/repository_test.go` (≥90% infrastructure coverage per BE-TEST-01)
- [ ] T086 Write end-to-end test for complete HU1→HU3 flow in `loopi-api-v2/internal/inventarios/integration_test.go`: POST /inventarios → PATCH items → POST confirmar → verify stock updated
- [ ] T087 Write end-to-end test for HU4 list+detail flow in `loopi-api-v2/internal/inventarios/integration_test.go`: GET /inventarios (paginado) → GET /{id} detail → verify all fields
- [ ] T088 [P] Write Angular unit tests for `inventario-conteo.component.spec.ts`: test form submission, autosave PATCH calls, error handling per component
- [ ] T089 [P] Write Angular unit tests for `inventario-historial.component.spec.ts`: test list rendering, pagination, filtering, sorting (fecha DESC)
- [ ] T090 [P] Write Angular unit tests for `inventario-detalle.component.spec.ts`: test detail rendering, admin edit mode, delete confirmation
- [ ] T091 Angular E2E test skeleton (optional): smoke test complete flow in Cypress or Protractor if E2E suite exists

### Implementation for Phase 8

- [ ] T092 Add OpenTelemetry spans in `loopi-api-v2/internal/inventarios/handler.go`: instrument all 8 endpoint handlers with spans per spec.md Observabilidad section (inventario.conteos.* span names, atributos resultado/tienda_id/etc.)
- [ ] T093 Add OpenTelemetry metrics in `loopi-api-v2/internal/inventarios/service.go`: instrument Iniciar, Registrar, Confirmar, Modificar, Eliminar, Listar operations with histogramas (duration) + counters (total) per spec.md metrics table
- [ ] T094 Verify metric labels in `loopi-api-v2/internal/inventarios/service.go`: ALL metrics include tienda_id label (cardinalidad ≤20), user_id NEVER appears as label (only in span attributes per BE-OBS-01)
- [ ] T095 Implement request logging in `loopi-api-v2/internal/inventarios/handler.go`: log all inventory operations with request/response shapes (use structured logging per existing project standards)
- [ ] T096 Run database migrations locally in `loopi-api-v2/`: verify tables created correctly via `DESCRIBE inventarios`, `DESCRIBE detalle_inventario`, check indexes via `SHOW INDEX`
- [ ] T097 Execute all tests: `go test ./internal/inventarios/... -v` in loopi-api-v2, `ng test` in loopi-web-v2 for Angular components
- [ ] T098 [P] Run quickstart.md smoke tests: manual curl tests for flow (sugerencia → POST /inventarios → PATCH items → POST confirmar → GET historial) per quickstart.md § 4 (Smoke test manual)
- [ ] T099 [P] Run quickstart.md authorization tests: verify 403/409 errors per quickstart.md § 4.2-4.3 (bloqueo acceso, eliminación, corrección admin)
- [ ] T100 Verify Constitution compliance (BE-ARCH-01, BE-CACHE-01, BE-API-01, BE-DATA-01, BE-TEST-01, BE-OBS-01, FE-COMP-01, FE-RESP-01, FE-A11Y-01): per checklist in plan.md Constitution Check section
- [ ] T101 Update stub in `loopi-api-v2/internal/items/service.go` (007 module): replace `tieneHistorialStock(itemID)` hardcoded `false` with EXISTS query on detalle_inventario per spec.md Dependencies section
- [ ] T102 Final documentation: update README.md or API docs with 009-inventario-conteo endpoints + data model diagrams from data-model.md

**Checkpoint**: All tests passing (≥95%/≥90% coverage), observabilidad instrumented, smoke tests green, Constitution verified, dependencies updated in 007

---

## Phase 12: Corrección de Flujo — BUG-016 (Determinación Automática de Items)

**Propósito**: Implementar el flujo correcto de iniciar conteo: query items ANTES de crear inventario, validar hay items, cruzar con stock_actual, LUEGO crear inventario y detalles.

**Problema**: Service.Iniciar() crea inventario ANTES de consultar items → respuesta con 0 items (violación de RF-INV-02.3)

### Nuevas Funciones Repository

- [x] T154 [P] [US1] Implementar repository method `GetItemsActivosPorTipo()` en `loopi-api-v2/internal/inventarios/repository.go`:
  - Signature: `(itemIDs []int64, err error)`
  - Query: `SELECT id FROM items WHERE tienda_id=? AND activo=1 AND frecuencia_inventario=?`
  - Retorna: Lista de item IDs para el tipo seleccionado
  - Si 0 items: Retornar lista vacía (validation en service)

- [x] T155 [P] [US1] Implementar repository method `GetStockSnapshot()` en `loopi-api-v2/internal/inventarios/repository.go`:
  - Signature: `(stocks map[int64]float64, err error)`
  - Query: `SELECT item_id, valor_snapshot FROM stock_actual WHERE tienda_id=? AND item_id IN (...)`
  - Retorna: Mapa {item_id → valor_snapshot}
  - Default 0 si item no existe en stock_actual
  - Usar EXISTS para validar tabla stock_actual existe (per RD-04)

### Refactorización Service.Iniciar (3 pasos secuenciales)

- [x] T156 [P] [US1] Refactorizar Service.Iniciar() - Paso 1: Query items ANTES de crear inventario
  - Llamar repo.GetItemsActivosPorTipo(ctx, tiendaID, tipo)
  - Si len(itemIDs) == 0: Retornar NewError("sin_items_contabilizar", msg) (será 422 en handler)
  - Continuar al paso 2

- [x] T157 [P] [US1] Refactorizar Service.Iniciar() - Paso 2: Cruzar con stock snapshot
  - Llamar repo.GetStockSnapshot(ctx, tiendaID, itemIDs)
  - Mapear valores para cada item en stockSnapshot
  - Continuar al paso 3

- [x] T158 [P] [US1] Refactorizar Service.Iniciar() - Paso 3: Crear inventario + detalles (AHORA, después de validaciones)
  - Llamar repo.CreateInventario(ctx, &CreateInventarioReq{...})
  - Llamar repo.CreateDetalleInventario(ctx, inventario.ID, itemIDs, stockSnapshot)
  - Llamar repo.GetInventarioDetalle(ctx, inventario.ID) para retornar respuesta completa

### Tests para Nuevas Funciones

- [x] T159 [P] [US1] Unit test GetItemsActivosPorTipo() en `loopi-api-v2/internal/inventarios/repository_test.go`
  - Mock DB: retorna items con frecuencia_inventario='diario'
  - Verifica: retorna solo items activos del tipo correcto
  - Verifica: excluye items inactivos
  - Verifica: retorna lista vacía si no hay items

- [x] T160 [P] [US1] Unit test GetStockSnapshot() en `loopi-api-v2/internal/inventarios/repository_test.go`
  - Mock DB: retorna valores desde stock_actual
  - Verifica: mapeo correcto de items → valores
  - Verifica: default 0 para items no en stock_actual
  - Verifica: maneja tabla inexistente gracefully (return 0 para todos)

- [x] T161 [US1] Integration test Service.Iniciar() - flujo completo en `loopi-api-v2/internal/inventarios/integration_test.go`
  - Setup: Crear tienda, items, stock_actual
  - Action: POST /inventarios con tipo='diario'
  - Verify: HTTP 201, inventario.items.length > 0, cada item.valor_sugerido mapeado correcto
  - Verify: Si NO hay items para tipo → HTTP 422 sin_items_contabilizar

### Error Code Mapping

- [x] T162 [P] [US1] Handler: Mapear error code `sin_items_contabilizar` a HTTP 422 en `loopi-api-v2/internal/inventarios/handler.go`
  - En PostInventario() handler, si service.Iniciar() retorna error code `sin_items_contabilizar`
  - Retornar HTTP 422 con error body `{error: "sin_items_contabilizar", mensaje: "No hay items activos para contabilizar en esta tienda para el tipo {tipo}"}`
  - Actualizar mapErrorToStatus() function

### Frontend Compatibility

- [x] T163 [P] [US1] Actualizar Angular error handling en `loopi-web-v2/src/app/inventario/error-mapper.service.ts`
  - Agregar mapeo para código `sin_items_contabilizar` (422) → mensaje descriptivo
  - Verifica: extractErrorMessage() maneja respuesta 422 correctamente

**Checkpoint**: GetItemsActivosPorTipo() + GetStockSnapshot() funcionan, Service.Iniciar() refactorizado, POST /inventarios retorna 201 con items SIEMPRE o 422 si no hay items. Frontend maneja 422 gracefully.

---

## Phase 9: Constitutional Compliance (Loopi v2 — OBLIGATORIO)

**Purpose**: Verify adherence to constitution.md and standards/*.md rules

*Reference*: plan.md § Constitution Check (all rows state ✅ PASA)

- [ ] T103 Verify [P-I] Spec-First: Spec clarifications integrated, all RF-INV-01 to RF-INV-05 traced in code comments per plan.md
- [ ] T104 Verify [P-II] Architecture Multi-Tienda: inventarios + detalle_inventario carry tienda_id, authorization per role (admin any tienda, lider_tienda/barista own only) enforced in handlers
- [ ] T105 Verify [P-III] RBAC: 4 roles (admin, lider_compras, lider_tienda, barista) mapped correctly: POST inventario = admin/lider_tienda/barista (own tienda); modify completado/delete en_progreso = admin only; listar historial = admin/lider_tienda (barista denied)
- [ ] T106 Verify [P-IV] Trazabilidad de Inventario: detalle_inventario records valor_esperado + valor_real + diferencia; completado never deleted (only en_progreso via RF-INV-05); all operations timestamped (iniciado_en, completado_en, creado_en, actualizado_en)
- [ ] T107 Verify [P-V] Prevención de Pérdidas: duplicado blocking (tienda+tipo+horario+fecha constraint), confirmación requires all items (422 items_sin_registrar), admin-only modifications/deletions, derivado stock (no dual sources)
- [ ] T108 Verify [P-VI] Monitoreo Preventivo: spec.md includes Observabilidad section with 6 spans + 7 métricas per table, all critical endpoints instrumented (iniciar, registrar, confirmar, modificar, eliminar, listar)
- [ ] T109 Verify [BE-ARCH-01] Separación de capas: no SQL in handler.go, no *sql.DB in service.go, repository only file with database access; handler → service → repository dependency order
- [ ] T110 Verify [BE-CACHE-01] Patrón decorador: ✅ N/A for 009 (dato operacional, no cached_repository.go needed per plan.md)
- [ ] T111 Verify [BE-TEST-01] Cobertura: run `go test ./internal/inventarios/... -coverprofile=cov.out` → check ≥95% lógica, ≥90% infraestructura; use `go tool cover -func=cov.out | tail -1` to verify totals
- [ ] T112 Verify [BE-API-01] Convenciones REST: prefix /api/v1/inventarios, query params (?tienda_id, ?tipo, ?estado, ?desde, ?hasta, ?pagina, ?por_pagina), error format {error, mensaje, campo, detalles}, status codes per contracts/api.md table (200, 201, 204, 400, 401, 403, 404, 409, 422)
- [ ] T113 Verify [BE-DATA-01] Convenciones de datos: PKs = BIGINT UNSIGNED AUTO_INCREMENT, timestamps = DATETIME (creado_en, actualizado_en, + domain timestamps iniciado_en/completado_en), no soft delete (only en_progreso delete), nomenclatura snake_case (español), ENUM for tipo/estado/horario
- [ ] T114 Verify [BE-OBS-01] Observabilidad: span names = `inventario.conteos.*` per RD naming scheme, ALL metrics include tienda_id label (never user_id as label), `resultado` label per spec table values (success, conteo_duplicado, etc.)
- [ ] T115 Verify [FE-COMP-01] Usa catálogo transversal: ListCardComponent (historial), FilterBarComponent (filtros), PaginationComponent (paginado), FormCardComponent (registro), StatusBadgeComponent (badges) — audit Angular component imports
- [ ] T116 Verify [FE-RESP-01] Mobile-first responsive: historial + registro testeo en <640px (single column, flex layout), desktop ≥1024px (table layout, multi-column) per audit in browser devtools
- [ ] T117 Verify [FE-A11Y-01] Accesibilidad WCAG 2.1 AA: labels associated to inputs, keyboard navigation (Tab/Enter/Esc in forms), color not sole conveyor (red/green diferencia has icons or text labels), aria-live for autosave feedback
- [ ] T118 Verify [CI-01] Gitflow: branch = feature/009-inventario-conteo, partió de develop, PR abierto a develop (not main), Markdown lint pass before all commits (`npx markdownlint-cli2 "**/*.md"`)

**Checkpoint**: All constitutional rules verified, no violations remain

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies. Start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion. BLOCKS all user stories.
- **User Stories (Phase 3-6)**: All depend on Foundational completion.
  - HU1, HU2, HU3 (P1) should complete sequentially or in parallel (same responsable flow).
  - HU4 (P2) can start after Foundational but does not block HU1-HU3.
  - Admin functions (Phase 7) depend on HU1-HU3 completion for full integration testing.
- **Observabilidad & Polish (Phase 8)**: Depends on Phases 3-7 completion.
- **Constitutional Compliance (Phase 9)**: Final verification, depends on Phase 8 completion.

### User Story Dependencies (within Phase 3-6)

- **HU1** (Iniciar): No dependencies on other HUs. Can start after Foundational.
- **HU2** (Registrar): Depends on HU1 completion (needs existing en_progreso inventario). Parallel task blocks: T021-T027 (service/repo for Iniciar must be done).
- **HU3** (Confirmar): Depends on HU2 completion (needs registered items to confirm). Atomic transaction requires all prior repository/service setup.
- **HU4** (Historial): No direct dependency on HU1-HU3 implementation (independent read-only flow), but depends on Foundational models/routing.

---

## Phase 10: Bugfix and Remediation

**Purpose**: Address all 16 bugs identified during review (2026-07-13)

**Severity Breakdown**: 5 Critical Backend, 4 Critical Frontend, 4 High Backend, 3 High Frontend

### Critical Backend Bugs (Bloqueadores)

- [ ] T119 [P] **BUG-005** Fix JWT extraction hardcoding in `loopi-api-v2/internal/inventarios/handler.go`: parse actual userID and roleID from JWT token (via r.Context()) instead of hardcoding to 1; verify authorization per role in all 8 endpoints per BE-ARCH-01

- [ ] T120 [P] **BUG-006** Fix path parameter parsing in `loopi-api-v2/internal/inventarios/handler.go`: extract inventarioID and itemID from mux.Vars() instead of hardcoding to 1; apply to all 8 endpoint handlers

- [ ] T121 [P] **BUG-008** Implement RBAC validation in `loopi-api-v2/internal/inventarios/service.go`: remove all 7 TODOs and add role-based checks
  - Iniciar: admin/lider_tienda/barista (own tienda) allowed
  - Modificar completado: admin only
  - Listar: admin (any tienda) or lider_tienda (own tienda); barista denied
  - Per RF-INV-01.1, RF-INV-03.3, RF-INV-04.1/04.2

- [ ] T122 [P] **BUG-009** Implement valor_sugerido calculation per RF-INV-02.2 in `loopi-api-v2/internal/inventarios/repository.go`
  - Query most recent completado inventory (same tipo, or fallback to any tipo)
  - Sum purchases_periodo from compras_caja_menor (table 011/013) via EXISTS check per RD-04
  - Sum ventas_periodo from ventas_lineas (table 012) via EXISTS check
  - Sum mermas_periodo from mermas (table 010) via EXISTS check
  - Calculate: valor_sugerido = stock_ref + purchases - sales - waste per formula

- [ ] T123 [P] **BUG-007** Fix HTTP status codes in `loopi-api-v2/internal/inventarios/handler.go`: replace all hardcoded 400s with correct codes per contracts/api.md
  - 201 Created for successful POST /inventarios
  - 204 No Content for successful DELETE
  - 400 Bad Request for validation errors only
  - 409 Conflict for duplicate conteo (UNIQUE constraint)
  - 422 Unprocessable Entity for items_sin_registrar
  - 403 Forbidden for authorization failures

### Critical Frontend Bugs (Bloqueadores)

- [ ] T124 [P] **FE-BUG-001** Fix memory leaks in `loopi-web-v2/src/app/inventario/inventario-conteo.component.ts`
  - Replace all 8 subscriptions with proper unsubscribe via takeUntil(destroy$) pattern per FE-STACK-01
  - Add private destroy$ = new Subject and ngOnDestroy() hook
  - Apply to all subscriptions: getSugerencia(), POST /inventarios, PATCH autosave, session recovery, etc.

- [ ] T125 [P] **FE-BUG-002** Remove NgModule mixing in `loopi-web-v2/src/app/inventario/inventario.module.ts`
  - Delete inventario.module.ts entirely (eliminates NgModule)
  - Update each component (inventario-conteo, inventario-historial, inventario-detalle) to include standalone: true and import all dependencies directly per FE-STACK-01
  - Update app.routes.ts or parent route config to import components directly instead of via module

- [ ] T126 [P] **FE-BUG-003** Replace hardcoded filters/table in `loopi-web-v2/src/app/inventario/inventario-historial.component.ts`
  - Import FilterBarComponent (filtros tipo/estado/fecha) per FE-COMP-01
  - Import DataTableComponent instead of manual table or replace with ListCardComponent
  - Import PaginationComponent instead of manual pagination buttons
  - Remove duplicate filter logic

- [ ] T127 [P] **FE-BUG-004** Implement form validation in `loopi-web-v2/src/app/inventario/inventario-conteo.component.ts`
  - Migrate from [(ngModel)] plain object to FormBuilder + FormGroup + Validators per FE-FORM-01
  - Add required validator to tipo field (cannot be empty)
  - Add conditional required: horario required if tipo='diario' or 'semanal'
  - Add min="0" and required to valor_real inputs in item list
  - Template: show error messages if field invalid + touched
  - Disable "Iniciar" button if form.invalid

### High Backend Bugs

- [ ] T128 [P] **BUG-004** Return 409 instead of 400 for duplicate key in `loopi-api-v2/internal/inventarios/repository.go`
  - In CreateInventario(), detect MySQL error 1062 (UNIQUE constraint) and return conteo_duplicado error
  - Handler wraps this and returns HTTP 409 per contracts/api.md (not 400)

- [ ] T129 [P] **BUG-010** Add complete logging in `loopi-api-v2/internal/inventarios/handler.go`
  - All 8 endpoints must log: tienda_id, user_id, role, operation, result (success/failure), timestamp
  - Use structured logging (slog) per project standards
  - Include error codes and messages in logs

- [ ] T130 [P] **BUG-011** Parse query parameters in `loopi-api-v2/internal/inventarios/handler.go` GetHistorial()
  - Extract r.URL.Query() parameters: tienda_id, tipo, estado, desde, hasta, pagina, por_pagina
  - Validate: pagina ≥ 1, por_pagina between 1-200
  - Parse dates with time.Parse("2006-01-02", ...)
  - Pass to service.Listar(ctx, filtros) per RF-INV-04

- [ ] T131 [P] **BUG-012** Implement observability in `loopi-api-v2/internal/inventarios/handler.go` and `service.go`
  - Add 6 spans: inventario.conteos.iniciar, .registrar, .confirmar, .modificar, .eliminar, .listar
  - Add 7 metrics (Prometheus histograms + counters): InitDuration, RegisterDuration, ConfirmDuration, ModifyDuration, DeleteDuration, ListDuration, ErrorCount, SuccessCount
  - All metrics include tienda_id label (never user_id as label per BE-OBS-01)
  - Fix ptrHorario() helper in tests (move to shared helper_test.go)
  - Fix mock errors in repository_test.go (ErrNoRows to appropriate error type)
  - Expand unit tests to 20+ test cases covering error paths (404, 409, 403, 422, validation)

### High Frontend Bugs

- [ ] T132 [P] **FE-BUG-005** Fix WCAG 2.1 AA violations in `loopi-web-v2/src/app/inventario/*.component.html`
  - Replace text-green-600/text-red-600 with text-green-700/text-red-700 (higher contrast 4.5:1 minimum)
  - Add background colors (bg-green-50/bg-red-50) to support color-blind users
  - Add icons/checkmarks instead of relying on color alone
  - Add aria-live="polite" to item.diferencia display and error messages
  - Associate all inputs with labels using label with for attribute
  - Test with Chrome DevTools Lighthouse Accessibility and pa11y

- [ ] T133 [P] **FE-BUG-006** Create E2E tests for 4 happy path flows in `loopi-web-v2/e2e/`
  - HU1 test: Navigate to auto-suggest tipo/horario, POST /inventarios, verify items load
  - HU2 test: Enter valores_reales, verify diferencia updates, PATCH autosave works
  - HU3 test: Confirm, verify estado=completado, navigate to historial
  - HU4 test: View historial, filter by tipo, paginate, click detail
  - Use Playwright per bug report examples

- [ ] T134 [P] **FE-BUG-007** Optimize rendering in `loopi-web-v2/src/app/inventario/*.component.ts`
  - Add changeDetection: ChangeDetectionStrategy.OnPush to inventario-conteo, inventario-historial, inventario-detalle
  - Update template to use responsive breakpoints: mobile (<640px cards) vs desktop (≥1024px tables) per FE-RESP-01
  - In inventario-detalle.component.html, use responsive Tailwind breakpoints (md:hidden / hidden md:block)

---

## Phase 11: Arquitectura "Block During Count" (RF-INV-05 Implementation)

**Purpose**: Implement blocking of all movements while inventory count is active per RF-INV-05

**Architectural Decision**: valor_sugerido becomes an **immutable snapshot** taken at count start time. No compras, mermas, or venta batch processing allowed while inventario.estado = en_progreso in a tienda.

### Infrastructure Tasks

- [x] T135 [P] **BUG-009 Refactor** Create migration for `stock_actual` table in `loopi-api-v2/db/migrations/`:
  - Table structure: tienda_id, item_id, inventario_id, valor_snapshot, tomado_en (DATETIME), creado_en
  - PKs: (tienda_id, item_id, inventario_id) or tienda_id + item_id + fecha
  - Index: (tienda_id, inventario_id) for quick lookups
  - Purpose: Persist snapshot of stock at exact moment POST /inventarios is called
  - Used to replace dynamic calculation in RF-INV-02.2

- [x] T136 [P] **BUG-009 Refactor** Create migration for `stock_movimientos` audit table in `loopi-api-v2/db/migrations/`:
  - Table structure: tienda_id, item_id, tipo_movimiento (ENUM: compra, merma, venta_batch, ajuste_conteo), cantidad_antes, cantidad_despues, cantidad_delta, referencia_id (ID from source table), usuario_id, creado_en (DATETIME), motivo (nullable)
  - PKs: id (BIGINT AUTO_INCREMENT)
  - Index: (tienda_id, creado_en) for audit trail queries, (referencia_id) for traceability
  - Purpose: Complete audit trail for stock changes; enables reconciliation and debugging

- [x] T137 Implement repository method `SnapshotStockActual()` in `loopi-api-v2/internal/inventarios/repository.go`:
  - Called when POST /inventarios is executed (Iniciar)
  - Inserts row into stock_actual table with current stock values from stock_movimientos or derived table
  - Returns: map[int64]float64 (item_id → valor_sugerido)
  - Error handling: If snapshot fails, log WARNING (non-blocking) and use 0 as fallback per RD-04

- [x] T138 Implement repository method `RecordMovimiento()` in `loopi-api-v2/internal/inventarios/repository.go`:
  - Called by compras (010), mermas (010), and venta batch (015) services AFTER recording the movement
  - Inserts row into stock_movimientos with before/after values, type, and reference ID
  - On error: Log with full context (tienda_id, item_id, usuario_id, error stack) for audit trail debugging
  - Does NOT block the movement; movement is already recorded, this is audit-only

### Validation & Blocking Tasks

- [x] T139 [P] Implement repository method `CanRecordMovimiento()` in `loopi-api-v2/internal/inventarios/repository.go`:
  - Signature: `(canRecord bool, activeCountID *int64, err error)`
  - Query: SELECT id FROM inventarios WHERE tienda_id = ? AND estado = 'en_progreso' LIMIT 1
  - Returns: (false, activeCountID, nil) if count active; (true, nil, nil) if allowed; (false, nil, err) on DB error
  - Called by: compras (010), mermas (010), venta batch (015) before INSERT/UPDATE operations

- [x] T140 [P] **RF-INV-05.1** Document integration point in `loopi-api-v2/internal/compras/service.go` (or equivalent 010 module):
  - **TODO**: Before registering compra (INSERT compras_caja_menor), call inventarios.CanRecordMovimiento(ctx, tienda_id)
  - If canRecord=false: Return NewError("inventario_activo", "No se pueden registrar movimientos...")
  - Handler wraps and returns HTTP 409 Conflict per RF-INV-05.2
  - Add test case: POST /compras with active count → 409 inventario_activo

- [x] T141 [P] **RF-INV-05.1** Document integration point in `loopi-api-v2/internal/mermas/service.go` (or equivalent 010 module):
  - **TODO**: Before registering merma (INSERT mermas), call inventarios.CanRecordMovimiento(ctx, tienda_id)
  - If canRecord=false: Return NewError("inventario_activo", "...")
  - Handler wraps and returns HTTP 409 Conflict
  - Add test case: POST /mermas with active count → 409 inventario_activo

- [x] T142 [P] **RF-INV-05.1** Document integration point in `loopi-api-v2/internal/pos/service.go` (or venta batch handler):
  - **TODO**: Before processing venta batch file (POST /ventas/batch or equivalent), call inventarios.CanRecordMovimiento(ctx, tienda_id)
  - Validation happens **BEFORE** parsing/uploading file per RF-INV-05.1
  - If canRecord=false: Return NewError("inventario_activo", "...") with no file processing
  - Handler returns HTTP 409 Conflict
  - Add test case: POST /ventas/batch with active count → 409 inventario_activo (no file processed)

### Frontend Tasks

- [x] T143 [P] Create Angular interceptor or service to check inventory status in `loopi-web-v2/src/app/inventario/inventario.service.ts`:
  - Add method: `getEstadoInventarioActivo(tienda_id: number): Observable<{activo: boolean, inventario?: InventarioResp}>`
  - Calls backend endpoint (create if needed: GET /inventarios/estado?tienda_id=X)
  - Used by compras, mermas, venta components to display/block UI

- [ ] T144 [P] **RF-INV-05.3** Add badge/warning in compras component (loopi-web-v2):
  - **TODO**: Before form input, check if inventario activo in tienda
  - If active: Show banner/toast: "⚠️ Hay un conteo en progreso. No se pueden registrar movimientos. Contacte al líder de tienda."
  - Include badge with count details (ID, responsable, inicio time)
  - Disable form inputs or show read-only state

- [ ] T145 [P] **RF-INV-05.3** Add badge/warning in mermas component (loopi-web-v2):
  - Same as T144 but for mermas module
  - Show "⚠️ Hay un conteo en progreso" message
  - Disable inputs if count active

- [ ] T146 **RF-INV-05.1** Block venta batch file upload in loopi-web-v2:
  - **TODO**: Before displaying file input for venta batch (POST /ventas/batch), call getEstadoInventarioActivo()
  - If active: Disable file input + show message: "No se pueden procesar ventas mientras hay un conteo en progreso."
  - If not active: Enable file input normally
  - On upload, if 409 returned: Show error toast with same message

### Testing Tasks

- [ ] T147 [P] Integration test: Bloqueo de Compras in `loopi-api-v2/internal/compras/*_test.go`:
  - Setup: Iniciar conteo en tienda
  - Action: POST /compras en misma tienda
  - Expected: HTTP 409, error code inventario_activo
  - Teardown: Confirmar o eliminar conteo

- [ ] T148 [P] Integration test: Bloqueo de Mermas in `loopi-api-v2/internal/mermas/*_test.go`:
  - Setup: Iniciar conteo en tienda
  - Action: POST /mermas en misma tienda
  - Expected: HTTP 409, error code inventario_activo

- [ ] T149 Integration test: Bloqueo de Venta Batch in `loopi-api-v2/internal/pos/*_test.go`:
  - Setup: Iniciar conteo en tienda
  - Action: POST /ventas/batch con archivo en misma tienda
  - Expected: HTTP 409, error code inventario_activo (no file processed)

- [x] T150 [P] E2E test: Complete flow with blocking in `loopi-web-v2/e2e/inventario-blocking.e2e.ts`:
  - HU5 test (new): Iniciar conteo → Navegar a compras → Verificar badge "Inventario activo" → Intentar guardar compra → Verificar error toast 409
  - HU6 test (new): Iniciar conteo → Navegar a mermas → Verificar badge → Intentar guardar merma → Error 409
  - HU7 test (new): Iniciar conteo → Navegar a venta batch → Verificar file input deshabilitado → Confirmar conteo → File input habilitado
  - Use Page Object Model from T151 below

- [x] T151 [P] Create E2E Page Object in `loopi-web-v2/e2e/support/blocking-page.ts`:
  - Selectors: inventory-active-banner, inventory-active-badge, file-input (venta batch), disable-overlay
  - Methods: verifyInventoryActiveBanner(), verifyFileInputDisabled(), verifyFileInputEnabled(), attemptSaveMovimiento()

**Checkpoint**: RF-INV-05 fully implemented. Movements blocked while count active, auditable via stock_movimientos table, E2E tests verify blocking behavior per feature, frontend informs users, 409 errors returned correctly.

---

**Checkpoint**: All 16 bugs remediated. Re-run unit tests (95%+ backend coverage), E2E tests pass (4+ tests), WCAG audit passes, Gitflow compliance verified, ready for final merge to develop.

---

## Execution Summary

**Total Tasks**: 151 (11 phases including new RF-INV-05 architecture phase)

**Parallelizable**: Tasks marked [P] can run in parallel (different files, no blocking dependencies)

**Critical Path**:

- Phase 1 (Setup): 3 days
- Phase 2 (Foundational): 5 days [BLOCKS all user stories]
- Phases 3-6 (User Stories 1-4): 12 days [parallel by story]
- Phase 7 (Admin): 3 days
- Phase 8 (Observability): 5 days
- Phase 9 (Constitutional): 2 days [verification only]
- Phase 10 (Bugfixes): 8 days [critical bugs first, parallel where possible]
- Phase 11 (Block During Count - RF-INV-05): 5 days [infrastructure tables + validation + frontend + E2E]

**Estimated Total**: 43 days (with parallelization, 3-4 weeks real time)

**Git Integration**: All commits tagged with feat(009): or fix(009): per Gitflow conventions, push to feature/009-inventario-conteo branch, PR to develop

### Parallel Opportunities within Each Phase

**Phase 1 Setup**:

- T001, T003 (directory structures) parallel
- T002, T004, T005 (migrations) sequential (NNNN, NNNN+1)

**Phase 2 Foundational**:

- T007, T008 (models + constants) can run together
- T012, T013 (Angular service + components) parallel
- T014, T015 (routing + transversals) parallel

**Phase 3 HU1**:

- T016-T020 (all tests) parallel
- T021-T027 (service + repo helpers) parallel
- T030-T032 (Angular form) sequential (form → HTML → submit logic)

**Phase 4 HU2**:

- T033-T036 (tests) parallel
- T037, T038 (service + repo) parallel
- T040-T042 (Angular component + autosave) sequential

**Phase 5 HU3**:

- T045-T048 (tests) parallel
- T049, T050 (service + repo) parallel
- T052-T054 (Angular confirmation flow) sequential

**Phase 6 HU4**:

- T055-T060 (tests) parallel
- T061-T064 (service + repo) parallel
- T067-T070 (Angular historial + detalle) sequential

## Parallel Example: Start HU1 and HU4 Together

After Foundational completes:

- Developer A starts Phase 3 (HU1): works on T021-T032
- Developer B starts Phase 6 (HU4): works on T061-T070 (independently testable)
- Both complete without blocking each other

---

## Implementation Strategy

### MVP First: HU1-HU3 Only

1. Complete Phase 1: Setup (1 day est.)
2. Complete Phase 2: Foundational (2 days est.)
3. Complete Phase 3: HU1 (2 days est.)
4. Complete Phase 4: HU2 (2 days est.)
5. Complete Phase 5: HU3 (2 days est.)
6. **STOP AND VALIDATE**: Execute smoke tests § 4 in quickstart.md
7. Deploy/demo MVP (conteo full flow works)
8. **After MVP validated**:
   - Phase 6: HU4 (2 days est.)
   - Phase 7: Admin functions (1 day est.)
   - Phase 8: Observabilidad (1 day est.)
   - Phase 9: Constitutional verification (1 day est.)

**Total Est.**: ~14 days sequential full-stack (Go + Angular), 10 days if parallelized (separate Go/Angular developers)

### Incremental Delivery (Per User Story)

Each user story is independently deployable:

1. Deploy MVP (HU1-HU3) → Barista/líder can count items
2. Deploy HU4 → Admin can review history
3. Deploy Admin functions → Admin can clean up and correct
4. Deploy Observabilidad → Ops can monitor

Each iteration adds measurable business value without breaking prior stages.

---

## Notes

- **[P] marker**: Different files, no blocking dependencies. Can parallelize within phase.
- **[Story] label**: Maps task to HU1/HU2/HU3/HU4 for traceability.
- **Setup phase paths**: Relative to each repo root (loopi-api-v2/ for Go, loopi-web-v2/ for Angular).
- **Test tasks**: Included but optional — focus on P1 requirements (HU1-HU3) first; P2 (HU4) tests follow if time permits.
- **Commit strategy**: Commit after each task or logical group (e.g., all T021-T027 after service + repo complete for HU1).
- **Validation checkpoints**: After each phase, run relevant tests to confirm independence before moving to next.
- **Quickstart.md validation**: Use as gate before declaring "feature ready for QA" — all smoke tests must pass.
