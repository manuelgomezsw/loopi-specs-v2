# Tasks: Gestión de Tiendas

**Input**: Design documents from `/specs/002-gestion-tiendas/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/api-tiendas.md ✅

**Tests**: No solicitados en el spec — no se incluyen tareas de prueba.

**Organización**: Tareas agrupadas por historia de usuario para implementación y prueba independiente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencias incompletas)
- **[Story]**: Historia de usuario a la que pertenece (US1–US4, mapeado al spec)
- Paths relativos a la raíz del repositorio correspondiente (`loopi-api-v2/` o `loopi-web-v2/`)

## Path Conventions

- **Backend**: `loopi-api-v2/internal/tiendas/`, `loopi-api-v2/migrations/`, `loopi-api-v2/cmd/api/`
- **Frontend**: `loopi-web-v2/src/app/tiendas/`

---

## Phase 0: Prerequisitos

**Propósito**: Verificar que las dependencias de features anteriores están disponibles antes de
comenzar cualquier trabajo.

- [ ] T000 Verificar que `loopi-api-v2/internal/middleware/auth.go` existe y exporta
  `JWTMiddleware` — provisto por feature `001-autenticacion`. Si no existe, coordinar con
  feature 001 antes de continuar. Bloquea Phase 2.

---

## Phase 1: Setup (Estructura de módulos)

**Propósito**: Crear directorios y archivos vacíos que dan forma al módulo en ambos proyectos.

- [ ] T001 Crear directorio `loopi-api-v2/internal/tiendas/` con archivos vacíos: `model.go`, `repository.go`, `service.go`, `handler.go`
- [ ] T002 [P] Crear directorios `loopi-web-v2/src/app/tiendas/tiendas-lista/` y `loopi-web-v2/src/app/tiendas/tienda-form/`

---

## Phase 2: Foundacional (Prerequisitos bloqueantes)

**Propósito**: Infraestructura base que DEBE completarse antes de cualquier historia de usuario.

**⚠️ CRÍTICO**: Ningún trabajo de historia de usuario puede comenzar hasta completar esta fase.

- [ ] T003 Escribir `loopi-api-v2/migrations/002_tiendas.up.sql`: CREATE TABLE tiendas con todos los campos de data-model.md (id BIGINT UNSIGNED PK, codigo VARCHAR(20) NOT NULL, nombre VARCHAR(150) NOT NULL, direccion, ciudad, telefono, activo TINYINT(1) DEFAULT 1, creado_por, creado_en, actualizado_por, actualizado_en DATETIME); índices uq_tiendas_codigo, uq_tiendas_nombre (collation utf8mb4_unicode_ci), idx_tiendas_activo; FK a usuarios para campos de auditoría
- [ ] T004 [P] Escribir `loopi-api-v2/migrations/002_tiendas.down.sql`: DROP TABLE IF EXISTS tiendas
- [ ] T005 [P] Implementar `loopi-api-v2/internal/tiendas/model.go` con structs: Tienda (tags `db:`), TiendaRequest, TiendaUpdateRequest (sin campo Codigo), TiendaResponse (tags `json:`), ListaTiendasResponse (Datos []TiendaResponse, Total, Pagina, Limite int) — tipos según data-model.md
- [ ] T006 Implementar interfaz `TiendaRepository` e implementación MySQL con sqlx en `loopi-api-v2/internal/tiendas/repository.go`: métodos Crear, ObtenerPorID, Listar (filtro activo, ORDER BY nombre ASC, LIMIT/OFFSET + count query), Actualizar, CambiarActivo (depends on T005)
- [ ] T007 Implementar interfaz `TiendaService` y struct `tiendaService` con inyección de TiendaRepository en `loopi-api-v2/internal/tiendas/service.go`; stub de métodos que compilará vacío (depends on T006)
- [ ] T008 Crear `loopi-api-v2/internal/tiendas/handler.go` con struct `TiendaHandler`, constructor `NewTiendaHandler(svc TiendaService)` y método `RegisterRoutes(r chi.Router)` que declara los 6 endpoints bajo `/api/v1/tiendas` (depends on T007)
- [ ] T009 [P] Crear `loopi-web-v2/src/app/tiendas/tiendas.service.ts` como servicio Angular injectable con HttpClient; declarar firmas de 6 métodos: `listar()`, `obtener()`, `crear()`, `actualizar()`, `inactivar()`, `reactivar()` — retornando `Observable<any>` como stub

**Checkpoint**: `go build ./...` pasa. Estructura frontend generada. Historias de usuario pueden comenzar.

---

## Phase 3: Historia de Usuario 4 — Ver el listado de tiendas (Prioridad: P1) 🎯 MVP

**Goal**: El admin ve todas las tiendas con filtro por estado (Todas/Activas/Inactivas), orden por nombre y estado vacío cuando no hay registros.

**Independent Test**: `GET /api/v1/tiendas` con JWT admin retorna `{"datos":[],"total":0,"pagina":1,"limite":50}`. La UI Angular muestra el mensaje de estado vacío.

- [ ] T010 [US4] Implementar método `Listar` en `loopi-api-v2/internal/tiendas/repository.go`: query SELECT con WHERE activo filtrable (`"todas"` omite filtro), ORDER BY nombre ASC, LIMIT/OFFSET; query COUNT separada para el total paginado (depends on T006)
- [ ] T011 [US4] Implementar método `Listar` en `loopi-api-v2/internal/tiendas/service.go`: valida estado ∈ {`"todas"`, `"activas"`, `"inactivas"`} (400 si inválido), pagina ≥ 1, limite entre 1 y 100 (default 50); llama repository.Listar; retorna ListaTiendasResponse (depends on T007, T010)
- [ ] T012 [US4] Implementar handler `GET /api/v1/tiendas` en `loopi-api-v2/internal/tiendas/handler.go`: extrae query params (estado, pagina, limite), valida JWT claim rol=admin (403 si no), llama service.Listar, serializa ListaTiendasResponse JSON 200; log estructurado JSON con user_id, rol, operacion="listar_tiendas", duracion_ms, status_http (depends on T008, T011)
- [ ] T013 [P] [US4] Implementar método `listar(estado: string, pagina: number, limite: number): Observable<ListaTiendasResponse>` en `loopi-web-v2/src/app/tiendas/tiendas.service.ts` que llama `GET /api/v1/tiendas` con HttpParams
- [ ] T014 [P] [US4] Crear `loopi-web-v2/src/app/tiendas/tiendas-lista/tiendas-lista.component.ts`: componente standalone; Signal `tiendas` y Signal `filtroEstado`; llama `tiendas.service.listar()` en ngOnInit; al cambiar filtro relanza la consulta; maneja estado vacío cuando total=0 (RF-TDA-04.4)
- [ ] T015 [US4] Crear `loopi-web-v2/src/app/tiendas/tiendas-lista/tiendas-lista.component.html`: tabla Tailwind con columnas nombre, codigo, ciudad, estado (activa/inactiva); selector de filtro Todas / Activas / Inactivas; bloque de estado vacío con mensaje que invita a crear la primera tienda; enlace a crear tienda (depends on T014)
- [ ] T016 [US4] Registrar ruta `/tiendas` en `loopi-web-v2/src/app/app.routes.ts` apuntando a `TiendasListaComponent` con lazy loading; agregar enlace a tiendas en la navegación del admin (depends on T015)

**Checkpoint**: `GET /api/v1/tiendas` operacional. Listado Angular muestra tiendas y estado vacío.

---

## Phase 4: Historia de Usuario 1 — Crear una tienda nueva (Prioridad: P1)

**Goal**: El admin crea una tienda con todos sus campos. El sistema normaliza `codigo` a mayúsculas y rechaza nombre o código duplicado con mensaje específico por campo.

**Independent Test**: `POST /api/v1/tiendas` con body válido retorna 201 + TiendaResponse con activo=true. Segunda llamada con mismo nombre retorna 409 con `error="nombre_duplicado"`.

- [ ] T017 [US1] Implementar método `Crear` en `loopi-api-v2/internal/tiendas/repository.go`: INSERT INTO tiendas con todos los campos; detecta error MySQL 1062 y retorna error tipado indicando si es conflicto de `codigo` o de `nombre` (usa constraint name del error) (depends on T006)
- [ ] T018 [US1] Implementar método `Crear` en `loopi-api-v2/internal/tiendas/service.go`: normaliza `codigo` a mayúsculas con `strings.ToUpper`; establece `creado_en` y `actualizado_en` con `time.Now().In(loc)` (loc=America/Bogota); asigna `creado_por` y `actualizado_por` desde el claim `user_id` del JWT; mapea error 1062 a `{"error":"nombre_duplicado",...}` o `{"error":"codigo_duplicado",...}` según campo afectado (depends on T017)
- [ ] T019 [US1] Implementar handler `POST /api/v1/tiendas` en `loopi-api-v2/internal/tiendas/handler.go`: decodifica TiendaRequest, valida campos requeridos (400 con campo si falta alguno), extrae user_id del JWT, llama service.Crear; retorna 201 + TiendaResponse o 409 + error JSON; log estructurado con operacion="crear_tienda" (depends on T008, T018)
- [ ] T020 [P] [US1] Implementar método `crear(req: TiendaRequest): Observable<TiendaResponse>` en `loopi-web-v2/src/app/tiendas/tiendas.service.ts` que llama `POST /api/v1/tiendas`
- [ ] T021 [P] [US1] Crear `loopi-web-v2/src/app/tiendas/tienda-form/tienda-form.component.ts`:
  componente standalone; ReactiveForm con campos codigo, nombre, direccion, ciudad, telefono
  (todos required); todos los campos con `<label>` explícito asociado (WCAG 2.1 AA,
  constitución §Accesibilidad); validación on-blur por campo + validación completa on-submit
  (constitución §Formularios); botón Guardar con `disabled` + texto "Guardando..." durante el
  envío (constitución §Formularios); errores de campo: `border-red-500` + texto `text-red-600`
  debajo del campo con el mensaje del campo `campo` del error API (RF-TDA-07.2); errores de
  API 4xx: toast no intrusivo esquina superior derecha, auto-cierre 5 s (constitución §Errores
  UI); al crear exitoso: toast verde "Tienda creada correctamente." auto-cierre 3 s y navega
  al listado (RF-TDA-07.1)
- [ ] T022 [US1] Crear `loopi-web-v2/src/app/tiendas/tienda-form/tienda-form.component.html`: formulario Tailwind con etiquetas y campos; botón Guardar; banner de éxito/error; agregar ruta `/tiendas/nueva` en `app.routes.ts` apuntando a `TiendaFormComponent` en modo creación (depends on T021)

**Checkpoint**: Flujo crear tienda operacional end-to-end. Nueva tienda aparece en el listado (HU4).

---

## Phase 5: Historia de Usuario 2 — Editar los datos de una tienda (Prioridad: P1)

**Goal**: El admin edita nombre, dirección, ciudad y teléfono de una tienda. El campo `codigo` se muestra como solo lectura y nunca se actualiza, aunque llegue en el body.

**Independent Test**: `PUT /api/v1/tiendas/1` con body válido retorna 200 + TiendaResponse con campo `codigo` intacto. `PUT` con nombre de otra tienda retorna 409.

- [ ] T023 [US2] Implementar métodos `ObtenerPorID` y `Actualizar` en `loopi-api-v2/internal/tiendas/repository.go`: SELECT por id; UPDATE tiendas SET nombre, direccion, ciudad, telefono, actualizado_por, actualizado_en WHERE id — nunca actualiza `codigo`; detecta error MySQL 1062 para nombre duplicado en update (depends on T006)
- [ ] T024 [US2] Implementar métodos `ObtenerPorID` y `Actualizar` en `loopi-api-v2/internal/tiendas/service.go`: ObtenerPorID retorna 404 si no existe; Actualizar ignora campo `Codigo` del TiendaUpdateRequest aunque venga; establece `actualizado_en` y `actualizado_por`; mapea error 1062 a `{"error":"nombre_duplicado",...}` (depends on T023)
- [ ] T025 [US2] Implementar handlers `GET /api/v1/tiendas/{id}` y `PUT /api/v1/tiendas/{id}` en `loopi-api-v2/internal/tiendas/handler.go`: extrae id del path con `chi.URLParam`; valida JWT rol=admin; GET retorna 200 + TiendaResponse; PUT decodifica TiendaUpdateRequest, llama service.Actualizar, retorna 200 + TiendaResponse o 404/409; log estructurado con operacion="obtener_tienda" u "actualizar_tienda" (depends on T008, T024)
- [ ] T026 [P] [US2] Implementar métodos `obtener(id: number): Observable<TiendaResponse>` y `actualizar(id: number, req: TiendaUpdateRequest): Observable<TiendaResponse>` en `loopi-web-v2/src/app/tiendas/tiendas.service.ts`
- [ ] T027 [US2] Extender `loopi-web-v2/src/app/tiendas/tienda-form/tienda-form.component.ts` para modo edición: detecta `tienda_id` en la ruta de activación; carga datos con `tiendas.service.obtener()`; campo `codigo` como input disabled; en submit llama `tiendas.service.actualizar()`; agregar ruta `/tiendas/:id/editar` en `app.routes.ts` apuntando a `TiendaFormComponent` en modo edición (depends on T026)

**Checkpoint**: Edición operacional. Cambios se reflejan inmediatamente en el listado. `codigo` permanece inmutable.

---

## Phase 6: Historia de Usuario 3 — Inactivar una tienda (Prioridad: P2)

**Goal**: El admin inactiva o reactiva tiendas. Reactivar muestra diálogo de confirmación. Repetir la misma operación sobre el estado actual retorna error explicativo.

**Independent Test**: `POST /api/v1/tiendas/1/inactivar` retorna 200 + activo=false. Segunda llamada retorna 422 con `error="tienda_ya_inactiva"`. `POST /api/v1/tiendas/1/reactivar` retorna 200 + activo=true.

- [ ] T028 [US3] Implementar método `CambiarActivo(id uint64, activo bool, adminID uint64, ahora time.Time)` en `loopi-api-v2/internal/tiendas/repository.go`: UPDATE tiendas SET activo, actualizado_por, actualizado_en WHERE id; retorna la tienda actualizada vía ObtenerPorID (depends on T006)
- [ ] T029 [US3] Implementar métodos `Inactivar(id, adminID)` y `Reactivar(id, adminID)` en `loopi-api-v2/internal/tiendas/service.go`: llama ObtenerPorID para verificar existencia (404 si no) y estado actual; retorna error `{"error":"tienda_ya_inactiva",...}` o `{"error":"tienda_ya_activa",...}` si el estado solicitado ya es el corriente (RF-TDA-03.6); llama repository.CambiarActivo (depends on T028)
- [ ] T030 [US3] Implementar handlers `POST /api/v1/tiendas/{id}/inactivar` y `POST /api/v1/tiendas/{id}/reactivar` en `loopi-api-v2/internal/tiendas/handler.go`: extrae id, valida JWT rol=admin; llama service.Inactivar o service.Reactivar; retorna 200 + TiendaResponse o 404/422 + error JSON; log estructurado con operacion="inactivar_tienda" o "reactivar_tienda" (depends on T008, T029)
- [ ] T031 [P] [US3] Implementar métodos `inactivar(id: number): Observable<TiendaResponse>` y `reactivar(id: number): Observable<TiendaResponse>` en `loopi-web-v2/src/app/tiendas/tiendas.service.ts`
- [ ] T032 [US3] Extender `loopi-web-v2/src/app/tiendas/tiendas-lista/tiendas-lista.component.ts`:
  agregar botón Inactivar (visible si activo=true) y botón Reactivar (visible si activo=false);
  Reactivar abre modal de confirmación con texto "¿Reactivar esta tienda?" (RF-TDA-03.4) antes
  de llamar al servicio; tras inactivar exitoso: toast neutro "Tienda [nombre] inactivada."
  auto-cierre 3 s (sin opción de deshacer); tras reactivar exitoso: toast verde
  "Tienda [nombre] reactivada." auto-cierre 3 s; errores API: toast rojo auto-cierre 5 s
  (constitución §Feedback acciones); actualiza Signal tiendas tras la operación (depends on T031)

**Checkpoint**: Ciclo activo↔inactivo operacional. Tiendas inactivas desaparecen del selector operativo de otros módulos.

---

## Phase 7: Polish y preocupaciones transversales

**Propósito**: Observabilidad, calidad y validación completa del feature.

- [ ] T033 [P] Agregar spans y métricas OpenTelemetry a todos los handlers en `loopi-api-v2/internal/tiendas/handler.go`: span por endpoint con atributos tienda_id, user_id, rol; métricas de latencia p95 y tasa de error (Constitución Principio VI)
- [ ] T034 [P] Verificar que todos los handlers emiten log estructurado JSON a stdout con campos `user_id`, `rol`, `operacion`, `tienda_id` (cuando aplique), `duracion_ms`, `status_http` (Constitución Principio VI)
- [ ] T035 Ejecutar y corregir gates de calidad en `loopi-api-v2/`: `go build ./...` →
  `golangci-lint run` → `govulncheck ./...` → `gitleaks detect --no-git` → `go test ./...`
  (sin archivos `_test.go` en esta feature, pasa trivialmente — gate de regresión para
  tests que se añadan en iteraciones futuras)
- [ ] T036 [P] Ejecutar y corregir gates de calidad en `loopi-web-v2/`: `ng build` → `npm audit --audit-level=high` → `gitleaks detect --no-git` → `ng test --watch=false`
- [ ] T037 Validar escenarios de quickstart.md: (a) crear con nombre duplicado → 409; (b) PUT con campo `codigo` → codigo intacto; (c) inactivar tienda ya inactiva → 422; (d) acceso con JWT rol=lider_tienda → 403; (e) estado vacío en listado Angular

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sin dependencias — comienza inmediatamente
- **Foundacional (Phase 2)**: Depende de Setup — **BLOQUEA** todas las historias
- **HU4 (Phase 3)**: Depende de Foundacional — puede comenzar en paralelo con HU1
- **HU1 (Phase 4)**: Depende de Foundacional — puede comenzar en paralelo con HU4
- **HU2 (Phase 5)**: Depende de Foundacional + HU1 (reutiliza `TiendaFormComponent`)
- **HU3 (Phase 6)**: Depende de Foundacional + HU4 (extiende `TiendasListaComponent`)
- **Polish (Phase 7)**: Depende de todas las historias completadas

### User Story Dependencies

| Historia | Depende de | Testeable independientemente |
|----------|------------|------------------------------|
| HU4 — Listado | Foundacional | ✅ `GET /api/v1/tiendas` |
| HU1 — Crear | Foundacional | ✅ `POST /api/v1/tiendas` |
| HU2 — Editar | Foundacional + HU1 (form reutilizado) | ✅ `GET + PUT /api/v1/tiendas/{id}` |
| HU3 — Inactivar | Foundacional + HU4 (lista extendida) | ✅ `POST /inactivar` + `/reactivar` |

### Parallel Opportunities por Fase

- **Phase 2**: T003+T004 (migraciones up/down), T005+T009 (model.go + Angular service stub)
- **Phase 3**: T013+T014 (método listar + componente lista)
- **Phase 4**: T020+T021 (método crear + componente form)
- **Phase 5**: T026+T027 (métodos obtener/actualizar + extensión form)
- **Phase 6**: T031+T032 (métodos inactivar/reactivar + extensión lista)
- **Phase 7**: T033+T034+T036 en paralelo

---

## Parallel Example: Historia de Usuario 4 (Listado)

```text
Una vez completa Phase 2 (Foundacional), lanzar en paralelo:
  → T013: método listar() en tiendas.service.ts (Angular)
  → T014: TiendasListaComponent con Signals (Angular)
  → T010: método Listar en repository.go (backend — puede avanzar antes que Angular)
