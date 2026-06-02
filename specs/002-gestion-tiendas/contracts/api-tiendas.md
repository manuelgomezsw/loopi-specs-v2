# Contratos API: Gestión de Tiendas

**Feature**: `002-gestion-tiendas` | **Prefijo**: `/api/v1/tiendas` | **Fecha**: 2026-05-23

## Autenticación

Todos los endpoints requieren header `Authorization: Bearer <JWT>`.
El JWT debe incluir `rol = "admin"`. Cualquier otro rol recibe `403 Forbidden`.

## Modelo de Respuesta Común

### TiendaResponse

```json
{
  "id": 1,
  "codigo": "TDA-001",
  "nombre": "Tienda Norte",
  "direccion": "Calle 100 #20-30",
  "ciudad": "Bogotá",
  "telefono": "3001234567",
  "activo": true,
  "creado_por": 5,
  "creado_en": "2026-05-23T10:00:00",
  "actualizado_por": 5,
  "actualizado_en": "2026-05-23T10:00:00"
}
```

### Formato de Error (estándar API Loopi)

```json
{
  "error": "codigo_snake_case",
  "mensaje": "Texto legible para el usuario.",
  "campo": "nombre_del_campo_opcional",
  "detalles": []
}
```

---

## Endpoints

### POST /api/v1/tiendas — Crear tienda

**Rol requerido**: `admin`

**Request Body**:

```json
{
  "codigo":    "TDA-001",
  "nombre":    "Tienda Norte",
  "direccion": "Calle 100 #20-30",
  "ciudad":    "Bogotá",
  "telefono":  "3001234567"
}
```

| Campo | Tipo | Obligatorio | Validación |
|-------|------|-------------|------------|
| `codigo` | string | ✅ | Max 20 chars, alfanumérico mayúsculas, único en sistema |
| `nombre` | string | ✅ | Max 150 chars, único case-insensitive |
| `direccion` | string | ✅ | Max 255 chars |
| `ciudad` | string | ✅ | Max 100 chars |
| `telefono` | string | ✅ | Max 20 chars |

**Respuestas**:

| Código | Condición | Body |
|--------|-----------|------|
| `201 Created` | Tienda creada exitosamente | `TiendaResponse` |
| `400 Bad Request` | Campos faltantes o formato inválido | `{ "error": "input_invalido", "mensaje": "...", "campo": "nombre_campo" }` |
| `401 Unauthorized` | Sin JWT o token expirado | `{ "error": "no_autenticado", "mensaje": "Debes iniciar sesión." }` |
| `403 Forbidden` | Rol distinto de `admin` | `{ "error": "sin_permiso", "mensaje": "No tienes permiso para esta operación." }` |
| `409 Conflict` | Nombre duplicado (case-insensitive) | `{ "error": "nombre_duplicado", "mensaje": "Ya existe una tienda con ese nombre.", "campo": "nombre" }` |
| `409 Conflict` | Código duplicado | `{ "error": "codigo_duplicado", "mensaje": "Ya existe una tienda con ese código.", "campo": "codigo" }` |

---

### GET /api/v1/tiendas — Listar tiendas

**Rol requerido**: `admin`

**Query Parameters**:

| Parámetro | Tipo | Default | Valores | Descripción |
|-----------|------|---------|---------|-------------|
| `estado` | string | `todas` | `todas`, `activas`, `inactivas` | Filtro por estado |
| `pagina` | int | `1` | ≥ 1 | Página solicitada |
| `limite` | int | `50` | 1–100 | Registros por página |

**Ejemplo**: `GET /api/v1/tiendas?estado=activas&pagina=1&limite=50`

**Respuesta 200 OK**:

```json
{
  "datos": [
    {
      "id": 1,
      "codigo": "TDA-001",
      "nombre": "Tienda Norte",
      "direccion": "Calle 100 #20-30",
      "ciudad": "Bogotá",
      "telefono": "3001234567",
      "activo": true,
      "creado_por": 5,
      "creado_en": "2026-05-23T10:00:00",
      "actualizado_por": 5,
      "actualizado_en": "2026-05-23T10:00:00"
    }
  ],
  "total": 12,
  "pagina": 1,
  "limite": 50
}
```

**Respuestas de error**:

| Código | Condición |
|--------|-----------|
| `400 Bad Request` | `estado` con valor inválido |
| `401 Unauthorized` | Sin JWT |
| `403 Forbidden` | Rol distinto de `admin` |

---

