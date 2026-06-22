# Tareas: Unidades de Medida y Tabla de Equivalencias

**Entrada**: Documentos de diseño desde `/specs/004-unidades-medida/`
**Prerrequisitos**: plan.md ✅ · spec.md ✅ · research.md ✅ · data-model.md ✅ · contracts/api.md ✅
**Repos**: `loopi-api-v2` (Go backend) · `loopi-web-v2` (Angular frontend)
**Dependencia de features**: `001-autenticacion` (JWT + middleware autenticacion.go);
  `003-gestion-empleados` (middleware solo_admin.go)

## Formato: `[ID] [P?] [HU?] Descripción con ruta exacta`

- **[P]**: Ejecutable en paralelo (archivos distintos, sin dependencias incompletas)
- **[HU]**: Historia de usuario a la que pertenece la tarea
- Sin etiqueta de historia: Fase de Setup o Fundacional

---

## Fase 1: Setup — Estructura de Directorios

**Propósito**: Crear la estructura de carpetas y rutas Angular para el módulo.

- [ ] T001 Crear directorios `loopi-api-v2/internal/unidades_medida/` e `internal/conversion/`
  (archivos vacíos con `.gitkeep` o directamente los primeros `.go` de la Fase 2)
- [ ] T002 [P] Crear estructura de directorios frontend en `loopi-web-v2/src/app/features/unidades-medida/`:
  subdirectorios `pages/lista-unidades/`, `pages/formulario-unidad/`, `pages/detalle-unidad/`,
  `services/`, `models/`
- [ ] T003 [P] Crear `loopi-web-v2/src/app/features/unidades-medida/unidades-medida.routes.ts`
  con rutas lazy-loaded: `''` → `ListaUnidadesComponent`, `'nueva'` → `FormularioUnidadComponent`,
  `':id'` → `DetalleUnidadComponent`, `':id/editar'` → `FormularioUnidadComponent` (modo edición)
- [ ] T004 Registrar `unidades-medida.routes.ts` en el router principal de la aplicación Angular
  (`app.routes.ts`) bajo la ruta `/unidades-medida` (lazy load con `loadChildren`)

**Punto de control**: `ng build` pasa sin errores tras crear la estructura vacía.

---

## Fase 2: Fundacional — Migraciones y Modelos Base

**Propósito**: DDL, seed, structs Go y TypeScript que TODAS las historias necesitan.

⚠️ **CRÍTICO**: Ninguna historia de usuario puede comenzar hasta completar esta fase.

- [ ] T005 Crear `loopi-api-v2/db/migrations/NNNN_crear_tabla_unidades_medida.up.sql` con DDL
  completo según data-model.md: tabla `unidades_medida`, constraint `uq_unidades_medida_codigo`,
  index `ix_unidades_medida_tipo_activo`, y `CHECK (factor_conversion > 0)` (MySQL 8.0+)
- [ ] T006 [P] Crear `loopi-api-v2/db/migrations/NNNN_crear_tabla_unidades_medida.down.sql`
  con `DROP TABLE IF EXISTS unidades_medida`
- [ ] T007 [P] Crear `loopi-api-v2/db/migrations/NNNN+1_seed_unidades_medida.up.sql` con INSERT
  de 3 unidades base (`g`, `ml`, `und`) con `unidad_base=1, factor_conversion=1.0000` y 10
  unidades estándar de gastronomía (`kg`, `t`, `mg`, `L`, `dL`, `cL`, `docena`, `par`, `caja`)
  con factores exactos según data-model.md; todos con `activo=1`
- [ ] T008 [P] Crear `loopi-api-v2/db/migrations/NNNN+1_seed_unidades_medida.down.sql` con
  `DELETE FROM unidades_medida WHERE codigo IN ('g','ml','und','kg','t','mg','L','dL','cL','docena','par','caja')`
- [ ] T009 Aplicar migraciones: `migrate -path ./db/migrations -database "$DB_DSN" up 2`;
  verificar `SELECT COUNT(*) FROM unidades_medida;` → debe retornar 13 y
  `SELECT codigo FROM unidades_medida WHERE unidad_base=1;` → debe retornar `g`, `ml`, `und`
- [ ] T010 Crear `loopi-api-v2/internal/unidades_medida/model.go` con structs Go:
  `UnidadMedida` (todos los campos de la BD), `CrearUMRequest` (codigo, nombre, tipo_medida,
  factor_conversion), `EditarUMRequest` (nombre `*string`, factor_conversion `*float64`),
  `ListarUMParams` (tipo, activo `*bool`, page, limit int), `ListarUMResponse` (slice +
  total/page/limit), `DetalleUMResponse` (UnidadMedida + ItemsConUnidadCanonica int),
  `ImpactoResponse` (unidad_id, items_con_unidad_canonica, advertencia `*string`),
  `InactivarResponse` (id, activo bool, mensaje string)
