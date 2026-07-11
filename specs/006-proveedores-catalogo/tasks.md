# Tasks: 006-proveedores-catalogo

**Input**: Documentos de diseño en `specs/006-proveedores-catalogo/`

**Artefactos usados**: plan.md, spec.md, research.md, data-model.md, contracts/api.md, quickstart.md

**Tests**: Incluidos en la fase de polish (no TDD). Los tests unitarios de `quickstart.md §5`
son los mínimos requeridos.

**Organización**: Una fase por historia de usuario para permitir entrega incremental e
independiente de cada historia.

## Formato: `[ID] [P?] [Story] Descripción con ruta de archivo`

- **[P]**: Se puede ejecutar en paralelo (archivos distintos, sin dependencias de tareas incompletas)
- **[Story]**: Historia de usuario a la que pertenece la tarea (US1…US4, numeración de spec.md)
- Todas las tareas incluyen la ruta exacta del archivo

---

## Phase 1: Setup (Estructura de directorios)

**Propósito**: Crear la estructura de carpetas del módulo en ambos repos antes de escribir código.

- [ ] T001 Crear directorios `loopi-api-v2/internal/proveedores/` y
  `loopi-web-v2/src/app/features/proveedores/{components/lista-proveedores,components/form-proveedor,models,services}/`
  según plan.md

---

## Phase 2: Fundacional (Prerrequisitos bloqueantes)

**Propósito**: Migración, modelos, repositorio base, caché y routing — deben estar completos
antes de iniciar cualquier historia de usuario.

**⚠️ CRÍTICO**: Ninguna historia puede comenzar hasta completar esta fase.

- [ ] T002 Escribir migración `NNNN_crear_tabla_proveedores.up.sql` y `.down.sql` con tabla
  `proveedores`, constraint `uq_proveedores_nit`, índices `ix_proveedores_activo` e
  `ix_proveedores_razon_social` en `loopi-api-v2/db/migrations/` (según data-model.md)
- [ ] T003 Aplicar migración con `golang-migrate` y verificar tabla, constraint e índices en BD
  de desarrollo (`DESCRIBE proveedores; SHOW INDEX FROM proveedores`)
- [ ] T004 [P] Definir structs Go `Proveedor`, `FiltrosListado`, `CrearProveedorRequest`,
  `EditarProveedorRequest`, `ProveedorResponse`, `ProveedorDetalleResponse`,
  `ListarProveedoresResponse`, `CambiarEstadoResponse` en
  `loopi-api-v2/internal/proveedores/model.go`
- [ ] T005 Implementar `Repository` (interfaz + struct + constructor `NewRepository(db)`) en
  `loopi-api-v2/internal/proveedores/repository.go` — esqueleto sin métodos CRUD (se agregan
  por historia de usuario)
- [ ] T006 Implementar `NewCachedRepository(inner Repository, ttl time.Duration) Repository` en
  `loopi-api-v2/internal/proveedores/cached_repository.go`: instancia propia de `EntityCache[T]`,
  TTL 24 h, claves `"list"` / `"id:<id>"` / `"activo:<valor>"`; invalidación: Crear →
  `cache.Clear()`, Editar/Inactivar/Activar → `cache.Delete("id:<id>")` + `cache.Clear()`; usa
  el paquete compartido `internal/cache/` ya existente en `develop` desde 004/005
- [ ] T007 Registrar prefijo `/api/v1/proveedores` en el router principal con middlewares
  `autenticacion` + `solo_admin` en `loopi-api-v2` (todo el módulo, incluida lectura, requiere
  rol `admin` — HU-1 Escenario 3)
- [ ] T008 [P] Crear `proveedor.model.ts` con interfaces TypeScript `Proveedor`,
  `ProveedorDetalle`, `ListarProveedoresResponse`, `CrearProveedorRequest`,
  `EditarProveedorRequest`, `CambiarEstadoResponse`, `FiltrosListadoProveedores`, `ApiError`
  según contracts/api.md en
  `loopi-web-v2/src/app/features/proveedores/models/proveedor.model.ts`
