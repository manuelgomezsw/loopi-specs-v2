# Tasks: 003-gestion-empleados — Selects Tienda y Tipo de Documento

**Branch**: `018-selects-tienda-tipo-doc`
**Input**: [plan.md](./plan.md) · [spec.md](./spec.md) · [data-model.md](./data-model.md) · [contracts/api.md](./contracts/api.md) · [research.md](./research.md)

**Alcance**: Actualización incremental. Los campos `Tienda` y `Tipo de documento` en los
formularios de creación y edición de empleado pasan de texto libre a `<select>` controlado.
Requiere migración de BD, validación backend y cambios en componentes Angular.

**Repos afectados**: `loopi-api` (migración + service) · `loopi-web` (2 componentes + service)

## Formato: `[ID] [P?] [Story?] Descripción con ruta de archivo`

- **[P]**: Paralelizable — archivos distintos, sin dependencias incompletas
- **[US1]**: Historia de Usuario 1 — Select fields en formulario de creación de empleado
- **[US2]**: Historia de Usuario 2 — Select fields en formulario de edición de empleado

---

## Phase 1: Fundacional (Prerrequisitos bloqueantes)

**Propósito**: Cambios de infraestructura que bloquean todo el resto — la migración
debe aplicarse antes de que el backend valide el ENUM, y el servicio Angular
de tiendas debe estar listo antes de que los componentes lo inyecten.

**⚠️ CRÍTICO**: Completar esta fase antes de iniciar las fases de usuario.

- [ ] T001 Crear migración `NNNN_alter_empleados_tipo_documento_enum.up.sql` en `loopi-api/db/migrations/` con los dos pasos: UPDATE de valores inválidos + ALTER COLUMN a ENUM('CC','CE','NUIP','PE') (ver data-model.md)
- [ ] T002 Crear migración reversible `NNNN_alter_empleados_tipo_documento_enum.down.sql` en `loopi-api/db/migrations/` que revierta a VARCHAR(30) NULL
- [ ] T003 [P] Verificar que `TiendasService.getTiendasActivas()` existe en `loopi-web/src/app/features/tiendas/tiendas.service.ts`; si no existe, agregar el método que llama a `GET /api/v1/tiendas?activo=true` y retorna `Observable<{id: number; nombre: string}[]>`

**Checkpoint**: Migración lista para aplicar · Servicio de tiendas activas disponible

---

## Phase 2: Backend — Validación `tipo_documento` (US1 + US2)

**Propósito**: Agregar la validación del ENUM en la capa de servicio y su mapeo HTTP.
Bloquea las fases de usuario hasta garantizar que el backend rechaza valores inválidos.

**⚠️ CRÍTICO**: Completar antes de las fases US1/US2.

- [ ] T004 Agregar error de dominio `ErrTipoDocumentoInvalido` en `loopi-api/internal/empleados/service.go` con mensaje "tipo de documento no válido"
- [ ] T005 Agregar mapa `tiposDocumentoValidos = map[string]bool{"CC":true,"CE":true,"NUIP":true,"PE":true}` y validación en `CrearEmpleado()` en `loopi-api/internal/empleados/service.go`
- [ ] T006 Agregar la misma validación en `EditarEmpleado()` en `loopi-api/internal/empleados/service.go`
- [ ] T007 [P] Mapear `ErrTipoDocumentoInvalido` → HTTP 422 `tipo_documento_invalido` en el switch de errores del handler de crear empleado en `loopi-api/internal/empleados/handler.go`
- [ ] T008 [P] Mapear `ErrTipoDocumentoInvalido` → HTTP 422 `tipo_documento_invalido` en el switch de errores del handler de editar empleado en `loopi-api/internal/empleados/handler.go`
- [ ] T009 [P] Agregar test `TestCrearEmpleadoTipoDocumentoInvalido` (valor "TI" → espera error `ErrTipoDocumentoInvalido`) en `loopi-api/internal/empleados/service_test.go`
- [ ] T010 [P] Agregar test `TestCrearEmpleadoTipoDocumentoValido` (CC, CE, NUIP, PE y cadena vacía → sin error) en `loopi-api/internal/empleados/service_test.go`

**Checkpoint**: `go test ./internal/empleados/...` pasa con los nuevos tests

---

