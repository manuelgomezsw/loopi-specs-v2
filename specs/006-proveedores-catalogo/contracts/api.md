# Contratos de API REST: 006-proveedores-catalogo

**Prefijo base**: `/api/v1/`
**Autenticación**: Bearer token JWT en header `Authorization`
**Autorización**: Solo `admin` puede escribir (crear, editar, inactivar, activar).
Solo el `admin` tiene acceso de lectura a este módulo (según spec HU-1 Escenario 3).
**Formato de error**:

```json
{ "error": "codigo_snake_case", "mensaje": "Texto para el usuario", "campo": "opcional", "detalles": [] }
```

---

## Endpoints

### 1. Listar proveedores

```http
GET /api/v1/proveedores
Authorization: Bearer {token_admin}
```

**Query parameters**:

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `estado` | string | `todos` | Filtrar por estado: `activo` \| `inactivo` \| `todos` (constitución §Convenciones de API REST) |
| `busqueda` | string | — | Búsqueda por razón social o NIT (subcadena, insensible a mayúsculas) |
| `page` | integer | `1` | Número de página (1-based) |
| `limit` | integer | `50` | Registros por página (máx. 200) |

**Response 200 OK**:

```json
{
  "proveedores": [
    {
      "id":                 1,
      "razon_social":       "Distribuidora La Cosecha S.A.S",
      "nit":                "900123456-7",
      "nombre_contacto":    "Carlos Rodríguez",
      "telefono_contacto":  "3001234567",
      "email_contacto":     "carlos@lacosecha.com",
      "activo":             true,
      "creado_en":          "2026-05-24T10:00:00",
      "actualizado_en":     "2026-05-24T10:00:00"
    }
  ],
  "total":  12,
  "page":   1,
  "limit":  50
}
```

> Cuando `total = 0` el array `proveedores` es `[]`. El frontend muestra el empty state
> (RF-PROV-04.4).

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 400 | `estado_invalido` | `estado` no es uno de `activo`, `inactivo`, `todos` |
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `acceso_denegado` | El rol del token no es `admin` |

---

### 2. Detalle de proveedor

```http
GET /api/v1/proveedores/{id}
Authorization: Bearer {token_admin}
```

**Response 200 OK**:

```json
{
  "id":                 1,
  "razon_social":       "Distribuidora La Cosecha S.A.S",
  "nit":                "900123456-7",
  "nombre_contacto":    "Carlos Rodríguez",
  "telefono_contacto":  "3001234567",
  "email_contacto":     "carlos@lacosecha.com",
  "activo":             true,
  "creado_en":          "2026-05-24T10:00:00",
  "actualizado_en":     "2026-05-24T10:00:00",
  "items_asignados":    3
}
```

> `items_asignados`: cantidad de items activos que tienen este proveedor asignado como
> habitual. Retorna `0` hasta que el módulo 007-items-catalogo esté implementado.

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `acceso_denegado` | El rol del token no es `admin` |
| 404 | `proveedor_no_encontrado` | No existe proveedor con ese id |

---

### 3. Crear proveedor

```http
POST /api/v1/proveedores
Authorization: Bearer {token_admin}
Content-Type: application/json
```

**Request body**:

```json
{
  "razon_social":      "Proveedor Informal",
  "nit":               "PROV-INFORMAL-001",
  "nombre_contacto":   "Juan García",
  "telefono_contacto": "3009876543",
  "email_contacto":    "juan@proveedor.com"
}
```

**Campos requeridos**: `razon_social`, `nit`
**Campos opcionales**: `nombre_contacto`, `telefono_contacto`, `email_contacto`
**Restricciones**:

- `nit`: cadena no vacía; única en todo el sistema (insensible a mayúsculas/minúsculas,
  collation `utf8mb4_unicode_ci`)
- `razon_social`: cadena no vacía
- `email_contacto`: si presente, debe tener formato de email válido

**Response 201 Created**:

```json
{
  "id":                 15,
  "razon_social":       "Proveedor Informal",
  "nit":                "PROV-INFORMAL-001",
  "nombre_contacto":    "Juan García",
  "telefono_contacto":  "3009876543",
  "email_contacto":     "juan@proveedor.com",
  "activo":             true,
  "creado_en":          "2026-05-24T15:30:00",
  "actualizado_en":     "2026-05-24T15:30:00"
}
```

**Errores**:

| Código HTTP | `error` | `campo` | Situación |
|-------------|---------|---------|-----------|
| 400 | `campo_requerido` | `razon_social` o `nit` | Campo obligatorio ausente o vacío |
| 400 | `email_invalido` | `email_contacto` | Formato de email inválido |
| 401 | `no_autenticado` | — | Token ausente o expirado |
| 403 | `acceso_denegado` | — | El rol del token no es `admin` |
| 409 | `nit_duplicado` | `nit` | Ya existe un proveedor con ese NIT |