- [ ] T009 [P] Configurar rutas lazy-loaded con guard de rol `admin` en
  `loopi-web-v2/src/app/features/proveedores/proveedores.routes.ts`: `/proveedores` →
  `ListaProveedoresComponent`, `/proveedores/nuevo` → `FormProveedorComponent` (modo `'crear'`),
  `/proveedores/:id/editar` → `FormProveedorComponent` (modo `'editar'`)

**Checkpoint**: Estructura y capas base listas — las historias de usuario pueden comenzar.

---

## Phase 3: Historia de Usuario 1 — Registrar un proveedor (P1) 🎯 MVP

**Meta**: El admin registra un proveedor con razón social y NIT (mínimo); datos de contacto
opcionales. El NIT duplicado es rechazado con 409. Roles no admin reciben 403.

**Prueba Independiente**: `POST /api/v1/proveedores` con razón social y NIT completos retorna
201, `activo=true`. Segundo `POST` con el mismo NIT retorna 409 `nit_duplicado`. `POST` sin
`razon_social` retorna 400 `campo_requerido`. Token de `lider_tienda` retorna 403.

### Backend — US1

- [ ] T010 [P] [US1] Implementar `Repository.Crear(ctx, req)` y
  `Repository.ExisteNIT(ctx, nit string, excludeID *int64) (bool, error)` en
  `loopi-api-v2/internal/proveedores/repository.go` — columnas explícitas, nunca `SELECT *`
- [ ] T011 [US1] Implementar `Service.Crear(ctx, req CrearProveedorRequest) (*Proveedor, error)`
  en `loopi-api-v2/internal/proveedores/service.go`: validar `razon_social`/`nit` no vacíos
  (400 `campo_requerido`), validar formato de `email_contacto` si presente (400
  `email_invalido`), verificar unicidad de NIT vía `Repository.ExisteNIT` (409 `nit_duplicado`),
  crear con `activo=true` por defecto, invalidar caché
- [ ] T012 [US1] Implementar handler `POST /api/v1/proveedores` con guard de rol `admin`,
  deserialización del body, mapeo de errores (400/401/403/409) y respuesta 201 en
  `loopi-api-v2/internal/proveedores/handler.go`

### Frontend — US1

- [ ] T013 [P] [US1] Crear `ProveedoresService`
  (`@Injectable({providedIn:'root'})`) con método `crear(req: CrearProveedorRequest):
  Observable<Proveedor>` en
  `loopi-web-v2/src/app/features/proveedores/services/proveedores.service.ts`
- [ ] T014 [US1] Implementar `FormProveedorComponent` standalone en modo `'crear'`
  (`FormModeService`), envuelto en `FormCardComponent` (`max-w-lg` — 5 campos): reactive form
  con validación on blur + submit, botón deshabilitado durante envío en
  `loopi-web-v2/src/app/features/proveedores/components/form-proveedor/form-proveedor.component.ts`
- [ ] T015 [US1] Template `form-proveedor.component.html`: `<h1>` "Nuevo proveedor" (sin prefijo
  `+`), breadcrumb, `<label>` asociado a cada input, leyenda "* Campo obligatorio", toast verde
  3 s en éxito, navega a `/proveedores` tras crear en
  `loopi-web-v2/src/app/features/proveedores/components/form-proveedor/form-proveedor.component.html`
- [ ] T016 [US1] Implementar `ListaProveedoresComponent` mínima (sin filtros — se extiende en
  US4): `ListCardComponent` + `DataTableComponent` con filas clickeables que navegan a
  `/proveedores/:id/editar`, `EmptyStateComponent` con mensaje "No hay proveedores registrados"
  y botón "Crear el primero" cuando `total=0`, botón primario "+ Nuevo proveedor" en
  `PageHeaderComponent` (constitución §Botones de Acción) en
  `loopi-web-v2/src/app/features/proveedores/components/lista-proveedores/lista-proveedores.component.ts`
  y `.html`

**Checkpoint**: US1 funcional — crear proveedor desde el frontend y verlo en el listado básico.

---

## Phase 4: Historia de Usuario 4 — Consultar el catálogo de proveedores (P1)