- [ ] T011 [P] Crear `loopi-api-v2/internal/unidades_medida/cache.go`: inicializar instancia
  Ristretto con 10_000 max keys, TTL default 5 min; implementar `invalidarCatalogo(id int64)`
  que borra claves `"um:all"`, `"um:id:{id}"`, `"um:tipo:peso"`, `"um:tipo:volumen"`,
  `"um:tipo:unidad"` según RD-01 en research.md
- [ ] T012 [P] Crear `loopi-web-v2/src/app/features/unidades-medida/models/unidad-medida.model.ts`
  con interfaces TypeScript: `TipoMedida`, `UnidadMedida`, `UnidadMedidaDetalle`,
  `ListarUnidadesMedidaResponse`, `CrearUnidadMedidaRequest`, `EditarUnidadMedidaRequest`,
  `ImpactoInactivacionResponse`, `InactivarUnidadResponse`, `ApiError` según contracts/api.md

**Punto de control**: `go build ./...` compila sin errores; `DESCRIBE unidades_medida` muestra
las 9 columnas esperadas y los 13 registros del seed están presentes.

⚠️ **Orden de rollback**: `migrate down 2` — seed primero, luego tabla.

---

## Fase 3: HU4 — Conversión Automática entre Unidades (Prioridad: P1)

**Objetivo**: El paquete `internal/conversion/` provee la función `Convertir` reutilizable por
todos los módulos consumidores (recetas, compras, recepción).

**Prueba Independiente**: `go test ./internal/conversion/... -v` — 6 tests pasan con cobertura > 90%.

- [ ] T013 Crear `loopi-api-v2/internal/conversion/conversion.go` con función pura
  `Convertir(cantidad, factorDesde float64, tipoDesde string, factorHacia float64, tipoHacia string) (float64, error)`:
  retornar `ErrTipoIncompatible` si `tipoDesde != tipoHacia`; retornar `ErrFactorInvalido` si
  algún factor ≤ 0; calcular `result = cantidad × (factorDesde / factorHacia)` y redondear a 4
  decimales con `math.Round(result×10000)/10000`; también implementar
  `EsCompatible(tipo1, tipo2 string) bool` según RD-02 y RD-05 en research.md
- [ ] T014 [P] Crear `loopi-api-v2/internal/conversion/conversion_test.go` con casos:
  `TestConvertirKgAGramos` (2.0, 1000.0, "peso", 1.0, "peso" → 2000.0000),
  `TestConvertirLitrosAMililitros` (1.5, 1000.0, "volumen", 1.0, "volumen" → 1500.0000),
  `TestConvertirDocenasAUnidades` (2.0, 12.0, "unidad", 1.0, "unidad" → 24.0000),
  `TestConvertirTiposIncompatibles` (1.0, 1000.0, "peso", 1.0, "volumen" → ErrTipoIncompatible),
  `TestConvertirFactorCero` (1.0, 0.0, "peso", 1.0, "peso" → ErrFactorInvalido),
  `TestConvertirMismaUnidad` (5.0, 1.0, "unidad", 1.0, "unidad" → 5.0000)
- [ ] T015 Ejecutar `go test ./internal/conversion/... -v -coverprofile=coverage.out` desde
  `loopi-api-v2/`; confirmar 6 tests PASS y cobertura ≥ 90% en `conversion.go`

**Punto de control HU4**: Todos los tests del paquete `conversion` pasan. La función `Convertir`
con sus dos errores está lista para importarse en módulos consumidores (recetas, compras, etc.).

---

## Fase 4: HU1 — Crear Unidad de Medida (Prioridad: P1) 🎯 MVP

**Objetivo**: Admin crea unidades nuevas y gestiona la inactivación con confirmación previa.

**Prueba Independiente**: `POST /api/v1/unidades_medida` crea unidad; código duplicado retorna
409; factor ≤ 0 retorna 422; lider_tienda recibe 403; `PATCH .../inactivar` inactiva correctamente.

### Backend — Repositorio

- [ ] T016 Crear `loopi-api-v2/internal/unidades_medida/repository.go` con interfaz
  `UMRepository` y struct `mysqlUMRepository`; implementar métodos:
  `Crear(ctx, *CrearUMRequest) (*UnidadMedida, error)` (INSERT + SELECT del row creado),
  `ExisteConCodigo(ctx, codigo string) (bool, error)`,
  `ContarItemsConUnidadCanonica(ctx, id int64) (int, error)` (query sobre `items` si existe,
  graceful degradation retornando 0 si tabla no existe),
  `ContarUnidadesActivasPorTipo(ctx, tipo string, excludeID int64) (int, error)`
  (`SELECT COUNT(*) FROM unidades_medida WHERE tipo_medida=? AND activo=1 AND id!=?`,
  requerido por `service.Inactivar` para verificar RF-UM-02.2 `unidad_base_no_inactivable`),
  `Inactivar(ctx, id int64) error` (UPDATE activo=0),
  `ObtenerPorID(ctx, id int64) (*UnidadMedida, error)` — todas con queries parametrizadas;
  columnas explícitas (nunca `SELECT *`)

