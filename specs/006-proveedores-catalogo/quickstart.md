# Quickstart: 006-proveedores-catalogo

**Prerrequisitos**: tener desplegada y funcionando la feature `001-autenticacion`.
Esta feature no depende de 002, 003, 004 ni 005.

---

## 1. Aplicar migraciones de base de datos

```bash
# Desde la raíz de loopi-api
migrate -path ./db/migrations -database "$DB_DSN" up
```

Migraciones nuevas en esta feature:

- `NNNN_crear_tabla_proveedores.up.sql` — crea la tabla con índices

Verificar:

```sql
SHOW TABLES LIKE 'proveedores';
DESCRIBE proveedores;

-- Verificar que la tabla está vacía al inicio
SELECT COUNT(*) FROM proveedores;
-- Esperado: 0 (no hay seed data; los proveedores los crea el admin)

-- Verificar constraint de NIT único
SHOW INDEX FROM proveedores WHERE Key_name = 'uq_proveedores_nit';
```

---

## 2. Ejecutar el backend (Go)

```bash
# Desde loopi-api/
go run .
```

Variables de entorno requeridas (archivo `.env` local, no commitear):

```env
DB_DSN=user:pass@tcp(host:3306)/loopi_dev_nombre?parseTime=true&loc=America%2FBogota
JWT_SECRET=...
```

Verificar que el módulo de proveedores registra sus rutas en los logs:

```json
{"level":"info","msg":"rutas registradas","modulo":"proveedores","endpoints":6}
```

Verificar que Ristretto inicializa sin errores en los logs:

```json
{"level":"info","msg":"ristretto cache inicializado","modulo":"proveedores","ttl_segundos":86400}
```

---

## 3. Ejecutar el frontend (Angular)

```bash
# Desde loopi-web/
ng serve
```

Navegar a: `http://localhost:4200/proveedores`
(Solo accesible con sesión de `admin` activa; roles `lider_tienda` y `barista`
reciben 403.)

---

## 4. Smoke test manual

### 4.1 Verificar acceso denegado a no-admin

```bash
# Obtener token de un lider_tienda
TOKEN_LIDER=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"lider1","contrasena":"xxx"}' | jq -r '.token')

# Intentar listar proveedores → 403
curl -s "http://localhost:8080/api/v1/proveedores" \
  -H "Authorization: Bearer $TOKEN_LIDER" | jq .
# Esperado: { "error": "acceso_denegado", "mensaje": "..." }
```

### 4.2 Crear proveedor (flujo básico)

```bash
# Obtener token admin
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"admin","contrasena":"xxx"}' | jq -r '.token')

# Crear proveedor con datos completos
curl -s -X POST "http://localhost:8080/api/v1/proveedores" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "razon_social": "Distribuidora La Cosecha S.A.S",
    "nit": "900123456-7",
    "nombre_contacto": "Carlos Rodríguez",
    "telefono_contacto": "3001234567",
    "email_contacto": "carlos@lacosecha.com"
  }' | jq .
# Esperado: 201, id=1, activo=true

# Crear proveedor sin email de contacto (único campo opcional)
curl -s -X POST "http://localhost:8080/api/v1/proveedores" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"razon_social":"Proveedor Simple","nit":"PROV-001","nombre_contacto":"Juan Pérez","telefono_contacto":"3009998877"}' | jq .
# Esperado: 201, id=2, email_contacto=null

# Intentar NIT duplicado → 409
curl -s -X POST "http://localhost:8080/api/v1/proveedores" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"razon_social":"Otro Proveedor","nit":"900123456-7","nombre_contacto":"X","telefono_contacto":"300"}' | jq .
# Esperado: 409 nit_duplicado

# Intentar sin razon_social → 400
curl -s -X POST "http://localhost:8080/api/v1/proveedores" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nit":"PROV-002","nombre_contacto":"X","telefono_contacto":"300"}' | jq .
# Esperado: 400 campo_requerido, campo="razon_social"

# Intentar sin nombre_contacto → 400
curl -s -X POST "http://localhost:8080/api/v1/proveedores" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"razon_social":"Proveedor Y","nit":"PROV-003","telefono_contacto":"300"}' | jq .
# Esperado: 400 campo_requerido, campo="nombre_contacto"

# Intentar sin telefono_contacto → 400
curl -s -X POST "http://localhost:8080/api/v1/proveedores" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"razon_social":"Proveedor Z","nit":"PROV-004","nombre_contacto":"X"}' | jq .
# Esperado: 400 campo_requerido, campo="telefono_contacto"
```

### 4.3 Listar con filtros y búsqueda

```bash
# Listar todos los proveedores
curl -s "http://localhost:8080/api/v1/proveedores" \
  -H "Authorization: Bearer $TOKEN" | jq '.total, .proveedores[].razon_social'
# Esperado: 2, "Distribuidora La Cosecha S.A.S", "Proveedor Simple"

# Filtrar activos
curl -s "http://localhost:8080/api/v1/proveedores?estado=activo" \
  -H "Authorization: Bearer $TOKEN" | jq '.total'
# Esperado: 2

# Búsqueda por texto
curl -s "http://localhost:8080/api/v1/proveedores?busqueda=cosecha" \
  -H "Authorization: Bearer $TOKEN" | jq '.total, .proveedores[0].razon_social'
# Esperado: 1, "Distribuidora La Cosecha S.A.S"

# Búsqueda por NIT parcial
curl -s "http://localhost:8080/api/v1/proveedores?busqueda=900123" \
  -H "Authorization: Bearer $TOKEN" | jq '.total'
# Esperado: 1

# Empty state (sin resultados)
curl -s "http://localhost:8080/api/v1/proveedores?busqueda=noexiste" \
  -H "Authorization: Bearer $TOKEN" | jq '.total, .proveedores'
# Esperado: 0, []
```

