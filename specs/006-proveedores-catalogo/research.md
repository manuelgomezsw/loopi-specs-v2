# Research: 006-proveedores-catalogo

**Generado**: 2026-05-24
**Feature**: Proveedores del Catálogo

---

## Decisiones Técnicas

### RD-01: Estrategia de caché para el catálogo de proveedores

**Decisión**: Aplicar caché Ristretto con patrón decorador, TTL 24 h, siguiendo la tabla
normativa de la constitución (§Caché Transversal — Ristretto, v1.10.0), que lista
explícitamente "Proveedores | Feature 006 | 24 h" como entidad de caché obligatoria sin
excepción por volatilidad.

**Implementación**:

- `internal/proveedores/cached_repository.go` implementa la interfaz `Repository` y
  envuelve `repository.go` (que no se modifica). Constructor:
  `NewCachedRepository(inner Repository, ttl time.Duration) Repository`.
- Usa el paquete compartido `internal/cache/` (`EntityCache[T]`, `ReadThrough[T]`), ya
  existente en `develop` desde 004/005.
- Claves: `"list"` (listado sin filtros), `"id:<id>"` (por ID), `"activo:<valor>"`
  (filtro por estado).
- Invalidación: **Crear** → `cache.Clear()`; **Editar / Inactivar / Activar** →
  `cache.Delete("id:<id>")` + `cache.Clear()`.
- `cached_repository_test.go` obligatorio, cobertura ≥ 90%: hit de caché (inner no se
  invoca), miss de caché (inner se invoca y el resultado se almacena), escritura invalida
  la caché, error del inner no almacena nada.

**Rationale**: La constitución uniforma el TTL de 24 h para toda entidad de catálogo,
independientemente de su volatilidad relativa; el tradeoff de datos potencialmente
desactualizados hasta por 24 h en instancias múltiples de App Engine se acepta a nivel de
proyecto para todo el catálogo (incluyendo proveedores). Con un catálogo de decenas
(máximo cientos) de registros, el impacto de servir datos de contacto con hasta 24 h de
desfase es operacionalmente aceptable: los pedidos y asignaciones a items usan
`proveedor.id` como referencia estable, no los datos de contacto en sí.

**Alternativas descartadas**:

- No cachear por volatilidad de datos de contacto: Era la decisión original de este
  documento, pero contradice la tabla normativa de la constitución que exige caché
  uniforme de 24 h para todas las entidades de catálogo (002 a 008), sin excepción
  documentada para proveedores. Descartado tras la enmienda constitucional v1.10.0.
- Caché con TTL 1 min o 5 min: Contradice el TTL normativo único de 24 h; introduciría
  inconsistencia con el resto del catálogo. Descartado.

---

### RD-02: Búsqueda full-text vs LIKE en el listado de proveedores

**Decisión**: Usar `LIKE '%?%'` con índice funcional en `razon_social` para la búsqueda
de texto libre. Búsqueda insensible a mayúsculas/minúsculas aprovechando el collation
`utf8mb4_unicode_ci` de la tabla.

**Implementación**:

El handler parsea `?estado=activo|inactivo|todos` (400 `estado_invalido` si el valor no
es uno de los tres) y lo traduce a `*bool` para el repositorio: `activo` → `true`,
`inactivo` → `false`, `todos` → `nil`. La query SQL y el repositorio siguen trabajando
con `*bool` internamente; solo cambia el contrato HTTP externo.

```go
// internal/proveedores/repository.go

func (r *Repository) Listar(ctx context.Context, filtros FiltrosListado) ([]Proveedor, int, error) {
    query := `
        SELECT id, razon_social, nit, nombre_contacto, telefono_contacto,
               email_contacto, activo, creado_en, actualizado_en
        FROM proveedores
        WHERE 1=1`
    args := []any{}

    if filtros.Activo != nil {
        query += ` AND activo = ?`
        args = append(args, *filtros.Activo)
    }
    if filtros.Busqueda != "" {
        query += ` AND (razon_social LIKE ? OR nit LIKE ?)`
        patron := "%" + filtros.Busqueda + "%"
        args = append(args, patron, patron)
    }
    query += ` ORDER BY razon_social ASC LIMIT ? OFFSET ?`
    args = append(args, filtros.Limit, (filtros.Page-1)*filtros.Limit)
    // ... ejecutar query
}
```