### Backend — Servicio

- [ ] T017 Crear `loopi-api-v2/internal/unidades_medida/service.go` con struct `UMService`
  que inyecta `UMRepository` y caché; implementar `Crear(ctx, *CrearUMRequest) (*UnidadMedida, error)`:
  validar `tipo_medida` ∈ `{peso, volumen, unidad}` → 422 `tipo_invalido`;
  validar `factor_conversion > 0` → 422 `factor_invalido`;
  verificar código único vía `ExisteConCodigo` → 409 `codigo_duplicado`;
  insertar; invalidar caché; retornar unidad creada
- [ ] T018 [P] Agregar `Inactivar(ctx, id int64) error` a `service.go`: obtener unidad (404
  si no existe); verificar que no esté ya inactiva (409 `ya_inactiva`); si `unidad_base=1`,
  verificar que no existan otras unidades activas del mismo tipo → 422
  `unidad_base_no_inactivable`; ejecutar `repository.Inactivar`; invalidar caché
- [ ] T019 [P] Agregar `ObtenerImpacto(ctx, id int64) (*ImpactoResponse, error)` a `service.go`:
  verificar existencia de unidad (404); llamar `repository.ContarItemsConUnidadCanonica`;
  si count > 0, poblar `Advertencia` con texto: "Al inactivar esta unidad, {N} item(s) quedarán
  con unidad canónica inactiva y sus transacciones nuevas serán bloqueadas hasta que se les
  reasigne una unidad activa."; si count = 0, `Advertencia = nil`

### Backend — Handler y Rutas

> ⚠️ **Constitución §VI (Observabilidad)**: La instrumentación OTel y los logs JSON DEBEN
> agregarse **al crear** T020/T021 (handler) y T017-T019 (service), no diferirse a Fase 7.
> T047/T048 en Fase 7 verifican y completan la cobertura — no realizan la instrumentación inicial.

- [ ] T020 Crear `loopi-api-v2/internal/unidades_medida/handler.go` con struct `UMHandler`
  que inyecta `UMService`; implementar `CrearUnidad(w http.ResponseWriter, r *http.Request)`:
  parsear body JSON → `CrearUMRequest`; body malformado → 400; llamar `service.Crear`; retornar
  201 Created con `UnidadMedida` serializado; mapear errores del servicio a HTTP correctos
  según contracts/api.md
- [ ] T021 [P] Agregar `InactivarUnidad(w, r)` y `ObtenerImpacto(w, r)` a `handler.go`:
  ambos parsean `{id}` del path (404 si no es entero válido); `InactivarUnidad` → 200 con
  `InactivarResponse`; `ObtenerImpacto` → 200 con `ImpactoResponse`; mapear errores del
  servicio a HTTP según contracts/api.md
- [ ] T022 Registrar en el router de `loopi-api-v2`:
  `POST /api/v1/unidades_medida` con middlewares `autenticacion` + `solo_admin`,
  `PATCH /api/v1/unidades_medida/{id}/inactivar` con `autenticacion` + `solo_admin`,
  `GET /api/v1/unidades_medida/{id}/impacto` con `autenticacion` + `solo_admin`;
  reutilizar `middleware/autenticacion.go` (001) y `middleware/solo_admin.go` (003)

### Backend — Tests

- [ ] T023 [P] Crear `loopi-api-v2/internal/unidades_medida/service_test.go` con mock de
  `UMRepository`; implementar: `TestCrearUnidadCodigoDuplicado` (ExisteConCodigo=true → 409),
  `TestCrearUnidadFactorCero` (factor=0 → 422 factor_invalido),
  `TestCrearUnidadTipoInvalido` (tipo="area" → 422 tipo_invalido),
  `TestCrearUnidadExitosa` (retorna UnidadMedida con id ≥ 1),
  `TestInactivarUnidadBase` (unidad_base=true y ContarUnidadesActivasPorTipo > 0 → 422),
  `TestInactivarYaInactiva` (activo=false → 409),
  `TestCacheInvalidacionEnCreate` (tras Crear exitoso, mock verifica que `invalidarCatalogo`
  fue llamado exactamente 1 vez),
  `TestCacheInvalidacionEnInactivar` (tras Inactivar exitoso, mock verifica que
  `invalidarCatalogo` fue llamado exactamente 1 vez),
  `TestAccesoSinAdminFalla` (handler test: request sin rol admin a POST/PUT/PATCH → 403
  `acceso_denegado`; usar `httptest.NewRecorder` + token con rol `lider_tienda`)
