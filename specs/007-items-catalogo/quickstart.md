# Quickstart: 007-items-catalogo

**Prerrequisitos**: tener desplegadas y funcionando las features
`001-autenticacion`, `004-unidades-medida`, `005-categorias-catalogo` y
`006-proveedores-catalogo`. El catálogo de items referencia subcategorías, unidades
de medida y proveedores activos.

---

## 1. Aplicar migraciones de base de datos

```bash
# Desde la raíz de loopi-api-v2
migrate -path ./db/migrations -database "$DB_DSN" up
```

Migraciones nuevas en esta feature:

- `NNNN_crear_tabla_items.up.sql` — crea la tabla con índices y constraints
- `NNNN+1_crear_tabla_items_costos_tienda.up.sql` — crea la tabla de historial de costos

Verificar:

```sql
SHOW TABLES LIKE 'items';
SHOW TABLES LIKE 'items_costos_tienda';

DESCRIBE items;
-- Esperado: id, codigo, nombre, tipo, subcategoria_id, proveedor_id, unidad_medida_id,
--           costo_unitario, frecuencia_inventario, stock_seguridad, tiempo_entrega_dias,
--           activo, creado_por, creado_en, actualizado_por, actualizado_en

DESCRIBE items_costos_tienda;
-- Esperado: id, item_id, tienda_id, costo_unitario, vigente_desde, creado_por, creado_en

-- Verificar índices únicos
SHOW INDEX FROM items WHERE Key_name = 'uq_items_codigo';
SHOW INDEX FROM items WHERE Key_name = 'uq_items_nombre';
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
{"level":"info","msg":"ristretto cache inicializado","modulo":"items","ttl_segundos":300}
```

---

## 3. Ejecutar el frontend (Angular)

```bash
# Desde loopi-web-v2/
ng serve
```

Navegar a: `http://localhost:4200/items`
(Solo accesible con sesión de `admin` activa.)

---

## 4. Smoke test manual

### 4.1 Crear items

```bash
# Obtener token admin
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"admin","contrasena":"xxx"}' | jq -r '.token')

# Crear item "Leche Entera" (requiere subcategoria_id=3, unidad_medida_id=5 existentes)
curl -s -X POST http://localhost:8080/api/v1/items \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo": "LEC-001",
    "nombre": "Leche Entera",
    "tipo": "insumo",
    "subcategoria_id": 3,
    "unidad_medida_id": 5,
    "costo_unitario": 3200,
    "frecuencia_inventario": "diario",
    "stock_seguridad": "10000.0000"
  }' | jq .
# Esperado: 201, id=1, activo=true, esta_en_uso=false

# Intentar código duplicado "LEC-001" → 409
curl -s -X POST http://localhost:8080/api/v1/items \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo": "LEC-001",
    "nombre": "Otro item",
    "tipo": "insumo",
    "subcategoria_id": 3,
    "unidad_medida_id": 5,
    "frecuencia_inventario": "semanal",
    "stock_seguridad": "0.0000"
  }' | jq .error
# Esperado: "codigo_duplicado"

# Intentar nombre duplicado case-insensitive "leche entera" → 409
curl -s -X POST http://localhost:8080/api/v1/items \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo": "LEC-002",
    "nombre": "leche entera",
    "tipo": "insumo",
    "subcategoria_id": 3,
    "unidad_medida_id": 5,
    "frecuencia_inventario": "diario",
    "stock_seguridad": "5000.0000"
  }' | jq .error
# Esperado: "nombre_duplicado"

# Intentar acceso con rol no admin → 403
TOKEN_BARISTA=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"barista1","contrasena":"xxx"}' | jq -r '.token')

curl -s -X POST http://localhost:8080/api/v1/items \
  -H "Authorization: Bearer $TOKEN_BARISTA" \
  -H "Content-Type: application/json" \
  -d '{"codigo":"CAF-999","nombre":"Test","tipo":"insumo","subcategoria_id":3,"unidad_medida_id":5,"frecuencia_inventario":"diario","stock_seguridad":"0"}' \
  | jq .error
# Esperado: "sin_permiso"
```

### 4.2 Consultar y editar

```bash
# Listar todos los items activos
curl -s "http://localhost:8080/api/v1/items?activo=true" \
  -H "Authorization: Bearer $TOKEN" | jq '{total, total_paginas}'
# Esperado: al menos 1 item

# Filtrar por tipo insumo
curl -s "http://localhost:8080/api/v1/items?tipo=insumo&activo=true" \
  -H "Authorization: Bearer $TOKEN" | jq '.items[0].tipo'
# Esperado: "insumo"

# Detalle del item (id=1) — verificar esta_en_uso=false
curl -s http://localhost:8080/api/v1/items/1 \
  -H "Authorization: Bearer $TOKEN" | jq '{codigo, esta_en_uso}'
# Esperado: { "codigo": "LEC-001", "esta_en_uso": false }

# Editar código mientras no está en uso → OK
curl -s -X PUT http://localhost:8080/api/v1/items/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo": "LEC-001-V2",
    "nombre": "Leche Entera",
    "subcategoria_id": 3,
    "unidad_medida_id": 5,
    "frecuencia_inventario": "diario",
    "stock_seguridad": "10000.0000"
  }' | jq .codigo
# Esperado: "LEC-001-V2"

# Revertir a LEC-001 para los tests siguientes
curl -s -X PUT http://localhost:8080/api/v1/items/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo": "LEC-001",
    "nombre": "Leche Entera",
    "subcategoria_id": 3,
    "unidad_medida_id": 5,
    "frecuencia_inventario": "diario",
    "stock_seguridad": "10000.0000"
  }' | jq .codigo
# Esperado: "LEC-001"
```

