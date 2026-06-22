# Plan de Implementación: 003-gestion-empleados — Selects Tienda y Tipo de Documento

**Branch**: `018-selects-tienda-tipo-doc` | **Fecha**: 2026-06-21 | **Spec**: [spec.md](./spec.md)

**Alcance**: Actualización incremental de la feature 003 ya implementada. Los formularios de
creación y edición de empleado reemplazan los campos `Tienda` y `Tipo de documento` (actualmente
cuadros de texto) por listas desplegables (`<select>`). El campo `Tienda` carga las tiendas
activas desde el backend. El campo `Tipo de documento` usa un conjunto cerrado de valores:
CC, CE, NUIP, PE.

---

## Summary

Los formularios de alta y edición de empleados presentan los campos `Tienda` y `Tipo de documento`
como entradas de texto libre, lo que permite datos inválidos (tiendas inexistentes, códigos de
documento no reconocidos). Esta actualización los convierte en `<select>` controlados:

- **Tienda**: lista desplegable poblada desde `GET /api/v1/tiendas?activo=true` al abrir el
  formulario. Solo muestra tiendas activas. Estado vacío si no hay ninguna.
- **Tipo de documento**: lista desplegable con valores fijos CC, CE, NUIP, PE. Campo opcional.

El backend requiere una migración para cambiar `tipo_documento` de `VARCHAR(30)` a
`ENUM('CC','CE','NUIP','PE')` y agregar validación del valor en los handlers de crear y editar.

---

## Technical Context

**Language/Version**: Go 1.21+ (backend) · TypeScript / Angular latest stable (frontend)

**Primary Dependencies**: Tailwind CSS v4, Angular Reactive Forms, go-sql-driver/mysql, golang-migrate

**Storage**: MySQL (GCP Cloud SQL) — migración requerida en tabla `empleados`

**Testing**: Go: `httptest` + `go-sqlmock` | Angular: `ng test` (Jasmine/Karma)

**Target Platform**: GCP App Engine (backend) · Firebase Hosting (frontend)

**Project Type**: Full-stack web application — actualización incremental de feature existente

**Performance Goals**: Formulario listo (incluyendo carga de tiendas) en < 300 ms en red local

**Constraints**: Retrocompatibilidad — datos existentes en `tipo_documento` deben migrarse limpiamente

**Scale/Scope**: Cambio mínimo: 2 campos en 2 formularios + 1 migración BD + validación backend

---

## Constitution Check

| Principio | Estado | Notas |
|-----------|--------|-------|
| §I Spec-First | ✅ | Spec 003 actualizada en branch 018 antes de este plan |
| §II Multi-tienda | ✅ | Select de tiendas filtra solo activas; el empleado sigue con FK simple a una tienda |
| §III RBAC | ✅ | Sin cambio en permisos; solo `admin` puede crear/editar empleados |
| §IV Trazabilidad | ✅ | Audit log existente ya registra `tipo_documento` en campo `detalle`; sin cambio requerido |
| §V Prevención pérdidas | ✅ | No aplica directamente a esta feature |
| §VI Monitoreo | ✅ | Sin nuevos endpoints críticos; se reutiliza el de tiendas |
| §Diseño de Interfaz | ✅ | `<select>` debe tener `bg-white border-gray-300` igual que `<input>` (ver §Superficie de Formulario) |
| §Arquitectura capas | ✅ | Validación `tipo_documento` va en service; cambio ENUM en repositorio |
| §Convenciones API | ✅ | Sin nuevos endpoints; se reutiliza `GET /api/v1/tiendas` de feature 002 |

**Resultado**: Sin violaciones. No se requiere registro de complejidad.

---

## Project Structure

### Documentación (esta feature)

```text
specs/003-gestion-empleados/
├── plan.md              ← este archivo
├── research.md          ← existente + RD-08 y RD-09 (nuevas decisiones)
├── data-model.md        ← actualizado: tipo_documento como ENUM + migración nueva
├── quickstart.md        ← actualizado: pasos de migración incremental
├── contracts/
│   └── api.md           ← actualizado: validación tipo_documento + error nuevo
└── tasks.md             ← pendiente (/speckit-tasks)
```

### Código fuente afectado

