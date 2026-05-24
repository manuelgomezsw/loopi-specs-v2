# Tasks: 005-categorias-catalogo

**Input**: Documentos de diseño en `specs/005-categorias-catalogo/`

**Artefactos usados**: plan.md, spec.md, research.md, data-model.md, contracts/api.md, quickstart.md

**Tests**: Incluidos en la fase de polish (no TDD). Los tests unitarios de `quickstart.md §5`
son los mínimos requeridos.

**Organización**: Una fase por historia de usuario para permitir entrega incremental e
independiente de cada historia.

## Formato: `[ID] [P?] [Story] Descripción con ruta de archivo`

- **[P]**: Se puede ejecutar en paralelo (archivos distintos, sin dependencias de tareas incompletas)
- **[Story]**: Historia de usuario a la que pertenece la tarea (US1…US5)
- Todas las tareas incluyen la ruta exacta del archivo

---

## Phase 1: Setup (Estructura de directorios)

**Propósito**: Crear la estructura de carpetas del módulo en ambos repos antes de escribir código.

- [ ] T001 Crear directorios `loopi-api-v2/internal/categorias/` y `loopi-web-v2/src/app/categorias/` según el plan de implementación

---

## Phase 2: Fundacional (Prerrequisitos bloqueantes)

**Propósito**: Migraciones, modelos, repositorio base, caché y routing — deben estar completos
antes de iniciar cualquier historia de usuario.

**⚠️ CRÍTICO**: Ninguna historia puede comenzar hasta completar esta fase.

- [ ] T002 Escribir migración `NNNN_crear_tabla_categorias.up.sql` y `.down.sql` con tabla, constraint `uq_categorias_nombre`, FK a `usuarios` e índice `ix_categorias_activo` en `loopi-api-v2/db/migrations/`
- [ ] T003 [P] Escribir migración `NNNN+1_crear_tabla_subcategorias.up.sql` y `.down.sql` con tabla, constraint `uq_subcategorias_nombre_categoria`, FK a `categorias` y `usuarios`, e índice `ix_subcategorias_categoria_activo` en `loopi-api-v2/db/migrations/`
- [ ] T004 Aplicar migraciones con `golang-migrate` y verificar tablas, índices y FKs en BD de desarrollo (`SHOW INDEX FROM categorias; SHOW INDEX FROM subcategorias`)
- [ ] T005 [P] Definir structs Go `Categoria`, `Subcategoria` y tipos de respuesta `CategoriaResponse`, `SubcategoriaResponse`, `CatalogoResponse` en `loopi-api-v2/internal/categorias/models.go`
- [ ] T006 Implementar `Repository` con pool de BD, interfaz y constructor `NewRepository(db)` en `loopi-api-v2/internal/categorias/repository.go`
- [ ] T007 Implementar caché Ristretto (TTL 5 min, claves `cat:all`, `cat:id:{id}`, `subcat:all`, `subcat:categoria:{id}`, `subcat:id:{id}`, función `invalidarCatalogo`) en `loopi-api-v2/internal/categorias/cache.go`
- [ ] T008 Registrar prefijos `/api/v1/categorias` y `/api/v1/subcategorias` en el router principal con middleware de autenticación JWT en `loopi-api-v2`

**Checkpoint**: Estructura lista — las historias de usuario pueden comenzar.

---

## Phase 3: Historia de Usuario 1 — Crear una categoría (P1) 🎯 MVP

**Meta**: El admin puede crear una categoría con nombre único (case-insensitive). Un intento de
nombre duplicado es rechazado con 409. Roles no admin reciben 403.

**Prueba Independiente**: `POST /api/v1/categorias` con `{"nombre":"Lácteo"}` retorna 201.
Segundo `POST` con `{"nombre":"lácteo"}` retorna 409. `GET /api/v1/categorias` muestra "Lácteo"
activa. Intento desde rol barista retorna 403.

### Backend — US1

- [ ] T009 [P] [US1] Implementar `Repository.InsertarCategoria(ctx, nombre, creadoPor)` y `Repository.ListarCategorias(ctx, soloActivas bool)` con consulta básica en `loopi-api-v2/internal/categorias/repository.go`
- [ ] T010 [US1] Implementar `Service.CrearCategoria(ctx, nombre)` extrayendo `user_id` del contexto JWT, delegando a repo e invalidando caché al completar en `loopi-api-v2/internal/categorias/service.go`
- [ ] T011 [US1] Implementar handler `POST /api/v1/categorias` con guard de rol `admin`, deserialización del body, manejo de 400/401/403/409 y respuesta 201 en `loopi-api-v2/internal/categorias/handler.go`

