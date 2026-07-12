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

- [X] T001 Crear directorios `loopi-api-v2/internal/items/` y `loopi-web-v2/src/app/items/` según el plan de implementación

---

## Phase 2: Fundacional (Prerrequisitos bloqueantes)

**Propósito**: Migraciones, modelos, repositorio base, caché y routing — deben estar completos
antes de iniciar cualquier historia de usuario.

**⚠️ CRÍTICO**: Ninguna historia puede comenzar hasta completar esta fase.

- [X] T002 Escribir migración `NNNN_crear_tabla_items.up.sql` (tabla `items` con todos los campos, constraints `uq_items_codigo`, `uq_items_nombre`, FKs a `subcategorias`, `proveedores`, `unidades_medida`, `usuarios`, índices `ix_items_activo`, `ix_items_tipo_activo`, `ix_items_frecuencia_activo`) y `.down.sql` en `loopi-api-v2/db/migrations/`
- [X] T003 [P] Escribir migración `NNNN+1_crear_tabla_items_costos_tienda.up.sql` (tabla `items_costos_tienda` append-only con FK a `items`, `tiendas`, `usuarios` e índice `ix_ict_item_tienda_vigente`) y `.down.sql` en `loopi-api-v2/db/migrations/`
- [X] T004 Aplicar migraciones con `golang-migrate` y verificar tablas, índices y FKs en BD de desarrollo (`SHOW INDEX FROM items; SHOW INDEX FROM items_costos_tienda; DESCRIBE items`)
- [X] T005 [P] Definir structs Go `Item`, `ItemCostoTienda` y DTOs `CrearItemRequest`, `ActualizarItemRequest`, `ItemResponse`, `ItemDetalleResponse`, `CostoTiendaRequest`, `CostoTiendaResponse`, `ListaItemsResponse` en `loopi-api-v2/internal/items/models.go`
- [X] T006 [P] Implementar caché Ristretto con TTL 5 min, claves `"item:id:{id}"`, `"item:codigo:{codigo}"`, `"items:freq:diario"`, `"items:freq:semanal"`, `"items:freq:mensual"` y función `invalidarItems(itemID, codigo)` en `loopi-api-v2/internal/items/cache.go`
- [X] T007 Implementar `Repository` con pool de BD, interfaz base y constructor `NewRepository(db, cache)` en `loopi-api-v2/internal/items/repository.go`
- [X] T008 Implementar `Service.estaEnUso(ctx, itemID) bool` que verifica mediante EXISTS queries en `information_schema` si el item tiene al menos un registro en `inventarios_conteos_items`, `recetas_ingredientes` o `pedidos_lineas`; retorna `false` de forma segura si alguna de esas tablas aún no existe — requerida por T020 (US4) y T028 (US2) en `loopi-api-v2/internal/items/service.go`
- [X] T009 Registrar prefijo `/api/v1/items` con middleware de autenticación JWT en el router principal de `loopi-api-v2`

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

- [X] T010 [P] [US1] Implementar `Repository.InsertarItem(ctx, item, creadoPor)` con captura de error MySQL 1062 para código y nombre duplicado, y retorno del `id` autogenerado en `loopi-api-v2/internal/items/repository.go`
- [X] T011 [US1] Implementar `Service.CrearItem(ctx, req)` extrayendo `user_id` del contexto JWT, validando campos obligatorios, verificando que subcategoría/unidad de medida estén activas, verificando que proveedor (si enviado) esté activo, delegando a repo e invalidando caché al completar en `loopi-api-v2/internal/items/service.go`
- [X] T012 [US1] Implementar handler `POST /api/v1/items` con guard de rol `admin`, deserialización del body, traducción de errores del servicio a códigos HTTP (400/401/403/404/409/422) y respuesta 201 con `ItemDetalleResponse` en `loopi-api-v2/internal/items/handler.go`

### Frontend — US1

