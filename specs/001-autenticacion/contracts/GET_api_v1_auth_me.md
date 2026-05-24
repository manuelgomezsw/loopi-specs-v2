# Contrato: GET /api/v1/auth/me

**Módulo**: Autenticación | **Método**: GET | **Autenticación requerida**: Sí (JWT cookie)

---

## Propósito

Permite al frontend Angular restaurar el estado de sesión en memoria al recargar la
página. Como el JWT viaja en una `httpOnly cookie` inaccesible desde JavaScript, el
frontend no puede leer el rol ni el `tienda_id` directamente. Este endpoint los
expone de forma segura a partir del token validado.

---

## Request

**URL**: `GET /api/v1/auth/me`

**Headers**: ninguno adicional (la cookie `jwt` se envía automáticamente).

**Body**: vacío

---

## Responses

### 200 OK — Sesión activa

```json
{
  "usuario_id": 42,
  "usuario": "jperez",
  "rol": "lider_tienda",
  "tienda_id": 3
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `usuario_id` | int | ID interno del usuario (`sub` del JWT) |
| `usuario` | string | Nombre de usuario (leído desde `usuarios` por `sub`) |
| `rol` | string | `admin` \| `lider_compras` \| `lider_tienda` \| `barista` |
| `tienda_id` | int \| null | ID de tienda; `null` para `admin` y `lider_compras` |

**Nota**: `usuario` se obtiene con una consulta a `usuarios` por `usuario_id`.
Los demás campos provienen directamente del JWT (sin consulta extra).

---

### 401 Unauthorized — Sin sesión activa

```json
{
  "error": "no_autenticado",
  "mensaje": "Sesión no válida o expirada"
}
```

El frontend debe redirigir al login al recibir 401 de este endpoint.

---

## Notas de implementación

- El middleware de validación JWT (3 pasos) se ejecuta antes del handler.
- La consulta a `usuarios` es solo para obtener el campo `usuario` (nombre); los
  datos de sesión (rol, tienda_id) se leen del JWT sin tocar la BD.
- Este endpoint es `GET` y no requiere `X-XSRF-TOKEN` (solo mutaciones lo exigen).
