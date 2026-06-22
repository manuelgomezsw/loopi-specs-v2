# Quickstart: 005-categorias-catalogo

**Prerrequisitos**: tener desplegada y funcionando la feature `001-autenticacion`.
Esta feature no depende de 002, 003 ni 004.

---

## 1. Aplicar migraciones de base de datos

```bash
# Desde la raíz de loopi-api-v2
migrate -path ./db/migrations -database "$DB_DSN" up
```

Migraciones nuevas en esta feature:

- `NNNN_crear_tabla_categorias.up.sql` — crea la tabla con índices y constraints
- `NNNN+1_crear_tabla_subcategorias.up.sql` — crea la tabla con índices y constraints

Verificar:

```sql
SHOW TABLES LIKE 'categorias';
SHOW TABLES LIKE 'subcategorias';

DESCRIBE categorias;
-- Esperado: id, nombre, activo, creado_por, creado_en, actualizado_por, actualizado_en

DESCRIBE subcategorias;
-- Esperado: id, nombre, categoria_id, activo, creado_por, creado_en, actualizado_por, actualizado_en

-- Verificar índices únicos
SHOW INDEX FROM categorias WHERE Key_name = 'uq_categorias_nombre';
SHOW INDEX FROM subcategorias WHERE Key_name = 'uq_subcategorias_nombre_categoria';
```

---

## 2. Ejecutar el backend (Go)

```bash
# Desde loopi-api-v2/
go run .
```

Variables de entorno requeridas (archivo `.env` local, no commitear):

```env
DB_DSN=user:pass@tcp(host:3306)/loopi_dev_nombre?parseTime=true&loc=America%2FBogota
JWT_SECRET=...
```

Verificar que Ristretto inicializa sin errores en los logs:

```json
{"level":"info","msg":"ristretto cache inicializado","modulo":"categorias","ttl_segundos":300}
```

---

## 3. Ejecutar el frontend (Angular)

```bash
# Desde loopi-web-v2/
ng serve
```

Navegar a: `http://localhost:4200/categorias`
(Solo accesible con sesión de `admin` activa.)

---

## 4. Smoke test manual

### 4.1 Crear categorías

```bash
# Obtener token admin
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"admin","contrasena":"xxx"}' | jq -r '.token')

# Crear categoría "Lácteo"
curl -s -X POST http://localhost:8080/api/v1/categorias \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Lácteo"}' | jq .
# Esperado: 201, id=1, activo=true, subcategorias=[]

# Intentar crear "lácteo" (duplicado case-insensitive) → 409
curl -s -X POST http://localhost:8080/api/v1/categorias \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"lácteo"}' | jq .error
# Esperado: "nombre_duplicado"

# Intentar acceso sin ser admin → 403
TOKEN_BARISTA=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"barista1","contrasena":"xxx"}' | jq -r '.token')

curl -s -X POST http://localhost:8080/api/v1/categorias \
  -H "Authorization: Bearer $TOKEN_BARISTA" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Verdura"}' | jq .error
# Esperado: "sin_permiso"
```

### 4.2 Crear subcategorías

```bash
# Crear subcategoría "Quesos" en Lácteo (id=1)
curl -s -X POST http://localhost:8080/api/v1/subcategorias \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Quesos","categoria_id":1}' | jq .
# Esperado: 201, id=1, categoria_id=1, activo=true

# Crear "Cremas" en Lácteo
curl -s -X POST http://localhost:8080/api/v1/subcategorias \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Cremas","categoria_id":1}' | jq .
# Esperado: 201, id=2

# Intentar duplicado "quesos" en misma categoría → 409
curl -s -X POST http://localhost:8080/api/v1/subcategorias \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"quesos","categoria_id":1}' | jq .error
# Esperado: "nombre_duplicado"

# Crear otra categoría y verificar que "Quesos" puede existir en ella también
curl -s -X POST http://localhost:8080/api/v1/categorias \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Verdura"}' | jq .id
# Esperado: 2

curl -s -X POST http://localhost:8080/api/v1/subcategorias \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Quesos","categoria_id":2}' | jq .
# Esperado: 201 — OK porque es diferente categoría
```

### 4.3 Consultar catálogo completo