### Frontend — US1

- [ ] T012 [P] [US1] Crear `CategoriasService` con señales de estado y métodos `crearCategoria(nombre: string)` y `obtenerCategorias(soloActivas?: boolean)` en `loopi-web-v2/src/app/categorias/categorias.service.ts`
- [ ] T013 [US1] Implementar componente standalone `CategoriasComponent` con formulario inline de creación (validación on-blur, botón deshabilitado en loading, campo `*` obligatorio) en `loopi-web-v2/src/app/categorias/categorias.component.ts`
- [ ] T014 [US1] Implementar template HTML con listado básico de categorías, formulario de creación y empty state "Aún no hay categorías registradas. Crea la primera →" en `loopi-web-v2/src/app/categorias/categorias.component.html`
- [ ] T015 [US1] Configurar ruta lazy-loaded `/categorias` con guard de rol `admin` y `<h1>` único en `loopi-web-v2/src/app/categorias/categorias.routes.ts`

**Checkpoint**: US1 funcional — crear categoría y ver listado básico operativo en backend y frontend.

---

## Phase 4: Historia de Usuario 2 — Crear una subcategoría (P1)

**Meta**: El admin puede crear una subcategoría dentro de una categoría existente. El nombre es
único dentro de la categoría (case-insensitive), pero puede repetirse entre categorías distintas.
No se puede crear una subcategoría bajo una categoría inactiva.

**Prueba Independiente**: `POST /api/v1/subcategorias` con `{"nombre":"Quesos","categoria_id":1}`
retorna 201. Segundo POST con `"nombre":"quesos"` en misma categoría retorna 409. POST con mismo
nombre en categoría distinta retorna 201. POST con `categoria_id` de categoría inactiva retorna
422 `categoria_padre_inactiva`.

### Backend — US2

- [ ] T016 [P] [US2] Implementar `Repository.InsertarSubcategoria(ctx, nombre, categoriaID, creadoPor)` y `Repository.ListarSubcategoriasPorCategoria(ctx, categoriaID, soloActivas bool)` en `loopi-api-v2/internal/categorias/repository.go`
- [ ] T017 [US2] Implementar `Service.CrearSubcategoria(ctx, nombre, categoriaID)` con validaciones: categoría padre existe y está activa + nombre único en la categoría (capturar error 1062 de MySQL) en `loopi-api-v2/internal/categorias/service.go`
- [ ] T018 [US2] Implementar handler `POST /api/v1/subcategorias` con guard de rol `admin` y manejo de 400/401/403/404/409/422 en `loopi-api-v2/internal/categorias/handler.go`

### Frontend — US2

- [ ] T019 [P] [US2] Agregar métodos `crearSubcategoria(nombre: string, categoriaId: number)` a `CategoriasService` en `loopi-web-v2/src/app/categorias/categorias.service.ts`
- [ ] T020 [US2] Agregar lógica de formulario inline para crear subcategoría dentro de cada fila de categoría (toggle visible al hacer clic en "＋ Subcategoría") en `loopi-web-v2/src/app/categorias/categorias.component.ts`
- [ ] T021 [US2] Actualizar template HTML con subcategorías anidadas bajo su categoría y formulario de nueva subcategoría expandible en `loopi-web-v2/src/app/categorias/categorias.component.html`

**Checkpoint**: US2 funcional — crear subcategorías con validación de unicidad por categoría.

---

## Phase 5: Historia de Usuario 5 — Consultar el catálogo de categorías (P1)

**Meta**: El admin ve el catálogo completo con categorías y subcategorías agrupadas, cada una
con nombre, estado activa/inactiva y cantidad de items asignados. Puede filtrar por estado.

**Prueba Independiente**: `GET /api/v1/categorias` retorna árbol con subcategorías anidadas y
`total_items`. `GET /api/v1/categorias?activo=true` filtra solo activas. Al seleccionar una
subcategoría se muestra su `total_items`.

### Backend — US5

- [ ] T022 [US5] Implementar `Service.ObtenerCatalogo(ctx, soloActivas bool)` que construye la respuesta anidada con `total_items` (JOIN graceful a `items` — retorna 0 si la tabla no existe aún) en `loopi-api-v2/internal/categorias/service.go`
- [ ] T023 [US5] Implementar handlers `GET /api/v1/categorias` (catálogo con subcategorías anidadas, parámetro `?activo`) y `GET /api/v1/categorias/{id}` con detalle completo en `loopi-api-v2/internal/categorias/handler.go`

