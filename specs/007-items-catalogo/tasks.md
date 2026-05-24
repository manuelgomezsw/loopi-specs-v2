# Tasks: 007-items-catalogo

**Input**: Documentos de diseño en `specs/007-items-catalogo/`

**Artefactos usados**: plan.md, spec.md, research.md, data-model.md, contracts/api.md, quickstart.md

**Tests**: Incluidos en la fase de polish (no TDD). Los tests unitarios de `quickstart.md §5`
son los mínimos requeridos por la constitución (mocks para BD; unitarios por componente Angular).

**Organización**: Una fase por historia de usuario para permitir entrega incremental e
independiente de cada historia.

## Formato: `[ID] [P?] [Story] Descripción con ruta de archivo`

- **[P]**: Se puede ejecutar en paralelo (archivos distintos, sin dependencias de tareas incompletas)
- **[Story]**: Historia de usuario a la que pertenece la tarea (US1…US5)
- Todas las tareas incluyen la ruta exacta del archivo

---

## Phase 1: Setup (Estructura de directorios)

**Propósito**: Crear la estructura de carpetas del módulo en ambos repos antes de escribir código.

- [ ] T001 Crear directorios `loopi-api-v2/internal/items/` y `loopi-web-v2/src/app/items/` según el plan de implementación

---

## Phase 2: Fundacional (Prerrequisitos bloqueantes)

**Propósito**: Migraciones, modelos, repositorio base, caché y routing — deben estar completos
antes de iniciar cualquier historia de usuario.

**⚠️ CRÍTICO**: Ninguna historia puede comenzar hasta completar esta fase.

- [ ] T002 Escribir migración `NNNN_crear_tabla_items.up.sql` (tabla `items` con todos los campos, constraints `uq_items_codigo`, `uq_items_nombre`, FKs a `subcategorias`, `proveedores`, `unidades_medida`, `usuarios`, índices `ix_items_activo`, `ix_items_tipo_activo`, `ix_items_frecuencia_activo`) y `.down.sql` en `loopi-api-v2/db/migrations/`
- [ ] T003 [P] Escribir migración `NNNN+1_crear_tabla_items_costos_tienda.up.sql` (tabla `items_costos_tienda` append-only con FK a `items`, `tiendas`, `usuarios` e índice `ix_ict_item_tienda_vigente`) y `.down.sql` en `loopi-api-v2/db/migrations/`
- [ ] T004 Aplicar migraciones con `golang-migrate` y verificar tablas, índices y FKs en BD de desarrollo (`SHOW INDEX FROM items; SHOW INDEX FROM items_costos_tienda; DESCRIBE items`)
- [ ] T005 [P] Definir structs Go `Item`, `ItemCostoTienda` y DTOs `CrearItemRequest`, `ActualizarItemRequest`, `ItemResponse`, `ItemDetalleResponse`, `CostoTiendaRequest`, `CostoTiendaResponse`, `ListaItemsResponse` en `loopi-api-v2/internal/items/models.go`
- [ ] T006 [P] Implementar caché Ristretto con TTL 5 min, claves `"item:id:{id}"`, `"item:codigo:{codigo}"`, `"items:freq:diario"`, `"items:freq:semanal"`, `"items:freq:mensual"` y función `invalidarItems(itemID, codigo)` en `loopi-api-v2/internal/items/cache.go`
- [ ] T007 Implementar `Repository` con pool de BD, interfaz base y constructor `NewRepository(db, cache)` en `loopi-api-v2/internal/items/repository.go`
- [ ] T008 Registrar prefijo `/api/v1/items` con middleware de autenticación JWT en el router principal de `loopi-api-v2`

**Checkpoint**: Estructura lista — las historias de usuario pueden comenzar.

---

## Phase 3: Historia de Usuario 1 — Crear un item (P1) 🎯 MVP

**Meta**: El admin registra un nuevo item con código único y nombre único. Los intentos de
código o nombre duplicado son rechazados con 409. Referencias a subcategoría, unidad de medida
o proveedor inexistentes o inactivos retornan 404/422. Roles no admin reciben 403.

**Prueba Independiente**: `POST /api/v1/items` con payload completo retorna 201, `activo=true`,
`esta_en_uso=false`. Segundo POST con mismo código retorna 409 `codigo_duplicado`. Segundo POST
con mismo nombre en distinto caso (ej. "leche entera") retorna 409 `nombre_duplicado`.
Intento desde rol barista retorna 403. Ver `quickstart.md §4.1`.

