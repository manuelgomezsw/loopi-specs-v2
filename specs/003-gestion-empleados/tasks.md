# Tareas: Gestión de Empleados

**Entrada**: Documentos de diseño desde `/specs/003-gestion-empleados/`
**Prerrequisitos**: plan.md ✅ · spec.md ✅ · research.md ✅ · data-model.md ✅ · contracts/api.md ✅
**Repos**: `loopi-api-v2` (Go backend) · `loopi-web-v2` (Angular frontend)

> **Revisión post-análisis** (2026-05-24): Correcciones aplicadas por `/speckit-analyze`:
> C1 (logs → Fase 2), G1 (T048 cambio contraseña), O1 (T046 router → Fase 2),
> G2 (T010 columnas explícitas), G3 (T047 VerificarTiendaActiva), G4 (T049 integración 001),
> G5 (notas inmutabilidad en migraciones), I1 (T028 depende T023), I2 (T008 verificar interfaz),
> D1 (rollback order), A1 (ruta concreta T040).

## Formato: `[ID] [P?] [HU?] Descripción con ruta exacta`

- **[P]**: Ejecutable en paralelo (archivos distintos, sin dependencias incompletas)
- **[HU]**: Historia de usuario a la que pertenece la tarea
- Sin etiqueta de historia: Fase de Setup o Fundacional

---

## Fase 1: Setup — Migraciones de Base de Datos

**Propósito**: Crear las tablas `empleados` y `log_auditoria_empleados` en MySQL.

- [ ] T001 Crear migración `NNNN_crear_tabla_empleados.up.sql` con DDL completo (columnas, índices,
  FK a tiendas) según data-model.md en `loopi-api-v2/db/migrations/`
- [ ] T002 Crear migración `NNNN_crear_tabla_empleados.down.sql` con `DROP TABLE IF EXISTS empleados`
  en `loopi-api-v2/db/migrations/`
- [ ] T003 [P] Crear migración `NNNN+1_crear_tabla_log_auditoria_empleados.up.sql` con DDL completo
  (columnas JSON, FKs a empleados) según data-model.md en `loopi-api-v2/db/migrations/`;
  añadir comentario SQL `-- INMUTABLE: no conceder UPDATE/DELETE al usuario de la aplicación`
  (RF-EMP-05-A.3)
- [ ] T004 [P] Crear migración `NNNN+1_crear_tabla_log_auditoria_empleados.down.sql` con
  `DROP TABLE IF EXISTS log_auditoria_empleados` en `loopi-api-v2/db/migrations/`

**Punto de control**: Ejecutar `migrate -path ./db/migrations -database $DB_DSN up 2` y verificar
con `DESCRIBE empleados; DESCRIBE log_auditoria_empleados;`

⚠️ **Orden de rollback**: down debe ejecutarse en orden inverso:
`log_auditoria_empleados` primero (tiene FK a `empleados`), luego `empleados`.
Comando: `migrate -path ./db/migrations -database $DB_DSN down 2`

---

## Fase 2: Fundacional — Infraestructura Compartida

**Propósito**: Tipos, helpers, middleware y observabilidad que TODAS las historias necesitan.

⚠️ **CRÍTICO**: Ninguna historia de usuario puede comenzar hasta completar esta fase.

- [ ] T005 Crear `loopi-api-v2/internal/config/hash.go` con constantes `BcryptCostProd = 12`
  y `BcryptCostTests = 4` (según RD-07 en research.md)
- [ ] T006 [P] Crear `loopi-api-v2/internal/empleados/model.go` con structs Go: `Empleado`,
  `CrearEmpleadoRequest`, `EditarEmpleadoRequest`, `CambiarEstadoRequest`,
  `ListarEmpleadosParams`, `ListarEmpleadosResponse`, `CrearEmpleadoResponse`,
  `ResetContrasenaResponse` — todos los campos según contracts/api.md
- [ ] T007 [P] Crear `loopi-web-v2/src/app/features/empleados/models/empleado.model.ts` con
  interfaces TypeScript: `Empleado`, `ListaEmpleadosResponse`, `CrearEmpleadoResponse`,
  `ResetContrasenaResponse`, `ListarEmpleadosParams` según contracts/api.md