## Phase 3: US1 — Select fields en formulario de creación de empleado (P1) 🎯 MVP

**Goal**: El formulario de creación muestra `<select>` para Tipo de documento (4 opciones
estáticas) y `<select>` para Tienda (cargado dinámicamente desde API al abrir el formulario).

**Prueba independiente**: Abrir el formulario de creación de empleado en el navegador;
verificar que ambos campos muestran listas desplegables. Crear un empleado con
Tipo de documento = "CE" y una tienda seleccionada → operación exitosa (201).

### Implementación US1

- [ ] T011 [P] [US1] Agregar constante `tiposDocumento` (array con CC, CE, NUIP, PE y sus etiquetas completas) en `loopi-web/src/app/features/empleados/crear-empleado/crear-empleado.component.ts`
- [ ] T012 [P] [US1] Reemplazar el `<input type="text">` de `tipo_documento` por `<select>` con `@for` sobre `tiposDocumento` en `loopi-web/src/app/features/empleados/crear-empleado/crear-empleado.component.html`; primera opción placeholder vacía `"— Seleccionar (opcional) —"`; aplicar `bg-white border-gray-300 rounded-lg`
- [ ] T013 [US1] Inyectar `TiendasService` y agregar propiedades `tiendasActivas`, `cargandoTiendas`, `errorCargaTiendas` + método privado `cargarTiendasActivas()` en `loopi-web/src/app/features/empleados/crear-empleado/crear-empleado.component.ts`; invocar en `ngOnInit()`
- [ ] T014 [US1] Reemplazar el campo de tienda actual por `<select>` dinámico en `loopi-web/src/app/features/empleados/crear-empleado/crear-empleado.component.html` con: skeleton `animate-pulse` durante carga, opción deshabilitada "No hay tiendas activas disponibles" si lista vacía, mensaje de error en `text-red-600` si falla la API (ver plan.md §1.3)

**Checkpoint**: El formulario de creación muestra ambos selects correctamente; crear empleado
funciona end-to-end con tienda seleccionada y tipo de documento "CC" → 201 con `contrasena_temporal`

---

## Phase 4: US2 — Select fields en formulario de edición de empleado (P1)

**Goal**: El formulario de edición aplica las mismas reglas de selects que el de creación
y preselecciona automáticamente los valores actuales del empleado.

**Prueba independiente**: Abrir el formulario de edición de un empleado con
`tipo_documento = "CC"` y tienda asignada; verificar que ambos `<select>` aparecen con
el valor actual preseleccionado. Cambiar tipo de documento a "NUIP" y guardar → 200.

### Implementación US2

- [ ] T015 [P] [US2] Agregar constante `tiposDocumento` (idéntica a T011) en `loopi-web/src/app/features/empleados/editar-empleado/editar-empleado.component.ts`
- [ ] T016 [P] [US2] Reemplazar el `<input type="text">` de `tipo_documento` por `<select>` en `loopi-web/src/app/features/empleados/editar-empleado/editar-empleado.component.html`; misma estructura que T012 pero con `[value]="tipo.codigo"` para preselección via `patchValue`
- [ ] T017 [US2] Inyectar `TiendasService` y agregar `cargarTiendasActivas()` en `loopi-web/src/app/features/empleados/editar-empleado/editar-empleado.component.ts`; encadenar el `patchValue` de `tienda_id` y `tipo_documento` dentro del callback de carga de tiendas (o usar `forkJoin`) para garantizar preselección correcta
- [ ] T018 [US2] Reemplazar el campo de tienda por `<select>` dinámico con preselección en `loopi-web/src/app/features/empleados/editar-empleado/editar-empleado.component.html`; mismos estados de carga/vacío/error que T014

**Checkpoint**: El formulario de edición muestra ambos selects con valores actuales preseleccionados;
guardar cambios (PUT) funciona correctamente; `tipo_documento` inválido enviado vía API → 422

---

## Phase 5: Polish y Validación Final

**Propósito**: Aplicar migración en dev, verificar cobertura y ejecutar smoke tests.