### Backend — US1

- [ ] T009 [P] [US1] Implementar `Repository.InsertarItem(ctx, item, creadoPor)` con captura de error MySQL 1062 para código y nombre duplicado, y retorno del `id` autogenerado en `loopi-api-v2/internal/items/repository.go`
- [ ] T010 [US1] Implementar `Service.CrearItem(ctx, req)` extrayendo `user_id` del contexto JWT, validando campos obligatorios, verificando que subcategoría/unidad de medida estén activas, verificando que proveedor (si enviado) esté activo, delegando a repo e invalidando caché al completar en `loopi-api-v2/internal/items/service.go`
- [ ] T011 [US1] Implementar handler `POST /api/v1/items` con guard de rol `admin`, deserialización del body, traducción de errores del servicio a códigos HTTP (400/401/403/404/409/422) y respuesta 201 con `ItemDetalleResponse` en `loopi-api-v2/internal/items/handler.go`

### Frontend — US1

- [ ] T012 [P] [US1] Crear `ItemsService` con señales de estado (`items`, `itemActual`, `cargando`, `error`) y método `crearItem(req: CrearItemRequest): Observable<ItemDetalleResponse>` en `loopi-web-v2/src/app/items/items.service.ts`
- [ ] T013 [P] [US1] Implementar componente standalone `ItemFormComponent` con formulario reactivo de creación: campos para código, nombre, tipo (select), subcategoría (select con datos de API 005), unidad de medida (select con datos de API 004), proveedor (select opcional con datos de API 006), costo unitario, frecuencia (select), stock de seguridad y tiempo de entrega; validación on-blur, botón deshabilitado en loading en `loopi-web-v2/src/app/items/item-form.component.ts`
- [ ] T014 [US1] Implementar template HTML del formulario de creación con todos los campos, marcación de campos obligatorios (`*`), mensajes de error de validación (`text-red-600` bajo el campo), spinner inline en el botón de submit durante el guardado y toast de éxito 3 s en `loopi-web-v2/src/app/items/item-form.component.html`
- [ ] T015 [US1] Configurar ruta lazy-loaded `/items/nuevo` con guard de rol `admin` y `<h1>` "Nuevo Item" en `loopi-web-v2/src/app/items/items.routes.ts`

**Checkpoint**: US1 funcional — crear item desde el frontend y verificar que aparece en BD.

---

## Phase 4: Historia de Usuario 4 — Consultar el catálogo de items (P1)

**Meta**: El admin ve el listado paginado de items con filtros por tipo, frecuencia y estado.
Desde el detalle ve todos los atributos del item incluyendo parámetros de stock y el historial
de costos por tienda.

**Prueba Independiente**: `GET /api/v1/items?activo=true` retorna listado paginado con `total` y
`total_paginas`. `GET /api/v1/items?tipo=insumo` filtra por tipo. `GET /api/v1/items/{id}` retorna
todos los atributos con `esta_en_uso`. Ver `quickstart.md §4.2`.

### Backend — US4

- [ ] T016 [P] [US4] Implementar `Repository.ListarItems(ctx, filtros ListarItemsFiltros, pagina, porPagina)` con query dinámica según filtros activos, COUNT para `total` y LIMIT/OFFSET para paginación en `loopi-api-v2/internal/items/repository.go`
- [ ] T017 [P] [US4] Implementar `Repository.ObtenerItemPorID(ctx, id)` con JOIN a subcategorias, proveedores y unidades_medida para nombres en `loopi-api-v2/internal/items/repository.go`
- [ ] T018 [US4] Implementar `Service.ListarItems(ctx, filtros, pagina, porPagina)` con caché para consultas por frecuencia (`items:freq:{frecuencia}`) cuando el filtro sea solo frecuencia+activo en `loopi-api-v2/internal/items/service.go`
- [ ] T019 [US4] Implementar `Service.ObtenerItem(ctx, id)` con cache-first por clave `"item:id:{id}"` y llamada a `estaEnUso(ctx, id)` para incluir el campo `esta_en_uso` en la respuesta en `loopi-api-v2/internal/items/service.go`
- [ ] T020 [US4] Implementar handlers `GET /api/v1/items` (acepta query params `tipo`, `frecuencia`, `activo`, `pagina`, `por_pagina`) y `GET /api/v1/items/{id}` en `loopi-api-v2/internal/items/handler.go`

