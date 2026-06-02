# Quickstart: Gestión de Tiendas

**Feature**: `002-gestion-tiendas` | **Fecha**: 2026-05-23

## Prerrequisitos

- Feature `001-autenticacion` implementada y migrada (tabla `usuarios` disponible)
- Acceso a GCP Cloud SQL dev (`loopi_dev_<tu_nombre>`)
- Go 1.22+ instalado localmente
- Node.js 20+ y Angular CLI instalados localmente
- CLI `golang-migrate` instalado (`go install -tags 'mysql' github.com/golang-migrate/migrate/v4/cmd/migrate@latest`)

## 1. Aplicar la Migración de BD

Desde `loopi-api-v2/`:

```bash
migrate -path migrations/ \
        -database "mysql://${DB_USER}:${DB_PASS}@tcp(${DB_HOST})/${DB_NAME}?loc=America%2FBogota" \
        up
```

Verificar que la tabla `tiendas` fue creada:

```sql
DESCRIBE tiendas;
SHOW INDEX FROM tiendas;
```

Para rollback:

```bash
migrate -path migrations/ \
        -database "mysql://..." \
        down 1
```

## 2. Correr el Backend en Local

```bash
cd loopi-api-v2/
export DB_DSN="user:pass@tcp(cloud-sql-dev-host)/loopi_dev_<nombre>?loc=America%2FBogota&parseTime=true"
export JWT_SECRET="tu-secret-dev"
go run ./cmd/api/
```

El servidor escucha en `http://localhost:8080`.

## 3. Probar los Endpoints

### Crear una tienda (requiere JWT de admin)

```bash
TOKEN="<JWT_del_admin>"

curl -s -X POST http://localhost:8080/api/v1/tiendas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo": "TDA-001",
    "nombre": "Tienda Norte",
    "direccion": "Calle 100 #20-30",
    "ciudad": "Bogotá",
    "telefono": "3001234567"
  }' | jq .
```

Respuesta esperada `201 Created`:

```json
{
  "id": 1,
  "codigo": "TDA-001",
  "nombre": "Tienda Norte",
  "activo": true,
  ...
}
```

### Listar tiendas activas

```bash
curl -s "http://localhost:8080/api/v1/tiendas?estado=activas" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

### Inactivar una tienda

```bash
curl -s -X POST http://localhost:8080/api/v1/tiendas/1/inactivar \
  -H "Authorization: Bearer $TOKEN" | jq .
```

### Reactivar una tienda

```bash
curl -s -X POST http://localhost:8080/api/v1/tiendas/1/reactivar \
  -H "Authorization: Bearer $TOKEN" | jq .
```

## 4. Correr el Frontend en Local

```bash
cd loopi-web-v2/
npm install
ng serve
```

Acceder a `http://localhost:4200/tiendas` (admin autenticado).

## 5. Ejecutar los Gates antes de Commit

### Backend

```bash
cd loopi-api-v2/
go build ./...
golangci-lint run
govulncheck ./...
gitleaks detect --no-git
go test ./...
```

### Frontend

```bash
cd loopi-web-v2/
ng build
npm audit --audit-level=high
gitleaks detect --no-git
ng test --watch=false
```

## 6. Validar Escenarios Clave

| Escenario | Comando / acción | Resultado esperado |
|-----------|------------------|--------------------|
| Crear tienda con nombre duplicado (case-insensitive) | `POST /api/v1/tiendas` con nombre `"tienda norte"` | `409 Conflict`, `error: "nombre_duplicado"` |
| Crear tienda con código duplicado | `POST /api/v1/tiendas` con `codigo: "TDA-001"` | `409 Conflict`, `error: "codigo_duplicado"` |
| Editar `codigo` en body de PUT | `PUT /api/v1/tiendas/1` con `"codigo": "TDA-999"` | `200 OK` pero `codigo` sigue siendo `"TDA-001"` |
| Inactivar tienda ya inactiva | `POST /api/v1/tiendas/1/inactivar` (2 veces) | `422 Unprocessable Entity` |
| Acceso con rol `lider_tienda` | Cualquier endpoint de tiendas | `403 Forbidden` |
| Tienda inactiva en selector de operaciones | UI de inventario/pedidos | Tienda inactiva no aparece como opción |
