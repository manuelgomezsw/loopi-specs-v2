# Modelo de Datos: Gestión de Tiendas

**Feature**: `002-gestion-tiendas` | **Fecha**: 2026-05-23

## Tabla: `tiendas`

```sql
CREATE TABLE tiendas (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo          VARCHAR(20)     NOT NULL,
  nombre          VARCHAR(150)    NOT NULL,
  direccion       VARCHAR(255)    NOT NULL,
  ciudad          VARCHAR(100)    NOT NULL,
  telefono        VARCHAR(20)     NOT NULL,
  activo          TINYINT(1)      NOT NULL DEFAULT 1,
  creado_por      BIGINT UNSIGNED NOT NULL,
  creado_en       DATETIME        NOT NULL,
  actualizado_por BIGINT UNSIGNED NOT NULL,
  actualizado_en  DATETIME        NOT NULL,

  PRIMARY KEY (id),

  CONSTRAINT uq_tiendas_codigo  UNIQUE KEY (codigo),
  CONSTRAINT uq_tiendas_nombre  UNIQUE KEY (nombre),

  CONSTRAINT fk_tiendas_creado_por
    FOREIGN KEY (creado_por) REFERENCES usuarios (id),
  CONSTRAINT fk_tiendas_actualizado_por
    FOREIGN KEY (actualizado_por) REFERENCES usuarios (id),

  INDEX idx_tiendas_activo (activo)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
```

## Descripción de Campos

| Campo | Tipo | Nullable | Default | Descripción |
|-------|------|----------|---------|-------------|
| `id` | `BIGINT UNSIGNED` | NO | AUTO_INCREMENT | PK interna. No exponer en URLs directas si se usa `codigo` como clave POS. |
| `codigo` | `VARCHAR(20)` | NO | — | Código corto alfanumérico en mayúsculas (ej. `TDA-001`). Inmutable tras creación. Clave de integración con `012-ventas-integracion-pos`. |
| `nombre` | `VARCHAR(150)` | NO | — | Nombre legible del punto de venta. Único con collation `utf8mb4_unicode_ci` → comparación case-insensitive garantizada por la BD. |
| `direccion` | `VARCHAR(255)` | NO | — | Dirección física del local. |
| `ciudad` | `VARCHAR(100)` | NO | — | Ciudad del local. |
| `telefono` | `VARCHAR(20)` | NO | — | Teléfono de contacto. Almacenado como texto (incluye prefijos, extensiones). |
| `activo` | `TINYINT(1)` | NO | `1` | `1` = tienda activa, `0` = tienda inactiva. No existe estado `eliminado`. |
| `creado_por` | `BIGINT UNSIGNED` | NO | — | FK → `usuarios.id` del admin que creó la tienda. |
| `creado_en` | `DATETIME` | NO | — | Timestamp de creación en zona horaria `America/Bogota`. |
| `actualizado_por` | `BIGINT UNSIGNED` | NO | — | FK → `usuarios.id` del admin que realizó la última modificación. |
| `actualizado_en` | `DATETIME` | NO | — | Timestamp de última modificación en zona horaria `America/Bogota`. |

## Índices y Restricciones

| Nombre | Tipo | Columnas | Propósito |
|--------|------|----------|-----------|
| `PRIMARY` | PK | `id` | Clave primaria |
| `uq_tiendas_codigo` | UNIQUE | `codigo` | Garantiza unicidad del código POS |
| `uq_tiendas_nombre` | UNIQUE | `nombre` | Unicidad case-insensitive (hereda collation de tabla `utf8mb4_unicode_ci`) |
| `idx_tiendas_activo` | INDEX | `activo` | Acelera el filtrado `WHERE activo = 1/0` |
| `fk_tiendas_creado_por` | FK | `creado_por → usuarios.id` | Integridad referencial de auditoría |
| `fk_tiendas_actualizado_por` | FK | `actualizado_por → usuarios.id` | Integridad referencial de auditoría |

## Transiciones de Estado

```
Estado inicial: activo = 1  (al crear)

     activo = 1                     activo = 0
   ┌──────────┐   [inactivar]   ┌─────────────┐
   │  ACTIVA  │ ──────────────► │  INACTIVA   │
   │          │ ◄────────────── │             │
   └──────────┘   [reactivar]   └─────────────┘
```

**Reglas de transición:**

- `ACTIVA → INACTIVA`: `POST /api/v1/tiendas/{id}/inactivar`. Solo si `activo = 1`
  (retorna 422 si ya está inactiva).
- `INACTIVA → ACTIVA`: `POST /api/v1/tiendas/{id}/reactivar`. Solo si `activo = 0`
  (retorna 422 si ya está activa). El frontend muestra diálogo de confirmación.