### Frontend — US4

- [ ] T021 [P] [US4] Implementar componente standalone `ItemsComponent` con señal de listado paginado, filtros reactivos (tipo, frecuencia, estado) y controles de paginación; el filtro activa una nueva llamada a `ItemsService.listarItems()` en `loopi-web-v2/src/app/items/items.component.ts`
- [ ] T022 [US4] Implementar template HTML de listado con tabla (columnas: código, nombre, tipo, frecuencia, estado), controles de filtro (selects), paginación y empty state "Aún no hay items registrados. Crea el primero →" en `loopi-web-v2/src/app/items/items.component.html`
- [ ] T023 [P] [US4] Implementar componente standalone `ItemDetalleComponent` que carga el item por ID de ruta y muestra todos sus atributos (código, nombre, tipo, subcategoría, proveedor, unidad de medida, costo global, frecuencia, stock de seguridad, tiempo de entrega, estado, en uso) en `loopi-web-v2/src/app/items/item-detalle.component.ts`
- [ ] T024 [US4] Implementar template HTML de detalle con todos los atributos, breadcrumb "Items / {nombre}", badge de estado (activo/inactivo) y badge "En uso" cuando `esta_en_uso=true` en `loopi-web-v2/src/app/items/item-detalle.component.html`
- [ ] T025 [US4] Agregar métodos `listarItems(filtros, pagina, porPagina)` y `obtenerItem(id)` a `ItemsService`, y rutas `/items` (listado) y `/items/:id` (detalle) en `loopi-web-v2/src/app/items/items.service.ts` y `items.routes.ts`

**Checkpoint**: US4 funcional — listado paginado con filtros y vista de detalle completa.

---

## Phase 5: Historia de Usuario 2 — Editar un item (P2)

**Meta**: El admin actualiza los parámetros operativos de un item. El código es editable si
`esta_en_uso=false`; bloqueado con 422 si tiene usos. Cambiar la unidad de medida con historial
requiere `confirmar_cambio_unidad: true`; sin él retorna 422.

**Prueba Independiente**: `PUT /api/v1/items/{id}` con `stock_seguridad` actualizado retorna 200
con nuevo valor. `PUT` intentando cambiar `codigo` con `esta_en_uso=true` retorna 422
`codigo_en_uso`. `PUT` cambiando `unidad_medida_id` sin `confirmar_cambio_unidad: true` retorna
422 `cambio_unidad_requiere_confirmacion`. Ver `quickstart.md §4.2`.

### Backend — US2

- [ ] T026 [P] [US2] Implementar `Service.estaEnUso(ctx, itemID)` que verifica con EXISTS queries vía `information_schema` si el item aparece en `inventarios_conteos_items`, `recetas_ingredientes` o `pedidos_lineas` (seguro ante tablas no creadas aún) en `loopi-api-v2/internal/items/service.go`
- [ ] T027 [US2] Implementar `Repository.ActualizarItem(ctx, id, campos, actualizadoPor)` y `Service.ActualizarItem(ctx, id, req)` con validaciones: bloquear `codigo` si `estaEnUso()=true` (422 `codigo_en_uso`), exigir `confirmar_cambio_unidad=true` si cambia `unidad_medida_id` y el item tiene historial de stock, unicidad de nombre en `loopi-api-v2/internal/items/repository.go` y `service.go`
- [ ] T028 [US2] Implementar handler `PUT /api/v1/items/{id}` con guard de rol `admin` y manejo de 400/401/403/404/409/422 en `loopi-api-v2/internal/items/handler.go`

### Frontend — US2

- [ ] T029 [P] [US2] Extender `ItemFormComponent` con modo edición: cargar datos actuales por ID, deshabilitar campo `codigo` cuando `item.esta_en_uso=true`, mostrar modal de confirmación "¿Confirmar cambio de unidad de medida? El historial de stock quedará en unidades inconsistentes." cuando se modifica `unidad_medida_id` en `loopi-web-v2/src/app/items/item-form.component.ts`
- [ ] T030 [US2] Actualizar template HTML con campo `codigo` en modo readonly cuando `esta_en_uso=true` (con tooltip "Código bloqueado — el item está en uso"), modal de confirmación de cambio de unidad con botón destructivo y botón cancelar en `loopi-web-v2/src/app/items/item-form.component.html`
- [ ] T031 [US2] Agregar método `editarItem(id, req)` a `ItemsService` y ruta `/items/:id/editar` en `loopi-web-v2/src/app/items/items.service.ts` y `items.routes.ts`