- [ ] T008 Crear `loopi-api-v2/middleware/solo_admin.go` que extrae claims JWT y verifica
  `rol == "admin"` retornando HTTP 403 `{error:"acceso_denegado"}` si no cumple;
  **verificar primero** que `autenticacion.ExtraerClaims()` (o equivalente) está exportado
  en el paquete de 001-autenticacion — si no lo está, crear wrapper local en
  `loopi-api-v2/internal/middleware/claims.go` antes de continuar
- [ ] T009 Crear `loopi-api-v2/internal/auditoria/empleados_log.go` con función
  `RegistrarLog(ctx, tx *sql.Tx, actorID, empleadoID int64, accion string, detalle map[string]any) error`
  que inserta en `log_auditoria_empleados`; el campo `detalle` nunca debe incluir
  contraseñas ni hashes
- [ ] T010 Crear `loopi-api-v2/internal/empleados/repository.go` con struct `Repository`,
  constructor `NewRepository(db *sql.DB)` y función base `ObtenerPorID(ctx, id) (*Empleado, error)`
  que retorna `ErrNoEncontrado` si no existe; el SELECT debe usar columnas explícitas
  (id, nombre, apellido, usuario, rol, tienda_id, activo, requiere_cambio_contrasena,
  creado_en, actualizado_en) — **nunca incluir `contrasena_hash`** (RF-EMP-05.6)
- [ ] T011 [P] Crear `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts`
  como skeleton con `HttpClient` inyectado y la constante `private readonly base = '/api/v1/empleados'`
- [ ] T045 [P] Crear helper de logging estructurado JSON en
  `loopi-api-v2/internal/middleware/logger.go` con función
  `LogOperacion(ctx, userID, rol, tiendaID int64, operacion string, extras map[string]any)`
  que emite JSON a stdout con los campos: `user_id`, `rol`, `tienda_id`, `operacion`,
  `timestamp`; campos adicionales via `extras` (ej. `empleado_id`, `duracion_ms`).
  **Constitución Principio VI**: los endpoints son críticos y deben ser monitoreables
  desde el primer deploy — este helper debe estar disponible antes de cualquier handler
- [ ] T046 Registrar skeleton del router en `loopi-api-v2/cmd/api/main.go`
  (o `loopi-api-v2/internal/router/router.go` según estructura del proyecto) con las
  6 rutas `/api/v1/empleados` + middleware `solo_admin` apuntando a handlers stub
  `http.NotFound`; los stubs se reemplazan con implementaciones reales en cada fase
- [ ] T047 Agregar función `ObtenerTiendaActivaPorID(ctx context.Context, id int64) error`
  en `loopi-api-v2/internal/empleados/repository.go` que consulta la tabla `tiendas`
  y retorna `ErrTiendaNoExiste` si no existe o `ErrTiendaInactiva` si `activo = 0`;
  requerida por T014 (crear) y T020 (editar) para cumplir RF-EMP-01.2 y RF-EMP-02.3

**Punto de control**: `go build ./...` pasa; `ng build` pasa; las 6 rutas del router
responden HTTP 404 (stub) al hacer `curl localhost:8080/api/v1/empleados`.

---

## Fase 3: Historia de Usuario 1 — Crear Empleado (Prioridad: P1) 🎯 MVP

**Objetivo**: El admin puede registrar un nuevo empleado con rol y tienda, obtener la contraseña
temporal y el empleado puede autenticarse de inmediato.

**Prueba Independiente**: `POST /api/v1/empleados` con rol barista + tienda_id válido → HTTP 201
con `contrasena_temporal`; repetir sin tienda_id → HTTP 422; repetir con usuario duplicado → HTTP 409.

- [ ] T012 [P] [HU1] Agregar funciones `InsertarEmpleado(ctx, tx, emp) (int64, error)` y
  `ExistePorUsuario(ctx, usuario) (bool, error)` en `loopi-api-v2/internal/empleados/repository.go`