### Frontend — US5

- [ ] T024 [P] [US5] Agregar métodos `obtenerCatalogo(activo?: boolean)` y `obtenerCategoria(id: number)` a `CategoriasService` en `loopi-web-v2/src/app/categorias/categorias.service.ts`
- [ ] T025 [US5] Implementar vista árbol completa en el template: categorías expandibles con subcategorías, badges de estado (activa/inactiva) y contador `total_items` por subcategoría en `loopi-web-v2/src/app/categorias/categorias.component.html`
- [ ] T026 [US5] Implementar filtro de estado (Todas / Solo activas / Solo inactivas) con señales reactivas y actualización del árbol sin recarga completa en `loopi-web-v2/src/app/categorias/categorias.component.ts`

**Checkpoint**: US5 funcional — vista completa del catálogo con filtrado por estado.

---

## Phase 6: Historia de Usuario 3 — Editar una categoría o subcategoría (P2)

**Meta**: El admin puede corregir el nombre de una categoría o subcategoría. El cambio no
afecta los items asignados. Nombres duplicados son rechazados con 409.

**Prueba Independiente**: `PUT /api/v1/categorias/{id}` con `{"nombre":"Lácteo"}` (corrige
"Lacteo") retorna 200 y todos los items conservan su clasificación. `PUT` con nombre de otra
subcategoría existente en la misma categoría retorna 409.

### Backend — US3

- [ ] T027 [P] [US3] Implementar `Repository.ActualizarCategoria(ctx, id, nombre, actualizadoPor)` y `Repository.ActualizarSubcategoria(ctx, id, nombre, actualizadoPor)` en `loopi-api-v2/internal/categorias/repository.go`
- [ ] T028 [P] [US3] Implementar `Service.EditarCategoria(ctx, id, nombre)` y `Service.EditarSubcategoria(ctx, id, nombre)` con validación de nombre único e invalidación de caché en `loopi-api-v2/internal/categorias/service.go`
- [ ] T029 [P] [US3] Implementar handlers `PUT /api/v1/categorias/{id}` y `PUT /api/v1/subcategorias/{id}` con guard de rol `admin` y manejo de 400/401/403/404/409 en `loopi-api-v2/internal/categorias/handler.go`

### Frontend — US3

- [ ] T030 [P] [US3] Agregar métodos `editarCategoria(id: number, nombre: string)` y `editarSubcategoria(id: number, nombre: string)` a `CategoriasService` en `loopi-web-v2/src/app/categorias/categorias.service.ts`
- [ ] T031 [US3] Implementar edición inline: clic en el nombre activa `<input>` editable; Enter o blur guarda, Esc cancela; spinner inline en el botón durante el guardado en `loopi-web-v2/src/app/categorias/categorias.component.ts`
- [ ] T032 [US3] Actualizar template HTML con campos de edición inline y mensajes de error de validación (`text-red-600` bajo el campo) en `loopi-web-v2/src/app/categorias/categorias.component.html`

**Checkpoint**: US3 funcional — edición de nombres con validación de duplicados.

---

## Phase 7: Historia de Usuario 4 — Inactivar o reactivar (P2)

**Meta**: El admin puede inactivar una categoría (cascade a subcategorías activas con
confirmación previa) o subcategoría. Puede reactivar ambas. Reactivar una categoría no
reactiva sus subcategorías automáticamente. No se puede reactivar una subcategoría si su
categoría padre está inactiva.

**Prueba Independiente**: `GET /api/v1/categorias/{id}/impacto` retorna `subcategorias_activas`.
`PATCH .../inactivar` inactiva la categoría y N subcategorías en una transacción.
`PATCH .../reactivar` en la categoría no reactiva sus subcategorías (siguen inactivas).
`PATCH subcategorias/{id}/reactivar` con categoría padre inactiva retorna 422.

### Backend — US4

