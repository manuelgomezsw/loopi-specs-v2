# Data Model: 009-inventario-conteo

**Fecha**: 2026-07-18  
**Versión**: 2.0 (Corregida con Determinación Automática de Items)

---

## Entidades Principales

### `inventarios` (Tabla Principal)

Registro de cada conteo físico realizado en una tienda.

```sql
CREATE TABLE inventarios (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tienda_id BIGINT UNSIGNED NOT NULL,
  tipo ENUM('diario', 'semanal', 'mensual', 'inicial') NOT NULL,
  horario ENUM('apertura', 'mediodia', 'cierre') NULL,
  horario_norm VARCHAR(20) GENERATED ALWAYS AS (
    CASE 
      WHEN horario = 'apertura' THEN '06:00'
      WHEN horario = 'mediodia' THEN '12:00'
      WHEN horario = 'cierre' THEN '18:00'
      ELSE NULL
    END
  ) STORED,
  estado ENUM('en_progreso', 'completado') NOT NULL DEFAULT 'en_progreso',
  responsable_id BIGINT UNSIGNED NOT NULL,
  fecha DATE NOT NULL DEFAULT (CURDATE()),
  iniciado_en DATETIME NOT NULL DEFAULT NOW(),
  completado_en DATETIME NULL,
  creado_en DATETIME NOT NULL DEFAULT NOW(),
  actualizado_en DATETIME NOT NULL DEFAULT NOW() ON UPDATE NOW(),
  
  KEY idx_tienda_tipo_horario_fecha (tienda_id, tipo, horario_norm, fecha),
  UNIQUE KEY uk_tienda_tipo_horario_fecha (tienda_id, tipo, horario_norm, fecha),
  KEY idx_responsable (responsable_id),
  KEY idx_estado (estado),
  
  CONSTRAINT fk_inventarios_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE RESTRICT,
  CONSTRAINT fk_inventarios_responsable FOREIGN KEY (responsable_id) REFERENCES empleados(id) ON DELETE RESTRICT
);
```

**Propósito**: Registra inicio de conteo con tipo/horario, responsable, y timestamps.

**Constraints**:

- UNIQUE (tienda_id, tipo, horario_norm, fecha): Solo 1 conteo activo/completado por tienda+tipo+horario+fecha
- Estado: en_progreso mientras se registran valores, completado una vez confirmado

---

### `detalle_inventario` (Tabla de Líneas)

Una línea por cada item contado en un inventario.

```sql
CREATE TABLE detalle_inventario (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  inventario_id BIGINT UNSIGNED NOT NULL,
  item_id BIGINT UNSIGNED NOT NULL,
  
  valor_esperado DECIMAL(10, 2) NOT NULL DEFAULT 0,
  valor_real DECIMAL(10, 2) NULL,
  diferencia DECIMAL(10, 2) GENERATED ALWAYS AS (
    COALESCE(valor_real, 0) - valor_esperado
  ) STORED,
  
  creado_en DATETIME NOT NULL DEFAULT NOW(),
  actualizado_en DATETIME NOT NULL DEFAULT NOW() ON UPDATE NOW(),
  
  PRIMARY KEY (inventario_id, item_id),
  KEY idx_item (item_id),
  KEY idx_valor_real_null (valor_real),
  
  CONSTRAINT fk_detalle_inventario_inv FOREIGN KEY (inventario_id) REFERENCES inventarios(id) ON DELETE CASCADE,
  CONSTRAINT fk_detalle_inventario_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT
);
```

**Propósito**: Línea item-level de conteo. Almacena valor esperado (snapshot de stock), valor real contado, y diferencia calculada.

**Campos**:

- `valor_esperado`: Snapshot inmutable del stock proyectado al inicio del conteo (per RF-INV-02.2, NUNCA cambia durante conteo)
- `valor_real`: Cantidad física contada (NULL hasta que se registra)
- `diferencia`: Generada = valor_real - valor_esperado (para auditoría y cálculo de Faltante/Exceso/Correcto)

