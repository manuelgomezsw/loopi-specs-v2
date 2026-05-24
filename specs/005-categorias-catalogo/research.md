# Research: 005-categorias-catalogo

**Generado**: 2026-05-24
**Feature**: Categorías y Subcategorías del Catálogo

---

## Decisiones Técnicas

### RD-01: Estrategia de caché Ristretto para el catálogo de categorías

**Decisión**: Caché de lectura con Ristretto, TTL 5 minutos, invalidación total en cualquier
write (crear, editar, inactivar, reactivar). Claves: `"cat:all"`, `"cat:id:{id}"`,
`"subcat:all"`, `"subcat:categoria:{id}"`, `"subcat:id:{id}"`.

**Implementación**:

```go
// internal/categorias/cache.go

const (
    cacheTTL              = 5 * time.Minute
    keyCatAll             = "cat:all"
    keyCatByID            = "cat:id:%d"
    keySubcatAll          = "subcat:all"
    keySubcatByCategoria  = "subcat:categoria:%d"
    keySubcatByID         = "subcat:id:%d"
)

// invalidarCatalogo borra todas las claves del módulo del caché.
// Se llama tras cada operación de escritura sobre categorías o subcategorías.
func (s *Service) invalidarCatalogo(categoriaID, subcatID int64) {
    s.cache.Del(keyCatAll)
    if categoriaID > 0 {
        s.cache.Del(fmt.Sprintf(keyCatByID, categoriaID))
        s.cache.Del(fmt.Sprintf(keySubcatByCategoria, categoriaID))
    }
    if subcatID > 0 {
        s.cache.Del(fmt.Sprintf(keySubcatByID, subcatID))
    }
    s.cache.Del(keySubcatAll)
}
```

**Rationale**: La constitución indica "items, unidades de medida, parámetros globales del
algoritmo" como datos cacheables de catálogo. Las categorías tienen exactamente el mismo
perfil: datos de baja volatilidad, consulta intensiva (cada formulario de creación/edición
de items necesita la lista de subcategorías). Con < 120 registros, el impacto en memoria
es despreciable. TTL de 5 min es conservador y consistente con RD-01 de 004.

**Alternativas descartadas**:

- Sin caché: Consulta a BD en cada render de un formulario de item — O(1) pero de alta
  frecuencia. Inaceptable a medida que el número de tiendas crece. Descartado.
- Redis externo: Overkill, añade latencia de red y complejidad operacional. La constitución
  ya especifica Ristretto. Descartado.
- Invalidación granular por ID solamente: Riesgo de inconsistencia en la vista de árbol
  (categoría + subcategorías deben verse siempre en estado coherente). Descartado a favor
  de invalidación total, que es segura para este volumen.

---

### RD-02: Validación case-insensitive de nombres via collation MySQL

**Decisión**: Usar la collation `utf8mb4_unicode_ci` (ya el default del proyecto) en las
tablas `categorias` y `subcategorias`. El UNIQUE constraint sobre `nombre` en `categorias`
y el UNIQUE compuesto `(categoria_id, nombre)` en `subcategorias` son automáticamente
case-insensitive con esta collation, sin lógica adicional en Go ni en los queries.

**Comportamiento verificado**:

```sql
-- Con utf8mb4_unicode_ci, estas dos INSERTs violan el constraint UNIQUE:
INSERT INTO categorias (nombre, ...) VALUES ('Lácteo', ...);
INSERT INTO categorias (nombre, ...) VALUES ('lácteo', ...);
-- ERROR 1062: Duplicate entry 'lácteo' for key 'uq_categorias_nombre'

-- Lo mismo aplica a subcategorías dentro de la misma categoría:
INSERT INTO subcategorias (categoria_id, nombre, ...) VALUES (1, 'Quesos', ...);
INSERT INTO subcategorias (categoria_id, nombre, ...) VALUES (1, 'quesos', ...);
-- ERROR 1062: Duplicate entry '1-quesos' for key 'uq_subcategorias_nombre_categoria'
```

**Rationale**: Delegar la validación de unicidad case-insensitive a la BD es más robusto
que hacerlo en Go, ya que es atómica y no hay condiciones de carrera entre dos requests
concurrentes que intenten crear el mismo nombre simultáneamente. La collation `_ci` (case
insensitive) de MySQL también maneja correctamente caracteres Unicode con tilde (Lácteo =
LÁCTEO = lácteo). Ambas tablas se crean con `COLLATE=utf8mb4_unicode_ci`, que es el
estándar ya establecido en el proyecto.

**Alternativas descartadas**:

- Normalizar a minúsculas en Go antes de persistir: Pierde la capitalización original
  del usuario ("Lácteo" se guardaría como "lácteo"). El admin vería sus propios datos
  distorsionados. Descartado.
- `LOWER()` en la query de validación (`SELECT ... WHERE LOWER(nombre) = LOWER(?)`):
  No puede usar el índice UNIQUE del constraint; requiere full table scan. Descartado.

---

### RD-03: Patrón de confirmación y cascade para inactivación de categoría

**Decisión**: Endpoint `GET /api/v1/categorias/{id}/impacto` que retorna el número de
subcategorías activas. El frontend llama a este endpoint, muestra el modal de confirmación
si hay subcategorías activas, y solo entonces llama `PATCH .../inactivar`. El backend
inactiva la categoría y todas sus subcategorías activas en una única transacción.

**Flujo**:

```text
Admin hace clic en "Inactivar categoría X"
  → Frontend llama GET /api/v1/categorias/{id}/impacto
  → Backend responde: { "subcategorias_activas": N }
  → Si N > 0: modal "Esta categoría tiene N subcategoría(s) activa(s).
               Al inactivarla, todas quedarán inactivas. ¿Confirmar?"
  → Si N = 0: no muestra modal (o uno simplificado)
  → Admin confirma → Frontend llama PATCH /api/v1/categorias/{id}/inactivar
  → Backend ejecuta transacción:
       UPDATE categorias SET activo=0, actualizado_por=?, actualizado_en=NOW() WHERE id=?
       UPDATE subcategorias SET activo=0, actualizado_por=?, actualizado_en=NOW()
              WHERE categoria_id=? AND activo=1
  → Retorna 200 con el estado actualizado
```

**Query de impacto**:

```sql
SELECT COUNT(*) AS subcategorias_activas
FROM subcategorias
WHERE categoria_id = ? AND activo = 1;
```

**Rationale**: Mismo patrón que RD-04 de 004-unidades-medida. El servidor no necesita
saber si el usuario ya leyó la advertencia — la responsabilidad de mostrar el diálogo es
del frontend. Esto es más robusto que un flag `confirmar` en el body, que podría
enviarse sin mostrar el diálogo. La transacción garantiza que la categoría y sus
subcategorías se inactivan atómicamente.

**Alternativas descartadas**:

- Flag `{ "confirmar": true }` en body de PATCH: Permite saltarse la confirmación. Sin
  valor de seguridad real. Descartado.
- ON DELETE CASCADE en MySQL (adaptado a soft delete): MySQL no soporta triggers de
  actualización automática de `activo`. Requeriría triggers DB complejos vs. lógica
  clara en Go. Descartado.

---

### RD-04: Comportamiento de reactivación de categoría padre

**Decisión**: Al reactivar una categoría, solo se activa la categoría misma. Las
subcategorías que fueron inactivadas (ya sea antes de la inactivación de la categoría,
por cascade, o en cualquier otro momento) permanecen inactivas y deben reactivarse
individualmente. El endpoint `PATCH /api/v1/categorias/{id}/reactivar` verifica que
la categoría esté inactiva antes de proceder.

Para reactivar una subcategoría, el endpoint `PATCH /api/v1/subcategorias/{id}/reactivar`
verifica que la **categoría padre esté activa**. Si la categoría padre está inactiva,
el sistema rechaza la reactivación con `422 categoria_padre_inactiva`.

**Flujo de reactivación de subcategoría**:

```text
Admin hace clic en "Reactivar subcategoría Y"
  → Backend verifica: ¿categoria_id de Y está activa?
  → Si la categoría padre está inactiva → 422 categoria_padre_inactiva
  → Si la categoría padre está activa →
       UPDATE subcategorias SET activo=1, actualizado_por=?, actualizado_en=NOW()
              WHERE id=?
  → Retorna 200
```

**Rationale**: Este comportamiento está definido explícitamente en la spec (RF-CAT-01.7
y escenario 4 de HU4). La reactivación selectiva preserva el control granular del admin:
el cascade de inactivación no se revierte automáticamente al reactivar el padre, evitando
restauraciones accidentales de subcategorías que quizá ya no son relevantes. La validación
de categoría padre activa en la reactivación de subcategoría evita estados inconsistentes
(subcategoría activa bajo categoría inactiva).

**Alternativas descartadas**:

- Reactivar cascade (categoría + todas sus subcategorías inactivas): Elimina el control
  granular del admin; podría restaurar subcategorías que el admin quería mantener
  inactivas. Descartado.
- Permitir reactivar una subcategoría aunque la categoría padre esté inactiva: Crea un
  estado inconsistente donde una subcategoría activa no aparecería en el catálogo porque
  su padre está inactivo. Confuso para el admin y para los módulos consumidores. Descartado.

---

### RD-05: Auditoría — campos creado_por y actualizado_por

**Decisión**: Los campos `creado_por` y `actualizado_por` son `BIGINT UNSIGNED NOT NULL`
con FK a `usuarios.id`. Se extraen del JWT en el middleware de autenticación y se
inyectan automáticamente en cada operación — nunca se reciben en el body del request.

**Extracción en el handler**:

```go
// El middleware de auth inyecta los claims en el contexto
userID := middleware.UserIDFromContext(ctx)

// En el service, se pasan como parámetros explícitos
repo.CrearCategoria(ctx, nombre, userID)
repo.ActualizarCategoria(ctx, id, nuevoNombre, userID)
repo.InactivarCategoria(ctx, id, userID)
```

**Rationale**: Centralizar la extracción del `user_id` en el middleware garantiza que
ningún handler pueda omitir o falsificar el campo de auditoría. Al no enviar el
`creado_por`/`actualizado_por` en el request body, se elimina el riesgo de que un
cliente malicioso inyecte un ID de usuario arbitrario. Consistente con el patrón de
auditoría establecido en el proyecto.

**Alternativas descartadas**:

- `creado_por` en el request body: Permite al cliente enviar cualquier `user_id`.
  Viola el principio de prevención de fraude. Descartado.
- Campos de auditoría opcionales (solo `creado_en`/`actualizado_en`): Insuficiente
  para diagnóstico. La spec clarificó explícitamente que se necesita quién + cuándo.
  Descartado.

---

## Dependencias Externas Confirmadas

| Paquete | Uso | Estado |
|---------|-----|--------|
| `go-sql-driver/mysql` | Driver MySQL | Ya en proyecto (desde 001) |
| `golang-migrate/migrate` | Migraciones BD | Ya en proyecto (desde 001) |
| `dgraph-io/ristretto` | Caché de catálogo en proceso | Ya en `go.mod` (desde 004) |
| JWT library | Extracción de `user_id` y `rol` | Ya en proyecto (desde 001) |