```text
loopi-api/
└── internal/
    └── empleados/
        ├── handler.go       # Sin cambios en rutas; validación tipo_documento delgada (parseo)
        ├── service.go       # Validación enum tipo_documento (ErrTipoDocumentoInvalido)
        └── repository.go    # Migración afecta el tipo de columna; sin cambio en queries
    └── db/migrations/
        └── NNNN_alter_empleados_tipo_documento_enum.up.sql    # VARCHAR(30) → ENUM
        └── NNNN_alter_empleados_tipo_documento_enum.down.sql  # ENUM → VARCHAR(30)

loopi-web/
└── src/app/
    └── features/
        └── empleados/
            ├── crear-empleado/
            │   ├── crear-empleado.component.html  # tipo_documento: text → select; tienda: text → select
            │   ├── crear-empleado.component.ts    # cargar tiendas activas al init; lista tipos_documento
            │   └── crear-empleado.component.spec.ts
            └── editar-empleado/
                ├── editar-empleado.component.html  # ídem crear; preselección valores actuales
                ├── editar-empleado.component.ts    # cargar tiendas + preseleccionar
                └── editar-empleado.component.spec.ts
        └── shared/services/
            └── tiendas.service.ts  # método getTiendasActivas() si no existe ya
```

---

## Phase 0: Research

### RD-08: Migración VARCHAR → ENUM para `tipo_documento`

**Decisión**: Migración en dos pasos dentro de un único script `.up.sql`:

1. Nullificar los valores que no sean válidos en el nuevo ENUM (CC, CE, NUIP, PE):

   ```sql
   UPDATE empleados
   SET tipo_documento = NULL
   WHERE tipo_documento IS NOT NULL
     AND tipo_documento NOT IN ('CC','CE','NUIP','PE');
   ```

2. Alterar la columna:

   ```sql
   ALTER TABLE empleados
     MODIFY COLUMN tipo_documento ENUM('CC','CE','NUIP','PE') NULL;
   ```

**Rationale**: MySQL no permite ALTER a ENUM si existen valores no contemplados en la definición.
El UPDATE previo limpia datos legacy (TI, PP, RC) que pudieran haberse ingresado por texto libre
antes de este cambio. Nullificar es más seguro que rechazar la migración en producción.

**Script down**:

```sql
ALTER TABLE empleados
  MODIFY COLUMN tipo_documento VARCHAR(30) NULL;
```

El down no restaura los valores perdidos (ya eran datos inválidos), pero la columna queda
operativa. Esto es aceptable — la migración es prácticamente irreversible en datos.

**Alternativas descartadas**:

- `TINYINT` con tabla lookup: innecesariamente complejo para un conjunto de 4 valores fijos.
- `VARCHAR` + constraint CHECK: MySQL 5.7 no soporta CHECK constraints funcionales. Descartado.
- `VARCHAR` + validación solo en aplicación: deja la BD sin constraint nativo. Descartado.

---

### RD-09: Fuente de datos para el select de tiendas

**Decisión**: Reutilizar `GET /api/v1/tiendas?activo=true` (feature 002-gestion-tiendas).
El frontend llama este endpoint al inicializar el formulario (en `ngOnInit`).

**Contrato esperado de la respuesta** (ya documentado en 002):

```json
{
  "tiendas": [
    { "id": 1, "nombre": "Tienda Centro" },
    { "id": 2, "nombre": "Tienda Norte" }
  ]
}
```

El `<select>` muestra `nombre` como etiqueta y usa `id` como valor del control.

**Estado vacío**: Si `tiendas` retorna `[]`, el `<select>` se renderiza deshabilitado con la
opción placeholder `"No hay tiendas activas disponibles"`. El botón de guardar permanece
habilitado para roles `admin` que no requieren tienda.

**Manejo de error de carga**: Si el GET falla (4xx/5xx/timeout), mostrar toast de error y
mantener el campo en estado de error con texto: `"No se pudieron cargar las tiendas. Intenta
de nuevo."`. El campo queda deshabilitado hasta que se recargue exitosamente.

**Rationale**: No se crea un endpoint nuevo. El endpoint de tiendas ya existe, está autenticado
por JWT y devuelve solo las tiendas activas al pasar `activo=true`.

**Alternativas descartadas**:

- Hardcodear nombres de tiendas: no escala, requiere redeploy ante cambios. Descartado.
- Nuevo endpoint `/api/v1/tiendas/activas`: redundante con el endpoint genérico filtrable. Descartado.