---

### `stock_actual` (Tabla de Snapshots)

Snapshot de stock de cada item en el momento exacto de POST /inventarios.

```sql
CREATE TABLE stock_actual (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tienda_id BIGINT UNSIGNED NOT NULL,
  item_id BIGINT UNSIGNED NOT NULL,
  inventario_id BIGINT UNSIGNED NULL,
  valor_snapshot DECIMAL(10, 2) NOT NULL DEFAULT 0,
  tomado_en DATETIME NOT NULL DEFAULT NOW(),
  creado_en DATETIME NOT NULL DEFAULT NOW(),
  
  UNIQUE KEY uk_tienda_item_inventario (tienda_id, item_id, inventario_id),
  KEY idx_tienda (tienda_id),
  KEY idx_inventario (inventario_id),
  
  CONSTRAINT fk_stock_actual_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE RESTRICT,
  CONSTRAINT fk_stock_actual_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT,
  CONSTRAINT fk_stock_actual_inv FOREIGN KEY (inventario_id) REFERENCES inventarios(id) ON DELETE SET NULL
);
```

**Propósito**: Persiste el valor_snapshot de cada item al inicio del conteo (base para cálculo RF-INV-02.2).

---

### `stock_movimientos` (Tabla de Auditoría)

Registro de todos los movimientos de stock (compras, mermas, ventas, ajustes).

```sql
CREATE TABLE stock_movimientos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tienda_id BIGINT UNSIGNED NOT NULL,
  item_id BIGINT UNSIGNED NOT NULL,
  tipo_movimiento ENUM('compra', 'merma', 'venta_batch', 'ajuste_conteo') NOT NULL,
  
  cantidad_antes DECIMAL(10, 2) NOT NULL,
  cantidad_despues DECIMAL(10, 2) NOT NULL,
  cantidad_delta DECIMAL(10, 2) GENERATED ALWAYS AS (cantidad_despues - cantidad_antes) STORED,
  
  referencia_id BIGINT UNSIGNED NULL,
  usuario_id BIGINT UNSIGNED NULL,
  inventario_id BIGINT UNSIGNED NULL,
  motivo VARCHAR(255) NULL,
  
  creado_en DATETIME NOT NULL DEFAULT NOW(),
  
  KEY idx_tienda_creado (tienda_id, creado_en),
  KEY idx_referencia (referencia_id),
  KEY idx_inventario (inventario_id),
  KEY idx_tipo_movimiento (tipo_movimiento),
  
  CONSTRAINT fk_stock_mov_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE RESTRICT,
  CONSTRAINT fk_stock_mov_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT
);
```

**Propósito**: Auditoría completa de todos los cambios de stock por tienda.

**Campos**:

- `tipo_movimiento`: compra (caja menor), merma (010), venta_batch (015), ajuste_conteo (009)
- `referencia_id`: ID de la transacción origen (compra_id, merma_id, venta_batch_id)
- `usuario_id`: Quién hizo el movimiento
- `inventario_id`: Conteo relacionado (si es ajuste_conteo)

---

## Flujo de Datos: Iniciar Conteo (RF-INV-02.3)