- [ ] T019 [P] Aplicar migración en entorno de desarrollo: `migrate -path ./db/migrations -database "$DB_DSN" up` en `loopi-api/` y verificar con `DESCRIBE empleados` que `tipo_documento` es `ENUM('CC','CE','NUIP','PE')`
- [ ] T020 [P] Ejecutar suite de tests backend con cobertura: `go test ./internal/empleados/... -coverprofile=coverage.out -covermode=atomic` en `loopi-api/` y verificar ≥ 95% en `service.go`
- [ ] T021 [P] Ejecutar tests Angular: `ng test --watch=false` en `loopi-web/` y verificar que pasan los specs de `crear-empleado.component.spec.ts` y `editar-empleado.component.spec.ts`
- [ ] T022 Ejecutar smoke test de creación per quickstart.md §4: crear empleado con `tipo_documento:"CE"` y `tienda_id` válido via curl → verificar 201 con `contrasena_temporal`
- [ ] T023 Ejecutar smoke test de validación backend: enviar `tipo_documento:"TI"` via curl → verificar 422 `tipo_documento_invalido`; enviar `tipo_documento:"NUIP"` → verificar 201

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Fundacional)
  ├─► T001, T002 → Phase 2 (Backend) → Phase 5 T019/T020
  └─► T003 (TiendasService) → T013 (US1) / T017 (US2)

Phase 2 (Backend)
  ├─► T004 → T005 → T006 (en serie: mismo archivo service.go)
  ├─► T007, T008 en paralelo (handler.go, secciones distintas)
  └─► T009, T010 en paralelo (tests del service)

Phase 3 (US1)
  ├─► T011 ‖ T012 en paralelo (archivos .ts y .html distintos)
  └─► T013 → T014 en serie (T014 usa estados declarados en T013)

Phase 4 (US2) — paralelizable con Phase 3
  ├─► T015 ‖ T016 en paralelo
  └─► T017 → T018 en serie

Phase 5
  ├─► T019 ‖ T020 ‖ T021 en paralelo
  └─► T022 → T023 en serie
```

### Dependencias entre User Stories

- **US1 (P1)**: Depende de Phase 1 y Phase 2. Sin dependencia de US2.
- **US2 (P1)**: Depende de Phase 1 y Phase 2. Sin dependencia de US1. Pueden implementarse
  en paralelo si hay dos desarrolladores disponibles.

---

## Parallel Example: US1 + US2 simultáneo

```bash
# Desarrollador A — tras completar Phases 1 y 2:
Task T011: "Agregar tiposDocumento en crear-empleado.component.ts"
Task T012: "Select tipo_documento en crear-empleado.component.html"  # paralelo con T011
# → T013 → T014

# Desarrollador B — en paralelo con Dev A:
Task T015: "Agregar tiposDocumento en editar-empleado.component.ts"
Task T016: "Select tipo_documento en editar-empleado.component.html"  # paralelo con T015
# → T017 → T018
```

---

## Implementation Strategy

### MVP (solo US1 — formulario de creación)

1. Completar **Phase 1** (T001–T003)
2. Completar **Phase 2** (T004–T010)
3. Completar **Phase 3** (T011–T014)
4. **VALIDAR**: smoke test de creación con ambos selects funcionando
5. Continuar con Phase 4 (US2 — formulario de edición)

### Entrega incremental

1. Phase 1 + Phase 2 → Migración aplicada · Backend valida ENUM
2. Phase 3 → Formulario de creación con selects (MVP funcional)
3. Phase 4 → Formulario de edición con selects y preselección
4. Phase 5 → Validación integral antes del PR

---

## Notes

- `[P]` dentro de una fase indica archivos distintos sin dependencia entre sí
- `tipo_documento` es **opcional**: el `<select>` debe tener una primera opción vacía;
  el formulario acepta envío sin selección → backend recibe campo omitido o `""`
- La preselección en edición (T017) es el punto más delicado: llamar `patchValue`
  **después** de que `tiendasActivas` esté poblado, no antes
- Si `getTiendasActivas()` ya existe en T003, marcar completado sin modificar el archivo
  para evitar regresiones en otras vistas que usen el mismo servicio
- Todos los `<select>` deben usar `bg-white border-gray-300 rounded-lg px-3 py-2`
  per §Superficie de Formulario de la constitución (v1.9.0)
- Total: **23 tareas** · US1: 4 tareas · US2: 4 tareas · Backend: 7 tareas · Fundacional: 3 · Polish: 5
