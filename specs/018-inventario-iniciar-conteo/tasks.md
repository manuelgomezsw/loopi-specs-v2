# Implementation Tasks: 018 — Iniciar Conteo de Inventario

**Feature**: 018-inventario-iniciar-conteo | **Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

**Type**: Backend (Go) + Frontend (Angular) migration from monolith (009) to sub-domain architecture (BE-ARCH-02)

**Scope**: Extract existing functionality from 009's monolithic handler/service/repository into new sub-domain structure `internal/inventarios/iniciar/` (backend) and `iniciar-conteo.component.ts` (frontend).

---

## Phase 0: Setup & Prerequisites

### Governance

- [ ] T001 Constitutional amendment BE-ARCH-02 merged to `develop` in loopi-specs-v2 (defines sub-domain architecture)
- [ ] T002 Sync loopi-api-v2/CLAUDE.md with updated standards/backend.md v1.1.0 (BE-ARCH-02 section)
- [ ] T003 Verify branch `feature/018-inventario-iniciar-conteo` created from `develop` (Gitflow CI-01)

### Pre-Implementation Gate

- [ ] T004 Run `go test ./internal/inventarios/... -v` in loopi-api-v2 to establish baseline (009's monolithic tests must pass)
- [ ] T005 Run `npm run test:unit` in loopi-web-v2 to establish baseline (existing components)

---

## Phase 1: Backend Architecture — Extract & Structure

**Goal**: Refactor `internal/inventarios/` from monolith (single handler/service/repository) to sub-domain structure, starting with `iniciar/` sub-package. All tests must pass after each task.

### Create Sub-Domain Directory & Core Shared Layer

- [ ] T006 Create directory structure: `internal/inventarios/core/`, `internal/inventarios/iniciar/` (with placeholder `handler.go`, `service.go`, `repository.go`)
- [ ] T007 Create `internal/inventarios/core/models.go` with shared types: `Inventario`, `DetalleInventario` (migrated from current `models.go`)
- [ ] T008 Create `internal/inventarios/core/repository.go` interface with placeholder methods for `SnapshotStockActual()`, `GetInventarioDetalle()`, `CanRecordMovimiento()`, `RecordMovimiento()`

### Migrate Handler Layer

- [ ] T009 [P] Extract `POST /api/v1/inventarios` handler logic from current `internal/inventarios/handler.go` → `internal/inventarios/iniciar/handler.go`
- [ ] T010 [P] Update handler to call `iniciar/service.Service` (not monolith service); wire dependency injection in `main.go`
- [ ] T011 [P] Create `internal/inventarios/iniciar/handler_test.go` with httptest + mock service (test HTTP contracts: 200, 201, 409, 422 responses)

### Migrate Service Layer

- [ ] T012 Extract service logic for "iniciar conteo" from current `internal/inventarios/service.go` → `internal/inventarios/iniciar/service.go`:
  - Type determination algorithm (`DeterminarTipo()` method)
  - Time-based horario suggestion (`SugererirHorario()`)
  - Inventory initialization (`Iniciar()` orchestrator method)
- [ ] T013 [P] Implement `iniciar/service.Service` interface calling `core/repository.go` methods for shared data (SnapshotStockActual)
- [ ] T014 [P] Create `internal/inventarios/iniciar/service_test.go` with mock `Repository` interface (≥95% coverage):
  - Test type determination: primer conteo → `inicial`; conteos posteriores → user-selected type
  - Test horario suggestion: 06:00-10:59 → `apertura`; 11:00-14:59 → `mediodía`; 15:00-23:59 → `cierre`
  - Test duplicate validation: same tienda/tipo/fecha/horario → returns error
  - Test without items of selected frequency → returns 422 `sin_items_contabilizar`

### Migrate Repository Layer (Iniciar)

- [ ] T015 [P] Extract iniciar-specific SQL from current `internal/inventarios/repository.go` → `internal/inventarios/iniciar/repository.go`:
  - `CreateInventario(ctx, tiendaID, tipo, horario, responsableID) (*Inventario, error)` — INSERT into `inventarios`
  - `GetItemsActivosPorTipo(ctx, tiendaID, tipo) ([]*Item, error)` — SELECT from `items` filtered by `frecuencia_inventario`
  - `ValidarDuplicado(ctx, tiendaID, tipo, horario, fecha) error` — check UNIQUE (tienda_id, tipo, horario, fecha) in `inventarios`
- [ ] T016 [P] Create `internal/inventarios/iniciar/repository.go` with concrete implementation using `*sql.DB`
- [ ] T017 [P] Create `internal/inventarios/iniciar/repository_test.go` with `go-sqlmock` (≥90% coverage):
  - Test CreateInventario success path (INSERT + SELECT for returned entity)
  - Test CreateInventario duplicate error (409 conflict)
  - Test GetItemsActivosPorTipo returns correct items filtered by type
  - Test ValidarDuplicado returns error on duplicate detection

### Migrate Core Shared Methods

- [ ] T018 Move `SnapshotStockActual()` from monolith repository → `internal/inventarios/core/repository.go` (used by iniciar + completar/020)
- [ ] T019 Create concrete implementation of `core/repository.go` interface with SQL for:
  - `SnapshotStockActual(ctx, tiendaID)` — SELECT cantidad FROM `stock_actual` for all items in tienda
  - Placeholder methods for `GetInventarioDetalle()`, `CanRecordMovimiento()`, `RecordMovimiento()` (to be filled by 019-023)
- [ ] T020 Create `internal/inventarios/core/repository_test.go` with `go-sqlmock` for SnapshotStockActual (≥90% coverage)

### Wiring & Integration

- [ ] T021 Update `main.go` to wire new sub-domain:
  - Create `iniciar.NewRepository(db)`
  - Create `core.NewRepository(db)` and pass to iniciar service via dependency injection
  - Create `iniciar.NewService(repo, coreRepo)`
  - Create `iniciar.NewHandler(service)`
  - Register handler on router
- [ ] T022 Run `go test ./internal/inventarios/... -v` and verify all tests pass (including migrated tests from 009)
- [ ] T023 Run `go build ./...` and verify no compile errors
- [ ] T024 Run `golangci-lint run` and verify no linter violations
- [ ] T025 Run `go test ./internal/inventarios/... -cover` and verify ≥95% service coverage, ≥90% repository coverage

---

## Phase 2: Observability — Instrumentation (BE-OBS-01)

**Goal**: Implement OpenTelemetry spans and metrics per spec section "Observabilidad".

### Spans (OTel)

- [ ] T026 [P] Add span instrumentation to `iniciar/handler.go`:
  - Span name: `inventario.iniciar.crear` with attributes `resultado` (success/validation_error/conflict), `tienda_id`
- [ ] T027 [P] Add span instrumentation to `iniciar/service.go`:
  - Span `inventario.iniciar.determinar_tipo` with attributes `resultado`, `tienda_id`, `tipo_determinado`
  - Span `inventario.iniciar.cargar_items` with attributes `resultado`, `tienda_id`, `cantidad_items`, `tipo`

### Metrics

- [ ] T028 [P] Implement histogram metric `inventario.iniciar.crear.duration` (ms) with labels `resultado`, `tienda_id`
- [ ] T029 [P] Implement counter metric `inventario.iniciar.crear.total` with labels `resultado`, `tienda_id`
- [ ] T030 [P] Implement histogram metric `inventario.iniciar.cargar_items.duration` (ms) with labels `resultado`, `tienda_id`, `tipo`
- [ ] T031 [P] Implement gauge metric `inventario.iniciar.items_cargados.size` (count) with label `tienda_id`

### Verification

- [ ] T032 Run `go test ./internal/inventarios/iniciar/... -v` to verify spans/metrics don't break tests
- [ ] T033 Manual test: POST to `/api/v1/inventarios` and verify traces appear in Datadog APM (if stage available)

---

## Phase 3: Frontend — Extract & Migrate Angular Component

**Goal**: Extract monolithic `inventario-conteo.component.ts` UI logic into new dedicated `iniciar-conteo.component.ts`.

### Component Structure

- [ ] T034 Create `src/app/inventario/iniciar-conteo/` directory with component scaffold
- [ ] T035 Create `iniciar-conteo.component.ts`:
  - Import form builder, reactive forms
  - Define form: `tipoSeleccionado` (radio/select), `horarioSugerido` (readonly display)
  - Bind to `inventario-api.service` for POST `/api/v1/inventarios`
- [ ] T036 Create `iniciar-conteo.component.html` (3-layer layout):
  - Header: "Iniciar Conteo", tienda actual, fecha actual
  - Form section: tipo selector with suggestion, horario display, "Iniciar" button
  - Items preview: readonly table (items a contar con valor_esperado)
- [ ] T037 Create `iniciar-conteo.component.scss` responsive (Tailwind v4 + custom styles if needed)

### Service & API Client

- [ ] T038 Create `inventario/core/inventario-api.service.ts` (extracted from monolith `inventario.service.ts`):
  - Method `iniciarConteo(tiendaID, tipo)` → POST `/api/v1/inventarios`
  - Method `obtenerItems(inventarioID, tipo)` → GET `/api/v1/inventarios/{id}/items`
  - Error mapping via `error-mapper.service.ts`
- [ ] T039 [P] Update `iniciar-conteo.component.ts` to use `inventario-api.service`
- [ ] T040 Wire navigation: after successful POST, redirect to `/inventario/:id/realizar` (feature 019 future route)

### State & Recovery

- [ ] T041 Implement session recovery in `iniciar-conteo.component`:
  - On component init, check `sessionStorage` for abandoned conteo_id
  - If exists and status = `en_progreso`, prompt user to resume (→ realizar-conteo) or start new
- [ ] T042 On successful POST, store `inventarioID` in `sessionStorage` (recovery key)

### Testing

- [ ] T043 Create `iniciar-conteo.component.spec.ts`:
  - Unit test: form submission calls service
  - Unit test: API error maps to user-friendly message
  - Unit test: horario suggestion logic (time-based)
  - Integration test: POST response updates component state
- [ ] T044 Run `npm run test:unit` and verify ≥90% coverage for iniciar-conteo component
- [ ] T045 Manual test in browser: fill form, submit, verify redirection to `/inventario/:id/realizar` (or error handling if items list empty)

### Accessibility & Responsiveness

- [ ] T046 [P] Verify component meets WCAG 2.1 AA (FE-A11Y-01):
  - Labels on form inputs, ARIA roles on buttons
  - Focus visible on form fields
  - Error messages announced via aria-live
- [ ] T047 [P] Verify responsive layout (FE-RESP-01):
  - Mobile (<640px): stack vertically, buttons full-width
  - Tablet (640px-1024px): 2-column layout
  - Desktop (>1024px): 3-column with sidebar

---

## Phase 4: Integration Testing & Migration Verification

**Goal**: Verify entire feature works end-to-end and doesn't break existing functionality.

### Backend Integration

- [ ] T048 Run complete backend test suite: `go test ./... -v` in loopi-api-v2 (all tests ≥ baseline)
- [ ] T049 Run gates: `golangci-lint run`, `govulncheck ./...`, `gitleaks detect --no-git`
- [ ] T050 Verify no SQL regressions: spot-check queries in router test with real conteo workflow

### Frontend Integration

- [ ] T051 Run complete frontend test suite: `npm run test:unit` in loopi-web-v2 (all tests ≥ baseline)
- [ ] T052 Build frontend: `npm run build` and verify no TypeScript errors
- [ ] T053 Manual E2E in browser:
  - Log in as lider_tienda
  - Navigate to Inventario > Iniciar
  - Fill form, submit
  - Verify conteo created in DB (check `inventarios` table)
  - Verify items loaded correctly (cross-check `stock_actual`)
  - Verify error handling: try duplicate tienda/tipo/fecha → 409 error
  - Verify "sin items" error: select frequency with zero items → 422

### Markdown & Documentation

- [ ] T054 Run `npx markdownlint-cli2 "specs/018/**/*.md"` and fix any linting errors
- [ ] T055 Update spec.md if any ambiguities arose during implementation (e.g., edge case behavior clarification)

---

## Phase 5: Pre-Merge Verification

**Goal**: Prepare PR for merge to `develop`.

### Code Review Checklist

- [ ] T056 Self-review: verify commit message format, no unnecessary files, clean git history
- [ ] T057 Verify Constitution Check (plan.md) — all P-*, BE-*, FE-* marked ✅ with no violations
- [ ] T058 Verify Architecture Check (BE-ARCH-01 and BE-ARCH-02):
  - Handler has NO SQL, NO service calls except to service
  - Service has NO SQL, NO *sql.DB imports
  - Repository has ALL SQL, properly parameterized
  - Core methods shared by 2+ consumers (if not yet, leave in sub-domain)

### Pre-Push Gates

- [ ] T059 Run markdownlint on all specs: `npx markdownlint-cli2 "**/*.md"`
- [ ] T060 Run backend gate: `go test ./... -v` (100% pass)
- [ ] T061 Run frontend gate: `npm run test:unit` (100% pass)
- [ ] T062 Run `git log --oneline feature/018-inventario-iniciar-conteo ^develop` and verify clean, logical commits

### PR Creation

- [ ] T063 Open PR to `develop`:
  - Title: `feat(018): migrar iniciar-conteo hacia sub-dominio`
  - Body: link to spec.md, describe what moved, reference plan.md
  - Assign reviewers (backend + frontend pairs)

---

## Phase 6: Post-Merge Checkpoint

**Goal**: Stabilize feature in `develop` before moving to 019.

### Deployment & Monitoring

- [ ] T064 Merge PR to `develop` after approval
- [ ] T065 Verify CI/CD runs green on merged branch
- [ ] T066 (Optional, if staging available) Deploy to staging and run smoke tests:
  - POST /api/v1/inventarios with valid payload
  - Verify response in Datadog APM (traces visible)
  - Verify metrics emitted (counters/histograms)
- [ ] T067 (Optional) Alert oncall that 018 (iniciar) is now live in staging

### Readiness for Next Phase (019)

- [ ] T068 Verify feature 019 (realizar-conteo) can cleanly depend on 018:
  - Call 018's core methods: `GetInventarioDetalle()` from `core/repository.go`
  - Call 018's handler to verify inventory exists before starting realizar
- [ ] T069 Document any lessons learned or architectural adjustments in `plan.md` for 019+

---

## MVP Scope & Parallel Opportunities

**Recommended MVP** (for first release):

- Phase 0 ✅ Setup & gates
- Phase 1 ✅ Backend handler/service/repository migration
- Phase 2 ✅ Observability wiring
- Phase 3 ✅ Frontend component
- Phase 4 ✅ Integration testing

**Parallelizable Tasks** (can run simultaneously once Phase 0 complete):

- T009–T011 (handler) + T012–T014 (service) — both don't depend on each other's completion, only on T006–T008
- T015–T017 (iniciar repository) + T018–T020 (core repository) — independent SQL layers
- T026–T033 (backend observability) can start once T025 passes
- T034–T047 (frontend component) can start once T021 wiring complete (backend API contract stable)

---

## Success Criteria (Feature-Level)

Upon completion of this task list:

✅ **Feature 018 (Iniciar Conteo)** runs independently as a sub-domain within `internal/inventarios/`
✅ All code migrated from 009's monolith with zero behavioral changes
✅ All tests passing: backend ≥95% service coverage, ≥90% repository coverage; frontend ≥90% component coverage
✅ Observability wired: spans + metrics emitted to Datadog
✅ Frontend component responsive, accessible (WCAG 2.1 AA), fully functional
✅ Feature ready for Phase 5: 019-inventario-realizar-conteo (feature 019)

---

## Known Constraints & Deferred Items

- **BE-ARCH-02 compliance**: This feature demonstrates sub-domain pattern but doesn't yet show "second consumer" triggering core promotion. Core methods (`SnapshotStockActual`, `GetInventarioDetalle`) will be consumed by features 020–023 as they're implemented.
- **Frontend routing**: Navigation to `/inventario/:id/realizar` assumes feature 019 route exists. May require placeholder route during implementation.
- **Database schema**: Assumes `inventarios`, `detalle_inventario`, `stock_actual`, `items`, `tiendas`, `empleados` tables already exist (created by 009). No migrations generated by this task list.
