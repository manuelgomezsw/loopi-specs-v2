# Modelo de Datos: Autenticación y Gestión de Sesión

**Feature**: `001-autenticacion` | **Fecha**: 2026-05-23

---

## Tabla: `tokens_revocados` *(nueva — propietaria de esta feature)*

Registra los JWTs revocados explícitamente (logout). El backend verifica esta tabla
en el paso 3 de la validación de sesión. La tabla crece solo en logout; un job
programado elimina registros expirados.

```sql
CREATE TABLE tokens_revocados (
    jti           VARCHAR(36)  NOT NULL,
    expira_en     DATETIME     NOT NULL,
    creado_en     DATETIME     NOT NULL,
    actualizado_en DATETIME    NOT NULL,
    PRIMARY KEY (jti),
    INDEX idx_tokens_revocados_expira_en (expira_en)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Campos**:

| Campo | Tipo | Nulo | Descripción |
|-------|------|------|-------------|
| `jti` | VARCHAR(36) | NO | UUID v4 del JWT revocado (PK) |
| `expira_en` | DATETIME | NO | Copia del claim `exp` del JWT; usado para limpieza por job |
| `creado_en` | DATETIME | NO | Timestamp de inserción (momento del logout) |
| `actualizado_en` | DATETIME | NO | Igual a `creado_en`; requerido por convención de datos |

**Índice**: `idx_tokens_revocados_expira_en` permite que el job de limpieza ejecute
`DELETE WHERE expira_en < NOW()` con escaneo de índice eficiente.

**Volumen estimado**: con TTL de 24 h y ~50 usuarios activos, máximo ~50 registros
en estado estable. La tabla es casi siempre pequeña.

---

## Columnas nuevas en `empleados` *(cross-feature — tabla propietaria: `003-gestion-empleados`)*

La tabla `empleados` requiere dos columnas para el mecanismo de bloqueo por intentos
fallidos. Esta migración es parte de `001-autenticacion` pero aplica sobre la tabla
creada por `003-gestion-empleados`.

```sql
ALTER TABLE empleados
    ADD COLUMN intentos_fallidos  INT      NOT NULL DEFAULT 0    AFTER activo,
    ADD COLUMN bloqueado_hasta    DATETIME     NULL DEFAULT NULL  AFTER intentos_fallidos;
```

**Campos**:

| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| `intentos_fallidos` | INT | NO | 0 | Contador de intentos fallidos consecutivos; se resetea a 0 en login exitoso |
| `bloqueado_hasta` | DATETIME | SÍ | NULL | Timestamp hasta el cual el usuario está bloqueado; NULL = sin bloqueo activo |

**Lógica de actualización**:

- Login fallido: `intentos_fallidos = intentos_fallidos + 1`; si llega a 5,
  `bloqueado_hasta = NOW() + INTERVAL 5 MINUTE`
- Login exitoso: `intentos_fallidos = 0`, `bloqueado_hasta = NULL`
- Verificación de bloqueo: `WHERE bloqueado_hasta > NOW()`

---

## JWT Payload *(no persistido en BD)*

El JWT se emite por el backend y viaja en la `httpOnly cookie`. Su payload es:

```json
{
  "jti": "550e8400-e29b-41d4-a716-446655440000",
  "sub": "42",
  "rol": "lider_tienda",
  "tienda_id": 3,
  "iat": 1716480000,
  "exp": 1716566400
}
```

| Claim | Tipo | Descripción |
|-------|------|-------------|
| `jti` | string (UUID v4) | Identificador único del token; usado como PK en `tokens_revocados` |
| `sub` | string (int) | ID del usuario autenticado |
| `rol` | string | `admin` \| `lider_compras` \| `lider_tienda` \| `barista` |
| `tienda_id` | int \| null | ID de tienda para `lider_tienda`/`barista`; `null` para `admin`/`lider_compras` |
| `iat` | int (unix) | Timestamp de emisión |
| `exp` | int (unix) | Timestamp de expiración (`iat` + `JWT_EXPIRY_HOURS * 3600`) |

---

## Migración

Archivo: `loopi-api/migrations/XXXX_auth_tokens_revocados.sql`

```sql
-- +migrate Up

CREATE TABLE tokens_revocados (
    jti            VARCHAR(36)  NOT NULL,
    expira_en      DATETIME     NOT NULL,
    creado_en      DATETIME     NOT NULL,
    actualizado_en DATETIME     NOT NULL,
    PRIMARY KEY (jti),
    INDEX idx_tokens_revocados_expira_en (expira_en)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE empleados
    ADD COLUMN intentos_fallidos  INT          NOT NULL DEFAULT 0    AFTER activo,
    ADD COLUMN bloqueado_hasta    DATETIME         NULL DEFAULT NULL  AFTER intentos_fallidos;

-- +migrate Down

ALTER TABLE empleados
    DROP COLUMN bloqueado_hasta,
    DROP COLUMN intentos_fallidos;

DROP TABLE IF EXISTS tokens_revocados;
```

**Nota de rollback**: el `DOWN` elimina columnas de `empleados` y la tabla
`tokens_revocados`. Al ejecutar `DOWN` en prod se pierden registros de bloqueo
activos; es aceptable ya que el impacto es temporal (usuarios bloqueados quedan
desbloqueados).
