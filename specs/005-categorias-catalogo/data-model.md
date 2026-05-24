# Modelo de Datos: 005-categorias-catalogo

**Generado**: 2026-05-24

---

## Entidades

### Tabla `categorias`

Catálogo compartido por marca. Nivel raíz de clasificación del catálogo de items.
No existe eliminación física — las categorías se inactivan o reactivan.

```sql
CREATE TABLE categorias (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre           VARCHAR(100)    NOT NULL
                     COMMENT 'Nombre único en el sistema (case-insensitive por utf8mb4_unicode_ci)',
  activo           TINYINT(1)      NOT NULL DEFAULT 1,
  creado_por       BIGINT UNSIGNED NOT NULL COMMENT 'FK a usuarios.id — quién creó el registro',
  creado_en        DATETIME        NOT NULL,
  actualizado_por  BIGINT UNSIGNED NOT NULL COMMENT 'FK a usuarios.id — último que modificó',
  actualizado_en   DATETIME        NOT NULL,

  PRIMARY KEY (id),
  CONSTRAINT uq_categorias_nombre
    UNIQUE (nombre),
  CONSTRAINT fk_categorias_creado_por
    FOREIGN KEY (creado_por) REFERENCES usuarios (id),
  CONSTRAINT fk_categorias_actualizado_por
    FOREIGN KEY (actualizado_por) REFERENCES usuarios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Índices adicionales**:

```sql
-- Listado activo/inactivo — consulta principal del catálogo
CREATE INDEX ix_categorias_activo ON categorias (activo);
```

**Reglas de integridad**:

| Regla | Validación |
|-------|------------|
| `nombre` único en el sistema, case-insensitive | Constraint `uq_categorias_nombre` + collation `_ci` |
| No DELETE físico | Solo a nivel de aplicación; siempre `activo = 0` o `activo = 1` |
| Al inactivar una categoría con subcategorías activas, se inactivan todas | Transacción en `service.go` |
| Al reactivar una categoría, las subcategorías permanecen inactivas | Solo a nivel de aplicación |
| `creado_por` / `actualizado_por` extraídos del JWT, nunca del request body | Solo a nivel de aplicación |

---

### Tabla `subcategorias`

Segundo nivel de clasificación del catálogo. Cada item pertenece a exactamente una
subcategoría. El `categoria_id` es inmutable tras la creación.

```sql
CREATE TABLE subcategorias (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre           VARCHAR(100)    NOT NULL
                     COMMENT 'Único dentro de la categoría, case-insensitive',
  categoria_id     BIGINT UNSIGNED NOT NULL
                     COMMENT 'FK a categorias.id — inmutable tras creación',
  activo           TINYINT(1)      NOT NULL DEFAULT 1,
  creado_por       BIGINT UNSIGNED NOT NULL COMMENT 'FK a usuarios.id',
  creado_en        DATETIME        NOT NULL,
  actualizado_por  BIGINT UNSIGNED NOT NULL COMMENT 'FK a usuarios.id',
  actualizado_en   DATETIME        NOT NULL,

  PRIMARY KEY (id),
  CONSTRAINT uq_subcategorias_nombre_categoria
    UNIQUE (categoria_id, nombre),
  CONSTRAINT fk_subcategorias_categoria
    FOREIGN KEY (categoria_id) REFERENCES categorias (id),
  CONSTRAINT fk_subcategorias_creado_por
    FOREIGN KEY (creado_por) REFERENCES usuarios (id),
  CONSTRAINT fk_subcategorias_actualizado_por
    FOREIGN KEY (actualizado_por) REFERENCES usuarios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Índices adicionales**:

```sql
-- Listado por categoría con filtro de estado — consulta principal
CREATE INDEX ix_subcategorias_categoria_activo ON subcategorias (categoria_id, activo);
```

**Reglas de integridad**:

| Regla | Validación |
|-------|------------|
| `nombre` único dentro de la misma categoría, case-insensitive | Constraint `uq_subcategorias_nombre_categoria` + collation `_ci` |
| `categoria_id` inmutable tras la creación | Solo a nivel de aplicación (`service.go` rechaza updates al `categoria_id`) |
| No DELETE físico | Solo a nivel de aplicación; siempre `activo = 0` o `activo = 1` |
| No se puede reactivar una subcategoría si su categoría padre está inactiva | Solo a nivel de aplicación |
| `creado_por` / `actualizado_por` extraídos del JWT | Solo a nivel de aplicación |

---

## Migraciones

| Archivo | Descripción |
|---------|-------------|
| `NNNN_crear_tabla_categorias.up.sql` | Crea tabla `categorias` con índices y constraints |
| `NNNN_crear_tabla_categorias.down.sql` | `DROP TABLE IF EXISTS categorias` |
| `NNNN+1_crear_tabla_subcategorias.up.sql` | Crea tabla `subcategorias` con índices y constraints |
| `NNNN+1_crear_tabla_subcategorias.down.sql` | `DROP TABLE IF EXISTS subcategorias` |

> `NNNN` debe ser el número correlativo siguiente al último archivo de migración en el proyecto.
> Las tablas no tienen datos seed (el admin las crea manualmente según la estructura de su negocio).

---

## Diagrama de Relaciones

```text
usuarios (001)               categorias               subcategorias
  ├── id (PK)  ◄───────────  ├── id (PK)  ◄─────────  ├── id (PK)
  └── ...      ◄──────────── ├── nombre (UNIQUE CI)   ├── nombre (UNIQUE dentro cat, CI)
                              ├── activo               ├── categoria_id (FK → categorias.id)
               ──creado_por─► ├── creado_por (FK)      ├── activo
               ─actualiz_por► ├── actualizado_por (FK) ├── creado_por (FK → usuarios.id)
                              ├── creado_en            ├── actualizado_por (FK → usuarios.id)
                              └── actualizado_en       ├── creado_en
                                                       └── actualizado_en

items (007 — futuro)
  ├── id (PK)
  ├── subcategoria_id (FK → subcategorias.id)
  └── ...
  (El item hereda implícitamente la categoría a través de su subcategoría)
```

---

## Transiciones de Estado

### Categoría

```text
              ┌───────────────────────────────────────────┐
  [crear]     │                                           │
──────────►   │  activo = 1                               │
              │  (aparece en selector al crear subcat)    │
              │                                           │
              └─────────────────┬─────────────────────────┘
                                │ [inactivar]
                                │ Cascade: inactiva todas las
                                │ subcategorías activas (transacción)
                                ▼
              ┌───────────────────────────────────────────┐
              │  activo = 0                               │
              │  - No aparece en selector de subcats      │ ◄────────────────────
              │  - Sus subcategorías quedan también        │    [inactivar]       │
              │    inactivas (cascade)                    │                      │
              │  - Items con subcat. de esta cat.         │  [reactivar]         │
              │    conservan su clasificación             │  ────────────────────►
              └───────────────────────────────────────────┘
                  Nota: reactivar la categoría NO reactiva
                  sus subcategorías automáticamente.
```

### Subcategoría

```text
              ┌───────────────────────────────────────────┐
  [crear]     │                                           │
──────────►   │  activo = 1                               │
              │  (aparece en selector al crear items)     │
              │                                           │
              └─────────────────┬─────────────────────────┘
                                │ [inactivar]
                                ▼
              ┌───────────────────────────────────────────┐
              │  activo = 0                               │ ◄────────────────────
              │  - No aparece en selector de items        │    [inactivar]       │
              │  - Items existentes conservan subcat.     │                      │
              │    visible en sus fichas                  │  [reactivar]         │
              └───────────────────────────────────────────┘  Solo si categoría  │
                                                              padre activa       │
                                                              ──────────────────►
                  Precondición de reactivación:
                    categorias.activo = 1 para el categoria_id de esta subcategoría.
                    Si no se cumple → 422 categoria_padre_inactiva.
```
