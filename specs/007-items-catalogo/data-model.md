# Modelo de Datos: 007-items-catalogo

**Generado**: 2026-05-24

---

## Entidades

### Tabla `items`

Catálogo compartido por marca. Entidad central del sistema: todo inventario, receta
y pedido referencia un item. No existe eliminación física — los items se inactivan o
reactivan. El código es único e inmutable una vez que el item tiene al menos un registro
en inventarios, pedidos o recetas.

```sql
CREATE TABLE items (
  id                    BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  codigo                VARCHAR(20)      NOT NULL
                          COMMENT 'Código único asignado por el admin (ej. CAF-001). Case-sensitive.',
  nombre                VARCHAR(150)     NOT NULL
                          COMMENT 'Nombre único en el sistema (case-insensitive por utf8mb4_unicode_ci).',
  tipo                  ENUM(
                          'insumo',
                          'material_consumo',
                          'activo'
                        )                NOT NULL,
  subcategoria_id       BIGINT UNSIGNED  NOT NULL
                          COMMENT 'FK a subcategorias.id. Puede cambiarse libremente.',
  proveedor_id          BIGINT UNSIGNED  NULL
                          COMMENT 'FK a proveedores.id. NULL = sin proveedor asignado.',
  unidad_medida_id      BIGINT UNSIGNED  NOT NULL
                          COMMENT 'FK a unidades_medida.id. Cambio con historial requiere confirmación.',
  costo_unitario        INT              NULL
                          COMMENT 'Costo por defecto global en COP sin decimales. NULL si no definido.',
  frecuencia_inventario ENUM(
                          'diario',
                          'semanal',
                          'mensual'
                        )                NOT NULL,
  stock_seguridad       DECIMAL(12,4)    NOT NULL
                          COMMENT 'En la unidad de medida del item. 0 si no aplica (p. ej. activos).',
  tiempo_entrega_dias   SMALLINT UNSIGNED NULL
                          COMMENT 'Días de entrega del proveedor habitual. NULL si no definido.',
  activo                TINYINT(1)       NOT NULL DEFAULT 1,
  creado_por            BIGINT UNSIGNED  NOT NULL
                          COMMENT 'FK a usuarios.id — quién creó el item.',
  creado_en             DATETIME         NOT NULL,
  actualizado_por       BIGINT UNSIGNED  NOT NULL
                          COMMENT 'FK a usuarios.id — último que modificó el item.',
  actualizado_en        DATETIME         NOT NULL,

  PRIMARY KEY (id),

  CONSTRAINT uq_items_codigo
    UNIQUE (codigo),
  CONSTRAINT uq_items_nombre
    UNIQUE (nombre),

  CONSTRAINT fk_items_subcategoria
    FOREIGN KEY (subcategoria_id) REFERENCES subcategorias (id),
  CONSTRAINT fk_items_proveedor
    FOREIGN KEY (proveedor_id) REFERENCES proveedores (id),
  CONSTRAINT fk_items_unidad_medida
    FOREIGN KEY (unidad_medida_id) REFERENCES unidades_medida (id),
  CONSTRAINT fk_items_creado_por
    FOREIGN KEY (creado_por) REFERENCES usuarios (id),
  CONSTRAINT fk_items_actualizado_por
    FOREIGN KEY (actualizado_por) REFERENCES usuarios (id)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Índices adicionales**:

```sql
-- Listado filtrado por estado — consulta principal del catálogo
CREATE INDEX ix_items_activo ON items (activo);

-- Filtrado por tipo (insumo/material_consumo/activo) — combinable con activo
CREATE INDEX ix_items_tipo_activo ON items (tipo, activo);