- [ ] T033 [P] [US4] Implementar `Repository.ContarSubcategoriasActivas(ctx, categoriaID)`, `Repository.InactivarCategoria(ctx, id, actualizadoPor)` e `Repository.InactivarSubcategoriasDeCategoria(ctx, categoriaID, actualizadoPor)` en `loopi-api-v2/internal/categorias/repository.go`
- [ ] T034 [P] [US4] Implementar `Repository.ReactivarCategoria(ctx, id, actualizadoPor)`, `Repository.InactivarSubcategoria(ctx, id, actualizadoPor)` y `Repository.ReactivarSubcategoria(ctx, id, actualizadoPor)` en `loopi-api-v2/internal/categorias/repository.go`
- [ ] T035 [US4] Implementar `Service.InactivarCategoria(ctx, id)` con transacción que inactiva la categoría y todas sus subcategorías activas en una sola operación atómica en `loopi-api-v2/internal/categorias/service.go`
- [ ] T036 [P] [US4] Implementar `Service.ObtenerImpactoCategoria(ctx, id)`, `Service.InactivarSubcategoria(ctx, id)` y `Service.ReactivarCategoria(ctx, id)` en `loopi-api-v2/internal/categorias/service.go`
- [ ] T037 [US4] Implementar `Service.ReactivarSubcategoria(ctx, id)` con validación: retorna 422 `categoria_padre_inactiva` si `categorias.activo = 0` para el `categoria_id` de la subcategoría en `loopi-api-v2/internal/categorias/service.go`
- [ ] T038 [P] [US4] Implementar handlers `GET /api/v1/categorias/{id}/impacto`, `PATCH /api/v1/categorias/{id}/inactivar` y `PATCH /api/v1/categorias/{id}/reactivar` en `loopi-api-v2/internal/categorias/handler.go`
- [ ] T039 [P] [US4] Implementar handlers `PATCH /api/v1/subcategorias/{id}/inactivar` y `PATCH /api/v1/subcategorias/{id}/reactivar` en `loopi-api-v2/internal/categorias/handler.go`

### Frontend — US4

- [ ] T040 [P] [US4] Agregar métodos `impactoCategoria(id)`, `inactivarCategoria(id)`, `reactivarCategoria(id)`, `inactivarSubcategoria(id)` y `reactivarSubcategoria(id)` a `CategoriasService` en `loopi-web-v2/src/app/categorias/categorias.service.ts`
- [ ] T041 [US4] Implementar flujo de confirmación en el componente: llamar a `impactoCategoria(id)`, si `subcategorias_activas > 0` mostrar modal "Esta categoría tiene N subcategoría(s) activa(s). Al inactivarla, todas quedarán inactivas. ¿Confirmar?", luego llamar a `inactivarCategoria(id)` en `loopi-web-v2/src/app/categorias/categorias.component.ts`
- [ ] T042 [US4] Implementar botones de acción inactivar/reactivar con estados de carga (spinner inline), toasts de éxito (3 s) y error (5 s), y atributos ARIA (`aria-label`, `aria-disabled`) en `loopi-web-v2/src/app/categorias/categorias.component.html`

**Checkpoint**: US4 funcional — inactivación con cascade y reactivación selectiva operativas.

---

## Phase 8: Polish y Aspectos Transversales

**Propósito**: Observabilidad, tests unitarios y validación de gates de CI.

- [ ] T043 [P] Instrumentar con trazas OTel: spans por endpoint con atributos `categoria.id`, `operacion`, `user.rol` en `loopi-api-v2/internal/categorias/handler.go`
- [ ] T044 [P] Agregar logs estructurados JSON con campos `user_id`, `rol`, `operacion`, `categoria_id`, `subcategoria_id` y `resultado` en cada operación de escritura en `loopi-api-v2/internal/categorias/service.go`
- [ ] T045 [P] Implementar tests unitarios del servicio con mock del repositorio cubriendo los 12 casos de `quickstart.md §5` en `loopi-api-v2/internal/categorias/service_test.go`
- [ ] T046 [P] Implementar tests unitarios del componente Angular (mock de `CategoriasService`) con casos: listado vacío, crear categoría, error 409, flujo de confirmación de inactivación en `loopi-web-v2/src/app/categorias/categorias.component.spec.ts`
- [ ] T047 Ejecutar gates CI backend: `go build ./...`, `golangci-lint run`, `govulncheck ./...`, `gitleaks detect --no-git`, `go test ./...` en `loopi-api-v2` — todos deben pasar sin errores
- [ ] T048 [P] Ejecutar gates CI frontend: `ng build`, `npm audit --audit-level=high`, `gitleaks detect --no-git`, `ng test --watch=false` en `loopi-web-v2` — todos deben pasar sin errores
- [ ] T049 Ejecutar smoke tests completos del `specs/005-categorias-catalogo/quickstart.md §4` y verificar cada resultado esperado

---

## Dependencias y Orden de Ejecución

