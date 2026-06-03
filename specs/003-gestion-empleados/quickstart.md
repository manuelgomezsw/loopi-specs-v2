# Quickstart: 003-gestion-empleados

**Prerrequisitos**: tener desplegada y funcionando la feature `001-autenticacion` y `002-gestion-tiendas`.

---

## 1. Aplicar migraciones de base de datos

```bash
# Desde la raíz de loopi-api-v2
migrate -path ./db/migrations -database "$DB_DSN" up
```

Migraciones nuevas en esta feature:

- `NNNN_crear_tabla_empleados.up.sql`
- `NNNN+1_crear_tabla_log_auditoria_empleados.up.sql`

Verificar:

```sql
SHOW TABLES LIKE 'empleados';
SHOW TABLES LIKE 'log_auditoria_empleados';
DESCRIBE empleados;
DESCRIBE log_auditoria_empleados;
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
BCRYPT_COST=12
```

> En tests, `BCRYPT_COST` se sobreescribe a `4` automáticamente vía constante en `config/hash.go`.

---

## 3. Ejecutar el frontend (Angular)

```bash
# Desde loopi-web-v2/
ng serve
```

Navegar a: `http://localhost:4200/empleados`
(Solo accesible con sesión de `admin` activa.)

---

## 4. Smoke test manual

### Crear primer empleado (admin → barista)

```bash
# 1. Obtener token admin
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"admin","contrasena":"xxx"}' | jq -r '.token')

# 2. Crear empleado
curl -s -X POST http://localhost:8080/api/v1/empleados \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Ana",
    "apellido": "Gómez",
    "usuario": "ana.gomez",
    "rol": "barista",
    "tienda_id": 1
  }' | jq .
# Esperado: 201, con "contrasena_temporal"

# 3. Intentar crear con mismo usuario → 409
curl -s -X POST http://localhost:8080/api/v1/empleados \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"X","apellido":"Y","usuario":"ana.gomez","rol":"barista","tienda_id":1}' | jq .
# Esperado: 409 usuario_duplicado

# 4. Listar empleados
curl -s "http://localhost:8080/api/v1/empleados?q=ana&page=1&limit=20" \
  -H "Authorization: Bearer $TOKEN" | jq .

# 5. Inactivar único admin → debe fallar
ADMIN_ID=$(curl -s "http://localhost:8080/api/v1/empleados?q=admin" \
  -H "Authorization: Bearer $TOKEN" | jq '.empleados[0].id')
curl -s -X PATCH "http://localhost:8080/api/v1/empleados/$ADMIN_ID/estado" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"activo":false}' | jq .
# Esperado: 422 ultimo_admin_activo
```

---

## 5. Ejecutar tests

```bash
# Desde loopi-api-v2/
go test ./internal/empleados/... -v

# Con cobertura
go test ./internal/empleados/... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

### Tests mínimos requeridos (P1)

| Test | Qué verifica |
|------|-------------|
| `TestCrearEmpleadoBaristaSinTienda` | Error 422 tienda requerida |
| `TestCrearEmpleadoUsuarioDuplicado` | Error 409 |
| `TestInactivarUltimoAdmin` | Error 422 ultimo_admin_activo |
| `TestResetContrasenaGeneraHash` | Hash bcrypt distinto al original |
| `TestListarEmpleadosBusquedaYPaginacion` | Total correcto + filtros activos |
| `TestAuditLogCreadoEnCadaOperacion` | Log registrado para CREAR, EDITAR, INACTIVAR, REACTIVAR, RESET |
| `TestEmpleadoInactivoNoAutentica` | Login rechazado (integración con 001-autenticacion) |

---

---

## 6. Integración con 001-autenticacion (RF-EMP-04.6)

**Estado**: ✅ Implementado — el bloqueo por `requiere_cambio_contrasena` está activo en `JWTMiddleware`.

### Cómo funciona

1. Al crear o resetear la contraseña de un empleado, `empleados.requiere_cambio_contrasena = 1`.
2. Al autenticarse, `BuscarUsuarioPorNombre` lee `requiere_cambio_contrasena` desde `empleados`
   e incluye el claim `requiere_cambio_contrasena: true` en el JWT emitido.
3. `JWTMiddleware` lee ese claim en cada request y, si es `true`, retorna **HTTP 403**
   con `{"error":"cambio_contrasena_requerido"}` en **todos los endpoints**, excepto
   `POST /api/v1/empleados/{id}/contrasena/cambiar`.
4. Al cambiar la contraseña exitosamente, `requiere_cambio_contrasena = 0` en la BD
   (y el empleado obtiene un nuevo JWT limpio en el siguiente login).

### Nota sobre la tabla `usuarios`

A partir de la migración 003, el módulo de auth lee desde `empleados` (no desde `usuarios`).
Los campos de control de acceso (`bloqueado_hasta`, `intentos_fallidos`) fueron agregados
a `empleados` en la migración 005. La tabla `usuarios` queda como artefacto legacy.

### Smoke test — flujo completo de cambio de contraseña

```bash
# 1. Crear un empleado (recibe contraseña temporal)
TEMP_PASS=$(curl -s -X POST http://localhost:8080/api/v1/empleados \
  -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Ana","apellido":"Gómez","usuario":"ana.gomez","rol":"barista","tienda_id":1}' \
  | jq -r '.contrasena_temporal')

# 2. Autenticarse con contraseña temporal → JWT con requiere_cambio_contrasena=true
curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"usuario\":\"ana.gomez\",\"contrasena\":\"$TEMP_PASS\"}"
# → HTTP 200, cookie jwt válida

# 3. Intentar cualquier endpoint → HTTP 403 cambio_contrasena_requerido
curl -s http://localhost:8080/api/v1/tiendas \
  --cookie "jwt=<token_de_ana>" | jq .
# → {"error":"cambio_contrasena_requerido","mensaje":"Debes cambiar tu contraseña antes de continuar."}

# 4. Cambiar la contraseña (endpoint permitido sin rol=admin)
ANA_ID=<id_de_ana>
curl -s -X POST "http://localhost:8080/api/v1/empleados/$ANA_ID/contrasena/cambiar" \
  --cookie "jwt=<token_de_ana>" \
  -H "Content-Type: application/json" \
  -d '{"nueva_contrasena":"nueva1234"}'
# → HTTP 200 {"mensaje":"Contraseña actualizada correctamente."}

# 5. Nuevo login → JWT con requiere_cambio_contrasena=false → acceso normal
curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"ana.gomez","contrasena":"nueva1234"}'
# → HTTP 200, acceso desbloqueado
```

---

## 7. Rollback

```bash
# Revertir migraciones (en orden inverso)
migrate -path ./migrations -database "$DB_DSN" down 5
```