**Checkpoint**: US2 funcional — edición de items con validación de bloqueo de código y confirmación de cambio de unidad.

---

## Phase 6: Historia de Usuario 3 — Inactivar y reactivar un item (P2)

**Meta**: El admin inactiva items que dejan de usarse (quedan fuera de conteos futuros y de
nuevas recetas/pedidos pero conservan historial). Puede reactivarlos sin restricciones. Un item
inactivo ingrediente de una receta activa genera advertencia en la receta (verificada en 008).

**Prueba Independiente**: `PATCH /api/v1/items/{id}/inactivar` retorna 200 `activo=false`.
`GET /api/v1/items?activo=true` ya no incluye el item. `PATCH .../reactivar` retorna 200
`activo=true`. Segundo `/inactivar` retorna 422 `item_ya_inactivo`. Ver `quickstart.md §4.3`.

### Backend — US3

- [ ] T032 [P] [US3] Implementar `Repository.InactivarItem(ctx, id, actualizadoPor)` y `Repository.ReactivarItem(ctx, id, actualizadoPor)` con UPDATE `activo` y `actualizado_en=NOW()` en `loopi-api-v2/internal/items/repository.go`
- [ ] T033 [US3] Implementar `Service.InactivarItem(ctx, id)` (verifica activo=1 antes; retorna 422 `item_ya_inactivo` si ya está inactivo) y `Service.ReactivarItem(ctx, id)` (verifica activo=0; retorna 422 `item_ya_activo` si ya está activo) con invalidación de caché en ambas operaciones en `loopi-api-v2/internal/items/service.go`
- [ ] T034 [US3] Implementar handlers `PATCH /api/v1/items/{id}/inactivar` y `PATCH /api/v1/items/{id}/reactivar` con guard de rol `admin` y manejo de 401/403/404/422 en `loopi-api-v2/internal/items/handler.go`

### Frontend — US3

- [ ] T035 [P] [US3] Agregar métodos `inactivarItem(id)` y `reactivarItem(id)` a `ItemsService` en `loopi-web-v2/src/app/items/items.service.ts`
- [ ] T036 [US3] Implementar en `ItemsComponent` y `ItemDetalleComponent`: botón "Inactivar" / "Reactivar" con modal de confirmación "¿Inactivar este item? Dejará de aparecer en nuevos inventarios y recetas.", spinner inline durante la acción, toast de éxito verde 3 s y actualización reactiva del estado en la lista en `loopi-web-v2/src/app/items/items.component.ts`, `items.component.html`, `item-detalle.component.ts` y `item-detalle.component.html`

**Checkpoint**: US3 funcional — ciclo de vida activo/inactivo operativo en backend y frontend.

---

## Phase 7: Historia de Usuario 5 — Costos por tienda (P2)

**Meta**: El admin puede registrar un costo específico por tienda para un item, sobreescribiendo
el costo global. El historial de cambios se preserva (append-only). Desde el detalle del item
se consulta el historial por tienda con el costo vigente identificado.

**Prueba Independiente**: `POST /api/v1/items/{id}/costos_tienda` con `{"tienda_id":1,
"costo_unitario":3400}` retorna 201. Segundo POST con nuevo costo 3600 retorna 201 (historial).
`GET /api/v1/items/{id}/costos_tienda` retorna 2 entradas para tienda 1 con `costo_vigente=3600`.
Ver `quickstart.md §4.4`.

### Backend — US5