- [X] T013 [P] [US1] Crear `ItemsService` con señales de estado (`items`, `itemActual`, `cargando`, `error`) y método `crearItem(req: CrearItemRequest): Observable<ItemDetalleResponse>` en `loopi-web-v2/src/app/items/items.service.ts`
- [X] T014 [P] [US1] Implementar componente standalone `ItemFormComponent` con formulario reactivo de creación: campos para código, nombre, tipo (select), subcategoría (select con datos de API 005), unidad de medida (select con datos de API 004), proveedor (select opcional con datos de API 006), costo unitario, frecuencia (select), stock de seguridad y tiempo de entrega; validación on-blur, botón deshabilitado en loading en `loopi-web-v2/src/app/items/item-form.component.ts`
- [X] T015 [US1] Implementar template HTML del formulario de creación con todos los campos, marcación de campos obligatorios (`*`), mensajes de error de validación (`text-red-600` bajo el campo), spinner inline en el botón de submit durante el guardado y toast de éxito 3 s en `loopi-web-v2/src/app/items/item-form.component.html`
- [X] T016 [US1] Configurar ruta lazy-loaded `/items/nuevo` con guard de rol `admin` y `<h1>` "Nuevo Item" en `loopi-web-v2/src/app/items/items.routes.ts`

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

- [X] T017 [P] [US4] Implementar `Repository.ListarItems(ctx, filtros ListarItemsFiltros, pagina, porPagina)` con query dinámica según filtros activos, COUNT para `total` y LIMIT/OFFSET para paginación en `loopi-api-v2/internal/items/repository.go`
- [X] T018 [P] [US4] Implementar `Repository.ObtenerItemPorID(ctx, id)` con JOIN a subcategorias, proveedores y unidades_medida para nombres en `loopi-api-v2/internal/items/repository.go`
- [X] T019 [US4] Implementar `Service.ListarItems(ctx, filtros, pagina, porPagina)` con caché para consultas por frecuencia (`items:freq:{frecuencia}`) cuando el filtro sea solo frecuencia+activo en `loopi-api-v2/internal/items/service.go`
- [X] T020 [US4] Implementar `Service.ObtenerItem(ctx, id)` con cache-first por clave `"item:id:{id}"` y llamada a `estaEnUso(ctx, id)` para incluir el campo `esta_en_uso` en la respuesta en `loopi-api-v2/internal/items/service.go`
- [X] T021 [US4] Implementar handlers `GET /api/v1/items` (acepta query params `tipo`, `frecuencia`, `activo`, `pagina`, `por_pagina`) y `GET /api/v1/items/{id}` en `loopi-api-v2/internal/items/handler.go`

### Frontend — US4

- [X] T022 [P] [US4] Implementar componente standalone `ItemsComponent` con señal de listado paginado, filtros reactivos (tipo, frecuencia, estado) y controles de paginación; el filtro activa una nueva llamada a `ItemsService.listarItems()` en `loopi-web-v2/src/app/items/items.component.ts`
- [X] T023 [US4] Implementar template HTML de listado con tabla (columnas: código, nombre, tipo, frecuencia, estado), controles de filtro (selects), paginación y empty state "Aún no hay items registrados. Crea el primero →" en `loopi-web-v2/src/app/items/items.component.html`
- [X] T024 [P] [US4] Implementar componente standalone `ItemDetalleComponent` que carga el item por ID de ruta y muestra todos sus atributos (código, nombre, tipo, subcategoría, proveedor, unidad de medida, costo global, frecuencia, stock de seguridad, tiempo de entrega, estado, en uso) en `loopi-web-v2/src/app/items/item-detalle.component.ts`
- [X] T025 [US4] Implementar template HTML de detalle con todos los atributos, breadcrumb "Items / {nombre}", badge de estado (activo/inactivo) y badge "En uso" cuando `esta_en_uso=true` en `loopi-web-v2/src/app/items/item-detalle.component.html`
- [X] T026 [US4] Agregar métodos `listarItems(filtros, pagina, porPagina)` y `obtenerItem(id)` a `ItemsService`, y rutas `/items` (listado) y `/items/:id` (detalle) en `loopi-web-v2/src/app/items/items.service.ts` y `items.routes.ts`

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

