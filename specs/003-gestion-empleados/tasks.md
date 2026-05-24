# Tareas: Gestión de Empleados

**Entrada**: Documentos de diseño desde `/specs/003-gestion-empleados/`
**Prerrequisitos**: plan.md ✅ · spec.md ✅ · research.md ✅ · data-model.md ✅ · contracts/api.md ✅
**Repos**: `loopi-api-v2` (Go backend) · `loopi-web-v2` (Angular frontend)

## Formato: `[ID] [P?] [HU?] Descripción con ruta exacta`

- **[P]**: Ejecutable en paralelo (archivos distintos, sin dependencias incompletas)
- **[HU]**: Historia de usuario a la que pertenece la tarea
- Sin etiqueta de historia: Fase de Setup o Fundacional

---

## Fase 1: Setup — Migraciones de Base de Datos

**Propósito**: Crear las tablas `empleados` y `log_auditoria_empleados` en MySQL.

- [ ] T001 Crear migración `NNNN_crear_tabla_empleados.up.sql` con DDL completo (columnas, índices, FK a tiendas) según data-model.md en `loopi-api-v2/db/migrations/`
- [ ] T002 Crear migración `NNNN_crear_tabla_empleados.down.sql` con `DROP TABLE IF EXISTS empleados` en `loopi-api-v2/db/migrations/`
- [ ] T003 [P] Crear migración `NNNN+1_crear_tabla_log_auditoria_empleados.up.sql` con DDL completo (columnas JSON, FKs a empleados) según data-model.md en `loopi-api-v2/db/migrations/`
- [ ] T004 [P] Crear migración `NNNN+1_crear_tabla_log_auditoria_empleados.down.sql` con `DROP TABLE IF EXISTS log_auditoria_empleados` en `loopi-api-v2/db/migrations/`

**Punto de control**: Ejecutar `migrate -path ./db/migrations -database $DB_DSN up 2` y verificar ambas tablas con `DESCRIBE empleados; DESCRIBE log_auditoria_empleados;`

---

## Fase 2: Fundacional — Infraestructura Compartida

**Propósito**: Tipos, helpers y middleware que TODAS las historias de usuario necesitan.

⚠️ **CRÍTICO**: Ninguna historia de usuario puede comenzar hasta completar esta fase.

- [ ] T005 Crear `loopi-api-v2/internal/config/hash.go` con constantes `BcryptCostProd = 12` y `BcryptCostTests = 4` (según RD-07 en research.md)
- [ ] T006 [P] Crear `loopi-api-v2/internal/empleados/model.go` con structs Go: `Empleado`, `CrearEmpleadoRequest`, `EditarEmpleadoRequest`, `CambiarEstadoRequest`, `ListarEmpleadosParams`, `ListarEmpleadosResponse`, `CrearEmpleadoResponse`, `ResetContrasenaResponse` — todos los campos según contracts/api.md
- [ ] T007 [P] Crear `loopi-web-v2/src/app/features/empleados/models/empleado.model.ts` con todas las interfaces TypeScript: `Empleado`, `ListaEmpleadosResponse`, `CrearEmpleadoResponse`, `ResetContrasenaResponse`, `ListarEmpleadosParams` según contracts/api.md
- [ ] T008 Crear `loopi-api-v2/middleware/solo_admin.go` que extrae claims JWT, verifica `rol == "admin"` y retorna `HTTP 403 {error:"acceso_denegado"}` si no cumple; reutilizar el extractor de claims de 001-autenticacion
- [ ] T009 Crear `loopi-api-v2/internal/auditoria/empleados_log.go` con función `RegistrarLog(ctx context.Context, tx *sql.Tx, actorID, empleadoID int64, accion string, detalle map[string]any) error` que inserta en `log_auditoria_empleados`; el campo `detalle` nunca debe incluir contraseñas ni hashes
- [ ] T010 Crear `loopi-api-v2/internal/empleados/repository.go` con struct `Repository`, constructor `NewRepository(db *sql.DB)` y función base `ObtenerPorID(ctx, id) (*Empleado, error)` que retorna `ErrNoEncontrado` si no existe
- [ ] T011 [P] Crear `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts` como skeleton con `HttpClient` inyectado y la constante `private readonly base = '/api/v1/empleados'`

**Punto de control**: `go build ./...` pasa; `ng build` pasa — sin errores de compilación.

---

## Fase 3: Historia de Usuario 1 — Crear Empleado (Prioridad: P1) 🎯 MVP