**Meta**: El admin ve el listado completo (activos e inactivos) con búsqueda por razón
social/NIT y filtro de estado (default Activos); al seleccionar un proveedor ve su detalle,
incluidos los items que lo tienen asignado.

**Prueba Independiente**: `GET /api/v1/proveedores?estado=activo` retorna solo activos.
`GET /api/v1/proveedores?busqueda=cosecha` filtra por subcadena de razón social o NIT.
`GET /api/v1/proveedores/{id}` retorna el detalle con `items_asignados`. Listado vacío muestra
el empty state.

### Backend — US4

- [ ] T017 [P] [US4] Implementar `Repository.Listar(ctx, filtros FiltrosListado)` (con `LIKE`
  sobre `razon_social`/`nit`, filtro `activo`, paginación), `Repository.ObtenerPorID(ctx, id)` y
  `Repository.ContarItemsAsignados(ctx, id)` (graceful `0` hasta que 007-items-catalogo exista)
  en `loopi-api-v2/internal/proveedores/repository.go`
- [ ] T018 [US4] Implementar `Service.Listar(ctx, filtros)` (a través de `cached_repository`,
  claves `"list"` / `"activo:<valor>"`) y `Service.ObtenerPorID(ctx, id)` (con
  `items_asignados`) en `loopi-api-v2/internal/proveedores/service.go`
- [ ] T019 [US4] Implementar handlers `GET /api/v1/proveedores` (parsear `estado` — default
  `todos`, 400 `estado_invalido` si no es `activo`/`inactivo`/`todos`; traducir a `*bool` para
  el filtro interno —, `busqueda`, `page`, `limit`) y `GET /api/v1/proveedores/{id}` (404
  `proveedor_no_encontrado`) en `loopi-api-v2/internal/proveedores/handler.go`

### Frontend — US4

- [ ] T020 [P] [US4] Agregar métodos `listar(filtros: FiltrosListadoProveedores)` y
  `obtener(id: number)` a `ProveedoresService` en
  `loopi-web-v2/src/app/features/proveedores/services/proveedores.service.ts`
- [ ] T021 [US4] Extender `ListaProveedoresComponent` con `FilterBarComponent` +
  `FilterStateService` (default `Estado=Activo`, constitución §Filtros en Listados; prohibido
  filtro ad-hoc), campo de búsqueda por texto, `StatusBadgeComponent` en la columna Estado y
  `PaginationComponent` server-side en
  `loopi-web-v2/src/app/features/proveedores/components/lista-proveedores/lista-proveedores.component.ts`
  y `.html`
- [ ] T022 [US4] Extender `FormProveedorComponent` para cargar los datos existentes en modo
  `'editar'` (`obtener(id)`) y mostrar `items_asignados` con `ReadonlyFieldComponent` (el guardado
  de cambios se implementa en US2) en
  `loopi-web-v2/src/app/features/proveedores/components/form-proveedor/form-proveedor.component.ts`

**Checkpoint**: US4 funcional — listado con búsqueda/filtro y detalle de proveedor operativos.

---

## Phase 5: Historia de Usuario 2 — Editar los datos de un proveedor (P2)

**Meta**: El admin corrige cualquier campo, incluido el NIT, con verificación de unicidad
excluyendo el propio registro. La edición no afecta items ni historial de pedidos.

**Prueba Independiente**: `PUT /api/v1/proveedores/{id}` con nuevo `nombre_contacto` retorna
200. `PUT` con el mismo NIT propio no genera 409. `PUT` con el NIT de otro proveedor existente
retorna 409 `nit_duplicado`.

### Backend — US2

- [ ] T023 [P] [US2] Implementar `Repository.Actualizar(ctx, id, req EditarProveedorRequest)` en
  `loopi-api-v2/internal/proveedores/repository.go`
- [ ] T024 [US2] Implementar `Service.Editar(ctx, id, req)` en
  `loopi-api-v2/internal/proveedores/service.go`: obtener proveedor (404 si no existe); si
  `nit` presente, validar no vacío (400 `campo_vacio`) y unicidad excluyendo el propio `id`
  (409 `nit_duplicado`); si `email_contacto` presente, validar formato (400 `email_invalido`);
  actualizar solo campos enviados; invalidar caché
