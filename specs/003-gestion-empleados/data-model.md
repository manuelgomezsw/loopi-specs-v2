# Modelo de Datos: 003-gestion-empleados

**Generado**: 2026-05-24

---

## Entidades

### Tabla `empleados`

Almacena el directorio de empleados del sistema. Un empleado inactivo conserva todos sus datos.
No existe eliminación física (sin `DELETE`).

```sql
CREATE TABLE empleados (
  id                         BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  nombre                     VARCHAR(100)     NOT NULL,
  apellido                   VARCHAR(100)     NOT NULL,
  usuario                    VARCHAR(50)      NOT NULL          COMMENT 'Único en el sistema; inmutable tras creación',
  contrasena_hash            VARCHAR(72)      NOT NULL          COMMENT 'bcrypt hash (cost 12); max 72 bytes útiles para bcrypt',
  rol                        ENUM(
                               'admin',
                               'lider_tienda',
                               'barista'
                             )                NOT NULL,
  tienda_id                  BIGINT UNSIGNED  NULL              COMMENT 'NULL solo para rol=admin',
  tipo_documento             VARCHAR(30)      NULL,
  numero_documento           VARCHAR(30)      NULL,
  telefono                   VARCHAR(20)      NULL,
  email                      VARCHAR(150)     NULL,
  fecha_nacimiento           DATE             NULL,
  activo                     TINYINT(1)       NOT NULL DEFAULT 1,
  requiere_cambio_contrasena TINYINT(1)       NOT NULL DEFAULT 1 COMMENT '1 = debe cambiar en próximo login',
  creado_en                  DATETIME         NOT NULL,
  actualizado_en             DATETIME         NOT NULL,

  PRIMARY KEY (id),
  CONSTRAINT uq_empleados_usuario UNIQUE (usuario),
  CONSTRAINT fk_empleados_tienda  FOREIGN KEY (tienda_id) REFERENCES tiendas(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Índices adicionales**:

```sql
-- Búsqueda por tienda (filtro en listado)
CREATE INDEX ix_empleados_tienda_id ON empleados (tienda_id);

-- Filtro por estado activo
CREATE INDEX ix_empleados_activo ON empleados (activo);

-- Búsqueda LIKE sobre nombre + apellido (opcional — evaluar en producción)
CREATE INDEX ix_empleados_nombre ON empleados (apellido, nombre);
```

**Reglas de integridad**:

| Regla | Validación |
|-------|------------|
| `tienda_id` requerida para `lider_tienda` y `barista` | CHECK a nivel aplicación (MySQL 5.7 no soporta CHECK funcional confiable) |
| `tienda_id` debe ser NULL para `admin` | CHECK a nivel aplicación |
| `usuario` único | Constraint `uq_empleados_usuario` |
| No DELETE físico | Enforced a nivel aplicación; solo `activo = 0` |

---

### Tabla `log_auditoria_empleados`

Registro inmutable de toda operación de escritura sobre un empleado.
Los registros NO se pueden editar ni eliminar. Sin columna `actualizado_en`.

```sql
CREATE TABLE log_auditoria_empleados (
  id           BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  actor_id     BIGINT UNSIGNED  NOT NULL  COMMENT 'Empleado admin que ejecutó la acción',
  accion       ENUM(
                 'CREAR',
                 'EDITAR',
                 'INACTIVAR',
                 'REACTIVAR',
                 'RESET_CONTRASENA'
               )                NOT NULL,
  empleado_id  BIGINT UNSIGNED  NOT NULL  COMMENT 'Empleado afectado',
  detalle      JSON             NULL      COMMENT 'Campos anteriores/nuevos según acción (ver RD-02)',
  creado_en    DATETIME         NOT NULL,

  PRIMARY KEY (id),
  CONSTRAINT fk_log_audit_actor    FOREIGN KEY (actor_id)    REFERENCES empleados(id),
  CONSTRAINT fk_log_audit_empleado FOREIGN KEY (empleado_id) REFERENCES empleados(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Índices adicionales**:

```sql
-- Consulta de audit por empleado afectado
CREATE INDEX ix_log_audit_empleado_id ON log_auditoria_empleados (empleado_id, creado_en DESC);

-- Consulta de audit por actor
CREATE INDEX ix_log_audit_actor_id ON log_auditoria_empleados (actor_id, creado_en DESC);
```

**Estructura del campo `detalle` por acción** (ver también RD-02 en research.md):

```json
// CREAR
{ "campos_nuevos": { "rol": "barista", "tienda_id": 2, "nombre": "Ana", "apellido": "Gómez" } }

// EDITAR
{ "campos_anteriores": { "rol": "barista", "tienda_id": 2 }, "campos_nuevos": { "rol": "lider_tienda", "tienda_id": 3 } }

// INACTIVAR
{ "estado_anterior": true, "estado_nuevo": false }

// REACTIVAR
{ "estado_anterior": false, "estado_nuevo": true }

// RESET_CONTRASENA
{ "motivo": "reset_admin" }
```

---

## Diagrama de Relaciones

```text
tiendas
  ├── id (PK)
  └── ...

empleados
  ├── id (PK)
  ├── usuario (UNIQUE)
  ├── rol ENUM
  ├── tienda_id (FK → tiendas.id, NULL si admin)
  ├── activo
  └── requiere_cambio_contrasena

log_auditoria_empleados
  ├── id (PK)
  ├── actor_id   (FK → empleados.id)
  ├── empleado_id (FK → empleados.id)
  ├── accion ENUM
  ├── detalle JSON
  └── creado_en (inmutable)
```

---

## Migraciones

| Archivo | Descripción |
|---------|-------------|
| `NNNN_crear_tabla_empleados.up.sql` | Crea tabla `empleados` con índices |
| `NNNN_crear_tabla_empleados.down.sql` | `DROP TABLE IF EXISTS empleados` |
| `NNNN+1_crear_tabla_log_auditoria_empleados.up.sql` | Crea tabla `log_auditoria_empleados` con índices |
| `NNNN+1_crear_tabla_log_auditoria_empleados.down.sql` | `DROP TABLE IF EXISTS log_auditoria_empleados` |

> `NNNN` debe ser el número correlativo siguiente al último archivo de migración existente en el proyecto.

---

## Transiciones de Estado del Empleado

```text
               ┌─────────────────────────┐
    [crear]    │                         │
  ──────────►  │  activo = 1             │
               │  requiere_cambio = 1    │
               │                         │
               └──────────┬──────────────┘
                           │  [inactivar]
                           ▼
               ┌─────────────────────────┐
               │  activo = 0             │
               │  (sin login posible)    │
               └──────────┬──────────────┘
                           │  [reactivar]
                           ▼
               ┌─────────────────────────┐
               │  activo = 1             │
               │  (rol y tienda previos) │
               └─────────────────────────┘

  En cualquier estado activo:
    [reset contraseña] → requiere_cambio_contrasena = 1
    [cambio de contraseña por empleado] → requiere_cambio_contrasena = 0
```