**Objetivo**: El admin puede registrar un nuevo empleado con rol y tienda, obtener la contraseña temporal y el empleado puede autenticarse de inmediato.

**Prueba Independiente**: `POST /api/v1/empleados` con rol barista + tienda_id válido → HTTP 201 con `contrasena_temporal`; repetir con rol barista sin tienda_id → HTTP 422; repetir con usuario duplicado → HTTP 409.

- [ ] T012 [P] [HU1] Agregar funciones `InsertarEmpleado(ctx, tx, emp) (int64, error)` y `ExistePorUsuario(ctx, usuario) (bool, error)` en `loopi-api-v2/internal/empleados/repository.go`
- [ ] T013 [P] [HU1] Agregar función `generarContrasenaTemp() (string, error)` usando `crypto/rand` (9 bytes → base64 URL-safe = 12 chars) en `loopi-api-v2/internal/empleados/service.go` (según RD-01 en research.md)
- [ ] T014 [HU1] Implementar `CrearEmpleado(ctx, actorID int64, req CrearEmpleadoRequest) (*CrearEmpleadoResponse, error)` en `loopi-api-v2/internal/empleados/service.go` con: validar campos obligatorios, verificar tienda activa para barista/lider_tienda, rechazar tienda para admin, verificar usuario único, generar contraseña temporal, hashear con bcrypt cost BcryptCostProd, insertar en TX, registrar audit log CREAR (sin contraseña en detalle)
- [ ] T015 [HU1] Implementar handler `POST /api/v1/empleados` en `loopi-api-v2/internal/empleados/handler.go` con middleware `solo_admin`; responde HTTP 201 con `CrearEmpleadoResponse` incluyendo `contrasena_temporal`
- [ ] T016 [P] [HU1] Agregar método `crear(data: CrearEmpleadoRequest): Observable<CrearEmpleadoResponse>` al servicio `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts`
- [ ] T017 [HU1] Crear componente standalone `loopi-web-v2/src/app/features/empleados/pages/formulario-empleado/formulario-empleado.component.ts` (modo crear): formulario reactivo con campos nombre, apellido, usuario, rol, tienda_id (visible solo si rol ≠ admin), tipo_documento, numero_documento, telefono, email, fecha_nacimiento; manejar errores 409 (usuario duplicado) y 422 (tienda requerida/inactiva) resaltando el campo
- [ ] T018 [HU1] Añadir modal de un solo uso que muestra `contrasena_temporal` tras creación exitosa (no cierra hasta confirmar copia) en `loopi-web-v2/src/app/features/empleados/pages/formulario-empleado/formulario-empleado.component.ts`; añadir ruta `/empleados/nuevo` en `loopi-web-v2/src/app/features/empleados/empleados.routes.ts`

**Punto de control**: HU1 completamente funcional — crear empleados con cada rol, ver contraseña temporal, rechazar duplicados y tienda faltante/inactiva.

---

## Fase 4: Historia de Usuario 2 — Editar Empleado (Prioridad: P1)

**Objetivo**: El admin actualiza datos personales, rol o tienda de un empleado existente; los cambios aplican en la próxima sesión.

**Prueba Independiente**: `PUT /api/v1/empleados/{id}` cambiando rol de barista a lider_tienda con nueva tienda → HTTP 200; intentar asignar tienda inactiva → HTTP 422.

- [ ] T019 [P] [HU2] Agregar función `ActualizarEmpleado(ctx, tx, id int64, campos map[string]any) error` en `loopi-api-v2/internal/empleados/repository.go`; construir UPDATE dinámico solo con campos enviados; nunca actualizar el campo `usuario`
- [ ] T020 [HU2] Implementar `EditarEmpleado(ctx, actorID, empleadoID int64, req EditarEmpleadoRequest) (*Empleado, error)` en `loopi-api-v2/internal/empleados/service.go` con: verificar tienda activa si rol requiere, limpiar `tienda_id` automáticamente si rol cambia a admin, registrar audit log EDITAR con `campos_anteriores` y `campos_nuevos` (excluir `contrasena_hash`)
- [ ] T021 [HU2] Implementar handler `PUT /api/v1/empleados/{id}` en `loopi-api-v2/internal/empleados/handler.go` con middleware `solo_admin`; retorna HTTP 200 con empleado actualizado (sin `contrasena_hash`)
- [ ] T022 [P] [HU2] Agregar método `editar(id: number, data: EditarEmpleadoRequest): Observable<Empleado>` y `obtener(id: number): Observable<Empleado>` al servicio `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts`
- [ ] T023 [HU2] Extender `loopi-web-v2/src/app/features/empleados/pages/formulario-empleado/formulario-empleado.component.ts` con modo edición: pre-cargar datos desde `GET /{id}`, deshabilitar campo `usuario`, mostrar botón "Guardar cambios"; añadir ruta `/empleados/:id/editar` en `loopi-web-v2/src/app/features/empleados/empleados.routes.ts`