---

## Phase 1: Design & Contracts

### 1.1 Actualización del modelo de datos

Ver [data-model.md](./data-model.md) — sección `Migraciones` actualizada con migración incremental
`NNNN_alter_empleados_tipo_documento_enum`.

### 1.2 Actualización de contratos de API

Ver [contracts/api.md](./contracts/api.md) — secciones "Crear empleado" y "Editar empleado"
actualizadas con:

- Validación del enum `tipo_documento` (valores permitidos: CC, CE, NUIP, PE).
- Nuevo error `422 tipo_documento_invalido`.

### 1.3 Diseño del formulario Angular

**Select `tipo_documento`** (estático — sin llamada API):

```typescript
// En el componente TypeScript
readonly tiposDocumento = [
  { codigo: 'CC',   etiqueta: 'CC — Cédula de Ciudadanía' },
  { codigo: 'CE',   etiqueta: 'CE — Cédula de Extranjería' },
  { codigo: 'NUIP', etiqueta: 'NUIP — Número Único de Identificación Personal' },
  { codigo: 'PE',   etiqueta: 'PE — Permiso Especial de Permanencia' },
];
```

```html
<!-- En el template HTML -->
<label for="tipoDocumento">Tipo de documento</label>
<select id="tipoDocumento" formControlName="tipo_documento"
        class="bg-white w-full border border-gray-300 rounded-lg px-3 py-2
               focus:outline-none focus:ring-2 focus:ring-blue-500">
  <option value="">— Seleccionar (opcional) —</option>
  @for (tipo of tiposDocumento; track tipo.codigo) {
    <option [value]="tipo.codigo">{{ tipo.etiqueta }}</option>
  }
</select>
```

**Select `tienda_id`** (dinámico — cargado desde API):

```typescript
// En el componente TypeScript
tiendasActivas: { id: number; nombre: string }[] = [];
cargandoTiendas = false;
errorCargaTiendas = false;

ngOnInit(): void {
  this.cargarTiendasActivas();
}

private cargarTiendasActivas(): void {
  this.cargandoTiendas = true;
  this.tiendasService.getTiendasActivas().subscribe({
    next: (tiendas) => {
      this.tiendasActivas = tiendas;
      this.cargandoTiendas = false;
    },
    error: () => {
      this.errorCargaTiendas = true;
      this.cargandoTiendas = false;
    }
  });
}
```

```html
<!-- En el template HTML -->
<label for="tienda">Tienda *</label>
@if (cargandoTiendas) {
  <div class="animate-pulse h-10 bg-gray-100 rounded-lg"></div>
} @else {
  <select id="tienda" formControlName="tienda_id"
          [disabled]="errorCargaTiendas"
          class="bg-white w-full border border-gray-300 rounded-lg px-3 py-2
                 focus:outline-none focus:ring-2 focus:ring-blue-500
                 disabled:bg-gray-100 disabled:text-gray-400">
    <option value="">— Seleccionar tienda —</option>
    @if (tiendasActivas.length === 0 && !errorCargaTiendas) {
      <option disabled>No hay tiendas activas disponibles</option>
    }
    @for (tienda of tiendasActivas; track tienda.id) {
      <option [value]="tienda.id">{{ tienda.nombre }}</option>
    }
  </select>
  @if (errorCargaTiendas) {
    <p class="text-red-600 text-sm mt-1">
      No se pudieron cargar las tiendas. Intenta de nuevo.
    </p>
  }
}
```

**Preselección en edición**: Al cargar el formulario de edición, esperar a que `tiendasActivas`
esté poblado antes de patchear `tienda_id` y `tipo_documento` con los valores actuales del
empleado. Usar `forkJoin` o encadenar el `patchValue` en el callback de carga de tiendas.

### 1.4 Validación backend

En `service.go`, agregar antes de crear o editar:

```go
var tiposDocumentoValidos = map[string]bool{
    "CC": true, "CE": true, "NUIP": true, "PE": true,
}

if req.TipoDocumento != "" && !tiposDocumentoValidos[req.TipoDocumento] {
    return nil, ErrTipoDocumentoInvalido
}
```

Error de dominio nuevo: `ErrTipoDocumentoInvalido` → HTTP 422, `tipo_documento_invalido`.

---

## Complexity Tracking

> Sin violaciones de constitución detectadas. Tabla omitida.