### Dependencias entre Fases

- **Phase 1 (Setup)**: Sin dependencias — comenzar de inmediato
- **Phase 2 (Fundacional)**: Depende de Phase 1 — **BLOQUEA todas las historias**
- **Phase 3 (US1)**: Depende de Phase 2 — primer incremento entregable
- **Phase 4 (US2)**: Depende de Phase 2; integra con US1 en la UI
- **Phase 5 (US5)**: Depende de Phase 2; extiende la vista de US1 y US2
- **Phase 6 (US3)**: Depende de Phase 2; extiende la vista existente
- **Phase 7 (US4)**: Depende de Phase 2; extiende la vista existente
- **Phase 8 (Polish)**: Depende de todas las historias deseadas completadas

### Dependencias entre Historias de Usuario

- **US1 (P1)**: Puede comenzar tras Phase 2 — sin dependencias en otras historias
- **US2 (P1)**: Puede comenzar tras Phase 2 — requiere que categorías existan en BD (ya garantizado por Phase 2)
- **US5 (P1)**: Puede comenzar tras Phase 2 — extiende el GET /categorias de US1 (compatible)
- **US3 (P2)**: Puede comenzar tras Phase 2 — agrega operaciones PUT independientes
- **US4 (P2)**: Puede comenzar tras Phase 2 — agrega operaciones PATCH independientes

### Dentro de Cada Historia

- Backend antes de frontend (el frontend necesita el endpoint para integrarse)
- Repository antes de service antes de handler
- Service antes de handler en backend
- Service Angular antes del componente en frontend

### Oportunidades de Paralelismo

- T002 y T003 (migraciones): paralelas
- T005 (models Go) puede hacerse en paralelo con T002-T003
- T009 (backend US1) y T012 (frontend US1): paralelas una vez disponible T008
- T016 (backend US2) y T019 (frontend US2): paralelas
- T027-T029 (backend US3): todas paralelas entre sí
- T033-T034 (repos US4): paralelas entre sí
- T036 (services US4 paralelos) con T035: paralela
- T043, T044, T045, T046, T048: todas paralelas entre sí

---

## Ejemplo Paralelo: Historia de Usuario 1

```bash
# Una vez completada Phase 2, lanzar en paralelo:
Task T009: "Repository.InsertarCategoria + ListarCategorias en repository.go"
Task T012: "Crear CategoriasService con crearCategoria() en categorias.service.ts"

# Luego (T009 y T012 completos):
Task T010: "Service.CrearCategoria en service.go"
# En paralelo con T010:
Task T013: "Componente con formulario en categorias.component.ts"

# Luego:
Task T011: "Handler POST /api/v1/categorias en handler.go"
Task T014: "Template HTML en categorias.component.html"
Task T015: "Rutas lazy-loaded en categorias.routes.ts"
```

---

## Estrategia de Implementación

### MVP (Solo US1)

1. Completar Phase 1: Setup
2. Completar Phase 2: Fundacional (CRÍTICO)
3. Completar Phase 3: US1 — Crear categoría
4. **PARAR Y VALIDAR**: Crear categoría desde el frontend, verificar en listado
5. Hacer demo / desplegar en stage si está listo

### Entrega Incremental

1. Setup + Fundacional → Base lista
2. US1 → Crear categoría (MVP funcional)
3. US2 → Crear subcategoría → Demo extendido
4. US5 → Vista completa del catálogo → Feature completa en read
5. US3 → Edición → Corrección de datos
6. US4 → Inactivar/Reactivar → Ciclo de vida completo
7. Polish → Tests + CI + Observabilidad

### Estrategia de Equipo Paralelo

Con dos desarrolladores:

1. Juntos completan Phase 1 + 2 (Setup + Fundacional)
2. Developer A: backend de US1-US2-US5 (endpoints GET + POST)
3. Developer B: frontend de US1-US2 (componente + servicio)
4. Integran y validan
5. Developer A: backend US3-US4
6. Developer B: frontend US3-US4 + US5 (vista completa)

---

## Notas

- `[P]` = archivos distintos, sin dependencias de tareas incompletas
- La etiqueta `[USN]` vincula la tarea a la historia de usuario para trazabilidad
- Cada historia debe ser completamente verificable con los smoke tests de `quickstart.md`
- Confirmar resultados de `quickstart.md §4` antes de declarar completa la historia
- Commitear tras cada tarea o grupo lógico
- Detener en cualquier checkpoint para validar la historia de forma independiente