- [ ] T025 [US2] Implementar handler `PUT /api/v1/proveedores/{id}` con guard de rol `admin`,
  mapeo de errores (400/401/403/404/409) y respuesta 200 en
  `loopi-api-v2/internal/proveedores/handler.go`

### Frontend — US2

- [ ] T026 [P] [US2] Agregar método `editar(id: number, req: EditarProveedorRequest)` a
  `ProveedoresService` en
  `loopi-web-v2/src/app/features/proveedores/services/proveedores.service.ts`
- [ ] T027 [US2] Completar `FormProveedorComponent` en modo `'editar'`: permitir editar el NIT,
  cambiar el botón a "Guardar cambios", toast "Proveedor actualizado correctamente." en
  `loopi-web-v2/src/app/features/proveedores/components/form-proveedor/form-proveedor.component.ts`
  y `.html`

**Checkpoint**: US2 funcional — edición completa, incluida la del NIT con validación de unicidad.

---

## Phase 6: Historia de Usuario 3 — Inactivar y reactivar un proveedor (P2)

**Meta**: El admin inactiva un proveedor (excluido de nuevos pedidos, referencia histórica
intacta) y puede reactivarlo sin pérdida de historial.

**Prueba Independiente**: `PATCH /api/v1/proveedores/{id}/inactivar` retorna 200
`activo=false`; segundo intento retorna 409 `ya_inactivo`. `PATCH .../activar` retorna 200
`activo=true`; segundo intento retorna 409 `ya_activo`.

### Backend — US3

- [ ] T028 [P] [US3] Implementar `Repository.CambiarEstado(ctx, id, activo bool)` en
  `loopi-api-v2/internal/proveedores/repository.go`
- [ ] T029 [US3] Implementar `Service.Inactivar(ctx, id)` (404 si no existe; 409 `ya_inactivo`
  si ya estaba inactivo) y `Service.Activar(ctx, id)` (404; 409 `ya_activo` si ya estaba
  activo), ambos invalidando caché, en `loopi-api-v2/internal/proveedores/service.go`
- [ ] T030 [US3] Implementar handlers `PATCH /api/v1/proveedores/{id}/inactivar` y
  `PATCH /api/v1/proveedores/{id}/activar` con guard de rol `admin` y mapeo de errores
  (401/403/404/409) en `loopi-api-v2/internal/proveedores/handler.go`

### Frontend — US3

- [ ] T031 [P] [US3] Agregar métodos `inactivar(id: number)` y `activar(id: number)` a
  `ProveedoresService` en
  `loopi-web-v2/src/app/features/proveedores/services/proveedores.service.ts`
- [ ] T032 [US3] Implementar `DangerZoneComponent` en modo `'editar'` de
  `FormProveedorComponent` (auto-oculto en modo `'crear'` vía `FormModeService`): botón dinámico
  "Inactivar proveedor" / "Reactivar proveedor" según el estado actual, modal de confirmación
  previo (constitución §Feedback), separado con `<hr>` + `mt-8` en
  `loopi-web-v2/src/app/features/proveedores/components/form-proveedor/form-proveedor.component.ts`
  y `.html`

**Checkpoint**: US3 funcional — ciclo de vida completo (inactivar/reactivar) operativo.

---

## Phase 7: Polish y Aspectos Transversales

**Propósito**: Observabilidad, tests unitarios y validación de gates de CI.

**⚠️ DEPLOY BLOCKER**: T033–T035 (OTel + métricas + logs) deben completarse **antes del primer
deploy a stage o producción** — Principio VI de la constitución: "Cada feature DEBE ser
monitoreable desde el primer deploy en producción."

- [ ] T033 [P] Instrumentar trazas OTel según `spec.md §Observabilidad`: spans
  `proveedores.crear`, `proveedores.listar`, `proveedores.editar`, `proveedores.inactivar`,
  `proveedores.activar` con sus atributos obligatorios en
  `loopi-api-v2/internal/proveedores/handler.go`