### 4.3 Flujo de inactivación y reactivación

```bash
# Inactivar item LEC-001
curl -s -X PATCH http://localhost:8080/api/v1/items/1/inactivar \
  -H "Authorization: Bearer $TOKEN" | jq .activo
# Esperado: false

# Verificar que no aparece en listado de activos
curl -s "http://localhost:8080/api/v1/items?activo=true" \
  -H "Authorization: Bearer $TOKEN" | jq '.items | map(select(.codigo == "LEC-001")) | length'
# Esperado: 0

# Reactivar
curl -s -X PATCH http://localhost:8080/api/v1/items/1/reactivar \
  -H "Authorization: Bearer $TOKEN" | jq .activo
# Esperado: true

# Intentar inactivar dos veces → 422
curl -s -X PATCH http://localhost:8080/api/v1/items/1/inactivar \
  -H "Authorization: Bearer $TOKEN"
curl -s -X PATCH http://localhost:8080/api/v1/items/1/inactivar \
  -H "Authorization: Bearer $TOKEN" | jq .error
# Esperado: "item_ya_inactivo"

# Reactivar para dejar limpio
curl -s -X PATCH http://localhost:8080/api/v1/items/1/reactivar \
  -H "Authorization: Bearer $TOKEN" | jq .activo
```

### 4.4 Costos por tienda

```bash
# Registrar costo específico para tienda 1 (debe existir en BD)
curl -s -X POST http://localhost:8080/api/v1/items/1/costos_tienda \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tienda_id": 1, "costo_unitario": 3400}' | jq .
# Esperado: 201, costo_unitario=3400, vigente_desde asignado por servidor

# Registrar un segundo cambio de costo (historial)
curl -s -X POST http://localhost:8080/api/v1/items/1/costos_tienda \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tienda_id": 1, "costo_unitario": 3600}' | jq .costo_unitario
# Esperado: 3600

# Consultar historial de costos
curl -s http://localhost:8080/api/v1/items/1/costos_tienda \
  -H "Authorization: Bearer $TOKEN" | jq '.costos_por_tienda[0].historial | length'
# Esperado: 2 (el más reciente es el vigente)

curl -s http://localhost:8080/api/v1/items/1/costos_tienda \
  -H "Authorization: Bearer $TOKEN" | jq '.costos_por_tienda[0].costo_vigente'
# Esperado: 3600 (el último registrado)
```

---

## 5. Ejecutar tests

```bash
# Desde loopi-api-v2/
go test ./internal/items/... -v

# Con cobertura
go test ./internal/items/... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

### Tests mínimos requeridos (P1)

| Test | Qué verifica |
|------|-------------|
| `TestCrearItemCodigoDuplicado` | Error 409 con código idéntico |
| `TestCrearItemNombreDuplicadoCaseInsensitive` | Error 409 con "leche entera" = "Leche Entera" |
| `TestCrearItemSinCamposObligatorios` | Error 400 por campos faltantes |
| `TestCrearItemSubcategoriaInactiva` | Error 422 subcategoria_inactiva |
| `TestEditarCodigoAntesDeUso` | 200 — código editable mientras esta_en_uso=false |
| `TestEditarCodigoDespuesDeUso` | Error 422 codigo_en_uso (mock estaEnUso=true) |
| `TestEditarNombreDuplicadoCaseInsensitive` | Error 409 al editar con nombre existente |
| `TestInactivarItem` | 200, activo=false |
| `TestInactivarItemYaInactivo` | Error 422 item_ya_inactivo |
| `TestReactivarItem` | 200, activo=true |
| `TestRegistrarCostoTienda` | 201, historial crea nueva entrada |
| `TestCostoVigenteTiendaEsElUltimo` | Historial con 2 entradas; costo_vigente = el más reciente |
| `TestListadoPaginadoFiltros` | Filtros tipo/frecuencia/activo retornan subconjuntos correctos |
| `TestAccesoSinAdminFallaEnEscritura` | Error 403 en POST/PUT/PATCH con rol no admin |
| `TestCacheInvalidacionEnCreate` | Caché invalidado tras crear item |
| `TestCacheInvalidacionEnInactivar` | Caché invalidado tras inactivar |

---

## 6. Rollback

```bash
# Revertir migraciones (en orden inverso)
migrate -path ./db/migrations -database "$DB_DSN" down 2
# Borra tabla items_costos_tienda y luego tabla items
```