### 4.4 Editar proveedor (incluyendo NIT)

```bash
ID=1

# Editar datos de contacto
curl -s -X PUT "http://localhost:8080/api/v1/proveedores/$ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nombre_contacto":"María López","telefono_contacto":"3107654321"}' | jq .
# Esperado: 200, nombre_contacto="María López"

# Editar NIT (exitoso)
curl -s -X PUT "http://localhost:8080/api/v1/proveedores/$ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nit":"900123456-8"}' | jq .nit
# Esperado: "900123456-8"

# Intentar editar NIT por uno ya existente → 409
curl -s -X PUT "http://localhost:8080/api/v1/proveedores/$ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nit":"PROV-001"}' | jq .
# Esperado: 409 nit_duplicado

# Intentar dejar vacío el nombre de contacto → 400
curl -s -X PUT "http://localhost:8080/api/v1/proveedores/$ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nombre_contacto":""}' | jq .
# Esperado: 400 campo_vacio, campo="nombre_contacto"

# Intentar dejar vacío el teléfono de contacto → 400
curl -s -X PUT "http://localhost:8080/api/v1/proveedores/$ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"telefono_contacto":""}' | jq .
# Esperado: 400 campo_vacio, campo="telefono_contacto"
```

### 4.5 Inactivar y reactivar

```bash
ID=1

# Inactivar proveedor
curl -s -X PATCH "http://localhost:8080/api/v1/proveedores/$ID/inactivar" \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: 200, activo=false

# Verificar que no aparece en pedidos (simulación — depende de 013)
curl -s "http://localhost:8080/api/v1/proveedores?estado=activo" \
  -H "Authorization: Bearer $TOKEN" | jq '.total'
# Esperado: 1 (solo Proveedor Simple está activo)

# Intentar inactivar de nuevo → 409
curl -s -X PATCH "http://localhost:8080/api/v1/proveedores/$ID/inactivar" \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: 409 ya_inactivo

# Reactivar
curl -s -X PATCH "http://localhost:8080/api/v1/proveedores/$ID/activar" \
  -H "Authorization: Bearer $TOKEN" | jq .
# Esperado: 200, activo=true

# Verificar que vuelve a aparecer
curl -s "http://localhost:8080/api/v1/proveedores?estado=activo" \
  -H "Authorization: Bearer $TOKEN" | jq '.total'
# Esperado: 2
```

### 4.6 Verificar empty state en UI

Navegar a `http://localhost:4200/proveedores` con la base de datos vacía:

- El listado debe mostrar el mensaje "No hay proveedores registrados" con botón "Crear
  primer proveedor" (RF-PROV-04.4).
- Al crear el primer proveedor, el listado se actualiza y muestra la tarjeta/fila.

---

## 5. Ejecutar tests

```bash
# Desde loopi-api/
go test ./internal/proveedores/... -v

# Con cobertura
go test ./internal/proveedores/... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

### Tests mínimos requeridos (P1)

| Test | Qué verifica |
|------|-------------|
| `TestCrearProveedorExitoso` | 201 con campos completos (sin email es el único opcional) |
| `TestCrearProveedorNITDuplicado` | Error 409 nit_duplicado |
| `TestCrearProveedorSinRazonSocial` | Error 400 campo_requerido, campo=razon_social |
| `TestCrearProveedorSinNombreContacto` | Error 400 campo_requerido, campo=nombre_contacto |
| `TestCrearProveedorSinTelefonoContacto` | Error 400 campo_requerido, campo=telefono_contacto |
| `TestEditarProveedorNITPropioNoConflicto` | Editar NIT al mismo valor no da 409 |
| `TestEditarProveedorNITDuplicado` | Error 409 al tomar NIT de otro proveedor |
| `TestEditarProveedorNombreContactoVacio` | Error 400 campo_vacio, campo=nombre_contacto |
| `TestEditarProveedorTelefonoContactoVacio` | Error 400 campo_vacio, campo=telefono_contacto |
| `TestInactivarProveedor` | 200 activo=false |
| `TestInactivarYaInactivo` | Error 409 ya_inactivo |
| `TestActivarProveedor` | 200 activo=true |
| `TestActivarYaActivo` | Error 409 ya_activo |
| `TestListarFiltroActivo` | Solo retorna activos cuando activo=true |
| `TestListarBusquedaPorRazonSocial` | Búsqueda insensible a mayúsculas |
| `TestListarBusquedaPorNIT` | Búsqueda por subcadena de NIT |
| `TestListarEmptyState` | Retorna total=0 y array vacío |
| `TestAccesoLiderTiendaFalla` | Error 403 en cualquier endpoint |
| `TestAccesoSinTokenFalla` | Error 401 en cualquier endpoint |

---

## 6. Rollback

```bash
# Revertir migración
migrate -path ./db/migrations -database "$DB_DSN" down 1
# Borra la tabla proveedores
```

> **Atención**: El rollback solo es seguro si aún no hay datos en producción ni FKs
> de 007-items o 013-pedidos apuntando a `proveedores.id`.