```bash
curl -s http://localhost:8080/api/v1/categorias \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: 2 categorías, Lácteo con 2 subcategorías, Verdura con 1

# Filtrar solo activos
curl -s "http://localhost:8080/api/v1/categorias?activo=true" \
  -H "Authorization: Bearer $TOKEN" | jq '.total'
# Esperado: 2
```

### 4.4 Flujo de inactivación con cascade

```bash
# Consultar impacto antes de inactivar
curl -s http://localhost:8080/api/v1/categorias/1/impacto \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: { "subcategorias_activas": 2 }

# Inactivar categoría Lácteo (inactiva también Quesos y Cremas)
curl -s -X PATCH http://localhost:8080/api/v1/categorias/1/inactivar \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: 200, activo=false, subcategorias_inactivadas=2

# Verificar que Quesos está inactiva
curl -s http://localhost:8080/api/v1/categorias/1 \
  -H "Authorization: Bearer $TOKEN" | jq '.subcategorias[].activo'
# Esperado: false, false

# Intentar crear subcategoría bajo categoría inactiva → 422
curl -s -X POST http://localhost:8080/api/v1/subcategorias \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Mantequilla","categoria_id":1}' | jq .error
# Esperado: "categoria_padre_inactiva"
```

### 4.5 Flujo de reactivación

```bash
# Reactivar categoría Lácteo (subcategorías siguen inactivas)
curl -s -X PATCH http://localhost:8080/api/v1/categorias/1/reactivar \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: 200, activo=true

# Verificar que subcategorías siguen inactivas
curl -s http://localhost:8080/api/v1/categorias/1 \
  -H "Authorization: Bearer $TOKEN" | jq '.subcategorias[].activo'
# Esperado: false, false  ← NO se reactivaron automáticamente

# Reactivar subcategoría "Quesos" (id=1)
curl -s -X PATCH http://localhost:8080/api/v1/subcategorias/1/reactivar \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: 200, activo=true

# Intentar reactivar subcategoría de una categoría inactiva → 422
# Primero inactivar Verdura (id=2)
curl -s -X PATCH http://localhost:8080/api/v1/categorias/2/inactivar \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: 200, subcategorias_inactivadas=1

# Intentar reactivar subcategoría de Verdura (id=3)
curl -s -X PATCH http://localhost:8080/api/v1/subcategorias/3/reactivar \
  -H "Authorization: Bearer $TOKEN" | jq .error
# Esperado: "categoria_padre_inactiva"
```

---

## 5. Ejecutar tests

```bash
# Desde loopi-api-v2/
go test ./internal/categorias/... -v

# Con cobertura
go test ./internal/categorias/... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

### Tests mínimos requeridos (P1)

| Test | Qué verifica |
|------|-------------|
| `TestCrearCategoriaNombreDuplicadoCaseInsensitive` | Error 409 con "lácteo" = "Lácteo" |
| `TestCrearSubcategoriaNombreDuplicadoMismaCat` | Error 409 dentro de la misma categoría |
| `TestCrearSubcategoriasMismoNombreDistintasCat` | 201 — nombres repetidos entre categorías distintas son válidos |
| `TestCrearSubcategoriaCategoriaInactiva` | Error 422 categoria_padre_inactiva |
| `TestInactivarCategoriaConSubcatsActivasCascade` | Inactiva categoría y 2 subcategorías en transacción |
| `TestImpactoCategoriaConSubcatsActivas` | Retorna subcategorias_activas=2 |
| `TestReactivarCategoriaNoreactivaSubcats` | Subcategorías siguen inactivas tras reactivar el padre |
| `TestReactivarSubcatCategoriaPadreInactiva` | Error 422 categoria_padre_inactiva |
| `TestReactivarSubcatCategoriaPadreActiva` | 200 — reactivación exitosa |
| `TestAccesoSinAdminFallaEnEscritura` | Error 403 en POST/PUT/PATCH con rol no admin |
| `TestCacheInvalidacionEnCreate` | Caché se vacía tras crear categoría o subcategoría |
| `TestCacheInvalidacionEnInactivar` | Caché se vacía tras inactivar |

---

## 6. Rollback

```bash
# Revertir migraciones (en orden inverso)
migrate -path ./db/migrations -database "$DB_DSN" down 2
# Borra tabla subcategorias y luego tabla categorias
```