- [ ] T013 [P] [HU1] Agregar función `generarContrasenaTemp() (string, error)` usando `crypto/rand`
  (9 bytes → base64 URL-safe = 12 chars) en `loopi-api-v2/internal/empleados/service.go`
  (según RD-01 en research.md)
- [ ] T014 [HU1] Implementar `CrearEmpleado(ctx, actorID int64, req CrearEmpleadoRequest) (*CrearEmpleadoResponse, error)`
  en `loopi-api-v2/internal/empleados/service.go` con: validar campos obligatorios,
  llamar `ObtenerTiendaActivaPorID` (T047) para barista/lider_tienda, rechazar tienda para admin,
  verificar usuario único con `ExistePorUsuario`, generar contraseña temporal, hashear con
  bcrypt cost `BcryptCostProd`, insertar en TX, registrar audit log CREAR (sin contraseña en detalle)
- [ ] T015 [HU1] Implementar handler `POST /api/v1/empleados` en
  `loopi-api-v2/internal/empleados/handler.go` con middleware `solo_admin`;
  responde HTTP 201 con `CrearEmpleadoResponse` incluyendo `contrasena_temporal`;
  **incluir `LogOperacion` (T045)** con campos `operacion:"crear_empleado"`, `empleado_id`,
  `duracion_ms`; reemplazar stub T046 con esta implementación
- [ ] T016 [P] [HU1] Agregar método `crear(data: CrearEmpleadoRequest): Observable<CrearEmpleadoResponse>`
  al servicio `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts`
- [ ] T017 [HU1] Crear componente standalone
  `loopi-web-v2/src/app/features/empleados/pages/formulario-empleado/formulario-empleado.component.ts`
  (modo crear): formulario reactivo con campos nombre, apellido, usuario, rol, tienda_id
  (visible solo si rol ≠ admin), tipo_documento, numero_documento, telefono, email,
  fecha_nacimiento; manejar errores 409 (usuario duplicado) y 422 (tienda requerida/inactiva)
  resaltando el campo afectado
- [ ] T018 [HU1] Añadir modal de un solo uso que muestra `contrasena_temporal` tras creación
  exitosa (no cierra hasta confirmar copia) en
  `loopi-web-v2/src/app/features/empleados/pages/formulario-empleado/formulario-empleado.component.ts`;
  añadir ruta `/empleados/nuevo` en
  `loopi-web-v2/src/app/features/empleados/empleados.routes.ts`

**Punto de control**: HU1 completamente funcional — crear empleados con cada rol, ver contraseña
temporal, rechazar duplicados y tienda faltante/inactiva.

---

## Fase 4: Historia de Usuario 2 — Editar Empleado (Prioridad: P1)

**Objetivo**: El admin actualiza datos personales, rol o tienda de un empleado existente;
los cambios aplican en la próxima sesión.

**Prueba Independiente**: `PUT /api/v1/empleados/{id}` cambiando rol de barista a lider_tienda
con nueva tienda → HTTP 200; intentar asignar tienda inactiva → HTTP 422.

- [ ] T019 [P] [HU2] Agregar función `ActualizarEmpleado(ctx, tx, id int64, campos map[string]any) error`
  en `loopi-api-v2/internal/empleados/repository.go`; construir UPDATE dinámico solo con
  campos enviados; nunca actualizar el campo `usuario`
- [ ] T020 [HU2] Implementar `EditarEmpleado(ctx, actorID, empleadoID int64, req EditarEmpleadoRequest) (*Empleado, error)`
  en `loopi-api-v2/internal/empleados/service.go` con: llamar `ObtenerTiendaActivaPorID` (T047)
  si rol requiere tienda, limpiar `tienda_id` automáticamente si rol cambia a admin, registrar
  audit log EDITAR con `campos_anteriores` y `campos_nuevos` (excluir `contrasena_hash`)
- [ ] T021 [HU2] Implementar handler `PUT /api/v1/empleados/{id}` en
  `loopi-api-v2/internal/empleados/handler.go` con middleware `solo_admin`;
  retorna HTTP 200 con empleado actualizado (sin `contrasena_hash`);
  **incluir `LogOperacion` (T045)** con `operacion:"editar_empleado"`, `empleado_id`, `duracion_ms`;
  reemplazar stub T046
