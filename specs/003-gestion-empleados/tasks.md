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

- [X] T001 Crear migración `006_tipo_documento_enum.up.sql` en `loopi-api-v2/migrations/` con los dos pasos: UPDATE de valores inválidos + ALTER COLUMN a ENUM('CC','CE','NUIP','PE')
- [X] T002 Crear migración reversible `006_tipo_documento_enum.down.sql` en `loopi-api-v2/migrations/` que revierta a VARCHAR(30) NULL
- [X] T003 [P] Agregar `getTiendasActivas()` en `loopi-web-v2/src/app/tiendas/tiendas.service.ts` — llama a `listar('activas', 1, 100)` y retorna `Observable<{id: number; nombre: string}[]>`

**Checkpoint**: Migración lista para aplicar · Servicio de tiendas activas disponible

---

## Phase 2: Backend — Validación `tipo_documento` (US1 + US2)

**Propósito**: Agregar la validación del ENUM en la capa de servicio y su mapeo HTTP.
Bloquea las fases de usuario hasta garantizar que el backend rechaza valores inválidos.

**⚠️ CRÍTICO**: Completar antes de las fases US1/US2.

- [X] T004 Agregar mapa `tiposDocumentoValidos` en `loopi-api-v2/internal/empleados/service.go` con los 4 valores válidos
- [X] T005 Agregar validación `tiposDocumentoValidos` en `CrearEmpleado()` usando `ValidationError{Codigo:"tipo_documento_invalido"}` en `loopi-api-v2/internal/empleados/service.go`
- [X] T006 Agregar la misma validación en `EditarEmpleado()` en `loopi-api-v2/internal/empleados/service.go`
- [X] T007 [P] Cubierto automáticamente — `mapServiceError` ya maneja `*ValidationError` via `errors.As` → HTTP 422
- [X] T008 [P] Ídem T007 — mismo mecanismo en `loopi-api-v2/internal/empleados/handler.go`
- [X] T009 [P] Agregar `TestCrearEmpleadoTipoDocumentoInvalido` (valor "TI" → espera código `tipo_documento_invalido`) en `loopi-api-v2/internal/empleados/service_test.go`
- [X] T010 [P] Agregar `TestCrearEmpleadoTipoDocumentoValido` (CC, CE, NUIP, PE y cadena vacía → sin error) en `loopi-api-v2/internal/empleados/service_test.go`

**Checkpoint**: `go test ./internal/empleados/...` pasa con los nuevos tests

---

## Phase 3: US1 — Select fields en formulario de creación de empleado (P1) 🎯 MVP

**Goal**: El formulario de creación muestra `<select>` para Tipo de documento (4 opciones
estáticas) y `<select>` para Tienda (cargado dinámicamente desde API al abrir el formulario).

**Prueba independiente**: Abrir el formulario de creación de empleado en el navegador;
verificar que ambos campos muestran listas desplegables. Crear un empleado con
Tipo de documento = "CE" y una tienda seleccionada → operación exitosa (201).

### Implementación US1

- [X] T011 [P] [US1] Agregar constante `TIPOS_DOCUMENTO` + propiedad `tiposDocumento` en `loopi-web-v2/src/app/empleados/empleado-form/empleado-form.component.ts`
- [X] T012 [P] [US1] Reemplazar `<input type="text">` de `tipo_documento` por `<select>` con `@for` sobre `tiposDocumento` en `loopi-web-v2/src/app/empleados/empleado-form/empleado-form.component.html`; primera opción placeholder vacía; estilos Constitución
- [X] T013 [US1] Inyectar `TiendasService`, agregar signals `tiendasActivas`, `cargandoTiendas`, `errorCargaTiendas` y método `cargarTiendasActivas()` en `loopi-web-v2/src/app/empleados/empleado-form/empleado-form.component.ts`; invocar en `ngOnInit()`
- [X] T014 [US1] Reemplazar campo tienda por `<select>` dinámico en `loopi-web-v2/src/app/empleados/empleado-form/empleado-form.component.html`; skeleton `animate-pulse` durante carga, opción disabled si vacío, mensaje error en `text-red-600`

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

- [X] T015 [P] [US2] Mismo componente que T011 (`EmpleadoFormComponent`) — ya incluye `tiposDocumento` con `modoEdicion` signal. Preselección funciona vía `patchValue` en `cargarEmpleado()`
- [X] T016 [P] [US2] Mismo template que T012 — el `<select>` de tipo_documento sirve tanto crear como editar
- [X] T017 [US2] Mismo componente que T013 — `cargarTiendasActivas()` se invoca en `ngOnInit()` antes de `cargarEmpleado()`; preselección de tienda funciona vía form binding reactive
- [X] T018 [US2] Mismo template que T014 — el `<select>` de tienda con estados de carga/error ya cubre edición

**Checkpoint**: El formulario de edición muestra ambos selects con valores actuales preseleccionados;
guardar cambios (PUT) funciona correctamente; `tipo_documento` inválido enviado vía API → 422

---

## Phase 5: Polish y Validación Final

**Propósito**: Aplicar migración en dev, verificar cobertura y ejecutar smoke tests.

- [ ] T019 [P] Aplicar migración en entorno de desarrollo: `migrate -path ./migrations -database "$DB_DSN" up` en `loopi-api-v2/` y verificar con `DESCRIBE empleados` que `tipo_documento` es `ENUM('CC','CE','NUIP','PE')`
- [X] T020 [P] Tests backend ejecutados: `go test ./internal/empleados/... -covermode=atomic` — todos pasan; `TestCrearEmpleadoTipoDocumentoInvalido` y `TestCrearEmpleadoTipoDocumentoValido` ✅; `go vet` sin errores ✅
- [ ] T021 [P] Ejecutar tests Angular: `ng test --watch=false` en `loopi-web-v2/` — requiere entorno con Chrome
- [ ] T022 Ejecutar smoke test de creación: crear empleado con `tipo_documento:"CE"` y `tienda_id` válido via curl → verificar 201 con `contrasena_temporal` (requiere BD migrada)
- [ ] T023 Ejecutar smoke test de validación backend: enviar `tipo_documento:"TI"` via curl → verificar 422 `tipo_documento_invalido` (requiere BD migrada)

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
