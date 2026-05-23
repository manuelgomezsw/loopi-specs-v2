# Contrato: POST /api/v1/auth/logout

**Módulo**: Autenticación | **Método**: POST | **Autenticación requerida**: Sí (JWT cookie)

---

## Request

**URL**: `POST /api/v1/auth/logout`

**Headers**:

```
X-XSRF-TOKEN: <csrf_token_del_cookie_XSRF-TOKEN>
```

**Body**: vacío

---

## Responses

### 204 No Content — Logout exitoso

**Headers de respuesta**:

```
Set-Cookie: jwt=; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=0
Set-Cookie: XSRF-TOKEN=; Secure; SameSite=Strict; Path=/; Max-Age=0
```

**Efectos**:

- El `jti` del JWT activo se inserta en `tokens_revocados` con `expira_en` = valor
  original del claim `exp` del token.
- Ambas cookies quedan expiradas (`Max-Age=0`).
- Cualquier solicitud posterior con ese `jti` será rechazada con 401 por el middleware
  de validación, aunque el JWT tenga firma válida y `exp` no vencido.
- OTel: span `auth.logout` registrado.

---

### 401 Unauthorized — Sin sesión activa o token inválido

```json
{
  "error": "no_autenticado",
  "mensaje": "Sesión no válida o expirada"
}
```

**Cuándo ocurre**: cookie `jwt` ausente, firma inválida, token expirado, o `jti`
ya en `tokens_revocados`.

---

### 403 Forbidden — CSRF token inválido o ausente

```json
{
  "error": "csrf_invalido",
  "mensaje": "Token CSRF requerido"
}
```

**Cuándo ocurre**: header `X-XSRF-TOKEN` ausente o no coincide con cookie `XSRF-TOKEN`.

---

## Notas de implementación

- El middleware de validación JWT (3 pasos) se ejecuta antes del handler de logout.
  Si el token ya es inválido o expirado, responde 401 antes de intentar la revocación.
- La inserción en `tokens_revocados` usa `INSERT IGNORE` para tolerar el caso raro
  de doble-logout (idempotente).
- `creado_en` y `actualizado_en` se establecen con `NOW()` en Colombia (`UTC-5`).