**Rationale**: Con un catálogo de decenas a bajos cientos de proveedores, `LIKE` con
índice sobre `razon_social` (prefijo) y sobre el campo completo como fallback es
suficientemente performante. MySQL full-text search requiere configuración adicional y
mínimo de palabras, lo que no aplica bien para búsqueda de códigos NIT. `LIKE '%?%'`
permite buscar subcadenas en NIT también (ej. el admin recuerda solo parte del NIT).

**Alternativas descartadas**:

- MySQL FULLTEXT index: Requiere parser de lenguaje natural, mínimo de palabras (default
  4 chars en InnoDB), no compatible con búsqueda por NIT parcial. Overkill para este
  volumen. Descartado.
- Búsqueda en frontend (filtrar array en memoria): Viola la constitución (paginación
  siempre en el servidor). Descartado.

---

### RD-03: Patrón de inactivación / reactivación

**Decisión**: Dos endpoints PATCH separados: `PATCH /api/v1/proveedores/{id}/inactivar`
y `PATCH /api/v1/proveedores/{id}/activar`. Sin confirmación de impacto previa (a
diferencia de unidades de medida, donde la inactivación bloquea transacciones de items).

**Flujo de inactivación** (patrón Lista-Formulario; sin vista de detalle separada):

```text
Admin abre form-proveedor en modo 'editar' (navega desde una fila de lista-proveedores)
  → En la sección "Zona de precaución" al pie del formulario, hace clic en "Inactivar proveedor"
  → Frontend muestra modal de confirmación (acción destructiva según constitución §Feedback)
  → Admin confirma
  → Frontend llama PATCH /api/v1/proveedores/{id}/inactivar
  → Backend valida: proveedor existe y está activo
  → Backend setea activo = 0, actualiza actualizado_en
  → Respuesta 200 con { id, activo: false, mensaje }
```

**Flujo de reactivación** (HU-3 Escenario 4; misma vista form-proveedor en modo 'editar'):

```text
Admin hace clic en "Reactivar proveedor" en la Zona de precaución del formulario
  → Frontend llama PATCH /api/v1/proveedores/{id}/activar
  → Backend setea activo = 1, actualiza actualizado_en
  → Respuesta 200 con { id, activo: true, mensaje }
```

**Rationale**: La inactivación de un proveedor NO bloquea inmediatamente ningún item
ni transacción existente (los items conservan la referencia histórica según RF-PROV-03.3).
Solo impide nuevos pedidos. No se necesita un endpoint `/impacto` previo porque:

1. El impacto es informativo, no bloqueante para el admin.
2. La constitución exige modal de confirmación para acciones destructivas irreversibles;
   la inactivación SÍ es reversible (RF-PROV-03.5), así que un modal simple de
   confirmación ("¿Inactivar este proveedor?") es suficiente.

**Alternativas descartadas**:

- Endpoint único `/toggle` que alterne el estado: Semántica ambigua; dificulta el control
  desde el frontend y los tests. Descartado.
- Endpoint `/impacto` previo a inactivación (similar a unidades de medida): El impacto no
  es bloqueante ni cuantificable en esta fase (los pedidos futuros son indefinidos).
  El modal simple de confirmación es suficiente. Descartado.
- `DELETE` lógico vía `PUT` con `activo: false`: Mezcla la semántica de edición de datos
  con el ciclo de vida. Los endpoints de acción explícitos (`/inactivar`, `/activar`) son
  más autodescriptivos. Descartado.

---

### RD-04: Estructura de módulo en el backend Go

**Decisión**: Módulo en `internal/proveedores/` con cuatro archivos: `model.go`,
`repository.go`, `service.go`, `handler.go`. Sin sub-paquetes.

**Estructura**:

```text
loopi-api/internal/proveedores/
├── model.go        # Tipos de dominio: Proveedor, FiltrosListado, requests/responses
├── repository.go   # Queries SQL directas a MySQL
├── service.go      # Lógica de negocio + validaciones de dominio
└── handler.go      # HTTP handlers (registro de rutas, parsing, respuestas)
```