- [ ] T023b [P] Crear `loopi-api-v2/internal/unidades_medida/repository_test.go` con
  `go-sqlmock` (`github.com/DATA-DOG/go-sqlmock`); cobertura obligatoria ≥ 90% en `repository.go`
  (Constitución §Estrategia de testing — paquetes de infraestructura); implementar:
  `TestRepositoryCrear` (INSERT correcto + SELECT del row creado; verificar columnas explícitas),
  `TestRepositoryCrearDuplicado` (driver retorna error de clave duplicada → propagado sin envolver),
  `TestRepositoryExisteConCodigo_Existe` (row retornado → true),
  `TestRepositoryExisteConCodigo_NoExiste` (no rows → false),
  `TestRepositoryListar_SinFiltros` (SQL_CALC_FOUND_ROWS + FOUND_ROWS() correctos),
  `TestRepositoryListar_FiltroTipo` (WHERE tipo_medida=? incluido en query),
  `TestRepositoryObtenerPorID_Existe` (row completo mapeado correctamente),
  `TestRepositoryObtenerPorID_NoExiste` (sql.ErrNoRows → nil, nil),
  `TestRepositoryEditar` (UPDATE dinámico incluye solo campos no-nil; actualizado_en=NOW()),
  `TestRepositoryInactivar` (UPDATE activo=0 ejecutado con id correcto),
  `TestRepositoryContarItemsConUnidadCanonica` (query sobre tabla items; graceful 0 si tabla no existe),
  `TestRepositoryContarUnidadesActivasPorTipo` (SELECT COUNT con tipo y excludeID correctos);
  todos los tests verifican que sqlmock.ExpectationsWereMet() pasa al finalizar

### Frontend — Service y Componentes

- [ ] T024 Crear `loopi-web-v2/src/app/features/unidades-medida/services/unidades-medida.service.ts`
  como `@Injectable({providedIn:'root'})` con `HttpClient`; implementar `crearUnidad(req:
  CrearUnidadMedidaRequest): Observable<UnidadMedida>` (POST `/api/v1/unidades_medida`),
  `inactivarUnidad(id: number): Observable<InactivarUnidadResponse>` (PATCH `.../inactivar`),
  `getImpacto(id: number): Observable<ImpactoInactivacionResponse>` (GET `.../impacto`)
- [ ] T025 Crear `loopi-web-v2/src/app/features/unidades-medida/pages/formulario-unidad/formulario-unidad.component.ts`
  como componente standalone; reactive form con `FormBuilder`: campo `codigo` (required,
  maxLength 20), `nombre` (required, maxLength 100), `tipo_medida` (select required),
  `factor_conversion` (required, min 0.0001); validar onBlur + onSubmit; deshabilitar botón
  durante envío (signal `cargando`); llamar `service.crearUnidad()`; toast verde 3 s en éxito;
  navegar a `/unidades-medida` tras crear; manejar error API mostrando `mensaje` del error
- [ ] T026 Crear `loopi-web-v2/src/app/features/unidades-medida/pages/formulario-unidad/formulario-unidad.component.html`:
  `<h1>` "Nueva unidad de medida"; breadcrumb `Unidades de medida → Nueva`; todos los campos
  con `<label for="...">` explícito (WCAG 2.1 AA); `aria-describedby` en campos con error;
  `<option>` para peso, volumen y unidad en el select; mensajes de error con texto descriptivo
  bajo cada campo (`text-red-600`, `border-red-500`); botón "Crear unidad" con spinner inline
  y texto "Guardando..." durante envío; Tailwind CSS v4.
  ⚠️ **Constitución §Superficie de Formulario (1.9.0)**: el formulario tiene ≤ 6 campos →
  elemento raíz `<div class="max-w-lg mx-auto">` (sin `<main>` propio — el ShellComponent ya
  provee `bg-gray-50` y el padding base); envolver `<form>` en tarjeta
  `<div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6 lg:p-8">`; todos los
  `<input>` y `<select>` con `class="bg-white ..."` explícito (no heredado del navegador)
- [ ] T027 Crear `loopi-web-v2/src/app/features/unidades-medida/pages/lista-unidades/lista-unidades.component.ts`
  (esqueleto para HU1): cargar lista al `ngOnInit`; signal `unidades: UnidadMedida[]`;
  método `abrirConfirmacionInactivar(unidad)` que llama `getImpacto(id)` y almacena resultado
  en signal `impactoSeleccionado`; método `confirmarInactivar()` que llama `inactivarUnidad(id)`
  y refresca la lista; signal `cargandoInactivar` para deshabilitar botón durante acción
