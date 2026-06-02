# Research: 004-unidades-medida

**Generado**: 2026-05-24
**Feature**: Unidades de Medida y Tabla de Equivalencias

---

## Decisiones Técnicas

### RD-01: Estrategia de caché Ristretto para el catálogo de unidades

**Decisión**: Caché de lectura con Ristretto, TTL 5 minutos, invalidación total en cualquier
write (crear, editar, inactivar). Claves: `"um:all"`, `"um:id:{id}"`, `"um:tipo:{tipo}"`.

**Implementación**:

```go
// internal/unidades_medida/cache.go

const (
    cacheTTL       = 5 * time.Minute
    keyAll         = "um:all"
    keyByID        = "um:id:%d"
    keyByTipo      = "um:tipo:%s"
)

// InvalidarCatalogo borra todas las claves del módulo del caché.
// Se llama tras cada operación de escritura.
func (s *Service) invalidarCatalogo(id int64) {
    s.cache.Del(keyAll)
    s.cache.Del(fmt.Sprintf(keyByID, id))
    s.cache.Del(fmt.Sprintf(keyByTipo, "peso"))
    s.cache.Del(fmt.Sprintf(keyByTipo, "volumen"))
    s.cache.Del(fmt.Sprintf(keyByTipo, "unidad"))
}
```

**Rationale**: La constitución indica explícitamente "unidades de medida" como dato cacheable
de catálogo. Con ~13-100 unidades, el impacto en memoria es mínimo. La invalidación total
(no granular) simplifica la implementación y es segura dado el bajo volumen de writes en
este catálogo. TTL de 5 min es conservador — en una sesión activa, el catálogo se actualiza
raramente.

**Alternativas descartadas**:

- Sin caché: El catálogo se consulta en cada conversión automática de todos los módulos
  consumidores — O(N) reads por transacción. Inaceptable a escala. Descartado.
- Invalidación granular por ID: Mayor complejidad de código sin beneficio measurable para
  un catálogo pequeño. Descartado.
- Redis externo: Overkill para catálogo in-process; añadiría latencia de red en cada
  conversión. La constitución ya especifica Ristretto. Descartado.

---

### RD-02: Implementación del algoritmo de conversión en Go

**Decisión**: Función pura en `internal/conversion/conversion.go` usando `float64` para
cálculo intermedio, con redondeo a 4 decimales antes de retornar o persistir.

**Fórmula**: Dado que todos los factores son relativos a la unidad base del tipo:

```text
cantidad_resultado = cantidad_origen × (factor_origen / factor_destino)
```

Caso especial: conversión a unidad canónica del item (unidad base, factor = 1):

```text
cantidad_canonical = cantidad_origen × factor_origen
```

**Implementación**:

```go
// internal/conversion/conversion.go

import (
    "errors"
    "math"
)

var (
    ErrTipoIncompatible  = errors.New("no se puede convertir entre tipos de medida distintos")
    ErrFactorInvalido    = errors.New("el factor de conversión debe ser mayor que cero")
)

// Convertir convierte cantidad desde la unidad `desde` a la unidad `hacia`.
// Ambas unidades deben ser del mismo tipo_medida.
// El resultado se redondea a 4 decimales de precisión.
func Convertir(cantidad float64, desdeFactor float64, desdeTipo string,
               haciaFactor float64, haciaTipo string) (float64, error) {
    if desdeTipo != haciaTipo {
        return 0, ErrTipoIncompatible
    }
    if desdeFactor <= 0 || haciaFactor <= 0 {
        return 0, ErrFactorInvalido
    }
    resultado := cantidad * (desdeFactor / haciaFactor)
    // Redondear a 4 decimales para coincidir con DECIMAL(12,4) en BD
    return math.Round(resultado*10000) / 10000, nil
}
```

**Ejemplo de uso**:

```go
// 2 kg → gramos (factor kg=1000, factor g=1)
resultado, _ := conversion.Convertir(2.0, 1000.0, "peso", 1.0, "peso")
// resultado = 2000.0000

// 1.5 L → mililitros (factor L=1000, factor ml=1)
resultado, _ = conversion.Convertir(1.5, 1000.0, "volumen", 1.0, "volumen")
// resultado = 1500.0000
```

**Rationale**: `float64` de Go (IEEE 754 de 64 bits) tiene ~15-17 dígitos decimales
significativos — más que suficiente para las 4 posiciones decimales requeridas por
`DECIMAL(12,4)`. No se necesita una biblioteca de aritmética decimal exacta
(`shopspring/decimal`) ya que las conversiones gastronómicas no acumulan errores
significativos en este rango de precisión.

**Alternativas descartadas**:

- `shopspring/decimal`: Precisión decimal exacta pero añade una dependencia externa y
  latencia por ser una operación de alto nivel. La diferencia entre float64 y decimal
  exacto en este dominio es < 0.00001 — imperceptible para operaciones de inventario.
  Descartado.
- `int64` en microunidades base: Requiere escalar todos los factores a enteros, complica
  el modelo de datos y la API. Descartado.

---

### RD-03: Seed data mediante migración SQL

**Decisión**: Los datos iniciales del catálogo (3 unidades base + 10 unidades estándar) se
cargan mediante una migración SQL dedicada, separada de la migración de creación de tabla.

**Migración de seed** (`NNNN+1_seed_unidades_medida.up.sql`):

```sql
-- Unidades base (factor_conversion = 1, unidad_base = 1)
INSERT INTO unidades_medida
  (codigo, nombre, tipo_medida, factor_conversion, unidad_base, activo, creado_en, actualizado_en)
VALUES
  ('g',   'Gramo',      'peso',    1.0000, 1, 1, NOW(), NOW()),
  ('ml',  'Mililitro',  'volumen', 1.0000, 1, 1, NOW(), NOW()),
  ('und', 'Unidad',     'unidad',  1.0000, 1, 1, NOW(), NOW());

-- Unidades estándar de gastronomía
INSERT INTO unidades_medida
  (codigo, nombre, tipo_medida, factor_conversion, unidad_base, activo, creado_en, actualizado_en)
VALUES
  -- Peso
  ('kg',  'Kilogramo',  'peso',    1000.0000,    0, 1, NOW(), NOW()),
  ('t',   'Tonelada',   'peso',    1000000.0000, 0, 1, NOW(), NOW()),
  ('mg',  'Miligramo',  'peso',    0.0010,       0, 1, NOW(), NOW()),
  -- Volumen
  ('L',   'Litro',      'volumen', 1000.0000,    0, 1, NOW(), NOW()),
  ('dL',  'Decilitro',  'volumen', 100.0000,     0, 1, NOW(), NOW()),
  ('cL',  'Centilitro', 'volumen', 10.0000,      0, 1, NOW(), NOW()),
  -- Unidad
  ('docena', 'Docena',  'unidad',  12.0000,      0, 1, NOW(), NOW()),
  ('par',    'Par',     'unidad',  2.0000,       0, 1, NOW(), NOW()),
  ('caja',   'Caja',    'unidad',  24.0000,      0, 1, NOW(), NOW());
```

**Rationale**: Separar la creación de tabla de los datos de seed permite hacer `down` de los
datos sin afectar la estructura. Es el patrón estándar con `golang-migrate`. Los datos seed
son deterministas y reproducibles en cualquier ambiente (dev, stage, prod).

**Alternativas descartadas**:

- Seed en código Go (runtime seeding): No determinista, requiere lógica de "ya existe",
  difícil de auditar. Descartado.
- Seed embebido en la misma migración de tabla: Hace el `down` más complejo y combina dos
  responsabilidades en una migración. Descartado.

---

### RD-04: Patrón de confirmación previa a inactivación

