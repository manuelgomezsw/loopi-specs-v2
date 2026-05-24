# Contratos de API REST: 004-unidades-medida

**Prefijo base**: `/api/v1/`
**Autenticación**: Bearer token JWT en header `Authorization`
**Autorización**: Solo `admin` puede escribir (crear, editar, inactivar). Lectura abierta
a todos los roles autenticados (el catálogo es de consulta para módulos consumidores).
**Formato de error**:

```json
{ "error": "codigo_snake_case", "mensaje": "Texto para el usuario", "campo": "opcional", "detalles": [] }
```

---

## Endpoints

### 1. Listar unidades de medida

```http
GET /api/v1/unidades_medida
Authorization: Bearer {token}
```

**Query parameters**:

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `tipo` | string | — | Filtrar por tipo: `peso`, `volumen` o `unidad` |
| `activo` | boolean | — | Filtrar por estado (`true` / `false`). Sin valor: retorna todas |
| `page` | integer | `1` | Número de página (1-based) |
| `limit` | integer | `50` | Registros por página (máx. 200) |

**Response 200 OK**:

```json
{
  "unidades_medida": [
    {
      "id":                1,
      "codigo":            "g",
      "nombre":            "Gramo",
      "tipo_medida":       "peso",
      "factor_conversion": 1.0000,
      "unidad_base":       true,
      "activo":            true,
      "creado_en":         "2026-05-24T10:00:00",
      "actualizado_en":    "2026-05-24T10:00:00"
    },
    {
      "id":                4,
      "codigo":            "kg",
      "nombre":            "Kilogramo",
      "tipo_medida":       "peso",
      "factor_conversion": 1000.0000,
      "unidad_base":       false,
      "activo":            true,
      "creado_en":         "2026-05-24T10:00:00",
      "actualizado_en":    "2026-05-24T10:00:00"
    }
  ],
  "total":  13,
  "page":   1,
  "limit":  50
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 400 | `tipo_invalido` | El parámetro `tipo` no es uno de los valores válidos |
| 401 | `no_autenticado` | Token ausente o expirado |

---

### 2. Detalle de unidad de medida

```http
GET /api/v1/unidades_medida/{id}
Authorization: Bearer {token}
```

**Response 200 OK**:

```json
{
  "id":                4,
  "codigo":            "kg",
  "nombre":            "Kilogramo",
  "tipo_medida":       "peso",
  "factor_conversion": 1000.0000,
  "unidad_base":       false,
  "activo":            true,
  "creado_en":         "2026-05-24T10:00:00",
  "actualizado_en":    "2026-05-24T10:00:00",
  "items_con_unidad_canonica": 5
}
```

> `items_con_unidad_canonica`: cantidad de items activos que tienen esta unidad como canónica.
> Retorna `0` hasta que el módulo 007-items-catalogo esté implementado.

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 404 | `unidad_no_encontrada` | No existe unidad con ese id |

---

### 3. Crear unidad de medida

```http
POST /api/v1/unidades_medida
Authorization: Bearer {token_admin}
Content-Type: application/json
```

**Request body**:

```json
{
  "codigo":            "oz",
  "nombre":            "Onza",
  "tipo_medida":       "peso",
  "factor_conversion": 28.3495
}
```

**Campos requeridos**: `codigo`, `nombre`, `tipo_medida`, `factor_conversion`
**Restricciones**: `factor_conversion > 0`; `tipo_medida` ∈ `{peso, volumen, unidad}`;
`codigo` único en todo el sistema

**Response 201 Created**:

```json
{
  "id":                14,
  "codigo":            "oz",
  "nombre":            "Onza",
  "tipo_medida":       "peso",
  "factor_conversion": 28.3495,
  "unidad_base":       false,
  "activo":            true,
  "creado_en":         "2026-05-24T15:30:00",
  "actualizado_en":    "2026-05-24T15:30:00"
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 400 | `campo_requerido` | Falta `codigo`, `nombre`, `tipo_medida` o `factor_conversion` |
| 400 | `tipo_invalido` | `tipo_medida` no es `peso`, `volumen` ni `unidad` |
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `acceso_denegado` | El token no corresponde a un `admin` activo |
| 409 | `codigo_duplicado` | Ya existe una unidad con ese código |
| 422 | `factor_invalido` | `factor_conversion` ≤ 0 |

---

### 4. Editar unidad de medida

```http
PUT /api/v1/unidades_medida/{id}
Authorization: Bearer {token_admin}
Content-Type: application/json
```

**Request body** (todos los campos editables son opcionales; solo se actualizan los enviados):

```json
{
  "nombre":            "Kilogramos",
  "factor_conversion": 1000.0000
}
```

**Campos editables**: `nombre`, `factor_conversion`
**Campos NO editables**: `codigo` (inmutable si hay items asignados), `tipo_medida`,
`unidad_base`
**Restricciones adicionales**: Para unidades base (`unidad_base = true`), `factor_conversion`
no puede modificarse (siempre es 1.0000)

**Response 200 OK**: Retorna la unidad actualizada completa (mismo schema que GET detalle,
sin `items_con_unidad_canonica`)

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 400 | `campo_requerido` | Body vacío |
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `acceso_denegado` | El token no corresponde a un `admin` activo |
| 404 | `unidad_no_encontrada` | No existe unidad con ese id |
| 409 | `codigo_duplicado` | `codigo` ya existe (si se intenta cambiar el código) |
| 422 | `codigo_en_uso` | `codigo` no puede cambiarse porque la unidad tiene items asignados |
| 422 | `factor_invalido` | `factor_conversion` ≤ 0 |
| 422 | `factor_base_inmutable` | Intento de cambiar el factor de una unidad base |

---

### 5. Inactivar unidad de medida

```http
PATCH /api/v1/unidades_medida/{id}/inactivar
Authorization: Bearer {token_admin}
```

> Llamar a este endpoint **solo después** de que el frontend haya consultado `/impacto`
> y obtenido confirmación explícita del admin.

**Request body**: vacío

**Response 200 OK**:

```json
{
  "id":     4,
  "activo": false,
  "mensaje": "Unidad inactivada correctamente."
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `acceso_denegado` | El token no corresponde a un `admin` activo |
| 404 | `unidad_no_encontrada` | No existe unidad con ese id |
| 409 | `ya_inactiva` | La unidad ya estaba inactiva |
| 422 | `unidad_base_no_inactivable` | La unidad es base de su tipo y hay unidades activas del mismo tipo |

---

### 6. Consultar impacto de inactivación

```http
GET /api/v1/unidades_medida/{id}/impacto
Authorization: Bearer {token_admin}
```

Retorna cuántos items activos tienen esta unidad como canónica. El frontend debe llamar
a este endpoint **antes** de mostrar la opción de inactivar.

**Response 200 OK**:

```json
{
  "unidad_id":                  4,
  "items_con_unidad_canonica":  5,
  "advertencia": "Al inactivar esta unidad, 5 item(s) quedarán con unidad canónica inactiva y sus transacciones nuevas serán bloqueadas hasta que se les reasigne una unidad activa."
}
```

> `advertencia` es `null` cuando `items_con_unidad_canonica = 0`.
> `items_con_unidad_canonica` retorna `0` hasta que el módulo 007-items-catalogo esté activo.

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `acceso_denegado` | El token no corresponde a un `admin` activo |
| 404 | `unidad_no_encontrada` | No existe unidad con ese id |

---

## Modelos TypeScript (loopi-web-v2)

```typescript
// src/app/features/unidades-medida/models/unidad-medida.model.ts

export type TipoMedida = 'peso' | 'volumen' | 'unidad';

export interface UnidadMedida {
  id:               number;
  codigo:           string;
  nombre:           string;
  tipo_medida:      TipoMedida;
  factor_conversion: number;
  unidad_base:      boolean;
  activo:           boolean;
  creado_en:        string;
  actualizado_en:   string;
}

export interface UnidadMedidaDetalle extends UnidadMedida {
  items_con_unidad_canonica: number;
}

export interface ListarUnidadesMedidaResponse {
  unidades_medida: UnidadMedida[];
  total:           number;
  page:            number;
  limit:           number;
}

export interface CrearUnidadMedidaRequest {
  codigo:            string;
  nombre:            string;
  tipo_medida:       TipoMedida;
  factor_conversion: number;
}

export interface EditarUnidadMedidaRequest {
  nombre?:            string;
  factor_conversion?: number;
}

export interface ImpactoInactivacionResponse {
  unidad_id:                 number;
  items_con_unidad_canonica: number;
  advertencia:               string | null;
}

export interface InactivarUnidadResponse {
  id:      number;
  activo:  boolean;
  mensaje: string;
}

export interface ApiError {
  error:    string;
  mensaje:  string;
  campo?:   string;
  detalles: unknown[];
}
```