- [ ] T028 [P] Crear `loopi-web-v2/src/app/features/unidades-medida/pages/lista-unidades/lista-unidades.component.html`
  (esqueleto con inactivación): encabezado con `<h1>` "Unidades de medida" y botón primario
  `+ Nueva unidad de medida` (routerLink a `./nueva`) — el prefijo `+ ` es obligatorio según
  Constitución §Botones de Acción (1.8.0); tabla responsive Tailwind CSS v4 con columnas
  código/nombre/tipo/factor/estado; botón "Inactivar" por fila (solo si `activo=true` y no es
  `unidad_base`); modal de confirmación destructiva: `<h2>` "¿Inactivar esta unidad?", texto de
  advertencia del `impactoSeleccionado.advertencia` o "Esta unidad no tiene items asignados",
  botón rojo "Confirmar inactivación" + botón secundario "Cancelar"; empty state: "Aún no hay
  unidades de medida registradas." con link "Crear primera unidad →"

**Punto de control HU1**: Ejecutar smoke test 4.2 de quickstart.md — crear unidad, duplicado 409,
factor 0 → 422; PATCH inactivar funciona; modal de confirmación aparece en el frontend.

---

## Fase 5: HU3 — Consultar Catálogo de Equivalencias (Prioridad: P1)

**Objetivo**: Admin visualiza el catálogo completo con filtros por tipo, paginación y detalle
de cada unidad con conteo de items que la usan como canónica.

**Prueba Independiente**: `GET /api/v1/unidades_medida?tipo=peso` retorna las 4 unidades de peso
del seed; `GET /api/v1/unidades_medida/{id}` retorna el detalle con `items_con_unidad_canonica`.

### Backend — Repositorio y Servicio

- [ ] T029 Agregar a `loopi-api-v2/internal/unidades_medida/repository.go`:
  `Listar(ctx, *ListarUMParams) (*ListarUMResponse, error)` con `SQL_CALC_FOUND_ROWS`, filtro
  `WHERE (? = '' OR tipo_medida = ?)` y `AND (? IS NULL OR activo = ?)`,
  `ORDER BY tipo_medida ASC, nombre ASC`, `LIMIT ? OFFSET ?`; `FOUND_ROWS()` para total;
  `ObtenerPorIDConItems(ctx, id int64) (*DetalleUMResponse, error)` que retorna la unidad +
  `ContarItemsConUnidadCanonica` para `items_con_unidad_canonica`
- [ ] T030 [P] Agregar a `loopi-api-v2/internal/unidades_medida/service.go`:
  `Listar(ctx, *ListarUMParams) (*ListarUMResponse, error)`: key de caché `"um:all"` (sin filtros)
  o `"um:tipo:{tipo}"` (con filtro tipo); TTL 5 min; cache miss → BD → set cache;
  `ObtenerPorID(ctx, id int64) (*DetalleUMResponse, error)`: cache `"um:id:{id}"` → BD si miss

### Backend — Handlers y Rutas

- [ ] T031 Agregar `ListarUnidades(w, r)` a `handler.go`: parsear query params `tipo`, `activo`,
  `page` (default 1), `limit` (default 50, max 200); validar `tipo` ∈ `{"peso","volumen","unidad",""}` → 400
  `tipo_invalido` si inválido; llamar `service.Listar`; retornar 200 `ListarUMResponse`
- [ ] T032 [P] Agregar `ObtenerUnidad(w, r)` a `handler.go`: parsear `{id}` del path; llamar
  `service.ObtenerPorID`; retornar 200 `DetalleUMResponse`; 404 con `unidad_no_encontrada`
  si no existe
- [ ] T033 Agregar al router: `GET /api/v1/unidades_medida` con middleware `autenticacion` (todos
  los roles), `GET /api/v1/unidades_medida/{id}` con middleware `autenticacion` (todos los roles)

### Backend — Tests HU3

- [ ] T034 [P] Agregar a `service_test.go`:
  `TestListarPorTipoPeso` (filtro tipo=peso, mock retorna 4 unidades),
  `TestListarCacheHit` (segunda llamada usa caché; `repository.Listar` llamado solo 1 vez),
  `TestListarTipoInvalidoEnHandler` (tipo="area" → 400 en handler test),
  `TestObtenerPorIDNoExiste` (repository retorna nil → error 404)

### Frontend — Lista completa y Detalle