- [X] T027 [P] [US2] Implementar `Repository.ActualizarItem(ctx, id, campos, actualizadoPor)` con UPDATE dinámico solo de campos modificados, captura de error MySQL 1062 para nombre duplicado y retorno del item actualizado en `loopi-api-v2/internal/items/repository.go`
- [X] T028 [US2] Implementar `Service.ActualizarItem(ctx, id, req)` con validaciones: (1) bloquear `codigo` si `estaEnUso(ctx, id)=true` (implementada en T008) → 422 `codigo_en_uso`; (2) verificar que la nueva `subcategoria_id` (si cambia) esté activa → 422 `subcategoria_inactiva`; (3) verificar que el nuevo `proveedor_id` (si enviado y cambia) esté activo → 422 `proveedor_inactivo`; (4) verificar que la nueva `unidad_medida_id` (si cambia) esté activa → 422 `unidad_medida_inactiva`; (5) si `unidad_medida_id` cambia, invocar stub `tieneHistorialStock(itemID)` (retorna `false` inicialmente — **TODO rastreado en `specs/009-inventario-conteo/spec.md` §Dependencias**: implementar con tablas de 009-inventario) y exigir `confirmar_cambio_unidad=true` si retorna `true` → 422 `cambio_unidad_requiere_confirmacion`; (6) unicidad de nombre → 409 `nombre_duplicado` en `loopi-api-v2/internal/items/service.go`
- [X] T029 [US2] Implementar handler `PUT /api/v1/items/{id}` con guard de rol `admin` y manejo de 400/401/403/404/409/422 en `loopi-api-v2/internal/items/handler.go`

### Frontend — US2

- [X] T030 [P] [US2] Extender `ItemFormComponent` con modo edición: cargar datos actuales por ID, deshabilitar campo `codigo` cuando `item.esta_en_uso=true`, mostrar modal de confirmación "¿Confirmar cambio de unidad de medida? El historial de stock quedará en unidades inconsistentes." cuando se modifica `unidad_medida_id` en `loopi-web-v2/src/app/items/item-form.component.ts`
- [X] T031 [US2] Actualizar template HTML con campo `codigo` en modo readonly cuando `esta_en_uso=true` (con tooltip "Código bloqueado — el item está en uso"), modal de confirmación de cambio de unidad con botón destructivo y botón cancelar en `loopi-web-v2/src/app/items/item-form.component.html`
- [X] T032 [US2] Agregar método `editarItem(id, req)` a `ItemsService` y ruta `/items/:id/editar` en `loopi-web-v2/src/app/items/items.service.ts` y `items.routes.ts`

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

- [X] T033 [P] [US3] Implementar `Repository.InactivarItem(ctx, id, actualizadoPor)` y `Repository.ReactivarItem(ctx, id, actualizadoPor)` con UPDATE `activo` y `actualizado_en=NOW()` en `loopi-api-v2/internal/items/repository.go`
- [X] T034 [US3] Implementar `Service.InactivarItem(ctx, id)` (verifica activo=1 antes; retorna 422 `item_ya_inactivo` si ya está inactivo) y `Service.ReactivarItem(ctx, id)` (verifica activo=0; retorna 422 `item_ya_activo` si ya está activo) con invalidación de caché en ambas operaciones; **nota:** la advertencia de RF-ITEM-03.6 (item inactivo en receta activa) es responsabilidad de 008-menu-recetas — la invalidación de caché en `InactivarItem` garantiza que 008 detecte el cambio en su próxima consulta en `loopi-api-v2/internal/items/service.go`
- [X] T035 [US3] Implementar handlers `PATCH /api/v1/items/{id}/inactivar` y `PATCH /api/v1/items/{id}/reactivar` con guard de rol `admin` y manejo de 401/403/404/422 en `loopi-api-v2/internal/items/handler.go`

### Frontend — US3

- [X] T036 [P] [US3] Agregar métodos `inactivarItem(id)` y `reactivarItem(id)` a `ItemsService` en `loopi-web-v2/src/app/items/items.service.ts`
- [X] T037 [US3] Implementar en `ItemsComponent` y `ItemDetalleComponent`: botón "Inactivar" / "Reactivar" con modal de confirmación "¿Inactivar este item? Dejará de aparecer en nuevos inventarios y recetas.", spinner inline durante la acción, toast de éxito verde 3 s y actualización reactiva del estado en la lista en `loopi-web-v2/src/app/items/items.component.ts`, `items.component.html`, `item-detalle.component.ts` y `item-detalle.component.html`

**Checkpoint**: US3 funcional — ciclo de vida activo/inactivo operativo en backend y frontend.

---

## Phase 7: Historia de Usuario 5 — Costos por tienda (P2)

**Meta**: El admin puede registrar un costo específico por tienda para un item, sobreescribiendo
el costo global. El historial de cambios se preserva (append-only). Desde el detalle del item
se consulta el historial por tienda con el costo vigente identificado.