**Punto de control**: HU1 + HU2 funcionales — crear y editar empleados, verificar cambios de rol y tienda.

---

## Fase 5: Historia de Usuario 3 — Inactivar y Reactivar Empleado (Prioridad: P1)

**Objetivo**: El admin inactiva o reactiva empleados; un empleado inactivo no puede autenticarse; el sistema impide inactivar al último admin activo.

**Prueba Independiente**: `PATCH /api/v1/empleados/{id}/estado` con `{activo:false}` → HTTP 200; intentar en el único admin → HTTP 422 con `ultimo_admin_activo`.

- [ ] T024 [P] [HU3] Agregar funciones `ActualizarActivo(ctx, tx, id int64, activo bool) error` y `ContarAdminsActivosExcluyendo(ctx, tx, id int64) (int, error)` en `loopi-api-v2/internal/empleados/repository.go`; `ContarAdminsActivosExcluyendo` ejecuta dentro de la TX para garantizar atomicidad (RD-04 en research.md)
- [ ] T025 [HU3] Implementar `CambiarEstado(ctx, actorID, empleadoID int64, activo bool) error` en `loopi-api-v2/internal/empleados/service.go`: abrir TX, si `activo=false` y rol=admin verificar `ContarAdminsActivosExcluyendo > 0` (retornar `ErrUltimoAdminActivo` si falla), llamar `ActualizarActivo`, registrar audit log INACTIVAR o REACTIVAR con `{estado_anterior, estado_nuevo}`, commit TX
- [ ] T026 [HU3] Implementar handler `PATCH /api/v1/empleados/{id}/estado` en `loopi-api-v2/internal/empleados/handler.go` con middleware `solo_admin`; mapear `ErrUltimoAdminActivo` → HTTP 422
- [ ] T027 [P] [HU3] Agregar método `cambiarEstado(id: number, activo: boolean): Observable<{id: number; activo: boolean}>` al servicio `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts`
- [ ] T028 [HU3] Agregar botón "Inactivar" / "Reactivar" en `loopi-web-v2/src/app/features/empleados/pages/formulario-empleado/formulario-empleado.component.ts` (modo edición) con diálogo de confirmación; mostrar mensaje específico cuando el servidor retorna `ultimo_admin_activo`

**Punto de control**: HU1 + HU2 + HU3 funcionales — inactivar un empleado bloquea su login; el último admin no puede inactivarse.

---

## Fase 6: Historia de Usuario 5 — Ver Listado de Empleados (Prioridad: P1)

**Objetivo**: El admin consulta, filtra, busca y pagina el listado de empleados de todas las tiendas.

**Prueba Independiente**: `GET /api/v1/empleados?q=ana&tienda_id=1&activo=true&page=1&limit=20` → HTTP 200 con `{empleados:[...], total:N, page:1, limit:20}`; campo `contrasena_hash` ausente en todos los objetos.

- [ ] T029 [P] [HU5] Agregar función `ListarEmpleados(ctx context.Context, p ListarEmpleadosParams) ([]Empleado, int, error)` en `loopi-api-v2/internal/empleados/repository.go` con query `SQL_CALC_FOUND_ROWS` + `LOWER(CONCAT(nombre,' ',apellido)) LIKE` + filtros `tienda_id`/`activo` + `LIMIT/OFFSET` (según RD-05 en research.md); nunca incluir `contrasena_hash` en el SELECT
- [ ] T030 [HU5] Implementar `ListarEmpleados` y `ObtenerEmpleado` en `loopi-api-v2/internal/empleados/service.go` como wrappers del repository con validación de parámetros (limit máx 100, page ≥ 1)
- [ ] T031 [HU5] Implementar handlers `GET /api/v1/empleados` y `GET /api/v1/empleados/{id}` en `loopi-api-v2/internal/empleados/handler.go` con middleware `solo_admin`; mapear query params a `ListarEmpleadosParams`
- [ ] T032 [P] [HU5] Agregar métodos `listar(params: ListarEmpleadosParams): Observable<ListaEmpleadosResponse>` al servicio `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts`
- [ ] T033 [HU5] Crear componente standalone `loopi-web-v2/src/app/features/empleados/pages/lista-empleados/lista-empleados.component.ts` con: tabla de empleados (nombre, apellido, usuario, rol, tienda, estado), campo de búsqueda (signal + debounce 300ms), selector de tienda, toggle activo/inactivo, paginación (botones Anterior/Siguiente + total), navegación a editar al hacer clic en fila
- [ ] T034 [HU5] Añadir ruta `/empleados` (lista) en `loopi-web-v2/src/app/features/empleados/empleados.routes.ts` y registrar la feature como lazy route en `loopi-web-v2/src/app/app.routes.ts`

