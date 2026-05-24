# Contrato: POST /api/v1/auth/login

**Módulo**: Autenticación | **Método**: POST | **Autenticación requerida**: No

---

## Request

**URL**: `POST /api/v1/auth/login`

**Headers**:

```http
Content-Type: application/json
```

**Body**:

```json
{
  "usuario": "string",
  "contrasena": "string"
}
```

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `usuario` | string | Sí | Nombre de usuario |
| `contrasena` | string | Sí | Contraseña en texto plano (transmitida por HTTPS) |

---

## Responses

### 200 OK — Login exitoso

**Headers de respuesta**:

```http
Set-Cookie: jwt=<token>; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=86400
Set-Cookie: XSRF-TOKEN=<csrf_token>; Secure; SameSite=Strict; Path=/
```

**Body**:

```json
{
  "rol": "lider_tienda",
  "tienda_id": 3
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `rol` | string | `admin` \| `lider_compras` \| `lider_tienda` \| `barista` |
| `tienda_id` | int \| null | ID de tienda asignada; `null` para `admin` y `lider_compras` |

**Efectos**:

- Se resetea `intentos_fallidos = 0` y `bloqueado_hasta = NULL` en `usuarios`.
- Se emite JWT firmado (HS256) con claims `jti`, `sub`, `rol`, `tienda_id`, `iat`, `exp`.
- Se genera `XSRF-TOKEN` aleatorio para protección CSRF.
- OTel: span con `auth.result=success`, `user.role=<rol>`.

---

### 401 Unauthorized — Credenciales incorrectas o cuenta inactiva

```json
{
  "error": "credenciales_invalidas",
  "mensaje": "Usuario o contraseña incorrectos"
}
```

**Efectos**:

- Si la cuenta existe y está activa: `intentos_fallidos = intentos_fallidos + 1`.
- Si `intentos_fallidos` llega a 5: `bloqueado_hasta = NOW() + INTERVAL 5 MINUTE`.
- Si la cuenta no existe o está inactiva: mismo mensaje (no se revela diferencia).
- OTel: span con `auth.result=invalid_credentials` o `auth.result=account_inactive`.

---

### 423 Locked — Cuenta bloqueada por intentos fallidos

```json
{
  "error": "cuenta_bloqueada",
  "mensaje": "Demasiados intentos fallidos. Intente nuevamente en 5 minutos.",
  "bloqueado_hasta": "2026-05-23T18:35:00"
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `bloqueado_hasta` | string (ISO 8601) | Hora Colombia hasta la cual el acceso está bloqueado |

**Nota**: HTTP 423 (Locked) es semánticamente más preciso que 429 para bloqueo por
credenciales; no implica rate-limiting general sino bloqueo de cuenta específica.

**Efectos**:

- No se incrementa `intentos_fallidos` si ya está bloqueado.
- OTel: span con `auth.result=account_locked`.

---

### 400 Bad Request — Body inválido

```json
{
  "error": "datos_invalidos",
  "mensaje": "Los campos usuario y contrasena son requeridos"
}
```

---

## Notas de implementación

- La verificación de contraseña usa `bcrypt.CompareHashAndPassword`. El tiempo de
  respuesta variable (bcrypt es lento) no debe revelar si el usuario existe: aplicar
  `bcrypt.CompareHashAndPassword` con un hash dummy cuando el usuario no existe para
  normalizar el tiempo de respuesta.
- El `XSRF-TOKEN` es un UUID v4 aleatorio generado en cada login; no derivado del JWT.
- El `Max-Age` de la cookie `jwt` iguala el valor de `JWT_EXPIRY_HOURS * 3600`.
