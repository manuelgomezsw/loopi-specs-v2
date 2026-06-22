# Contratos de API REST: 005-categorias-catalogo

**Prefijo base**: `/api/v1/`
**Autenticación**: Bearer token JWT en header `Authorization`
**Autorización**:

- Solo `admin` puede crear, editar, inactivar y reactivar.
- Todos los roles autenticados pueden leer (el catálogo es de consulta para módulos consumidores).

**Formato de error**:

```json
{ "error": "codigo_snake_case", "mensaje": "Texto para el usuario", "campo": "opcional", "detalles": [] }
```

---

## Endpoints — Categorías

### 1. Listar catálogo completo (categorías con subcategorías anidadas)

```http
GET /api/v1/categorias
Authorization: Bearer {token}
```

**Query parameters**:

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `activo` | boolean | — | Filtrar por estado. Sin valor: retorna todas |

**Response 200 OK**:

```json
{
  "categorias": [
    {
      "id": 1,
      "nombre": "Lácteo",
      "activo": true,
      "creado_por": 1,
      "creado_en": "2026-05-24T10:00:00",
      "actualizado_por": 1,
      "actualizado_en": "2026-05-24T10:00:00",
      "subcategorias": [
        {
          "id": 1,
          "nombre": "Quesos",
          "categoria_id": 1,
          "activo": true,
          "creado_por": 1,
          "creado_en": "2026-05-24T10:00:00",
          "actualizado_por": 1,
          "actualizado_en": "2026-05-24T10:00:00",
          "total_items": 5
        },
        {
          "id": 2,
          "nombre": "Cremas",
          "categoria_id": 1,
          "activo": false,
          "creado_por": 1,
          "creado_en": "2026-05-24T10:00:00",
          "actualizado_por": 1,
          "actualizado_en": "2026-05-24T11:00:00",
          "total_items": 2
        }
      ]
    }
  ],
  "total": 1
}
```

> `total_items`: cantidad de items del catálogo con esa subcategoría asignada (activos e
> inactivos). Se calcula con un JOIN a la tabla `items` (007 — futuro); retorna 0 hasta
> que esa feature exista.

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |

---

### 2. Detalle de categoría

```http
GET /api/v1/categorias/{id}
Authorization: Bearer {token}
```

**Response 200 OK**: Mismo schema que un elemento de `categorias[]` en el listado, con
subcategorías anidadas.

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 404 | `categoria_no_encontrada` | No existe una categoría con ese ID |

---

### 3. Crear categoría

```http
POST /api/v1/categorias
Authorization: Bearer {token}
Content-Type: application/json
```

**Request body**:

```json
{ "nombre": "Lácteo" }
```

**Response 201 Created**:

```json
{
  "id": 1,
  "nombre": "Lácteo",
  "activo": true,
  "creado_por": 1,
  "creado_en": "2026-05-24T10:00:00",
  "actualizado_por": 1,
  "actualizado_en": "2026-05-24T10:00:00",
  "subcategorias": []
}
```

**Errores**:

| Código HTTP | `error` | `campo` | Situación |
|-------------|---------|---------|-----------|
| 400 | `nombre_requerido` | `nombre` | Campo vacío o ausente |
| 401 | `no_autenticado` | — | Token ausente o expirado |
| 403 | `sin_permiso` | — | El rol no es `admin` |
| 409 | `nombre_duplicado` | `nombre` | Ya existe una categoría con ese nombre (case-insensitive) |

---

### 4. Editar nombre de categoría

```http
PUT /api/v1/categorias/{id}
Authorization: Bearer {token}
Content-Type: application/json
```

**Request body**:

```json
{ "nombre": "Lácteo" }
```

**Response 200 OK**: Mismo schema que el detalle de categoría (sin subcategorías anidadas).

**Errores**:

| Código HTTP | `error` | `campo` | Situación |
|-------------|---------|---------|-----------|
| 400 | `nombre_requerido` | `nombre` | Campo vacío o ausente |
| 401 | `no_autenticado` | — | Token ausente o expirado |
| 403 | `sin_permiso` | — | El rol no es `admin` |
| 404 | `categoria_no_encontrada` | — | No existe una categoría con ese ID |
| 409 | `nombre_duplicado` | `nombre` | Ya existe otra categoría con ese nombre (case-insensitive) |

---

### 5. Consultar impacto de inactivación de categoría

```http
GET /api/v1/categorias/{id}/impacto
Authorization: Bearer {token}
```

**Response 200 OK**:

```json
{ "subcategorias_activas": 3 }
```

> El frontend usa este endpoint para decidir si mostrar el modal de confirmación
> antes de llamar a `/inactivar`.

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 404 | `categoria_no_encontrada` | No existe una categoría con ese ID |

---

### 6. Inactivar categoría

```http
PATCH /api/v1/categorias/{id}/inactivar
Authorization: Bearer {token}
```