- [ ] T022 [P] [HU2] Agregar métodos `editar(id: number, data: EditarEmpleadoRequest): Observable<Empleado>`
  y `obtener(id: number): Observable<Empleado>` al servicio
  `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts`
- [ ] T023 [HU2] Extender
  `loopi-web-v2/src/app/features/empleados/pages/formulario-empleado/formulario-empleado.component.ts`
  con modo edición: pre-cargar datos desde `GET /{id}`, deshabilitar campo `usuario`,
  mostrar botón "Guardar cambios"; añadir ruta `/empleados/:id/editar` en
  `loopi-web-v2/src/app/features/empleados/empleados.routes.ts`
  ⚠️ **T028 depende de esta tarea completada** (ambas modifican el mismo componente)

**Punto de control**: HU1 + HU2 funcionales — crear y editar empleados, verificar cambios de
rol y tienda.

---

## Fase 5: Historia de Usuario 3 — Inactivar y Reactivar Empleado (Prioridad: P1)

**Objetivo**: El admin inactiva o reactiva empleados; un empleado inactivo no puede autenticarse;
el sistema impide inactivar al último admin activo.

**Prueba Independiente**: `PATCH /api/v1/empleados/{id}/estado` con `{activo:false}` → HTTP 200;
intentar en el único admin → HTTP 422 con `ultimo_admin_activo`.

- [ ] T024 [P] [HU3] Agregar funciones `ActualizarActivo(ctx, tx, id int64, activo bool) error`
  y `ContarAdminsActivosExcluyendo(ctx, tx, id int64) (int, error)` en
  `loopi-api-v2/internal/empleados/repository.go`; `ContarAdminsActivosExcluyendo` ejecuta
  dentro de la TX para garantizar atomicidad (RD-04 en research.md)
- [ ] T025 [HU3] Implementar `CambiarEstado(ctx, actorID, empleadoID int64, activo bool) error`
  en `loopi-api-v2/internal/empleados/service.go`: abrir TX, si `activo=false` y rol=admin
  verificar `ContarAdminsActivosExcluyendo > 0` (retornar `ErrUltimoAdminActivo` si falla),
  llamar `ActualizarActivo`, registrar audit log INACTIVAR o REACTIVAR con
  `{estado_anterior, estado_nuevo}`, commit TX
- [ ] T026 [HU3] Implementar handler `PATCH /api/v1/empleados/{id}/estado` en
  `loopi-api-v2/internal/empleados/handler.go` con middleware `solo_admin`;
  mapear `ErrUltimoAdminActivo` → HTTP 422;
  **incluir `LogOperacion` (T045)** con `operacion:"cambiar_estado_empleado"`, `empleado_id`,
  `duracion_ms`; reemplazar stub T046
- [ ] T027 [P] [HU3] Agregar método
  `cambiarEstado(id: number, activo: boolean): Observable<{id: number; activo: boolean}>`
  al servicio `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts`
- [ ] T028 [HU3] Agregar botón "Inactivar" / "Reactivar" en
  `loopi-web-v2/src/app/features/empleados/pages/formulario-empleado/formulario-empleado.component.ts`
  (modo edición) con diálogo de confirmación; mostrar mensaje específico cuando el servidor
  retorna `ultimo_admin_activo`
  ⚠️ **Depende de T023 completo** — ambas tareas modifican el mismo componente; no paralelizar

**Punto de control**: HU1 + HU2 + HU3 funcionales — inactivar un empleado bloquea su login;
el último admin no puede inactivarse.

---

## Fase 6: Historia de Usuario 5 — Ver Listado de Empleados (Prioridad: P1)

**Objetivo**: El admin consulta, filtra, busca y pagina el listado de empleados de todas
las tiendas.

**Prueba Independiente**: `GET /api/v1/empleados?q=ana&tienda_id=1&activo=true&page=1&limit=20`
→ HTTP 200 con `{empleados:[...], total:N, page:1, limit:20}`; campo `contrasena_hash`
ausente en todos los objetos de la respuesta.