```text
1. items tabla (activo=1, frecuencia_inventario)
   ↓ GetItemsActivosPorTipo(tienda, tipo)
   ├→ Query: SELECT id FROM items 
           WHERE tienda_id=? AND activo=1 AND frecuencia_inventario=?
   ├→ Resultado: [item_501, item_502, ..., item_510]
   └→ Si 0 items: Retornar 422 sin_items_contabilizar

2. inventarios tabla (CREATE new)
   ↓ CreateInventario()
   ├→ INSERT inventarios (tienda_id, tipo, horario, estado=en_progreso, responsable_id)
   ├→ Resultado: inventario_id = 123, iniciado_en = NOW()
   └→ Si UNIQUE violation: Retornar 409 conteo_bloqueado

3. stock_actual tabla (QUERY snapshot)
   ↓ GetStockSnapshot(tienda, itemIDs)
   ├→ Query: SELECT item_id, valor_snapshot FROM stock_actual 
           WHERE tienda_id=? AND item_id IN (?, ?, ...)
   ├→ Resultado: {item_501: 50, item_502: 45, item_503: 0, ...}
   └→ Default 0 si item no existe en stock_actual

4. detalle_inventario tabla (CREATE with valor_esperado)
   ↓ CreateDetalleInventario()
   ├→ INSERT detalle_inventario (inventario_id, item_id, valor_esperado) 
           FOR EACH item
   ├→ Línea 1: {inventario_id: 123, item_id: 501, valor_esperado: 50}
   ├→ Línea 2: {inventario_id: 123, item_id: 502, valor_esperado: 45}
   ├→ Línea 3: {inventario_id: 123, item_id: 503, valor_esperado: 0}
   └→ Resultado: 10 detalle_inventario rows insertadas

5. Respuesta HTTP 201
   ├→ Body: InventarioResp {
           id: 123,
           items: [
             {item_id: 501, valor_esperado: 50, valor_real: null},
             {item_id: 502, valor_esperado: 45, valor_real: null},
             ...
           ]
        }
   └→ Frontend recibe items listos para contar
```

---

## Flujo de Datos: Registrar Valor (RF-INV-02)

```text
1. Frontend ingresa valor_real para item_id
   ↓ PATCH /inventarios/{id}/items/{item_id}
   ├→ Payload: {valor_real: 48}

2. Service.RegistrarValor()
   ├→ Validar inventario existe y estado=en_progreso
   ├→ Validar usuario = responsable_id
   ├→ Calcular diferencia = valor_real - valor_esperado = 48 - 45 = 3

3. Repository.UpdateDetalle()
   ├→ UPDATE detalle_inventario 
           SET valor_real=48, actualizado_en=NOW()
           WHERE inventario_id=123 AND item_id=502
   └→ diferencia se calcula automáticamente (GENERATED column)

4. Respuesta HTTP 200
   ├→ Body: ItemDetailResp {
           item_id: 502,
           valor_esperado: 45,
           valor_real: 48,
           diferencia: 3
        }
   └→ Frontend muestra diferencia en verde (Exceso: +3)
```

---

## Flujo de Datos: Confirmar Conteo (RF-INV-03)

```text
1. Frontend: POST /inventarios/{id}/confirmar

2. Service.Confirmar()
   ├→ Validar inventario existe y estado=en_progreso
   ├→ Validar TODOS los items tienen valor_real NOT NULL
   ├→ Si alguno NULL: Retornar 422 items_sin_registrar

3. Repository.ConfirmarInventario() — ATOMIC TRANSACTION
   ├→ BEGIN TRANSACTION
   ├→ UPDATE inventarios SET estado='completado', completado_en=NOW()
   ├→ INSERT INTO stock_movimientos (tipo=ajuste_conteo, ...) para cada item
   ├→ COMMIT
   └→ Resultado: estado='completado', timestamp registrado

4. Stock derivado (NO INSERT explícito en stock actual)
   ├→ Stock de cada item = valor_real del conteo confirmado
   ├→ Se consulta en tiempo real desde detalle_inventario.valor_real
   └→ Próximo conteo usa este como valor_sugerido

5. Respuesta HTTP 200
   ├→ Body: InventarioResp {
           id: 123,
           estado: 'completado',
           completado_en: '2026-07-18T10:45:30Z',
           items: [...]
        }
   └→ Frontend navega a historial
```

---

## Validaciones y Constraints

### En Base de Datos