---

### 4. Editar proveedor

```http
PUT /api/v1/proveedores/{id}
Authorization: Bearer {token_admin}
Content-Type: application/json
```

**Request body** (todos los campos son opcionales; solo se actualizan los enviados):

```json
{
  "razon_social":      "Distribuidora La Cosecha Ltda",
  "nit":               "900123456-8",
  "nombre_contacto":   "María López",
  "telefono_contacto": "3107654321",
  "email_contacto":    "maria@lacosecha.com"
}
```

**Campos editables**: `razon_social`, `nit`, `nombre_contacto`, `telefono_contacto`,
`email_contacto`

> El NIT es editable (RF-PROV-02.2). Al cambiar el NIT, el sistema verifica unicidad
> excluyendo el propio registro (RF-PROV-02.3).

**Response 200 OK**: Retorna el proveedor actualizado completo (mismo schema que GET
detalle, sin `items_asignados`):

```json
{
  "id":                 1,
  "razon_social":       "Distribuidora La Cosecha Ltda",
  "nit":                "900123456-8",
  "nombre_contacto":    "María López",
  "telefono_contacto":  "3107654321",
  "email_contacto":     "maria@lacosecha.com",
  "activo":             true,
  "creado_en":          "2026-05-24T10:00:00",
  "actualizado_en":     "2026-05-24T16:00:00"
}
```

**Errores**:

| Código HTTP | `error` | `campo` | Situación |
|-------------|---------|---------|-----------|
| 400 | `campo_vacio` | `razon_social` o `nit` | Se envió el campo pero con valor vacío |
| 400 | `email_invalido` | `email_contacto` | Formato de email inválido |
| 401 | `no_autenticado` | — | Token ausente o expirado |
| 403 | `acceso_denegado` | — | El rol del token no es `admin` |
| 404 | `proveedor_no_encontrado` | — | No existe proveedor con ese id |
| 409 | `nit_duplicado` | `nit` | El NIT ya pertenece a otro proveedor |

---

### 5. Inactivar proveedor

```http
PATCH /api/v1/proveedores/{id}/inactivar
Authorization: Bearer {token_admin}
```

> El frontend DEBE mostrar modal de confirmación antes de llamar a este endpoint
> (constitución §Feedback: acciones destructivas reversibles).

**Request body**: vacío

**Response 200 OK**:

```json
{
  "id":      1,
  "activo":  false,
  "mensaje": "Proveedor inactivado correctamente."
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `acceso_denegado` | El rol del token no es `admin` |
| 404 | `proveedor_no_encontrado` | No existe proveedor con ese id |
| 409 | `ya_inactivo` | El proveedor ya estaba inactivo |

---

### 6. Activar proveedor (reactivar)

```http
PATCH /api/v1/proveedores/{id}/activar
Authorization: Bearer {token_admin}
```

**Request body**: vacío

**Response 200 OK**:

```json
{
  "id":      1,
  "activo":  true,
  "mensaje": "Proveedor activado correctamente."
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `acceso_denegado` | El rol del token no es `admin` |
| 404 | `proveedor_no_encontrado` | No existe proveedor con ese id |
| 409 | `ya_activo` | El proveedor ya estaba activo |

---

## Modelos TypeScript (`loopi-web`)

```typescript
// src/app/features/proveedores/models/proveedor.model.ts

export interface Proveedor {
  id:                 number;
  razon_social:       string;
  nit:                string;
  nombre_contacto:    string | null;
  telefono_contacto:  string | null;
  email_contacto:     string | null;
  activo:             boolean;
  creado_en:          string;
  actualizado_en:     string;
}

export interface ProveedorDetalle extends Proveedor {
  items_asignados: number;
}

export interface ListarProveedoresResponse {
  proveedores: Proveedor[];
  total:       number;
  page:        number;
  limit:       number;
}

export interface CrearProveedorRequest {
  razon_social:      string;
  nit:               string;
  nombre_contacto?:  string;
  telefono_contacto?: string;
  email_contacto?:   string;
}

export interface EditarProveedorRequest {
  razon_social?:     string;
  nit?:              string;
  nombre_contacto?:  string;
  telefono_contacto?: string;
  email_contacto?:   string;
}

export interface CambiarEstadoResponse {
  id:      number;
  activo:  boolean;
  mensaje: string;
}

export interface FiltrosListadoProveedores {
  estado?:    'activo' | 'inactivo' | 'todos';
  busqueda?:  string;
  page?:      number;
  limit?:     number;
}

export interface ApiError {
  error:    string;
  mensaje:  string;
  campo?:   string;
  detalles: unknown[];
}
```