- [ ] T034 [P] Instrumentar métricas OTel según `spec.md §Observabilidad`:
  `catalogo.proveedor.crear.total`, `catalogo.proveedor.crear.duration`,
  `catalogo.proveedor.listar.duration` (etiqueta `cache_hit`),
  `catalogo.proveedor.inactivar.total`, `catalogo.proveedor.activar.total` en
  `loopi-api-v2/internal/proveedores/handler.go`
- [ ] T035 [P] Agregar logs JSON estructurados con campos `user_id`, `rol`, `operacion`,
  `proveedor_id` y `resultado` en cada operación de escritura en
  `loopi-api-v2/internal/proveedores/service.go`
- [ ] T036 [P] Implementar `service_test.go` con mock del repositorio cubriendo los 15 casos de
  `quickstart.md §5` en `loopi-api-v2/internal/proveedores/service_test.go`
- [ ] T037 [P] Implementar `handler_test.go` con `httptest.NewRecorder()` y mock de `Service`
  cubriendo todos los códigos HTTP (200/201/400/401/403/404/409) de los 6 endpoints, incluidos
  `TestAccesoLiderTiendaFalla` y `TestAccesoSinTokenFalla` en
  `loopi-api-v2/internal/proveedores/handler_test.go`
- [ ] T038 [P] Implementar `repository_test.go` con `go-sqlmock` cubriendo INSERT/UPDATE/SELECT
  y manejo de errores de BD (error 1062 de NIT duplicado, `sql.ErrNoRows`) para todos los
  métodos del repositorio en `loopi-api-v2/internal/proveedores/repository_test.go`
- [ ] T039 [P] Implementar `cached_repository_test.go` inyectando mock de `Repository` (inner):
  hit de caché (inner NO invocado), miss de caché (inner invocado + resultado almacenado),
  escritura invalida caché correctamente, error del inner no almacena en caché — cobertura
  mínima ≥ 90 % en `loopi-api-v2/internal/proveedores/cached_repository_test.go`
- [ ] T040 [P] Implementar `lista-proveedores.component.spec.ts` y
  `form-proveedor.component.spec.ts` (mock de `ProveedoresService`) con casos: listado vacío,
  crear proveedor, error 409 NIT duplicado, flujo de confirmación de inactivación en
  `loopi-web-v2/src/app/features/proveedores/components/`
- [ ] T041 [P] Implementar `proveedores.service.spec.ts` (mock de `HttpClient`) con casos: crear
  exitoso, editar NIT duplicado, inactivar, activar en
  `loopi-web-v2/src/app/features/proveedores/services/proveedores.service.spec.ts`
- [ ] T042 Ejecutar gates CI backend: `go build ./...`, `golangci-lint run`,
  `govulncheck ./...`, `gitleaks detect --no-git`, `go test ./...` en `loopi-api-v2` — todos
  deben pasar sin errores
- [ ] T043 [P] Ejecutar gates CI frontend: `ng build`, `npm audit --audit-level=high`,
  `gitleaks detect --no-git`, `ng test --watch=false` en `loopi-web-v2` — todos deben pasar sin
  errores
- [ ] T044 Ejecutar smoke tests completos de `specs/006-proveedores-catalogo/quickstart.md §4` y
  verificar cada resultado esperado

---

## Dependencias y Orden de Ejecución

### Dependencias entre Fases

- **Phase 1 (Setup)**: Sin dependencias — comenzar de inmediato
- **Phase 2 (Fundacional)**: Depende de Phase 1 — **BLOQUEA todas las historias**
- **Phase 3 (US1)**: Depende de Phase 2 — primer incremento entregable (MVP)
- **Phase 4 (US4)**: Depende de Phase 2; extiende `ListaProveedoresComponent` y
  `FormProveedorComponent` construidos en US1
- **Phase 5 (US2)**: Depende de Phase 2; extiende `FormProveedorComponent` (modo editar) de US4
- **Phase 6 (US3)**: Depende de Phase 2; extiende `FormProveedorComponent` (modo editar) de US4
- **Phase 7 (Polish)**: Depende de todas las historias deseadas completadas

### Dependencias entre Historias de Usuario

- **US1 (P1)**: Puede comenzar tras Phase 2 — sin dependencias en otras historias
- **US4 (P1)**: Puede comenzar tras Phase 2 en el backend; en el frontend reutiliza los
  componentes creados en US1 (misma vista, no un componente nuevo)
