# Modelo de Datos: 004-unidades-medida

**Generado**: 2026-05-24

---

## Entidades

### Tabla `unidades_medida`

Catálogo compartido por marca de unidades de medida y sus factores de conversión respecto
a la unidad base del tipo. No existe eliminación física — las unidades se inactivan.

```sql
CREATE TABLE unidades_medida (
  id                BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  codigo            VARCHAR(20)      NOT NULL          COMMENT 'Código corto único (ej. kg, ml, und). Inmutable si hay items asignados.',
  nombre            VARCHAR(100)     NOT NULL          COMMENT 'Nombre completo (ej. Kilogramo, Mililitro)',
  tipo_medida       ENUM(
                      'peso',
                      'volumen',
                      'unidad'
                    )                NOT NULL          COMMENT 'Tipo de magnitud física. Área diferida a versión futura.',
  factor_conversion DECIMAL(12,4)    NOT NULL          COMMENT 'Unidades de la base equivalentes a 1 unidad de esta. Base: factor = 1.0000.',
  unidad_base       TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = unidad base del tipo (g, ml, und). Solo una por tipo.',
  activo            TINYINT(1)       NOT NULL DEFAULT 1,
  creado_en         DATETIME         NOT NULL,
  actualizado_en    DATETIME         NOT NULL,

  PRIMARY KEY (id),
  CONSTRAINT uq_unidades_medida_codigo UNIQUE (codigo),
  CONSTRAINT chk_unidades_medida_factor CHECK (factor_conversion > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

> **Nota MySQL**: La restricción `CHECK` es soportada desde MySQL 8.0.16. En versiones anteriores
> se valida a nivel de aplicación en el servicio Go.

**Índices adicionales**:

```sql
-- Listado agrupado por tipo con filtro por estado activo (consulta principal del catálogo)
CREATE INDEX ix_unidades_medida_tipo_activo ON unidades_medida (tipo_medida, activo);
```

**Reglas de integridad**:

| Regla | Validación |
|-------|------------|
| `factor_conversion > 0` | CHECK en BD (MySQL 8.0+) + aplicación |
| `factor_conversion = 1.0000` para unidades base | Solo a nivel aplicación |
| Una sola `unidad_base = 1` por tipo | Solo a nivel aplicación (on create) |
| `codigo` único en el sistema | Constraint `uq_unidades_medida_codigo` |
| `codigo` inmutable si la unidad está asignada a algún item | Solo a nivel aplicación |
| No DELETE físico | Solo a nivel aplicación; siempre `activo = 0` |
| La unidad base no puede inactivarse si hay unidades activas de su tipo | Solo a nivel aplicación |

---

## Seed de Datos Iniciales

Los datos seed se cargan mediante una migración separada para poder revertirse
independientemente de la estructura de la tabla.

### Unidades Base (factor = 1.0000, unidad_base = 1)

| codigo | nombre | tipo_medida | factor_conversion |
|--------|--------|-------------|-------------------|
| `g` | Gramo | peso | 1.0000 |
| `ml` | Mililitro | volumen | 1.0000 |
| `und` | Unidad | unidad | 1.0000 |

### Unidades Estándar de Gastronomía (unidad_base = 0)

| codigo | nombre | tipo_medida | factor_conversion | equivalencia |
|--------|--------|-------------|-------------------|--------------|
| `kg` | Kilogramo | peso | 1000.0000 | 1 kg = 1000 g |
| `t` | Tonelada | peso | 1000000.0000 | 1 t = 1 000 000 g |
| `mg` | Miligramo | peso | 0.0010 | 1 mg = 0.001 g |
| `L` | Litro | volumen | 1000.0000 | 1 L = 1000 ml |
| `dL` | Decilitro | volumen | 100.0000 | 1 dL = 100 ml |
| `cL` | Centilitro | volumen | 10.0000 | 1 cL = 10 ml |
| `docena` | Docena | unidad | 12.0000 | 1 docena = 12 und |
| `par` | Par | unidad | 2.0000 | 1 par = 2 und |
| `caja` | Caja | unidad | 24.0000 | 1 caja = 24 und |

---

## Migraciones

| Archivo | Descripción |
|---------|-------------|
| `NNNN_crear_tabla_unidades_medida.up.sql` | Crea tabla `unidades_medida` con índices |
| `NNNN_crear_tabla_unidades_medida.down.sql` | `DROP TABLE IF EXISTS unidades_medida` |
| `NNNN+1_seed_unidades_medida.up.sql` | Inserta 3 bases + 10 unidades estándar de gastronomía |
| `NNNN+1_seed_unidades_medida.down.sql` | `DELETE FROM unidades_medida WHERE codigo IN (...)` |

> `NNNN` debe ser el número correlativo siguiente al último archivo de migración en el proyecto.

---

## Diagrama de Relaciones

```text
unidades_medida                     items (007 — futuro)
  ├── id (PK)                         ├── id (PK)
  ├── codigo (UNIQUE)                 ├── unidad_id (FK → unidades_medida.id)
  ├── nombre                          └── ...
  ├── tipo_medida ENUM
  ├── factor_conversion DECIMAL(12,4)
  ├── unidad_base TINYINT(1)
  └── activo TINYINT(1)

  (Los módulos consumidores almacenan unidad_origen y cantidad_origen
  en sus propios registros transaccionales — ver RD-01 en research.md)
```

---

## Transiciones de Estado

```text
             ┌─────────────────────────────────────┐
  [crear]    │                                     │
──────────►  │  activo = 1                         │
             │  (aparece en selects del catálogo)  │
             │                                     │
             └──────────────────┬──────────────────┘
                                │  [inactivar]
                                │  Previa confirmación:
                                │  - admin acepta impacto sobre items
                                ▼
             ┌─────────────────────────────────────┐
             │  activo = 0                         │
             │  - No aparece en nuevas asignaciones│
             │  - Transacciones nuevas bloqueadas  │
             │    para items que la tenían como    │
             │    canónica (responsabilidad 007+)  │
             │  - Historial previo intacto         │
             └─────────────────────────────────────┘

  Restricciones de la unidad base (unidad_base = 1):
    - NO puede inactivarse mientras existan unidades activas del mismo tipo
    - NO puede modificarse su factor_conversion (siempre 1.0000)
    - NO puede modificarse su codigo ni tipo_medida
```

---

## Función de Conversión

La lógica de conversión no vive en la tabla sino en el paquete
`internal/conversion/` del backend. Ver [research.md RD-02](research.md) y
[research.md RD-05](research.md) para los detalles de implementación.

**Fórmula**:

```text
cantidad_resultado = cantidad_origen × (factor_origen / factor_destino)
```

**Ejemplo verificable** (escenario de prueba HU4):

```text
Item "Harina": unidad canónica = g (factor = 1.0000)
Compra: 2 kg (factor kg = 1000.0000)

cantidad_resultado = 2 × (1000.0000 / 1.0000) = 2000.0000 g ✅
```