```

---

## Implementation Strategy

### MVP First (HU4 + HU1)

1. Completar Phase 1: Setup
2. Completar Phase 2: Foundacional (**CRÍTICO** — bloquea todo)
3. Completar Phase 3 (HU4) + Phase 4 (HU1) en paralelo si hay dos desarrolladores
4. **PARAR Y VALIDAR**: crear una tienda → verla en el listado
5. Deploy/demo si listo

### Incremental Delivery

1. Setup + Foundacional → base técnica lista
2. HU4 (Listado) → admin ve tiendas (lista vacía inicialmente)
3. HU1 (Crear) → admin crea y ve tiendas → **MVP demostrable**
4. HU2 (Editar) → admin actualiza datos → operación CRUD completa
5. HU3 (Inactivar) → admin gestiona ciclo de vida → feature completa
6. Polish → calidad y observabilidad → listo para producción

### Parallel Team Strategy (backend + frontend)

1. Ambos completan Setup + Foundacional juntos
2. Backend implementa T010→T011→T012 (handler HU4); Frontend implementa T013→T014→T015 (Angular HU4)
3. Integrar HU4 end-to-end; repetir patrón para HU1, HU2, HU3

---

## Notes

- `[P]` = archivos distintos sin dependencias incompletas **dentro de la misma fase**. Tareas
  de fases distintas son siempre secuenciales aunque compartan archivo (ej. T013, T020, T026,
  T031 modifican `tiendas.service.ts` pero en fases diferentes → no hay conflicto de merge)
- `[USn]` mapea la tarea a la historia de usuario para trazabilidad
- No se generan tareas de test (no solicitadas en el spec)
- Aplicar la migración en dev antes de comenzar Phase 3:
  `migrate -path loopi-api-v2/migrations/ -database "mysql://...?loc=America%2FBogota" up`
- El campo `codigo` SIEMPRE se normaliza a mayúsculas en `service.Crear` (`strings.ToUpper`) antes de persistir (RF-TDA-01.5)
- Los errores MySQL 1062 se mapean a errores de negocio en el **service**, nunca en el handler
- El middleware JWT de `001-autenticacion` debe estar disponible en `loopi-api-v2/internal/middleware/auth.go` antes de comenzar Phase 2 — verificado por T000
- OpenTelemetry se agrega en Polish (T033), no en la implementación inicial — evita complejidad prematura
- **RF-TDA-04.6** (tiendas activas en el selector global del panel del admin) corresponde a otra
  feature de layout/navegación — fuera del alcance de `002-gestion-tiendas`. Esta feature
  provee el dato `activo` a través de los endpoints existentes
- **RF-TDA-03.2** (bloqueo de nuevas operaciones en tienda inactiva) es responsabilidad de cada
  módulo operacional futuro (003–014): al crear inventario, pedido o compra deberán verificar
  `tiendas.activo = 1`
- **RF-TDA-05.1 y RF-TDA-05.2** (aislamiento multi-tienda por empleado) definen el contrato
  arquitectural; la aplicación del filtro por `tienda_id` es responsabilidad de los módulos
  operacionales futuros (003–014), no de esta feature
- Verificar que feature `001-autenticacion` provee `AuthInterceptor` en Angular
  (`loopi-web-v2/src/app/core/interceptors/auth.interceptor.ts`) para capturar 401 → redirect
  `/login` y 403 → pantalla "Sin permiso" (constitución §Errores UI). Si no existe, añadir
  tarea en feature 001