- **US2 (P2)**: Backend sin dependencias de otras historias; frontend depende de que
  `FormProveedorComponent` en modo `'editar'` ya cargue datos (US4)
- **US3 (P2)**: Backend sin dependencias de otras historias; frontend depende del modo
  `'editar'` de `FormProveedorComponent` (US4)

### Dentro de Cada Historia

- Repository antes de service antes de handler (backend)
- Service Angular antes que el componente (frontend)
- Backend antes de frontend dentro de cada historia (el frontend necesita el endpoint)

### Oportunidades de Paralelismo

- T004 (model.go) puede hacerse en paralelo con T002–T003 (migración)
- T008 y T009 (frontend fundacional): paralelas entre sí y con el backend fundacional
- T010 (backend US1) y T013 (frontend service US1): paralelas una vez completada Phase 2
- T017 (backend US4) y T020 (frontend service US4): paralelas
- T023 (backend US2) y T026 (frontend service US2): paralelas
- T028 (backend US3) y T031 (frontend service US3): paralelas
- T033, T034, T035, T036, T037, T038, T039, T040, T041: todas paralelas entre sí
- T042 y T043 requieren T033–T041 completadas; T044 requiere T042 y T043 completadas

---

## Ejemplo Paralelo: Historia de Usuario 1

```bash
# Una vez completada Phase 2, lanzar en paralelo:
Task T010: "Repository.Crear + ExisteNIT en repository.go"
Task T013: "ProveedoresService.crear() en proveedores.service.ts"

# Luego (T010 completo):
Task T011: "Service.Crear en service.go"
# En paralelo con T011:
Task T014: "FormProveedorComponent modo 'crear' en form-proveedor.component.ts"

# Luego:
Task T012: "Handler POST /api/v1/proveedores en handler.go"
Task T015: "Template form-proveedor.component.html"
Task T016: "ListaProveedoresComponent mínima"
```

---

## Estrategia de Implementación

### MVP (Solo US1)

1. Completar Phase 1: Setup
2. Completar Phase 2: Fundacional (CRÍTICO)
3. Completar Phase 3: US1 — Registrar proveedor
4. **PARAR Y VALIDAR**: Crear proveedor desde el frontend, verificar en el listado básico
5. Hacer demo / desplegar en stage si está listo

### Entrega Incremental

1. Setup + Fundacional → Base lista (repositorio, caché, rutas)
2. US1 → Registrar proveedor (MVP funcional)
3. US4 → Listado con búsqueda/filtro + detalle → Feature completa en lectura
4. US2 → Edición completa (incluido NIT) → Corrección de datos
5. US3 → Inactivar/Reactivar → Ciclo de vida completo
6. Polish → Tests + CI + Observabilidad

### Estrategia de Equipo Paralelo

Con dos desarrolladores:

1. Juntos completan Phase 1 + 2 (Setup + Fundacional)
2. Developer A: backend de US1-US4 (endpoints POST + GET)
3. Developer B: frontend de US1-US4 (componentes + servicio)
4. Integran y validan
5. Developer A: backend US2-US3
6. Developer B: frontend US2-US3 (edición + zona de precaución)

---

## Notas

- `[P]` = archivos distintos, sin dependencias de tareas incompletas
- La etiqueta `[USN]` vincula la tarea a la historia de usuario de `spec.md` para trazabilidad
  (US1=Registrar, US2=Editar, US3=Inactivar/Reactivar, US4=Consultar)
- `ListaProveedoresComponent` y `FormProveedorComponent` son los ÚNICOS dos componentes del
  módulo — patrón Lista-Formulario normativo; no crear un componente de detalle separado
- `Repository.ContarItemsAsignados` retorna 0 graciosamente hasta que 007-items-catalogo cree
  la tabla `items` — no bloquea el desarrollo de esta feature
- Nunca `SELECT *` — columnas explícitas en todas las queries de `repository.go`
- Cada historia debe ser completamente verificable con los smoke tests de `quickstart.md`
- Commitear tras cada tarea o grupo lógico
- Detener en cualquier checkpoint para validar la historia de forma independiente