-- Items activos por frecuencia — consulta crítica de 009-inventario (cacheada con Ristretto)
CREATE INDEX ix_items_frecuencia_activo ON items (frecuencia_inventario, activo);
```

**Reglas de integridad**:

| Regla | Validación |
|-------|------------|
| `codigo` único en el sistema, case-sensitive | Constraint `uq_items_codigo` |
| `nombre` único en el sistema, case-insensitive | Constraint `uq_items_nombre` + collation `_ci` |
| `codigo` inmutable si el item tiene usos en inventarios/pedidos/recetas | `service.estaEnUso()` — a nivel de aplicación |
| Cambio de `unidad_medida_id` con historial de stock requiere confirmación | Modal en frontend + flag `confirmar_cambio_unidad` en body |
| No DELETE físico | Solo a nivel de aplicación; siempre `activo = 0` o `activo = 1` |
| `stock_seguridad` ≥ 0 para todos los tipos | Validación en Go: rechaza valores negativos; 0 permitido para activos |
| `creado_por` / `actualizado_por` extraídos del JWT, nunca del request body | Solo a nivel de aplicación |

---

### Tabla `items_costos_tienda`

Registro histórico append-only de los costos por tienda para cada item. El costo vigente
de un item en una tienda es la fila más reciente (`vigente_desde DESC LIMIT 1`). Si no
existe ninguna fila para una tienda, se usa `Item.costo_unitario` como valor por defecto.

```sql
CREATE TABLE items_costos_tienda (
  id             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  item_id        BIGINT UNSIGNED  NOT NULL
                   COMMENT 'FK a items.id.',
  tienda_id      BIGINT UNSIGNED  NOT NULL
                   COMMENT 'FK a tiendas.id.',
  costo_unitario INT              NOT NULL
                   COMMENT 'Costo en COP sin decimales para esta tienda en este momento.',
  vigente_desde  DATETIME         NOT NULL
                   COMMENT 'Momento desde el que aplica este costo. Se asigna con NOW() al insertar.',
  creado_por     BIGINT UNSIGNED  NOT NULL
                   COMMENT 'FK a usuarios.id — admin que registró este costo.',
  creado_en      DATETIME         NOT NULL,

  PRIMARY KEY (id),

  CONSTRAINT fk_ict_item
    FOREIGN KEY (item_id) REFERENCES items (id),
  CONSTRAINT fk_ict_tienda
    FOREIGN KEY (tienda_id) REFERENCES tiendas (id),
  CONSTRAINT fk_ict_creado_por
    FOREIGN KEY (creado_por) REFERENCES usuarios (id)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Índices adicionales**:

```sql
-- Consulta del costo vigente: ORDER BY vigente_desde DESC LIMIT 1
CREATE INDEX ix_ict_item_tienda_vigente
  ON items_costos_tienda (item_id, tienda_id, vigente_desde);
```

**Reglas de integridad**:

| Regla | Validación |
|-------|------------|
| Tabla append-only — no existe UPDATE ni DELETE | Solo a nivel de aplicación |
| `costo_unitario` > 0 | Validación en Go: rechaza valores ≤ 0 |
| `vigente_desde` asignado por el servidor (`NOW()`) | Solo a nivel de aplicación; nunca viene del request body |
| `creado_por` extraído del JWT | Solo a nivel de aplicación |

---

## Migraciones

| Archivo | Descripción |
|---------|-------------|
| `NNNN_crear_tabla_items.up.sql` | Crea tabla `items` con índices y constraints |
| `NNNN_crear_tabla_items.down.sql` | `DROP TABLE IF EXISTS items` |
| `NNNN+1_crear_tabla_items_costos_tienda.up.sql` | Crea tabla `items_costos_tienda` con índices |
| `NNNN+1_crear_tabla_items_costos_tienda.down.sql` | `DROP TABLE IF EXISTS items_costos_tienda` |

> `NNNN` debe ser el número correlativo siguiente al último archivo de migración en el proyecto
> (actualmente los proveedores — 006 — son la migración previa más reciente).
> Las tablas no tienen datos seed; el admin carga el catálogo manualmente.

---

## Diagrama de Relaciones

```text
usuarios (001)
  └── id (PK)
       │
       ├─creado_por──────────────────────────────────────────────────────────┐
       └─actualizado_por──────────────────────────────────────────────────┐  │
                                                                           │  │
unidades_medida (004)          subcategorias (005)     proveedores (006)  │  │
  └── id (PK) ◄──────────┐      └── id (PK) ◄────┐     └── id (PK) ◄─┐  │  │
                          │                        │                   │  │  │
                     items                         │                   │  │  │
                       ├── id (PK)                 │                   │  │  │
                       ├── codigo (UNIQUE)          │                   │  │  │
                       ├── nombre (UNIQUE CI)       │                   │  │  │
                       ├── tipo (ENUM)              │                   │  │  │
                       ├── subcategoria_id (FK) ────┘                   │  │  │
                       ├── proveedor_id (FK, nullable) ─────────────────┘  │  │
                       ├── unidad_medida_id (FK) ───────────────────────────┘  │
                       ├── costo_unitario (global, nullable)                    │
                       ├── frecuencia_inventario (ENUM)                         │
                       ├── stock_seguridad (DECIMAL 12,4)                       │
                       ├── tiempo_entrega_dias (nullable)                       │
                       ├── activo (TINYINT 1)                                   │
                       ├── creado_por (FK → usuarios) ──────────────────────────┘
                       ├── creado_en
                       ├── actualizado_por (FK → usuarios)
                       └── actualizado_en
                            │
                            │  (1 item → N costos por tienda)
                            ▼
                     items_costos_tienda
                       ├── id (PK)
                       ├── item_id (FK → items.id)
                       ├── tienda_id (FK → tiendas.id)
                       ├── costo_unitario (INT COP)
                       ├── vigente_desde (DATETIME)
                       ├── creado_por (FK → usuarios.id)
                       └── creado_en

tiendas (002)
  └── id (PK) ◄──── items_costos_tienda.tienda_id

Módulos consumidores (futuros):
  inventarios_conteos_items.item_id  → items.id  (009)
  recetas_ingredientes.item_id       → items.id  (008)
  pedidos_lineas.item_id             → items.id  (012-013)
```

---

## Transiciones de Estado

### Item

```text
                ┌──────────────────────────────────────────────┐
  [crear]       │                                              │
─────────────►  │  activo = 1                                  │
                │  - Aparece en conteos según su frecuencia    │
                │  - Seleccionable en recetas y pedidos        │
                │  - Costo global editable en cualquier momento│
                └──────────────────┬───────────────────────────┘
                                   │ [inactivar]
                                   ▼
                ┌──────────────────────────────────────────────┐
                │  activo = 0                                  │ ◄────────────
                │  - NO aparece en nuevos conteos              │  [inactivar] │
                │  - NO seleccionable en nuevas recetas        │              │
                │    ni nuevas líneas de pedido                │  [reactivar] │
                │  - Historial completo accesible para admin   │  ────────────►
                └──────────────────────────────────────────────┘
                   Nota: si el item es ingrediente de una receta
                   activa, la receta muestra advertencia de
                   ingrediente inactivo.
```

### Código del item (campo especial)

```text
                ┌──────────────────────────────────────────────┐
  [crear]       │                                              │
─────────────►  │  EDITABLE                                    │
                │  (el item no tiene usos en ningún módulo)    │
                │  estaEnUso() = false                         │
                └──────────────────┬───────────────────────────┘
                                   │ [primer uso en inventario,
                                   │  receta o pedido]
                                   ▼
                ┌──────────────────────────────────────────────┐
                │  BLOQUEADO                                   │
                │  (estaEnUso() = true)                        │
                │  El PUT rechaza cambios al campo `codigo`    │
                │  con error 422 codigo_en_uso                 │
                └──────────────────────────────────────────────┘
```
