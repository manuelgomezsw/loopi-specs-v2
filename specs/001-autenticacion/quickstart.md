# Quickstart: Autenticación — Setup Local (Dev)

**Feature**: `001-autenticacion` | **Fecha**: 2026-05-23

---

## Prerequisitos

- Go 1.22+
- Node.js 20+ y Angular CLI 18+
- Acceso a la instancia Cloud SQL dev (`loopi_dev_<nombre>`)
- Archivo `.env` con variables de entorno del backend

---

## 1. Variables de entorno — Backend (`loopi-api`)

Crear `loopi-api/.env`:

```env
DB_DSN=<usuario>:<password>@tcp(<cloud-sql-host>:3306)/loopi_dev_<nombre>?parseTime=true&loc=America%2FBogota
JWT_SECRET=dev-secret-cambiar-en-prod
JWT_EXPIRY_HOURS=24
```

> `JWT_SECRET` puede ser cualquier string en dev. En stage/prod viene de GCP Secret Manager.

---

## 2. Migración de base de datos

```bash
# Desde loopi-api/
golang-migrate -path migrations/ -database "$DB_DSN" up
```

Esto crea la tabla `tokens_revocados` y agrega las columnas `intentos_fallidos` y
`bloqueado_hasta` a `usuarios`.

---

## 3. Levantar el backend

```bash
# Desde loopi-api/
go run .
# Escucha en localhost:8080
```

---

## 4. Levantar el frontend

```bash
# Desde loopi-web/
ng serve
# Disponible en localhost:4200
# Proxy configurado para redirigir /api/* → localhost:8080
```

> Asegurarse de que `loopi-web/src/proxy.conf.json` incluya:

```json
{ "/api": { "target": "http://localhost:8080", "secure": false } }
```

---

## 5. Verificar el flujo de login

```bash
# Login exitoso
curl -c cookies.txt -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"admin","contrasena":"test123"}'
# Espera: 200 + cookies jwt y XSRF-TOKEN

# Verificar sesión activa
curl -b cookies.txt http://localhost:8080/api/v1/auth/me
# Espera: 200 con rol y tienda_id

# Logout
curl -b cookies.txt -c cookies.txt -X POST http://localhost:8080/api/v1/auth/logout \
  -H "X-XSRF-TOKEN: $(grep XSRF-TOKEN cookies.txt | awk '{print $7}')"
# Espera: 204

# Verificar revocación
curl -b cookies.txt http://localhost:8080/api/v1/auth/me
# Espera: 401
```

---

## 6. Ejecutar tests

```bash
# Backend
cd loopi-api && go test ./internal/auth/...

# Frontend
cd loopi-web && ng test --watch=false
```

---

## Notas de seguridad en dev

- `SameSite=Strict` funciona en `localhost` sin HTTPS gracias a la excepción de
  navegadores modernos para localhost.
- No usar el `JWT_SECRET` de dev en ningún otro ambiente.
- La cookie `jwt` no es visible en las DevTools de Chrome bajo "Application > Cookies"
  para verificarla; usar `curl -v` o inspeccionar la respuesta del login.