- No existe transición a estado eliminado. No hay `DELETE` físico.

## Relaciones con Otras Tablas

```
usuarios (001-autenticacion)
  └── tiendas.creado_por     → usuarios.id  [FK, RESTRICT]
  └── tiendas.actualizado_por → usuarios.id [FK, RESTRICT]

tiendas (esta feature)
  └── ... es referenciada por futuras features:
       003-gestion-empleados  → usuarios.tienda_id
       009-inventario-conteo  → conteos.tienda_id
       010-mermas             → mermas.tienda_id
       011-caja-menor         → compras.tienda_id
       013-pedidos-oc         → pedidos.tienda_id
       012-ventas-pos         → ventas.tienda_id (vía campo codigo)
```

## Migración

**Archivo**: `loopi-api-v2/migrations/002_tiendas.up.sql`

```sql
-- Migración 002: Crear tabla tiendas
-- Dependencia: migración 001 (tabla usuarios) debe estar aplicada

SET time_zone = 'America/Bogota';

CREATE TABLE IF NOT EXISTS tiendas (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo          VARCHAR(20)     NOT NULL,
  nombre          VARCHAR(150)    NOT NULL,
  direccion       VARCHAR(255)    NOT NULL,
  ciudad          VARCHAR(100)    NOT NULL,
  telefono        VARCHAR(20)     NOT NULL,
  activo          TINYINT(1)      NOT NULL DEFAULT 1,
  creado_por      BIGINT UNSIGNED NOT NULL,
  creado_en       DATETIME        NOT NULL,
  actualizado_por BIGINT UNSIGNED NOT NULL,
  actualizado_en  DATETIME        NOT NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_tiendas_codigo  (codigo),
  UNIQUE KEY uq_tiendas_nombre  (nombre),
  INDEX       idx_tiendas_activo (activo),

  CONSTRAINT fk_tiendas_creado_por
    FOREIGN KEY (creado_por)      REFERENCES usuarios (id),
  CONSTRAINT fk_tiendas_actualizado_por
    FOREIGN KEY (actualizado_por) REFERENCES usuarios (id)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
```

**Archivo**: `loopi-api-v2/migrations/002_tiendas.down.sql`

```sql
-- Rollback migración 002: Eliminar tabla tiendas
DROP TABLE IF EXISTS tiendas;
```

## Struct Go (model.go)

```go
// Tienda representa un punto de venta físico.
type Tienda struct {
    ID             uint64    `db:"id"`
    Codigo         string    `db:"codigo"`
    Nombre         string    `db:"nombre"`
    Direccion      string    `db:"direccion"`
    Ciudad         string    `db:"ciudad"`
    Telefono       string    `db:"telefono"`
    Activo         bool      `db:"activo"`
    CreadoPor      uint64    `db:"creado_por"`
    CreadoEn       time.Time `db:"creado_en"`
    ActualizadoPor uint64    `db:"actualizado_por"`
    ActualizadoEn  time.Time `db:"actualizado_en"`
}

// TiendaRequest es el body de creación.
type TiendaRequest struct {
    Codigo    string `json:"codigo"    validate:"required,max=20,uppercase"`
    Nombre    string `json:"nombre"    validate:"required,max=150"`
    Direccion string `json:"direccion" validate:"required,max=255"`
    Ciudad    string `json:"ciudad"    validate:"required,max=100"`
    Telefono  string `json:"telefono"  validate:"required,max=20"`
}

// TiendaUpdateRequest es el body de edición (sin codigo).
type TiendaUpdateRequest struct {
    Nombre    string `json:"nombre"    validate:"required,max=150"`
    Direccion string `json:"direccion" validate:"required,max=255"`
    Ciudad    string `json:"ciudad"    validate:"required,max=100"`
    Telefono  string `json:"telefono"  validate:"required,max=20"`
}

// TiendaResponse es la representación pública de la entidad.
type TiendaResponse struct {
    ID             uint64    `json:"id"`
    Codigo         string    `json:"codigo"`
    Nombre         string    `json:"nombre"`
    Direccion      string    `json:"direccion"`
    Ciudad         string    `json:"ciudad"`
    Telefono       string    `json:"telefono"`
    Activo         bool      `json:"activo"`
    CreadoPor      uint64    `json:"creado_por"`
    CreadoEn       time.Time `json:"creado_en"`
    ActualizadoPor uint64    `json:"actualizado_por"`
    ActualizadoEn  time.Time `json:"actualizado_en"`
}

// ListaTiendasResponse es la respuesta paginada del listado.
type ListaTiendasResponse struct {
    Datos   []TiendaResponse `json:"datos"`
    Total   int              `json:"total"`
    Pagina  int              `json:"pagina"`
    Limite  int              `json:"limite"`
}
```