### GET /api/v1/tiendas/{id} — Obtener tienda por ID

**Rol requerido**: `admin`

**Path Params**: `id` — BIGINT UNSIGNED

**Respuestas**:

| Código | Condición | Body |
|--------|-----------|------|
| `200 OK` | Tienda encontrada | `TiendaResponse` |
| `401 Unauthorized` | Sin JWT | Error estándar |
| `403 Forbidden` | Rol distinto de `admin` | Error estándar |
| `404 Not Found` | Tienda no existe | `{ "error": "tienda_no_encontrada", "mensaje": "La tienda no existe." }` |

---

### PUT /api/v1/tiendas/{id} — Editar tienda

**Rol requerido**: `admin`

**Path Params**: `id` — BIGINT UNSIGNED

**Request Body** (el campo `codigo` es ignorado aunque se envíe):

```json
{
  "nombre":    "Tienda Norte Renovada",
  "direccion": "Carrera 15 #80-10",
  "ciudad":    "Bogotá",
  "telefono":  "3009876543"
}
```

| Campo | Tipo | Obligatorio | Validación |
|-------|------|-------------|------------|
| `nombre` | string | ✅ | Max 150 chars, único case-insensitive (excluye la propia tienda) |
| `direccion` | string | ✅ | Max 255 chars |
| `ciudad` | string | ✅ | Max 100 chars |
| `telefono` | string | ✅ | Max 20 chars |

**Respuestas**:

| Código | Condición | Body |
|--------|-----------|------|
| `200 OK` | Tienda actualizada | `TiendaResponse` (con campos de auditoría actualizados) |
| `400 Bad Request` | Campos faltantes o formato inválido | Error estándar con `campo` |
| `401 Unauthorized` | Sin JWT | Error estándar |
| `403 Forbidden` | Rol distinto de `admin` | Error estándar |
| `404 Not Found` | Tienda no existe | Error estándar |
| `409 Conflict` | Nombre duplicado en otra tienda | `{ "error": "nombre_duplicado", ..., "campo": "nombre" }` |

---

### POST /api/v1/tiendas/{id}/inactivar — Inactivar tienda

**Rol requerido**: `admin`

**Path Params**: `id` — BIGINT UNSIGNED

**Request Body**: vacío (`{}` o sin body)

**Respuestas**:

| Código | Condición | Body |
|--------|-----------|------|
| `200 OK` | Tienda inactivada | `TiendaResponse` con `activo: false` |
| `401 Unauthorized` | Sin JWT | Error estándar |
| `403 Forbidden` | Rol distinto de `admin` | Error estándar |
| `404 Not Found` | Tienda no existe | Error estándar |
| `422 Unprocessable Entity` | Tienda ya está inactiva | `{ "error": "tienda_ya_inactiva", "mensaje": "La tienda ya se encuentra inactiva." }` |

---

### POST /api/v1/tiendas/{id}/reactivar — Reactivar tienda

**Rol requerido**: `admin`

**Path Params**: `id` — BIGINT UNSIGNED

**Request Body**: vacío (`{}` o sin body)

**Notas**: El frontend muestra diálogo de confirmación antes de llamar este endpoint.
El backend ejecuta la reactivación sin precondiciones adicionales.

**Respuestas**:

| Código | Condición | Body |
|--------|-----------|------|
| `200 OK` | Tienda reactivada | `TiendaResponse` con `activo: true` |
| `401 Unauthorized` | Sin JWT | Error estándar |
| `403 Forbidden` | Rol distinto de `admin` | Error estándar |
| `404 Not Found` | Tienda no existe | Error estándar |
| `422 Unprocessable Entity` | Tienda ya está activa | `{ "error": "tienda_ya_activa", "mensaje": "La tienda ya se encuentra activa." }` |

---

## Resumen de Endpoints

| Método | Ruta | Descripción | Rol |
|--------|------|-------------|-----|
| `POST` | `/api/v1/tiendas` | Crear tienda | admin |
| `GET` | `/api/v1/tiendas` | Listar tiendas (con filtro de estado) | admin |
| `GET` | `/api/v1/tiendas/{id}` | Obtener tienda por ID | admin |
| `PUT` | `/api/v1/tiendas/{id}` | Editar tienda | admin |
| `POST` | `/api/v1/tiendas/{id}/inactivar` | Inactivar tienda | admin |
| `POST` | `/api/v1/tiendas/{id}/reactivar` | Reactivar tienda | admin |