- [ ] T037 [P] [US5] Implementar `Repository.InsertarCostoTienda(ctx, itemID, tiendaID, costoUnitario, creadoPor)` (INSERT con `vigente_desde=NOW()`) y `Repository.ListarCostosTienda(ctx, itemID)` (historial completo ordenado por `vigente_desde DESC`, agrupado por tienda) en `loopi-api-v2/internal/items/repository.go`
- [ ] T038 [US5] Implementar `Service.RegistrarCostoTienda(ctx, itemID, req)` con validaciones: item existe y está activo, tienda existe, `costo_unitario > 0`, y `Service.ObtenerHistorialCostos(ctx, itemID)` que construye la respuesta agrupada con `costo_vigente` (primer elemento de cada tienda) y `costo_global` del item en `loopi-api-v2/internal/items/service.go`
- [ ] T039 [US5] Implementar handlers `POST /api/v1/items/{id}/costos_tienda` (201) y `GET /api/v1/items/{id}/costos_tienda` (200) en `loopi-api-v2/internal/items/handler.go`

### Frontend — US5

- [ ] T040 [P] [US5] Agregar métodos `registrarCostoTienda(itemID, req)` y `obtenerCostosTienda(itemID)` a `ItemsService` en `loopi-web-v2/src/app/items/items.service.ts`
- [ ] T041 [US5] Implementar sección "Costos por tienda" en `ItemDetalleComponent`: tabla con columnas tienda / costo vigente / última actualización; formulario inline para registrar nuevo costo (select de tienda + campo de costo); spinner durante el guardado y toast de éxito 3 s; si tienda no tiene costo propio mostrar "(usa costo global: ${costo_global})" en `loopi-web-v2/src/app/items/item-detalle.component.ts` y `item-detalle.component.html`

**Checkpoint**: US5 funcional — historial de costos por tienda visible y actualizable desde el detalle.

---

## Phase 8: Polish y Aspectos Transversales

**Propósito**: Observabilidad, tests unitarios y validación de gates de CI.

**⚠️ DEPLOY BLOCKER**: T042 y T043 (OTel + logs) deben completarse **antes del primer deploy
a stage o producción** — Principio VI de la constitución: "Cada feature DEBE ser monitoreable
desde el primer deploy en producción."

- [ ] T042 [P] Instrumentar con trazas OTel: spans por endpoint con atributos `item.id`, `item.codigo`, `operacion`, `user.rol`, `user.id` en todos los handlers de `loopi-api-v2/internal/items/handler.go`
- [ ] T043 [P] Agregar logs estructurados JSON con campos `user_id`, `rol`, `operacion`, `item_id`, `item_codigo` y `resultado` en cada operación de escritura (crear, actualizar, inactivar, reactivar, registrar costo) en `loopi-api-v2/internal/items/service.go`
- [ ] T044 [P] Implementar tests unitarios del servicio con mock del repositorio cubriendo los 16 casos de `quickstart.md §5` (creación duplicados, RBAC, edición código bloqueado, inactivar/reactivar, caché, costos tienda) en `loopi-api-v2/internal/items/service_test.go`
- [ ] T045 [P] Implementar tests unitarios de `ItemsComponent` con mock de `ItemsService` (casos: listado vacío empty state, filtro por tipo, paginación, botón inactivar con modal) en `loopi-web-v2/src/app/items/items.component.spec.ts`
- [ ] T046 [P] Implementar tests unitarios de `ItemsService` con mock de `HttpClient` (casos: crearItem exitoso, 409 código/nombre duplicado, editarItem código bloqueado, inactivar/reactivar, registrar costo) en `loopi-web-v2/src/app/items/items.service.spec.ts`
- [ ] T047 Ejecutar gates CI backend: `go build ./...`, `golangci-lint run`, `govulncheck ./...`, `gitleaks detect --no-git`, `go test ./...` en `loopi-api-v2` — todos deben pasar sin errores
- [ ] T048 [P] Ejecutar gates CI frontend: `ng build`, `npm audit --audit-level=high`, `gitleaks detect --no-git`, `ng test --watch=false` en `loopi-web-v2` — todos deben pasar sin errores
- [ ] T049 Ejecutar smoke tests completos del `specs/007-items-catalogo/quickstart.md §4` y verificar cada resultado esperado

---

## Dependencias y Orden de Ejecución

### Dependencias entre Fases

- **Phase 1 (Setup)**: Sin dependencias — comenzar de inmediato
- **Phase 2 (Fundacional)**: Depende de Phase 1 — **BLOQUEA todas las historias**
- **Phase 3 (US1)**: Depende de Phase 2 — primer incremento entregable (MVP)
- **Phase 4 (US4)**: Depende de Phase 2; T018-T019 (service) dependen de T016-T017 (repo)
- **Phase 5 (US2)**: Depende de Phase 2; T027 depende de T026 (estaEnUso)
- **Phase 6 (US3)**: Depende de Phase 2; T033 depende de T032
- **Phase 7 (US5)**: Depende de Phase 2; T038 depende de T037
- **Phase 8 (Polish)**: Depende de las historias deseadas completadas