**Rationale**: Patrón consistente con los demás módulos del proyecto (001-autenticacion,
004-unidades-medida). La feature es un CRUD simple sin lógica algorítmica compleja que
justifique sub-paquetes. Un paquete único facilita navegar el código de la feature
sin saltar entre muchos directorios.

**Alternativas descartadas**:

- Paquete separado por capa (models/, repositories/, services/): Rompe la cohesión por
  feature y complica el contexto de carga para tareas feature-específicas según la
  constitución. Descartado.
- Handlers inline en `main.go`: No escala con múltiples features. Descartado.

---

### RD-05: Ubicación y estructura del módulo Angular

**Decisión**: Feature module lazy-loaded en
`loopi-web/src/app/features/proveedores/` con dos componentes standalone:
`ListaProveedoresComponent` y `FormProveedorComponent` (crear + editar), siguiendo el
patrón Lista-Formulario normativo (constitución §Patrón Lista–Formulario, v1.4.1) — sin
componente de detalle separado.

**Estructura**:

```text
loopi-web/src/app/features/proveedores/
├── components/
│   ├── lista-proveedores/
│   │   ├── lista-proveedores.component.ts   # Usa ListCardComponent, FilterBarComponent
│   │   │                                    # (default Estado=Activo), DataTableComponent,
│   │   │                                    # StatusBadgeComponent, EmptyStateComponent,
│   │   │                                    # PaginationComponent, PageHeaderComponent
│   │   ├── lista-proveedores.component.html
│   │   └── lista-proveedores.component.spec.ts
│   └── form-proveedor/
│       ├── form-proveedor.component.ts   # Crear + editar (modo controlado por @Input /
│       │                                 # FormModeService); modo editar incluye
│       │                                 # items_asignados (ReadonlyFieldComponent) y
│       │                                 # DangerZoneComponent (inactivar/reactivar)
│       ├── form-proveedor.component.html # Usa FormCardComponent
│       └── form-proveedor.component.spec.ts
├── models/
│   └── proveedor.model.ts
├── services/
│   └── proveedores.service.ts
└── proveedores.routes.ts
```

**Componentes Angular transversales usados** (catálogo normativo, spec 000-design-system;
prohibido reimplementar): `ListCardComponent`, `FilterBarComponent`, `StatusBadgeComponent`,
`DataTableComponent`, `EmptyStateComponent`, `PaginationComponent`, `PageHeaderComponent`,
`FormCardComponent`, `ReadonlyFieldComponent`, `DangerZoneComponent`, `FilterStateService`,
`FormModeService`.

**Rationale**: Componentes standalone (Angular actual) con lazy loading desde el router.
`FormProveedorComponent` unifica crear y editar en un solo componente con modo `'crear'`
o `'editar'` vía `@Input()`/`FormModeService`, evitando duplicar la validación del
formulario. La información de `items_asignados` y las acciones de ciclo de vida
(inactivar/reactivar) viven dentro del formulario de edición — no en una vista de detalle
separada — para cumplir el patrón Lista-Formulario y reutilizar `DangerZoneComponent`.
Patrón consistente con `004-unidades-medida` (2 componentes: lista + form).

**Alternativas descartadas**:

- Componentes separados para crear y editar: Duplica la lógica del formulario reactivo
  y las validaciones. Descartado.
- Componente `DetalleProveedorComponent` separado (decisión original de este documento):
  Introduce un tercer nivel de navegación (lista → detalle → formulario) que contradice
  el patrón Lista-Formulario normativo, donde la fila de la lista navega directamente al
  formulario de edición y este contiene todas las acciones posibles sobre el registro.
  Descartado.
- NgModule clásico: La constitución usa componentes standalone (Angular actual). Descartado.

---

## Dependencias Externas Confirmadas

| Paquete | Uso | Estado |
|---------|-----|--------|
| `go-sql-driver/mysql` | Driver MySQL | Ya en proyecto (desde 001) |
| `golang-migrate/migrate` | Migraciones BD | Ya en proyecto (desde 001) |
| JWT library | Extracción de claims (middleware RBAC) | Ya en proyecto (desde 001) |
| Angular (última estable) | Frontend SPA | Ya en proyecto |
| Tailwind CSS v4 | Estilos UI | Ya en proyecto |