**Punto de control**: HU1–HU3 + HU5 funcionales — listado completo con búsqueda, filtros y paginación; sin `contrasena_hash` en ninguna respuesta.

---

## Fase 7: Historia de Usuario 4 — Resetear Contraseña (Prioridad: P2)

**Objetivo**: El admin resetea la contraseña de un empleado; este recibe una contraseña temporal que debe cambiar en su primer login.

**Prueba Independiente**: `POST /api/v1/empleados/{id}/contrasena` → HTTP 200 con `{contrasena_temporal}`; llamar de nuevo → HTTP 200 con contraseña diferente (no idempotente, RF-EMP-04.2).

- [ ] T035 [P] [HU4] Agregar función `ActualizarContrasena(ctx, id int64, hash string) error` que actualiza `contrasena_hash` y pone `requiere_cambio_contrasena = 1` en `loopi-api-v2/internal/empleados/repository.go`
- [ ] T036 [HU4] Implementar `ResetearContrasena(ctx, actorID, empleadoID int64) (string, error)` en `loopi-api-v2/internal/empleados/service.go`: generar contraseña temporal con `generarContrasenaTemp()`, hashear con bcrypt cost BcryptCostProd, llamar `ActualizarContrasena`, registrar audit log RESET_CONTRASENA con `{motivo:"reset_admin"}` (sin contraseña en detalle, RF-EMP-05-A.2)
- [ ] T037 [HU4] Implementar handler `POST /api/v1/empleados/{id}/contrasena` en `loopi-api-v2/internal/empleados/handler.go` con middleware `solo_admin`; retorna HTTP 200 con `{contrasena_temporal}`
- [ ] T038 [P] [HU4] Agregar método `resetearContrasena(id: number): Observable<ResetContrasenaResponse>` al servicio `loopi-web-v2/src/app/features/empleados/services/empleados.service.ts`
- [ ] T039 [HU4] Agregar botón "Resetear contraseña" en `loopi-web-v2/src/app/features/empleados/pages/formulario-empleado/formulario-empleado.component.ts` (modo edición) con diálogo de confirmación; mostrar `contrasena_temporal` en modal de un solo uso (no cierra hasta confirmar) igual que en creación (HU1)

**Punto de control**: Flujo completo de reset funcional — contraseña temporal mostrada una vez, empleado forzado a cambiarla en próximo login.

---

## Fase Final: Pulido y Aspectos Transversales

**Propósito**: Observabilidad, normalización de errores, tests unitarios y registro de rutas.

- [ ] T040 Registrar rutas `/api/v1/empleados` en el router principal de `loopi-api-v2` (wire `NewHandler` + `solo_admin` middleware) para todos los 6 endpoints
- [ ] T041 [P] Agregar logs estructurados JSON en todos los handlers de `loopi-api-v2/internal/empleados/handler.go`: incluir `user_id`, `rol`, `tienda_id` del JWT, `operacion` (nombre del endpoint), `empleado_id` afectado, `duracion_ms`
- [ ] T042 [P] Validar que todos los errores del handler usen el formato `{error, mensaje, campo, detalles}` con códigos HTTP correctos (400/403/404/409/422/500) definidos en contracts/api.md en `loopi-api-v2/internal/empleados/handler.go`
- [ ] T043 [P] Escribir tests unitarios en `loopi-api-v2/internal/empleados/service_test.go` usando mocks: `TestCrearEmpleadoBaristaSinTienda` (→ error tienda_requerida), `TestCrearEmpleadoUsuarioDuplicado` (→ error usuario_duplicado), `TestInactivarUltimoAdmin` (→ ErrUltimoAdminActivo), `TestResetContrasenaGeneraHashDistinto` (dos resets → hashes distintos), `TestEditarEmpleadoTiendaInactiva` (→ error tienda_no_existe)
- [ ] T044 Ejecutar smoke tests del `quickstart.md` y actualizar `plan.md` marcando tasks.md como ✅ completo

