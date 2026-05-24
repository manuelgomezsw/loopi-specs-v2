# Research: 006-proveedores-catalogo

**Generado**: 2026-05-24
**Feature**: Proveedores del Catálogo

---

## Decisiones Técnicas

### RD-01: Estrategia de caché para el catálogo de proveedores

**Decisión**: No aplicar caché Ristretto para el catálogo de proveedores.

**Rationale**: La constitución especifica Ristretto para "datos de catálogo de lectura
intensiva y baja volatilidad: items, unidades de medida, parámetros globales del
algoritmo". Los proveedores no cumplen ambas condiciones:

- **Intensidad de lectura**: Los proveedores se consultan principalmente al crear o editar
  un pedido, no en cada transacción operacional. La frecuencia es baja comparada con
  items o unidades de medida.
- **Volatilidad**: La spec indica que los datos de contacto "cambian con frecuencia". Un
  caché con TTL corto ofrecería muy poco beneficio neto y añadiría complejidad de
  invalidación.

Con un catálogo de decenas (máximo cientos) de proveedores, las queries directas a MySQL
con índice sobre `activo` y `razon_social` responderán en < 5 ms — suficiente para el
criterio de "< 2 minutos por operación" de los Criterios de Éxito.

**Alternativas descartadas**:

- Caché con TTL 1 min: Muy corto para justificar la complejidad de invalidación;
  proveedores no son datos de alta frecuencia de lectura. Descartado.
- Caché con TTL 5 min (igual que unidades de medida): La alta volatilidad de datos de
  contacto haría que el caché quedara desactualizado frecuentemente. Descartado.

---

### RD-02: Búsqueda full-text vs LIKE en el listado de proveedores

**Decisión**: Usar `LIKE '%?%'` con índice funcional en `razon_social` para la búsqueda
de texto libre. Búsqueda insensible a mayúsculas/minúsculas aprovechando el collation
`utf8mb4_unicode_ci` de la tabla.

**Implementación**:

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

**Flujo de inactivación**:

```text
Admin hace clic en "Inactivar proveedor X"
  → Frontend muestra modal de confirmación (acción destructiva según constitución §Feedback)
  → Admin confirma
  → Frontend llama PATCH /api/v1/proveedores/{id}/inactivar
  → Backend valida: proveedor existe y está activo
  → Backend setea activo = 0, actualiza actualizado_en
  → Respuesta 200 con { id, activo: false, mensaje }
```

**Flujo de reactivación** (HU-3 Escenario 4):

```text
Admin hace clic en "Reactivar proveedor X"
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
`loopi-web/src/app/features/proveedores/` con tres componentes standalone:
`ListaProveedoresComponent`, `FormProveedorComponent` (crear + editar),
`DetalleProveedorComponent`.

**Estructura**:

```text
loopi-web/src/app/features/proveedores/
├── components/
│   ├── lista-proveedores/
│   │   ├── lista-proveedores.component.ts
│   │   ├── lista-proveedores.component.html
│   │   └── lista-proveedores.component.spec.ts
│   ├── form-proveedor/
│   │   ├── form-proveedor.component.ts   # Crear + editar (modo controlado por @Input)
│   │   ├── form-proveedor.component.html
│   │   └── form-proveedor.component.spec.ts
│   └── detalle-proveedor/
│       ├── detalle-proveedor.component.ts
│       ├── detalle-proveedor.component.html
│       └── detalle-proveedor.component.spec.ts
├── models/
│   └── proveedor.model.ts
├── services/
│   └── proveedores.service.ts
└── proveedores.routes.ts
```

**Rationale**: Componentes standalone (Angular actual) con lazy loading desde el router.
`FormProveedorComponent` unifica crear y editar en un solo componente con modo `'crear'`
o `'editar'` vía `@Input()`, evitando duplicar la validación del formulario. Patrón
consistente con otras features del proyecto.

**Alternativas descartadas**:

- Componentes separados para crear y editar: Duplica la lógica del formulario reactivo
  y las validaciones. Descartado.
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