**Decisión**: Endpoint `GET /api/v1/unidades_medida/{id}/impacto` que retorna cuántos items
usan esta unidad como canónica. El frontend llama a este endpoint, muestra la confirmación
al usuario con ese conteo, y solo entonces invoca `PATCH .../inactivar`. El backend no
requiere un flag `confirmar` — la responsabilidad de mostrar el diálogo está en el frontend.

**Flujo**:

```text
Admin hace clic en "Inactivar unidad X"
  → Frontend llama GET /api/v1/unidades_medida/{id}/impacto
  → Backend responde: { "items_con_unidad_canonica": N }
  → Si N > 0: frontend muestra modal de confirmación con el texto del spec
  → Si N = 0: frontend puede inactivar directamente (sin modal, o con modal simplificado)
  → Admin confirma → Frontend llama PATCH /api/v1/unidades_medida/{id}/inactivar
  → Backend inactiva y retorna 200
```

**Query del endpoint `/impacto`** (cuando la tabla `items` exista en 007):

```sql
-- Retorna 0 si la tabla items no existe aún (graceful degradation)
SELECT COUNT(*) FROM items WHERE unidad_id = ? AND activo = 1;
```

**Nota de implementación**: En fase inicial (antes de 007-items-catalogo), el endpoint
`/impacto` retorna `{ "items_con_unidad_canonica": 0 }` ya que la tabla `items` no existe.
La verificación real se activa cuando 007 agrega la FK `unidad_id` en `items`.

**Rationale**: Desacopla la lógica de confirmación del servidor — el servidor no necesita
saber si el usuario ya leyó la advertencia. El estado de los items es información de
lectura, no un prerrequisito de escritura. Este patrón es más robusto que un flag
`confirmar: true` que podría ser enviado sin mostrar el diálogo al usuario.

**Alternativas descartadas**:

- Flag `{ "confirmar": true }` en body de PATCH: Permite saltarse la confirmación en el
  frontend; no agrega seguridad real. Descartado.
- Pre-check en el mismo PATCH y retornar 409 si hay items: Requiere dos llamadas de todas
  formas y complica el handler. Descartado.

---

### RD-05: Ubicación del paquete de conversión

**Decisión**: Función de conversión en paquete propio `internal/conversion/` para que
todos los módulos consumidores (recetas, compras, recepción) la importen directamente.

**Interfaz pública del paquete**:

```go
// internal/conversion/conversion.go
package conversion

// Convertir convierte cantidad desde unidad con factorDesde al tipo tipoMedida
// hacia unidad con factorHacia del mismo tipo.
// Retorna ErrTipoIncompatible si los tipos no coinciden.
// Retorna ErrFactorInvalido si algún factor es <= 0.
func Convertir(cantidad, factorDesde float64, tipoDesde string,
               factorHacia float64, tipoHacia string) (float64, error)

// EsCompatible retorna true si ambas unidades son del mismo tipo_medida.
func EsCompatible(tipo1, tipo2 string) bool
```

**Rationale**: Centralizar la lógica de conversión en un único paquete garantiza que todos
los módulos usen exactamente el mismo algoritmo y manejo de errores. Evita duplicación y
discrepancias entre módulos. Al ser una función pura (sin I/O), es trivialmente testeable.

**Alternativas descartadas**:

- Duplicar la lógica en cada módulo consumidor: Riesgo de divergencia entre implementaciones.
  Descartado.
- Método en el struct `UnidadMedida`: Acoplaría el paquete `unidades_medida` a todos los
  módulos consumidores vía import circular potencial. Descartado.

---

## Dependencias Externas Confirmadas

| Paquete | Uso | Estado |
|---------|-----|--------|
| `go-sql-driver/mysql` | Driver MySQL | Ya en proyecto (desde 001) |
| `golang-migrate/migrate` | Migraciones BD | Ya en proyecto (desde 001) |
| `dgraph-io/ristretto` | Caché de catálogo en proceso | Requiere add a `go.mod` |
| JWT library | Extracción de claims (middleware) | Ya en proyecto (desde 001) |