**Prueba Independiente**: `POST /api/v1/items/{id}/costos_tienda` con `{"tienda_id":1,
"costo_unitario":3400}` retorna 201. Segundo POST con nuevo costo 3600 retorna 201 (historial).
`GET /api/v1/items/{id}/costos_tienda` retorna 2 entradas para tienda 1 con `costo_vigente=3600`.
Ambos endpoints devuelven 403 `sin_permiso` para roles distintos de `admin`.
Ver `quickstart.md §4.4`.

### Backend — US5

- [X] T038 [P] [US5] Implementar `Repository.InsertarCostoTienda(ctx, itemID, tiendaID, costoUnitario, creadoPor)` (INSERT con `vigente_desde=NOW()`) y `Repository.ListarCostosTienda(ctx, itemID)` (historial completo ordenado por `vigente_desde DESC`, agrupado por tienda) en `loopi-api-v2/internal/items/repository.go`
- [X] T039 [US5] Implementar `Service.RegistrarCostoTienda(ctx, itemID, req)` con validaciones: item existe y está activo, tienda existe (404 `tienda_no_encontrada`) y está activa (422 `tienda_inactiva`), `costo_unitario > 0` (400 `costo_invalido`), y `Service.ObtenerHistorialCostos(ctx, itemID)` que construye la respuesta agrupada con `costo_vigente` (primer elemento de cada tienda) y `costo_global` del item en `loopi-api-v2/internal/items/service.go`
- [X] T040 [US5] Implementar handlers `POST /api/v1/items/{id}/costos_tienda` (201) y `GET /api/v1/items/{id}/costos_tienda` (200), ambos con guard de rol `admin` (403 `sin_permiso` para el resto de roles, según matriz `§2.5` "Ver historial de costos") en `loopi-api-v2/internal/items/handler.go`

### Frontend — US5

- [X] T041 [P] [US5] Agregar métodos `registrarCostoTienda(itemID, req)` y `obtenerCostosTienda(itemID)` a `ItemsService` en `loopi-web-v2/src/app/items/items.service.ts`
- [X] T042 [US5] Implementar sección "Costos por tienda" en `ItemDetalleComponent`: tabla con columnas tienda / costo vigente / última actualización; formulario inline para registrar nuevo costo (select de tienda + campo de costo); spinner durante el guardado y toast de éxito 3 s; si tienda no tiene costo propio mostrar "(usa costo global: ${costo_global})" en `loopi-web-v2/src/app/items/item-detalle.component.ts` y `item-detalle.component.html`

**Checkpoint**: US5 funcional — historial de costos por tienda visible y actualizable desde el detalle.

---

## Phase 8: Polish y Aspectos Transversales

**Propósito**: Observabilidad, tests unitarios y validación de gates de CI.

**⚠️ DEPLOY BLOCKER**: T043 y T044 (OTel + logs) deben completarse **antes del primer deploy
a stage o producción** — Principio VI de la constitución: "Cada feature DEBE ser monitoreable
desde el primer deploy en producción."

- [X] T043 [P] Instrumentar con trazas y métricas OTel según `spec.md §Observabilidad`: spans `items.crear`, `items.actualizar`, `items.cambiar_estado`, `items.costos_tienda.registrar` con atributos `resultado`, `item.id`/`item.codigo`, `tienda_id` (solo en costos por tienda), `user.rol`, `user.id`; métricas `items.creacion.duration`/`.total`, `items.actualizacion.duration`/`.total`, `items.costos_tienda.registro.total`, `items.listado.duration` en todos los handlers de `loopi-api-v2/internal/items/handler.go`
- [X] T044 [P] Agregar logs estructurados JSON con campos `user_id`, `rol`, `operacion`, `item_id`, `item_codigo` y `resultado` en cada operación de escritura (crear, actualizar, inactivar, reactivar, registrar costo) en `loopi-api-v2/internal/items/service.go`
- [X] T045 [P] Implementar tests unitarios del servicio con mock del repositorio cubriendo los 16 casos de `quickstart.md §5` más `TestCambiarFrecuenciaNoAfectaHistorialPrevio` (verificar que PUT con nueva `frecuencia_inventario` retorna 200 con el nuevo valor y no altera ningún registro de historial de conteos previos) en `loopi-api-v2/internal/items/service_test.go`
- [X] T046 [P] Implementar tests unitarios de `ItemsComponent` con mock de `ItemsService` (casos: listado vacío empty state, filtro por tipo, paginación, botón inactivar con modal) en `loopi-web-v2/src/app/items/items.component.spec.ts`
- [X] T047 [P] Implementar tests unitarios de `ItemsService` con mock de `HttpClient` (casos: crearItem exitoso, 409 código/nombre duplicado, editarItem código bloqueado, inactivar/reactivar, registrar costo) en `loopi-web-v2/src/app/items/items.service.spec.ts`
- [X] T048 Ejecutar gates CI backend: `go build ./...`, `golangci-lint run`, `govulncheck ./...`, `gitleaks detect --no-git`, `go test ./...` en `loopi-api-v2` — todos deben pasar sin errores
- [X] T049 [P] Ejecutar gates CI frontend: `ng build`, `npm audit --audit-level=high`, `gitleaks detect --no-git`, `ng test --watch=false` en `loopi-web-v2` — todos deben pasar sin errores
- [X] T050 Ejecutar smoke tests completos del `specs/007-items-catalogo/quickstart.md §4` y verificar cada resultado esperado