Inactiva la categoría y, en la misma transacción, todas sus subcategorías activas.

**Response 200 OK**:

```json
{
  "id": 1,
  "nombre": "Lácteo",
  "activo": false,
  "subcategorias_inactivadas": 3,
  "actualizado_por": 1,
  "actualizado_en": "2026-05-24T12:00:00"
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `sin_permiso` | El rol no es `admin` |
| 404 | `categoria_no_encontrada` | No existe una categoría con ese ID |
| 422 | `categoria_ya_inactiva` | La categoría ya está inactiva |

---

### 7. Reactivar categoría

```http
PATCH /api/v1/categorias/{id}/reactivar
Authorization: Bearer {token}
```

Reactiva solo la categoría. Sus subcategorías permanecen inactivas y deben reactivarse
individualmente.

**Response 200 OK**:

```json
{
  "id": 1,
  "nombre": "Lácteo",
  "activo": true,
  "actualizado_por": 1,
  "actualizado_en": "2026-05-24T13:00:00"
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `sin_permiso` | El rol no es `admin` |
| 404 | `categoria_no_encontrada` | No existe una categoría con ese ID |
| 422 | `categoria_ya_activa` | La categoría ya está activa |

---

## Endpoints — Subcategorías

### 8. Crear subcategoría

```http
POST /api/v1/subcategorias
Authorization: Bearer {token}
Content-Type: application/json
```

**Request body**:

```json
{ "nombre": "Quesos", "categoria_id": 1 }
```

**Response 201 Created**:

```json
{
  "id": 1,
  "nombre": "Quesos",
  "categoria_id": 1,
  "activo": true,
  "creado_por": 1,
  "creado_en": "2026-05-24T10:00:00",
  "actualizado_por": 1,
  "actualizado_en": "2026-05-24T10:00:00",
  "total_items": 0
}
```

**Errores**:

| Código HTTP | `error` | `campo` | Situación |
|-------------|---------|---------|-----------|
| 400 | `nombre_requerido` | `nombre` | Campo vacío o ausente |
| 400 | `categoria_requerida` | `categoria_id` | Campo ausente o <= 0 |
| 401 | `no_autenticado` | — | Token ausente o expirado |
| 403 | `sin_permiso` | — | El rol no es `admin` |
| 404 | `categoria_no_encontrada` | `categoria_id` | La categoría padre no existe |
| 409 | `nombre_duplicado` | `nombre` | Ya existe esa subcategoría en esta categoría (case-insensitive) |
| 422 | `categoria_padre_inactiva` | `categoria_id` | No se puede crear una subcategoría bajo una categoría inactiva |

---

### 9. Editar nombre de subcategoría

```http
PUT /api/v1/subcategorias/{id}
Authorization: Bearer {token}
Content-Type: application/json
```

**Request body**:

```json
{ "nombre": "Quesos Maduros" }
```

> El `categoria_id` es inmutable — no se acepta en el request.

**Response 200 OK**: Mismo schema que el response de creación de subcategoría.

**Errores**:

| Código HTTP | `error` | `campo` | Situación |
|-------------|---------|---------|-----------|
| 400 | `nombre_requerido` | `nombre` | Campo vacío o ausente |
| 401 | `no_autenticado` | — | Token ausente o expirado |
| 403 | `sin_permiso` | — | El rol no es `admin` |
| 404 | `subcategoria_no_encontrada` | — | No existe una subcategoría con ese ID |
| 409 | `nombre_duplicado` | `nombre` | Ya existe esa subcategoría en esta categoría (case-insensitive) |

---

### 10. Inactivar subcategoría

```http
PATCH /api/v1/subcategorias/{id}/inactivar
Authorization: Bearer {token}
```

**Response 200 OK**:

```json
{
  "id": 1,
  "nombre": "Quesos",
  "categoria_id": 1,
  "activo": false,
  "actualizado_por": 1,
  "actualizado_en": "2026-05-24T14:00:00"
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `sin_permiso` | El rol no es `admin` |
| 404 | `subcategoria_no_encontrada` | No existe una subcategoría con ese ID |
| 422 | `subcategoria_ya_inactiva` | La subcategoría ya está inactiva |

---

### 11. Reactivar subcategoría

```http
PATCH /api/v1/subcategorias/{id}/reactivar
Authorization: Bearer {token}
```

Requiere que la categoría padre esté activa.

**Response 200 OK**:

```json
{
  "id": 1,
  "nombre": "Quesos",
  "categoria_id": 1,
  "activo": true,
  "actualizado_por": 1,
  "actualizado_en": "2026-05-24T15:00:00"
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `sin_permiso` | El rol no es `admin` |
| 404 | `subcategoria_no_encontrada` | No existe una subcategoría con ese ID |
| 422 | `subcategoria_ya_activa` | La subcategoría ya está activa |
| 422 | `categoria_padre_inactiva` | La categoría padre está inactiva; reactívala primero |