---

## Dependencias y Orden de Ejecución

### Dependencias de Fase

- **Fase 1 (Setup)**: Sin dependencias — puede comenzar de inmediato
- **Fase 2 (Fundacional)**: Depende de Fase 1 — **BLOQUEA todas las historias de usuario**
- **Fase 3–7 (Historias)**: Dependen de Fase 2; pueden ejecutarse secuencialmente en orden de prioridad
- **Fase Final**: Depende de que todas las historias deseadas estén completas

### Dependencias entre Historias de Usuario

- **HU1 (P1)**: Puede comenzar tras Fase 2 — sin dependencias de otras historias
- **HU2 (P1)**: Puede comenzar tras Fase 2 — reutiliza formulario-empleado de HU1; testeable independientemente
- **HU3 (P1)**: Puede comenzar tras Fase 2 — testeable independientemente; la UI extiende el formulario de HU2
- **HU5 (P1)**: Puede comenzar tras Fase 2 — independiente; requiere datos creados por HU1 para testeo E2E
- **HU4 (P2)**: Puede comenzar tras Fase 2 — la UI extiende el formulario de HU2; testeable con endpoint solo

### Dentro de Cada Historia de Usuario

- Repository → Service → Handler (backend, en ese orden)
- Model → Service → Component (frontend, en ese orden)
- Backend y frontend de la misma historia pueden trabajarse en paralelo por distintos desarrolladores

### Oportunidades de Paralelismo

- T001 + T003 (migraciones): en paralelo
- T005, T006, T007, T008, T009, T010, T011: todas en paralelo excepto que T009/T010 deben compilar después de T006
- Por historia: Repository [P] + Service y Handler en secuencia; Angular service [P] + Component en secuencia
- HU1, HU2, HU3, HU5 pueden trabajarse en paralelo por equipos distintos una vez completada la Fase 2

---

## Ejemplo de Ejecución Paralela — Fase 2

```text
Paralelo (backends + frontend simultáneo):
  T005 → config/hash.go
  T006 → model.go (Go structs)
  T007 → empleado.model.ts (TS interfaces)
  T008 → middleware/solo_admin.go
  T009 → auditoria/empleados_log.go
  T010 → repository.go (base)
  T011 → empleados.service.ts (skeleton)
```

## Ejemplo de Ejecución Paralela — HU1

```text
Paralelo inicial:
  T012 → repository: InsertarEmpleado + ExistePorUsuario
  T013 → service: generarContrasenaTemp()
  T016 → Angular service: crear()

Secuencial (depende de T012 + T013):
  T014 → service: CrearEmpleado (completo)

Secuencial (depende de T014):
  T015 → handler: POST /api/v1/empleados

Paralelo (depende de T016):
  T017 → Angular: formulario-empleado (crear mode)

Secuencial (depende de T015 + T017):
  T018 → Angular: modal contrasena_temporal + ruta /empleados/nuevo
```

---

## Estrategia de Implementación

### MVP Primero (Solo HU1)

1. Completar Fase 1: Migraciones
2. Completar Fase 2: Fundacional (**CRÍTICO**)
3. Completar Fase 3: HU1 — Crear empleado
4. **PARAR Y VALIDAR**: Crear empleado con cada rol, ver contraseña temporal
5. Deploy/demo si está listo

### Entrega Incremental

1. Fase 1 + Fase 2 → Base lista
2. HU1 → Crear empleados (MVP) ✓ demo
3. HU2 → Editar empleados ✓ demo
4. HU3 → Inactivar/reactivar ✓ demo
5. HU5 → Listado con búsqueda ✓ demo
6. HU4 → Reset contraseña ✓ demo
7. Fase Final → Observabilidad + tests + registro de rutas

---

## Notas

- Las tareas `[P]` pueden ejecutarse en paralelo (archivos distintos, sin bloqueos)
- Cada historia de usuario es un incremento completamente testeable antes de la siguiente
- `contrasena_hash` nunca en respuestas API (RF-EMP-05.6) — verificar en T029 y T031
- Audit log en toda operación de escritura (RF-EMP-05-A.1) — registrar en T014, T020, T025, T036
- Verificación atómica del último admin (RF-EMP-03.5) — implementar en TX en T025
- bcrypt cost: `BcryptCostProd` en producción, `BcryptCostTests` en tests (T005 define las constantes)