- [ ] T035 Completar `lista-unidades.component.ts`: agregar signals `filtroTipo: TipoMedida | ''`
  y `filtroActivo: boolean | null`; signal `paginaActual = 1`; signal `total = 0`; método
  `cargarUnidades()` que llama `service.listarUnidades({tipo, activo, page, limit})`; effect
  que llama `cargarUnidades()` cuando cambian los signals de filtro o página; mostrar spinner
  inline durante carga; mostrar conteo "N unidades encontradas"
- [ ] T036 [P] Completar `lista-unidades.component.html`: agregar `<select>` para `filtroTipo`
  (opciones: Todos / Peso / Volumen / Unidad) y `<select>` para `filtroActivo` (Todos / Activas /
  Inactivas); paginación con botones "Anterior" / "Siguiente" deshabilitados en extremos; spinner
  inline `< 300 ms sin indicador, 300 ms–3 s spinner` per constitución; badge de tipo de medida
  por fila con color distinto (Tailwind CSS v4)
- [ ] T037 Crear `loopi-web-v2/src/app/features/unidades-medida/pages/detalle-unidad/detalle-unidad.component.ts`:
  standalone component; inyectar `ActivatedRoute` y `UnidadesMedidaService`; cargar unidad via
  `service.getUnidad(id)` al init; signals `unidad: UnidadMedidaDetalle | null` y
  `cargando: boolean`; métodos `irAEditar()` y `abrirInactivar()`
- [ ] T038 [P] Crear `loopi-web-v2/src/app/features/unidades-medida/pages/detalle-unidad/detalle-unidad.component.html`:
  `<h1>` con nombre de la unidad; breadcrumb `Unidades de medida → [nombre]`; card con todos los
  campos: código (badge monospace), nombre, tipo, factor, estado (badge verde/rojo), `unidad_base`
  (badge "Unidad Base" si aplica); badge azul "N items usan esta unidad" cuando > 0; botón
  primario "Editar" (oculto si inactiva o unidad_base), botón secundario "Inactivar" (oculto si
  ya inactiva o unidad_base); estado vacío de error con botón "Volver al catálogo"
- [ ] T039 Agregar métodos `listarUnidades(params: Partial<{tipo: string, activo: boolean, page: number, limit: number}>): Observable<ListarUnidadesMedidaResponse>` y
  `getUnidad(id: number): Observable<UnidadMedidaDetalle>` a `unidades-medida.service.ts`

**Punto de control HU3**: Ejecutar smoke test 4.1 de quickstart.md — listar todas (retorna 13),
filtrar por peso (retorna 4); detalle de `kg` muestra `items_con_unidad_canonica=0`.

---

## Fase 6: HU2 — Editar Unidad de Medida (Prioridad: P2)

**Objetivo**: Admin corrige nombre y factor de conversión; código es inmutable cuando hay
items; factor de unidad base es inmutable.

**Prueba Independiente**: `PUT /api/v1/unidades_medida/{id}` con `{"nombre":"Kilogramos"}` retorna
la unidad actualizada; intento de cambiar `factor_conversion` en unidad base retorna 422.

### Backend — Repositorio, Servicio, Handler

- [ ] T040 Agregar `Editar(ctx, id int64, req *EditarUMRequest) (*UnidadMedida, error)` a
  `repository.go`: construir UPDATE dinámico solo con los campos no-nil de `EditarUMRequest`
  (`nombre`, `factor_conversion`); siempre actualizar `actualizado_en = NOW()`; retornar la
  unidad actualizada con SELECT posterior
- [ ] T041 Agregar `Editar(ctx, id int64, req *EditarUMRequest) (*UnidadMedida, error)` a
  `service.go`: obtener unidad (404 si no existe); si req.FactorConversion != nil y
  unidad.UnidadBase = true → 422 `factor_base_inmutable`; si req.FactorConversion != nil y
  *req.FactorConversion ≤ 0 → 422 `factor_invalido`; ejecutar `repository.Editar`; invalidar
  caché (`"um:id:{id}"`, `"um:all"`, `"um:tipo:{tipo}"`)
- [ ] T042 [P] Agregar `EditarUnidad(w, r)` a `handler.go`: parsear body `EditarUMRequest`;
  body vacío o sin campos → 400 `campo_requerido`; llamar `service.Editar`; retornar 200 con
  `UnidadMedida` actualizada; mapear errores a HTTP según contracts/api.md
- [ ] T043 [P] Agregar `PUT /api/v1/unidades_medida/{id}` al router con middlewares
  `autenticacion` y `solo_admin`

### Backend — Tests HU2

- [ ] T044 [P] Agregar a `service_test.go`:
  `TestEditarFactorUnidadBase` (unidad.UnidadBase=true, req.FactorConversion=&0.5 → 422),
  `TestEditarUnidadNoExiste` (repository retorna nil → 404),
  `TestEditarNombreExitoso` (nombre actualizado, caché invalidado; repository.Editar llamado 1 vez)