| Constraint | Tabla | Propósito | Acción |
|-----------|-------|----------|--------|
| UNIQUE (tienda_id, tipo, horario_norm, fecha) | inventarios | Solo 1 conteo por tienda+tipo+hora+fecha | Bloquea duplicate → 409 |
| FK tienda_id | inventarios, detalle_inventario, stock_actual, stock_movimientos | Referential integrity | RESTRICT en delete |
| FK responsable_id | inventarios | Responsable es empleado válido | RESTRICT en delete |
| FK item_id | detalle_inventario, stock_actual, stock_movimientos | Items válidos | RESTRICT en delete |
| PK (inventario_id, item_id) | detalle_inventario | Un detalle por item+inventario | UNIQUE enforcement |
| NOT NULL tipo, estado, responsable_id | inventarios | Campos requeridos | Bloquea insert incompleto |

### En Aplicación

| Validación | Capa | Condición | Acción |
|-----------|------|-----------|--------|
| Items for tipo | Service.Iniciar() | GetItemsActivosPorTipo() retorna 0 | 422 sin_items_contabilizar |
| Duplicado conteo | Service.Iniciar() | UNIQUE constraint violation | 409 conteo_bloqueado |
| Autorización | Service.Iniciar/Registrar/Confirmar | user != responsable_id | 403 conteo_bloqueado |
| Items sin registrar | Service.Confirmar() | ∃ item.valor_real IS NULL | 422 items_sin_registrar |
| Movimientos bloqueados | Service (otros módulos) | ∃ inventario en_progreso en tienda | 409 inventario_activo |

---

## Índices Recomendados

| Tabla | Índice | Uso |
|-------|--------|-----|
| inventarios | (tienda_id, tipo, horario_norm, fecha) | UNIQUE constraint + fast duplicate check |
| inventarios | (estado) | Filtrar conteos activos rápidamente |
| inventarios | (responsable_id) | Auditoría de quién hizo cada conteo |
| detalle_inventario | (inventario_id, item_id) | PRIMARY KEY (lookups por inventario) |
| detalle_inventario | (valor_real) | Queries de "items sin registrar" (WHERE valor_real IS NULL) |
| stock_actual | (tienda_id, item_id, inventario_id) | UNIQUE constraint |
| stock_actual | (tienda_id) | GetStockSnapshot() por tienda |
| stock_movimientos | (tienda_id, creado_en) | Auditoría trail por tienda+fecha |
| stock_movimientos | (referencia_id) | Traceability (link a compra/merma/venta) |

---

## Relaciones y Cardinalidades

```text
tiendas (1) ──── (N) inventarios
               └── (N) stock_actual
               └── (N) stock_movimientos

empleados (1) ──── (N) inventarios (responsable_id)

items (1) ──── (N) detalle_inventario
           └── (N) stock_actual
           └── (N) stock_movimientos

inventarios (1) ──── (N) detalle_inventario (CASCADE delete)
            └── (N) stock_actual (SET NULL on delete)
            └── (N) stock_movimientos (SET NULL on delete)
```

---

## Tamaño Estimado

| Tabla | Filas/año (est.) | Tamaño/año | Purga |
|-------|------------------|------------|-------|
| inventarios | 365 × 20 tiendas = 7,300 | ~2 MB | Nunca (auditoría permanente) |
| detalle_inventario | 7,300 × 100 items/conteo = 730,000 | ~50 MB | Nunca (auditoría) |
| stock_actual | 730,000 | ~50 MB | Overwrite (por tienda+item+inventario) |
| stock_movimientos | ~10,000 moves/día × 365 = 3.65M | ~250 MB | Nunca (auditoría) |

**Total**: ~350 MB/año (manejable, backup diario recomendado)

---

**Bugfix**: 2026-07-19 — BUG-019 Eliminación de campo redundante `valor_sugerido`. Mantener solo `valor_esperado` que es el snapshot de stock al inicio del conteo y contra el que se calcula la diferencia.

**Última actualización**: 2026-07-19 — Data model v3 con campo redundante eliminado
