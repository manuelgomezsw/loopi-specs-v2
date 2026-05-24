# Quickstart: 004-unidades-medida

**Prerrequisitos**: tener desplegada y funcionando la feature `001-autenticacion`.
Esta feature no depende de 002 ni 003.

---

## 1. Aplicar migraciones de base de datos

```bash
# Desde la raíz de loopi-api-v2
migrate -path ./db/migrations -database "$DB_DSN" up
```

Migraciones nuevas en esta feature:

- `NNNN_crear_tabla_unidades_medida.up.sql` — crea la tabla con índices
- `NNNN+1_seed_unidades_medida.up.sql` — inserta 3 bases + 10 unidades estándar

Verificar:

```sql
SHOW TABLES LIKE 'unidades_medida';
DESCRIBE unidades_medida;

-- Debe retornar 13 registros
SELECT COUNT(*) FROM unidades_medida;

-- Verificar unidades base (factor = 1, unidad_base = 1)
SELECT codigo, nombre, tipo_medida, factor_conversion
FROM unidades_medida
WHERE unidad_base = 1
ORDER BY tipo_medida;
-- Esperado: g (peso), ml (volumen), und (unidad)
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
{"level":"info","msg":"ristretto cache inicializado","modulo":"unidades_medida","ttl_segundos":300}
```

---

## 3. Ejecutar el frontend (Angular)

```bash
# Desde loopi-web-v2/
ng serve
```

Navegar a: `http://localhost:4200/unidades-medida`
(Solo accesible con sesión de `admin` activa.)

---

## 4. Smoke test manual

### 4.1 Consultar catálogo inicial

```bash
# Obtener token admin
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"admin","contrasena":"xxx"}' | jq -r '.token')

# Listar todas las unidades
curl -s "http://localhost:8080/api/v1/unidades_medida" \
  -H "Authorization: Bearer $TOKEN" | jq '.total, .unidades_medida[].codigo'
# Esperado: 13, seguido de: "g", "ml", "und", "kg", "t", "mg", "L", "dL", "cL", "docena", "par", "caja"

# Filtrar por tipo
curl -s "http://localhost:8080/api/v1/unidades_medida?tipo=peso" \
  -H "Authorization: Bearer $TOKEN" | jq '.total'
# Esperado: 4 (g, mg, kg, t)
```

### 4.2 Crear unidad nueva

```bash
# Crear unidad oz (onza)
curl -s -X POST "http://localhost:8080/api/v1/unidades_medida" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"codigo":"oz","nombre":"Onza","tipo_medida":"peso","factor_conversion":28.3495}' | jq .
# Esperado: 201, id=14 (o siguiente disponible), factor_conversion=28.3495

# Intentar crear con código duplicado → 409
curl -s -X POST "http://localhost:8080/api/v1/unidades_medida" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"codigo":"kg","nombre":"KiloGramo","tipo_medida":"peso","factor_conversion":1000}' | jq .
# Esperado: 409 codigo_duplicado

# Intentar crear con factor_conversion=0 → 422
curl -s -X POST "http://localhost:8080/api/v1/unidades_medida" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"codigo":"xxx","nombre":"Prueba","tipo_medida":"peso","factor_conversion":0}' | jq .
# Esperado: 422 factor_invalido
```

### 4.3 Verificar conversión automática (función pura)

```bash
# Ejecutar test unitario de conversión
cd loopi-api-v2
go test ./internal/conversion/... -v -run TestConvertir
# Esperado: 2 kg → 2000 g (PASS), tipos incompatibles → error (PASS)
```

### 4.4 Inactivar unidad (flujo completo)

```bash
# Consultar impacto antes de inactivar
ID_OZ=$(curl -s "http://localhost:8080/api/v1/unidades_medida?tipo=peso" \
  -H "Authorization: Bearer $TOKEN" | jq '.unidades_medida[] | select(.codigo=="oz") | .id')

curl -s "http://localhost:8080/api/v1/unidades_medida/$ID_OZ/impacto" \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: items_con_unidad_canonica=0, advertencia=null (007 no existe aún)

# Inactivar
curl -s -X PATCH "http://localhost:8080/api/v1/unidades_medida/$ID_OZ/inactivar" \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: 200, activo=false

# Intentar inactivar la unidad base 'g' → 422
ID_G=$(curl -s "http://localhost:8080/api/v1/unidades_medida?tipo=peso" \
  -H "Authorization: Bearer $TOKEN" | jq '.unidades_medida[] | select(.codigo=="g") | .id')

curl -s -X PATCH "http://localhost:8080/api/v1/unidades_medida/$ID_G/inactivar" \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: 422 unidad_base_no_inactivable

# Intentar acceso sin token → 401
curl -s "http://localhost:8080/api/v1/unidades_medida" | jq .error
# Esperado: "no_autenticado"
```

---

## 5. Ejecutar tests

```bash
# Desde loopi-api-v2/
go test ./internal/unidades_medida/... ./internal/conversion/... -v

# Con cobertura
go test ./internal/unidades_medida/... ./internal/conversion/... \
  -coverprofile=coverage.out
go tool cover -html=coverage.out
```

### Tests mínimos requeridos (P1)

| Test | Qué verifica |
|------|-------------|
| `TestCrearUnidadCodigoDuplicado` | Error 409 |
| `TestCrearUnidadFactorCero` | Error 422 factor_invalido |
| `TestEditarCodigoEnUso` | Error 422 cuando hay items asignados (mock) |
| `TestEditarFactorUnidadBase` | Error 422 factor_base_inmutable |
| `TestInactivarUnidadBase` | Error 422 unidad_base_no_inactivable |
| `TestConvertirKgAGramos` | 2.0 kg → 2000.0000 g |
| `TestConvertirTiposIncompatibles` | Error ErrTipoIncompatible |
| `TestConvertirFactorCero` | Error ErrFactorInvalido |
| `TestCacheInvalidacionEnCreate` | Caché se vacía tras crear unidad |
| `TestCacheInvalidacionEnInactivar` | Caché se vacía tras inactivar |
| `TestListarPorTipoPeso` | Retorna solo unidades de tipo peso |
| `TestAccesoSinAdminFalla` | Error 403 en POST/PUT/PATCH sin rol admin |

---

## 6. Rollback

```bash
# Revertir migraciones (en orden inverso)
migrate -path ./db/migrations -database "$DB_DSN" down 2
# Borra seed y luego la tabla unidades_medida
```