- [ ] T029 [P] [HU5] Agregar función `ListarEmpleados(ctx, p ListarEmpleadosParams) ([]Empleado, int, error)`
  en `loopi-api-v2/internal/empleados/repository.go` con query `SQL_CALC_FOUND_ROWS` +
  `LOWER(CONCAT(nombre,' ',apellido)) LIKE` + filtros `tienda_id`/`activo` + `LIMIT/OFFSET`
  (según RD-05 en research.md); columnas explícitas — **nunca incluir `contrasena_hash`**
  en el SELECT (RF-EMP-05.6)
- [ ] T030 [HU5] Implementar `ListarEmpleados` y `ObtenerEmpleado` en
  `loopi-api-v2/internal/empleados/service.go` como wrappers del repository con validación
  de parámetros (limit máx 100, page ≥ 1)
- [ ] T031 [HU5] Implementar handlers `GET /api/v1/empleados` y `GET /api/v1/empleados/{id}`
  en `loopi-api-v2/internal/empleados/handler.go` con middleware `solo_admin`;
  mapear query params a `ListarEmpleadosParams`;
  **incluir `LogOperacion` (T045)** con `operacion:"listar_empleados"` / `"obtener_empleado"`,
  `duracion_ms`; reemplazar stubs T046
- [ ] T032 [P] [HU5] Agregar método `listar(params: ListarEmpleadosParams): Observable<ListaEmpleadosResponse>`
  al servicio `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts`
- [ ] T033 [HU5] Crear componente standalone
  `loopi-web-v2/src/app/features/empleados/pages/lista-empleados/lista-empleados.component.ts`
  con: tabla de empleados (nombre, apellido, usuario, rol, tienda, estado), campo de búsqueda
  (signal + debounce 300ms), selector de tienda, toggle activo/inactivo, paginación
  (botones Anterior/Siguiente + total), navegación a editar al hacer clic en fila
- [ ] T034 [HU5] Añadir ruta `/empleados` (lista) en
  `loopi-web-v2/src/app/features/empleados/empleados.routes.ts` y registrar la feature
  como lazy route en `loopi-web-v2/src/app/app.routes.ts`

**Punto de control**: HU1–HU3 + HU5 funcionales — listado completo con búsqueda, filtros
y paginación; `contrasena_hash` ausente en todas las respuestas.

---

## Fase 7: Historia de Usuario 4 — Resetear Contraseña (Prioridad: P2)

**Objetivo**: El admin resetea la contraseña de un empleado; este recibe una contraseña temporal
que debe cambiar en su primer login; el empleado también puede cambiar su propia contraseña.

**Prueba Independiente**: `POST /api/v1/empleados/{id}/contrasena` → HTTP 200 con
`{contrasena_temporal}`; llamar de nuevo → HTTP 200 con contraseña diferente (no idempotente,
RF-EMP-04.2); `POST /api/v1/empleados/{id}/contrasena/cambiar` con contraseña de 3 chars →
HTTP 400 (mínimo 4 chars, RF-EMP-04.5).

- [ ] T035 [P] [HU4] Agregar función `ActualizarContrasena(ctx, id int64, hash string) error`
  que actualiza `contrasena_hash` y pone `requiere_cambio_contrasena = 1` en
  `loopi-api-v2/internal/empleados/repository.go`
- [ ] T036 [HU4] Implementar `ResetearContrasena(ctx, actorID, empleadoID int64) (string, error)`
  en `loopi-api-v2/internal/empleados/service.go`: generar contraseña temporal con
  `generarContrasenaTemp()`, hashear con bcrypt cost `BcryptCostProd`, llamar
  `ActualizarContrasena`, registrar audit log RESET_CONTRASENA con `{motivo:"reset_admin"}`
  (sin contraseña en detalle, RF-EMP-05-A.2)