### Frontend — Formulario en Modo Edición

- [ ] T045 Actualizar `formulario-unidad.component.ts` para modo edición: detectar si la ruta
  contiene `':id/editar'` via `ActivatedRoute`; si modo edición, llamar `service.getUnidad(id)`
  y pre-poblar el form; deshabilitar campo `codigo` en modo edición (`{disabled: true}`);
  cambiar label del botón a "Guardar cambios"; llamar `service.editarUnidad(id, req)` en submit;
  toast verde "Unidad actualizada correctamente." y navegar a `/unidades-medida/:id` tras éxito
- [ ] T046 [P] Agregar `editarUnidad(id: number, req: EditarUnidadMedidaRequest): Observable<UnidadMedida>`
  a `unidades-medida.service.ts` (PUT `/api/v1/unidades_medida/{id}`)

**Punto de control HU2**: Admin edita nombre de "Kilogramo" a "Kilogramos" y guarda; campo código
está deshabilitado en el formulario; intento de cambiar factor en unidad base `g` retorna 422.

---

## Fase 7: Pulido y Cortes Transversales

**Propósito**: Observabilidad, accesibilidad, pruebas de extremo a extremo y gates de calidad.

- [ ] T047 [P] Verificar y completar trazas OpenTelemetry en
  `loopi-api-v2/internal/unidades_medida/handler.go`: confirmar que los 6 endpoints tienen
  `span, ctx := tracer.Start(r.Context(), "um.{operacion}")`; atributos OTel: `unidad.id`,
  `user.id`, `user.rol`, `operacion`; `span.SetStatus(codes.Error, ...)` en errores 4xx/5xx
  — la instrumentación básica debe haberse iniciado al implementar T020/T021 (Constitución §VI)
- [ ] T048 [P] Verificar y completar logs JSON estructurados en
  `loopi-api-v2/internal/unidades_medida/service.go`: confirmar cobertura en todas las
  operaciones (`crear_unidad`, `editar_unidad`, `inactivar_unidad`, `listar_unidades`);
  campos requeridos: `"user_id"`, `"rol"`, `"operacion"`, `"unidad_id"` cuando aplica;
  INFO en éxito; ERROR en errores de negocio — los logs básicos deben haberse iniciado
  al implementar T017-T019/T030/T041 (Constitución §VI)
- [ ] T049 [P] Verificar accesibilidad WCAG 2.1 AA en los 4 componentes Angular: confirmar que
  `formulario-unidad.component.html` tiene `<label for>` en todos los campos, `aria-describedby`
  en inputs con error, `aria-live="polite"` en zona de mensajes de error; confirmar que el modal
  de confirmación tiene `role="dialog"` y `aria-labelledby`; confirmar navegación con Tab en modal
- [ ] T050 Ejecutar smoke test completo de `specs/004-unidades-medida/quickstart.md` secciones
  4.1 a 4.4: listar catálogo inicial (13 unidades), crear unidad `oz`, errors 409/422, conversión
  Go tests, flujo completo de inactivación — documentar resultados
- [ ] T051 [P] Ejecutar gates de backend en `loopi-api-v2/`:
  `go build ./...` (0 errores), `golangci-lint run` (0 issues), `govulncheck ./...` (0 CVEs),
  `gitleaks detect --no-git` (0 secrets), `go test ./...` (todos los tests pasan)
- [ ] T052 [P] Ejecutar gates de frontend en `loopi-web-v2/`:
  `ng build` (0 errores, TypeScript estricto habilitado), `npm audit --audit-level=high`
  (0 vulnerabilidades high/critical), `gitleaks detect --no-git` (0 secrets),
  `ng test --watch=false` (todos los tests pasan)

---

## Dependencias y Orden de Ejecución

### Dependencias entre Fases

- **Fase 1 — Setup**: Sin dependencias. Comenzar de inmediato.
- **Fase 2 — Fundacional**: Depende de Fase 1. **BLOQUEA todas las historias de usuario.**
- **Fase 3 — HU4 Conversión**: Depende de Fase 2 (model.go). Puede iniciarse en paralelo con las
  fases 4-6 al terminar Fase 2, ya que es un paquete independiente sin dependencias de API.
- **Fase 4 — HU1 Crear**: Depende de Fase 2. Puede ejecutarse en paralelo con Fase 3 y Fase 5.
- **Fase 5 — HU3 Consultar**: Depende de Fase 2 y de los métodos repository/service de Fase 4
  (comparten el mismo repository.go y service.go). En la práctica, se recomienda secuencial.
