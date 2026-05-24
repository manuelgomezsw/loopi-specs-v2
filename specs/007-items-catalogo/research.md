# Research: 007-items-catalogo

**Generado**: 2026-05-24
**Feature**: Items del Catálogo

---

## Decisiones Técnicas

### RD-01: Paginación del listado de items

**Decisión**: Paginación del lado del servidor con `LIMIT` / `OFFSET`. Página por defecto: 50
ítems. Los parámetros de query son `pagina` (1-based, default 1) y `por_pagina` (default 50,
máximo 200). La respuesta incluye `total`, `pagina` y `total_paginas`.

**Rationale**: La constitución establece paginación siempre del lado del servidor para
colecciones que puedan crecer ilimitadamente. A diferencia de categorías (< 120 registros
acotados por diseño), el catálogo de items puede alcanzar centenares de registros a medida
que el negocio crece. LIMIT/OFFSET es suficiente para este volumen; cursor pagination añade
complejidad sin beneficio hasta los millones de registros.

**Alternativas descartadas**:

- Sin paginación (igual que categorías): El catálogo de items es ilimitado por diseño. Si se
  aplicara la misma excepción que en 005, la query podría retornar cientos de filas con JOINs
  pesados. Descartado.
- Cursor pagination (keyset): Más eficiente para grandes volúmenes pero su implementación es
  significativamente más compleja. Innecesaria hasta superar los cientos de miles de registros.
  Descartado.

---

### RD-02: Estrategia de caché Ristretto para items

**Decisión**: Caché selectiva — NO se cachea el listado paginado (demasiadas variantes de
filtros), SÍ se cachean dos conjuntos de alta frecuencia:

1. **Item por ID** y **Item por código**: claves `"item:id:{id}"` y `"item:codigo:{codigo}"`,
   TTL 5 min. Usadas por módulos consumidores (inventario, recetas, pedidos).
2. **Items activos por frecuencia de inventario**: claves `"items:freq:diario"`,
   `"items:freq:semanal"`, `"items:freq:mensual"`. TTL 5 min. Son las consultas de mayor
   frecuencia del módulo 009-inventario al armar los conteos.

Invalidación total del módulo (`invalidarItems()`) en cualquier operación de escritura
(crear, editar, inactivar, reactivar, cambiar costo por tienda).

**Implementación**:

```go
// internal/items/cache.go

const (
    cacheTTL         = 5 * time.Minute
    keyItemByID      = "item:id:%d"
    keyItemByCodigo  = "item:codigo:%s"
    keyItemsFreqD    = "items:freq:diario"
    keyItemsFreqS    = "items:freq:semanal"
    keyItemsFreqM    = "items:freq:mensual"
)

func (s *Service) invalidarItems(itemID int64, codigo string) {
    s.cache.Del(fmt.Sprintf(keyItemByID, itemID))
    s.cache.Del(fmt.Sprintf(keyItemByCodigo, codigo))
    s.cache.Del(keyItemsFreqD)
    s.cache.Del(keyItemsFreqS)
    s.cache.Del(keyItemsFreqM)
}
```

**Rationale**: El listado paginado con filtros (tipo × frecuencia × estado) genera demasiadas
claves de caché distintas para ser útil. En cambio, las consultas "dame todos los items diarios
activos" son exactas, constantes y de alta frecuencia (una por conteo de inventario iniciado).
Cachear estas tres claves tiene impacto operativo real. El lookup por ID y por código es la
forma en que módulos consumidores acceden a los datos de un item individual.

**Alternativas descartadas**:

- Cachear el listado paginado completo: Demasiadas variantes (tipo, frecuencia, activo, página).
  La invalidación total en cualquier write haría el caché ineficiente. Descartado.
- Sin caché: Items son catálogo de lectura intensiva (constitución los menciona explícitamente
  como datos cacheables). Descartado.

---

### RD-03: Unicidad case-insensitive de código y nombre

**Decisión**:

- **Código**: UNIQUE constraint `uq_items_codigo` sobre la columna `codigo`.
  El código se almacena tal como el admin lo ingresa (ej. `CAF-001`). La unicidad es
  case-sensitive para el código (por convención de nomenclatura del negocio).
- **Nombre**: UNIQUE constraint `uq_items_nombre` sobre la columna `nombre`.
  La collation `utf8mb4_unicode_ci` de la tabla garantiza unicidad case-insensitive
  automáticamente, igual que en 005 y 006.

**Rationale**: El código tiene convención fija de mayúsculas (`CAF-001`), por lo que la
unicidad case-sensitive es correcta y deseable — `CAF-001` y `caf-001` serían codificaciones
incorrectas del mismo item, no items distintos. El nombre sigue el mismo patrón que categorías:
"Leche Entera" y "leche entera" no pueden coexistir.

**Alternativas descartadas**:

- Código case-insensitive: El negocio define que los códigos son siempre mayúsculas. No tiene
  sentido tratarlos como insensibles. Descartado.
- Validación en Go antes de persistir: No atómica ante concurrencia. La BD es la única fuente
  de verdad para la unicidad. Descartado.

---

### RD-04: Lock de código — verificación de "en uso"