- [ ] T037 [HU4] Implementar handler `POST /api/v1/empleados/{id}/contrasena` en
  `loopi-api-v2/internal/empleados/handler.go` con middleware `solo_admin`;
  retorna HTTP 200 con `{contrasena_temporal}`;
  **incluir `LogOperacion` (T045)** con `operacion:"reset_contrasena"`, `empleado_id`,
  `duracion_ms`; reemplazar stub T046
- [ ] T038 [P] [HU4] Agregar método `resetearContrasena(id: number): Observable<ResetContrasenaResponse>`
  al servicio `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts`
- [ ] T039 [HU4] Agregar botón "Resetear contraseña" en
  `loopi-web-v2/src/app/features/empleados/pages/formulario-empleado/formulario-empleado.component.ts`
  (modo edición) con diálogo de confirmación; mostrar `contrasena_temporal` en modal de un
  solo uso igual que en creación (HU1)
- [ ] T048 [HU4] Implementar endpoint `POST /api/v1/empleados/{id}/contrasena/cambiar`
  en `loopi-api-v2/internal/empleados/handler.go` (accesible sin middleware `solo_admin`
  pero requiere token válido del propio empleado): valida que `nueva_contrasena` tiene
  mínimo 4 caracteres (RF-EMP-04.5) retornando HTTP 400 si no cumple, hashea con bcrypt
  cost `BcryptCostProd`, actualiza `contrasena_hash` y pone `requiere_cambio_contrasena = 0`
  en DB vía `ActualizarContrasena` + función nueva `MarcarCambioCompletado`

**Punto de control**: Flujo completo de reset + cambio funcional — contraseña temporal mostrada
una vez; cambio rechaza menos de 4 chars; flag `requiere_cambio_contrasena` pasa a 0 al cambiar.

---

## Fase Final: Pulido y Aspectos Transversales

**Propósito**: Observabilidad completa, normalización de errores, tests y coordinación
con 001-autenticacion.

- [ ] T040 Verificar que las 6 rutas del router principal están correctamente conectadas
  a los handlers reales (no stubs) en `loopi-api-v2/cmd/api/main.go`
  (o el archivo equivalente según estructura del proyecto); confirmar que el middleware
  `solo_admin` está aplicado en todas excepto en T048 (`/contrasena/cambiar`)
- [ ] T041 [P] Audit de observabilidad: verificar que **todos** los handlers de empleados
  usan `LogOperacion` (T045) con los campos `user_id`, `rol`, `tienda_id`, `operacion`,
  `empleado_id` (cuando aplica), `duracion_ms`; corregir cualquier handler que los omita
- [ ] T042 [P] Validar que todos los errores del handler usan el formato
  `{error, mensaje, campo, detalles}` con códigos HTTP correctos
  (400/403/404/409/422/500) según contracts/api.md en
  `loopi-api-v2/internal/empleados/handler.go`
- [ ] T043 [P] Escribir tests unitarios en `loopi-api-v2/internal/empleados/service_test.go`
  usando mocks: `TestCrearEmpleadoBaristaSinTienda` (→ error tienda_requerida),
  `TestCrearEmpleadoUsuarioDuplicado` (→ error usuario_duplicado),
  `TestInactivarUltimoAdmin` (→ ErrUltimoAdminActivo),
  `TestResetContrasenaGeneraHashDistinto` (dos resets → hashes distintos),
  `TestEditarEmpleadoTiendaInactiva` (→ error tienda_no_existe),
  `TestCambiarContrasenaMinimo4Chars` (→ HTTP 400 con 3 chars)
- [ ] T049 Verificar integración RF-EMP-04.6 con 001-autenticacion: confirmar que el
  middleware de sesión de 001-autenticacion lee el flag `requiere_cambio_contrasena`
  (del JWT o de la BD) y retorna HTTP 403 en todos los endpoints excepto
  `POST /api/v1/empleados/{id}/contrasena/cambiar`; documentar el punto de integración
  en `specs/003-gestion-empleados/quickstart.md`
- [ ] T044 Ejecutar smoke tests del `quickstart.md` e incluir el escenario de
  cambio de contraseña con validación de mínimo 4 chars

---

## Dependencias y Orden de Ejecución

### Dependencias de Fase