- **Fase 6 — HU2 Editar**: Depende de Fases 4 y 5 (reutiliza repositorio y servicio ya existentes).
- **Fase 7 — Pulido**: Depende de Fases 4, 5 y 6.

### Dependencias Dentro de Cada Fase

- Fase 2: T005–T008 [P entre sí]; T009 depende de T005–T008; T010–T012 [P entre sí] y con T005–T008
- Fase 4: T016–T019 [P entre sí] → T020–T021 dependen de T017–T019 → T022 depende de T020–T021;
  T023 [P] con T016–T019; T024 [P] con T016–T019 → T025–T028 dependen de T024
- Fase 5: T029–T030 [P entre sí] → T031–T032 dependen de T030 → T033 depende de T031–T032;
  T035–T036 dependen de T039; T037–T038 [P entre sí] dependen de T039
- Fase 6: T040 → T041 depende de T040 → T042 depende de T041; T045 depende de T039

### Dependencias entre Historias de Usuario

- **HU4 (P1)**: Sin dependencias de otras HU. Iniciar tras Fase 2.
- **HU1 (P1)**: Sin dependencias de otras HU. Iniciar tras Fase 2.
- **HU3 (P1)**: Sin dependencias de otras HU. Comparte archivos con HU1 (repository.go, service.go,
  handler.go, service.ts) — coordinación necesaria al trabajar en los mismos archivos.
- **HU2 (P2)**: Sin dependencias funcionales de HU1/HU3 para el backend. Para el frontend,
  reutiliza `formulario-unidad.component.ts` de HU1.

---

## Ejemplo de Ejecución Paralela — HU4 (Fase 3)

```bash
# Ejecutar en paralelo (archivos distintos):
# → T013: conversion.go
# → T014: conversion_test.go

# Secuencial (depende de T013 y T014):
# → T015: go test ./internal/conversion/... -v
```

## Ejemplo de Ejecución Paralela — HU1 Backend (Fase 4)

```bash
# Ejecutar en paralelo (archivos distintos):
# → T016: repository.go (métodos Crear, ExisteConCodigo, ContarItems, Inactivar, ObtenerPorID)
# → T017: service.go (método Crear)
# → T023: service_test.go (tests de Crear)

# Tras T017:
# → T018: service.go (agregar Inactivar)
# → T019: service.go (agregar ObtenerImpacto)

# Tras T016, T017, T018, T019:
# → T020: handler.go (CrearUnidad)
# → T021: handler.go (InactivarUnidad + ObtenerImpacto) [P con T020]
# → T022: rutas del router
```

---

## Estrategia de Implementación

### MVP (Solo HU4 + HU1 — Fases 1-4)

1. Completar Fase 1 (Setup) — 4 tareas
2. Completar Fase 2 (Fundacional) — 8 tareas
3. Completar Fase 3 (HU4 Conversión) — 3 tareas → **El paquete `conversion` está listo para 007+**
4. Completar Fase 4 (HU1 Crear + Inactivar) — 13 tareas
5. **PARAR Y VALIDAR**: Admin crea unidades, sistema previene duplicados, conversión funciona
6. Desplegar en stage y validar smoke tests 4.2, 4.3, 4.4

### Entrega Incremental

1. Setup + Fundacional + HU4 → Conversión lista para módulos consumidores
2. HU1 → Admin gestiona creación e inactivación (MVP del catálogo)
3. HU3 → Admin consulta y filtra el catálogo con detalle de items
4. HU2 → Admin corrige errores en nombre y factor

### Estrategia con Varios Desarrolladores

1. Dev A (backend): Fases 1→2→3→4 backend (T001, T005–T023)
2. Dev B (frontend): Fase 2 (T012) → Fase 4 frontend (T024–T028) en paralelo con Dev A
3. Dev C: Fases 5 y 6 completas una vez Fases 3 y 4 terminadas

---

## Notas

- `[P]` = archivos distintos, sin dependencias incompletas — ejecutar simultáneamente
- `[HU]` = historia de usuario para trazabilidad
- El paquete `internal/conversion/` es INDEPENDIENTE del módulo `unidades_medida` — importarlo
  con `import "loopi-api-v2/internal/conversion"` en módulos consumidores (007, 008, 013…)
- `repository.ContarItemsConUnidadCanonica` retorna 0 graciosamente hasta que 007-items-catalogo
  cree la tabla `items` — no bloquea el desarrollo de esta feature
- El campo `codigo` NO debe incluirse en `EditarUMRequest`; si el cliente lo envía, ignorarlo
  (no rechazarlo con error — simplemente no actualizarlo)
- Nunca `SELECT *` — columnas explícitas en todas las queries de `repository.go`
- Hacer commit tras cada fase completada y verificada