---

## Dependencias y Orden de Ejecución

### Dependencias entre Fases

- **Phase 1 (Setup)**: Sin dependencias — comenzar de inmediato
- **Phase 2 (Fundacional)**: Depende de Phase 1 — **BLOQUEA todas las historias**
- **Phase 3 (US1)**: Depende de Phase 2 — primer incremento entregable (MVP)
- **Phase 4 (US4)**: Depende de Phase 2; T019-T020 (service) dependen de T017-T018 (repo)
- **Phase 5 (US2)**: Depende de Phase 2; T028 depende de T027 (repositorio) y de T008 (estaEnUso, Phase 2)
- **Phase 6 (US3)**: Depende de Phase 2; T034 depende de T033
- **Phase 7 (US5)**: Depende de Phase 2; T039 depende de T038
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
- En US1: T010 (repo) y T013 (frontend service) paralelas; T011 depende de T010
- En US4: T017, T018 (repos) paralelas entre sí; T019, T020 (services) paralelas entre sí una vez completos los repos
- En US4: T022, T024 (componentes Angular) paralelos entre sí
- En US2: T027 (repositorio) y T030 (frontend form) paralelos; T028 depende de T027 y T008
- En US3: T033 (repos) y T036 (frontend service) paralelos
- En US5: T038 (repos) y T041 (frontend service) paralelos
- T043, T044, T045, T046, T047, T049: todas paralelas entre sí en Phase 8

---

## Ejemplo Paralelo: Historia de Usuario 1

```bash
# Una vez completada Phase 2, lanzar en paralelo:
Task T010: "Repository.InsertarItem en repository.go"
Task T013: "ItemsService con crearItem() en items.service.ts"

# Luego (T010 completo):
Task T011: "Service.CrearItem en service.go"
# En paralelo con T011:
Task T014: "ItemFormComponent en item-form.component.ts"

# Luego (T011 y T014 completos):
Task T012: "Handler POST /api/v1/items en handler.go"
Task T015: "Template HTML formulario en item-form.component.html"
Task T016: "Ruta /items/nuevo en items.routes.ts"
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

### Estado de implementación (2026-07-12)

Implementación completa en `loopi-api-v2` (PR #28, mergeado a `develop`) y `loopi-web-v2`
(PR #29, mergeado a `develop`, incluye el fix de UX que consolida detalle/formulario en
una sola pantalla — ver PR #29 commit `783e8e9`). T001-T049 completadas, incluyendo backend
(migraciones, modelo, repositorio, caché Ristretto, servicio, handlers, OTel, logs
estructurados), frontend (`ItemsService`, `ItemsListaComponent`, `ItemFormComponent`, rutas
y nav) y tests unitarios (16 casos de servicio backend + suites de componentes/servicio
frontend, todos en verde).

**T004 y T050 verificadas y cerradas por el equipo (2026-07-12)** fuera de este entorno de
sesión (que no tiene BD MySQL disponible): migraciones aplicadas en BD de desarrollo y
smoke tests de `quickstart.md §4` confirmados OK contra el stack real.

**Feature 007-items-catalogo: completa.** 50/50 tareas cerradas.