- **Fase 1 (Setup)**: Sin dependencias — puede comenzar de inmediato
- **Fase 2 (Fundacional)**: Depende de Fase 1 — **BLOQUEA todas las historias de usuario**
- **Fase 3–7 (Historias)**: Dependen de Fase 2; ejecutar en orden de prioridad
- **Fase Final**: Depende de que todas las historias deseadas estén completas

### Dependencias entre Historias de Usuario

- **HU1 (P1)**: Puede comenzar tras Fase 2 — sin dependencias de otras historias
- **HU2 (P1)**: Puede comenzar tras Fase 2 — reutiliza formulario de HU1; testeable independientemente
- **HU3 (P1)**: Depende de **T023 completo** antes de T028 (mismo archivo); testeable independientemente
- **HU5 (P1)**: Puede comenzar tras Fase 2 — independiente; requiere datos de HU1 para testeo E2E
- **HU4 (P2)**: Puede comenzar tras Fase 2; T048 puede desarrollarse en paralelo con T035–T039

### Dependencias Explícitas dentro de Historias

- T028 → depende de T023 (mismo archivo `formulario-empleado.component.ts`)
- T014 → depende de T047 (`ObtenerTiendaActivaPorID`)
- T020 → depende de T047 (`ObtenerTiendaActivaPorID`)
- T015, T021, T026, T031, T037 → dependen de T045 (helper logging)
- Todos los handlers → dependen de T046 (router skeleton previo)

### Oportunidades de Paralelismo

- T001 + T003 en paralelo (migraciones distintas)
- T005–T011 + T045 + T047 en paralelo (Fase 2, archivos distintos)
- T046 puede ejecutarse tras T006 (necesita structs de model.go)
- Por historia: repository [P] + angular service [P] → service → handler (secuencial)

---

## Ejemplo de Ejecución Paralela — Fase 2

```text
Paralelo simultáneo:
  T005 → config/hash.go
  T006 → model.go (structs Go)
  T007 → empleado.model.ts (interfaces TS)
  T008 → middleware/solo_admin.go
  T009 → auditoria/empleados_log.go
  T010 → repository.go (base, columnas explícitas)
  T011 → empleados.service.ts (skeleton)
  T045 → middleware/logger.go (logging estructurado)
  T047 → repository.go: ObtenerTiendaActivaPorID

Secuencial (después de T006):
  T046 → router skeleton con stubs
```

---

## Estrategia de Implementación

### MVP Primero (Solo HU1)

1. Completar Fase 1: Migraciones
2. Completar Fase 2: Fundacional incluyendo T045 (logs) y T046 (router)
3. Completar Fase 3: HU1 — Crear empleado
4. **PARAR Y VALIDAR**: Crear empleados con cada rol, ver contraseña temporal
5. Deploy/demo si está listo — observabilidad ya activa desde el primer deploy

### Entrega Incremental

1. Fase 1 + Fase 2 → Base + router + logs listos
2. HU1 → Crear empleados (MVP) ✓ demo
3. HU2 → Editar empleados ✓ demo
4. HU3 → Inactivar/reactivar ✓ demo
5. HU5 → Listado con búsqueda ✓ demo
6. HU4 → Reset + cambio contraseña ✓ demo
7. Fase Final → Audit, tests, integración 001

---

## Notas

- Las tareas `[P]` pueden ejecutarse en paralelo (archivos distintos, sin bloqueos)
- **T028 depende de T023** — no paralelizar (mismo archivo)
- Cada historia de usuario es un incremento completamente testeable antes de la siguiente
- `contrasena_hash` nunca en respuestas API (RF-EMP-05.6) — verificar en T010, T029, T031
- Audit log en toda operación de escritura (RF-EMP-05-A.1) — T014, T020, T025, T036
- Verificación atómica del último admin (RF-EMP-03.5) — TX en T025
- bcrypt cost: `BcryptCostProd` en producción, `BcryptCostTests` en tests (T005)
- Logging estructurado desde Fase 2 (T045) — Constitución Principio VI
- Router skeleton en Fase 2 (T046) — los checkpoints de HU1–HU5 requieren endpoints accesibles