### Dependencias entre Historias de Usuario

- **US1 (P1)**: Puede comenzar tras Phase 2 — sin dependencias en otras historias
- **US4 (P1)**: Puede comenzar tras Phase 2 — independiente de US1 (funciona con listado vacío)
- **US2 (P2)**: Puede comenzar tras Phase 2 — requiere US1 para tener items que editar
- **US3 (P2)**: Puede comenzar tras Phase 2 — requiere US1 para tener items que inactivar
- **US5 (P2)**: Puede comenzar tras Phase 2 — requiere US1 + US4 para contexto de detalle

### Dentro de Cada Historia

- Backend antes que frontend (el frontend requiere los endpoints para integrarse)
- Repository → Service → Handler (secuencia de capas)
- Service Angular antes del componente en frontend

### Oportunidades de Paralelismo

- T002 y T003 (migraciones): paralelas entre sí; T004 las aplica en secuencia
- T005, T006 (models Go, cache.go): paralelas con T002-T003
- En US1: T009 (repo) y T012 (frontend service) paralelas; T010 depende de T009
- En US4: T016, T017 (repos) paralelas entre sí; T018, T019 (services) paralelas entre sí una vez completos los repos
- En US4: T021, T023 (componentes Angular) paralelos entre sí
- En US2: T026 (estaEnUso) y T029 (frontend form) paralelos
- En US3: T032 (repos) y T035 (frontend service) paralelos
- En US5: T037 (repos) y T040 (frontend service) paralelos
- T042, T043, T044, T045, T046, T048: todas paralelas entre sí en Phase 8

---

## Ejemplo Paralelo: Historia de Usuario 1

```bash
# Una vez completada Phase 2, lanzar en paralelo:
Task T009: "Repository.InsertarItem en repository.go"
Task T012: "ItemsService con crearItem() en items.service.ts"

# Luego (T009 completo):
Task T010: "Service.CrearItem en service.go"
# En paralelo con T010:
Task T013: "ItemFormComponent en item-form.component.ts"

# Luego (T010 y T013 completos):
Task T011: "Handler POST /api/v1/items en handler.go"
Task T014: "Template HTML formulario en item-form.component.html"
Task T015: "Ruta /items/nuevo en items.routes.ts"
```

---

## Estrategia de Implementación

### MVP (Solo US1 + US4)

1. Completar Phase 1: Setup
2. Completar Phase 2: Fundacional (CRÍTICO)
3. Completar Phase 3: US1 — Crear item
4. Completar Phase 4: US4 — Consultar catálogo
5. **PARAR Y VALIDAR**: Crear item desde el frontend y verificar listado + detalle
6. Hacer demo / desplegar en stage si está listo

### Entrega Incremental

1. Setup + Fundacional → Base lista
2. US1 → Crear item (MVP funcional)
3. US4 → Listar + detalle → Catálogo consultable
4. US2 → Editar → Corrección de datos operativos
5. US3 → Inactivar/Reactivar → Ciclo de vida completo
6. US5 → Costos por tienda → Trazabilidad de precios
7. Polish → Tests + CI + Observabilidad

### Estrategia de Equipo Paralelo

Con dos desarrolladores:

1. Juntos completan Phase 1 + 2 (Setup + Fundacional)
2. Developer A: backend US1-US4 (endpoints POST + GET)
3. Developer B: frontend US1-US4 (formulario + listado + detalle)
4. Integran y validan MVP
5. Developer A: backend US2-US3-US5
6. Developer B: frontend US2-US3-US5 + tests

---

## Notas

- `[P]` = archivos distintos, sin dependencias de tareas incompletas
- La etiqueta `[USN]` vincula la tarea a la historia de usuario para trazabilidad
- Cada historia debe ser completamente verificable con los smoke tests de `quickstart.md`
- Confirmar resultados de `quickstart.md §4` antes de declarar completa cada historia
- Commitear tras cada tarea o grupo lógico
- Detener en cualquier checkpoint para validar la historia de forma independiente