**Decisión**: El `service.go` expone `estaEnUso(ctx, itemID) bool`, que verifica con
`EXISTS` queries si el item aparece en alguna de las tablas de módulos consumidores:
`inventarios_conteos_items`, `recetas_ingredientes`, `pedidos_lineas`. Mientras esas tablas
no existan (feature en construcción), la query retorna `false` sin error. La función usa
`IF EXISTS (SELECT table_name FROM information_schema.tables WHERE …)` para cada tabla,
haciendo la verificación segura ante tablas aún no creadas.

**Implementación de referencia**:

```go
// internal/items/service.go

func (s *Service) estaEnUso(ctx context.Context, itemID int64) (bool, error) {
    tables := []struct {
        tabla  string
        columna string
    }{
        {"inventarios_conteos_items", "item_id"},
        {"recetas_ingredientes", "item_id"},
        {"pedidos_lineas", "item_id"},
    }
    for _, t := range tables {
        var count int
        // Query segura: returns 0 if table doesn't exist yet
        query := fmt.Sprintf(`
            SELECT COUNT(*) FROM information_schema.tables
            WHERE table_schema = DATABASE() AND table_name = '%s'`, t.tabla)
        if err := s.db.QueryRowContext(ctx, query).Scan(&count); err != nil {
            return false, err
        }
        if count == 0 {
            continue // tabla no creada aún
        }
        var usado int
        usoQ := fmt.Sprintf(
            "SELECT COUNT(*) FROM %s WHERE %s = ? LIMIT 1", t.tabla, t.columna)
        if err := s.db.QueryRowContext(ctx, usoQ, itemID).Scan(&usado); err != nil {
            return false, err
        }
        if usado > 0 {
            return true, nil
        }
    }
    return false, nil
}
```

**Rationale**: Centralizar la lógica de "en uso" en el service de items evita que el handler
deba conocer detalles de otros módulos. La verificación dinámica vía `information_schema`
garantiza que la feature 007 pueda desplegarse antes que las features 008, 009 y 012 sin
código muerto ni errores. A medida que se crean las tablas referenciadas, la función las
detecta automáticamente.

**Alternativas descartadas**:

- Interfaz `ItemUsageChecker` inyectada en el service: Requiere que cada módulo implemente
  la interfaz y la registre en el contenedor de dependencias. Más correcto en teoría pero
  overkill para este caso; añade complejidad de wiring sin beneficio tangible en este
  stack de Go simple. Descartado.
- Hardcodear `return false` mientras las tablas no existen: Riesgo de olvidar actualizarlo
  al implementar las features consumidoras. Descartado en favor de la verificación dinámica.

---

### RD-05: Historial de costos por tienda — `items_costos_tienda`

**Decisión**: La tabla `items_costos_tienda` es **append-only**: cada vez que el admin
actualiza el costo de un item para una tienda específica, se inserta un nuevo registro con
`vigente_desde = NOW()`. El costo vigente para una tienda se obtiene con:

```sql
SELECT costo_unitario
FROM items_costos_tienda
WHERE item_id = ? AND tienda_id = ?
ORDER BY vigente_desde DESC
LIMIT 1;
```

Si no existe ningún registro para esa tienda, se usa el `Item.costo_unitario` (valor global
por defecto).

**Endpoint de escritura**: `POST /api/v1/items/{id}/costos_tienda` (requiere rol `admin`).
No existe un PUT/PATCH: siempre se inserta un nuevo registro histórico.

**Endpoint de lectura**: `GET /api/v1/items/{id}/costos_tienda` — retorna el historial
completo de cambios de costo por tienda, agrupado por tienda.

**Rationale**: El append-only preserva el historial completo sin necesidad de tablas de
auditoría adicionales. La consulta del costo vigente es O(1) con el índice
`ix_ict_item_tienda_vigente (item_id, tienda_id, vigente_desde)`. No se necesita un campo
`activo` ni `vigente_hasta` porque la temporalidad la determina el ordering por
`vigente_desde DESC LIMIT 1`.

**Alternativas descartadas**:

- Tabla con `activo` flag (última fila activa = costo vigente): Requiere UPDATE a la fila
  anterior al insertar la nueva. Más pasos, más riesgo de inconsistencia en concurrencia.
  Descartado.
- Tabla separada para "costo vigente" y "historial": Duplica datos y complica la consistencia.
  Descartado.

---

### RD-06: Auditoría — campos `creado_por` y `actualizado_por`

**Decisión**: Mismo patrón que 005-categorias-catalogo (RD-05 de esa feature). Los campos
son `BIGINT UNSIGNED NOT NULL` con FK a `usuarios.id`. Se extraen del JWT en el middleware
de autenticación y se inyectan en cada operación — nunca se reciben en el body del request.

La tabla `items_costos_tienda` solo tiene `creado_por` y `creado_en` (es append-only; no
hay actualización).

**Rationale**: Centralizar la extracción del `user_id` en el middleware garantiza que ningún
handler pueda omitir o falsificar el campo de auditoría. Patrón ya establecido en el proyecto.

---

## Dependencias Externas Confirmadas

| Paquete | Uso | Estado |
|---------|-----|--------|
| `go-sql-driver/mysql` | Driver MySQL | Ya en proyecto (desde 001) |
| `golang-migrate/migrate` | Migraciones BD | Ya en proyecto (desde 001) |
| `dgraph-io/ristretto` | Caché de catálogo en proceso | Ya en `go.mod` (desde 004) |
| JWT library | Extracción de `user_id` y `rol` | Ya en proyecto (desde 001) |
