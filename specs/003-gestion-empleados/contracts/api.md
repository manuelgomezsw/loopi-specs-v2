# Contratos de API REST: 003-gestion-empleados

**Prefijo base**: `/api/v1/`
**Autenticación**: Bearer token JWT en header `Authorization`
**Autorización**: Solo `admin` puede acceder a todos los endpoints de este módulo
**Formato de error**:

```json
{ "error": "codigo_snake_case", "mensaje": "Texto para el usuario", "campo": "opcional", "detalles": [] }
```

---

## Endpoints

### 1. Crear empleado

```http
POST /api/v1/empleados
Authorization: Bearer {token_admin}
Content-Type: application/json
```

**Request body**:

```json
{
  "nombre":           "Ana",
  "apellido":         "Gómez",
  "usuario":          "ana.gomez",
  "rol":              "barista",
  "tienda_id":        2,
  "tipo_documento":   "CC",
  "numero_documento": "1234567890",
  "telefono":         "3001234567",
  "email":            "ana@loopi.co",
  "fecha_nacimiento": "1995-03-15"
}
```

**Campos requeridos**: `nombre`, `apellido`, `usuario`, `rol`
**Condicional**: `tienda_id` requerido si `rol` ∈ `{lider_tienda, barista}`
**Prohibido**: `tienda_id` si `rol = admin`

**Response 201 Created**:

```json
{
  "id":                2,
  "nombre":            "Ana",
  "apellido":          "Gómez",
  "usuario":           "ana.gomez",
  "rol":               "barista",
  "tienda_id":         2,
  "activo":            true,
  "contrasena_temporal": "aB3xK9mP2nQr"
}
```

> `contrasena_temporal` se muestra **una única vez** en esta respuesta y no se vuelve a exponer.

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 400 | `campo_requerido` | Falta `nombre`, `apellido`, `usuario` o `rol` |
| 403 | `acceso_denegado` | El token no corresponde a un `admin` activo |
| 409 | `usuario_duplicado` | Ya existe un empleado con ese `usuario` |
| 422 | `tienda_requerida` | `rol` requiere `tienda_id` pero no se proporcionó |
| 422 | `tienda_no_existe` | `tienda_id` no corresponde a una tienda activa |
| 422 | `tienda_no_permitida_para_admin` | `rol=admin` no admite `tienda_id` |
| 422 | `tipo_documento_invalido` | `tipo_documento` tiene un valor fuera del conjunto permitido (CC, CE, NUIP, PE) |

---

### 2. Listar empleados

```http
GET /api/v1/empleados
Authorization: Bearer {token_admin}
```

**Query parameters**:

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `q` | string | `""` | Búsqueda parcial sobre `nombre`, `apellido` o `usuario` (ILIKE) |
| `tienda_id` | integer | — | Filtrar por tienda |
| `activo` | boolean | — | Filtrar por estado (`true` / `false`) |
| `page` | integer | `1` | Número de página (1-based) |
| `limit` | integer | `20` | Registros por página (máx. 100) |

**Response 200 OK**:

```json
{
  "empleados": [
    {
      "id":        1,
      "nombre":    "Carlos",
      "apellido":  "Ramírez",
      "usuario":   "carlos.ramirez",
      "rol":       "lider_tienda",
      "tienda_id": 1,
      "activo":    true
    }
  ],
  "total": 42,
  "page":  1,
  "limit": 20
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 403 | `acceso_denegado` | El token no corresponde a un `admin` activo |

---

### 3. Detalle de empleado

```http
GET /api/v1/empleados/{id}
Authorization: Bearer {token_admin}
```

**Response 200 OK**:

```json
{
  "id":                1,
  "nombre":            "Carlos",
  "apellido":          "Ramírez",
  "usuario":           "carlos.ramirez",
  "rol":               "lider_tienda",
  "tienda_id":         1,
  "tipo_documento":    "CC",
  "numero_documento":  "9876543210",
  "telefono":          "3109876543",
  "email":             "carlos@loopi.co",
  "fecha_nacimiento":  "1990-07-22",
  "activo":            true,
  "requiere_cambio_contrasena": false,
  "creado_en":         "2026-05-18T10:00:00",
  "actualizado_en":    "2026-05-20T14:30:00"
}
```

> `contrasena_hash` **nunca** se incluye en la respuesta.

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 403 | `acceso_denegado` | El token no corresponde a un `admin` activo |
| 404 | `empleado_no_encontrado` | No existe empleado con ese `id` |

---

### 4. Editar empleado

```http
PUT /api/v1/empleados/{id}
Authorization: Bearer {token_admin}
Content-Type: application/json
```

**Request body** (todos los campos son opcionales; solo se actualizan los enviados):

```json
{
  "nombre":           "Carlos Alberto",
  "apellido":         "Ramírez",
  "rol":              "lider_tienda",
  "tienda_id":        2,
  "tipo_documento":   "CC",
  "numero_documento": "9876543210",
  "telefono":         "3109876543",
  "email":            "carlos@loopi.co",
  "fecha_nacimiento": "1990-07-22"
}
```

> El campo `usuario` **no puede modificarse**.

**Response 200 OK**: empleado actualizado (mismo esquema que GET /{id}, sin `contrasena_hash`).

**Comportamientos especiales**:

- Si `rol` cambia a `lider_tienda` o `barista` y `tienda_id` no se envía → error `tienda_requerida`.
- Si `rol` cambia a `admin` → el sistema elimina `tienda_id` automáticamente.
- Los cambios de rol aplican en la **próxima sesión** del empleado afectado.

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 403 | `acceso_denegado` | El token no corresponde a un `admin` activo |
| 404 | `empleado_no_encontrado` | No existe empleado con ese `id` |
| 422 | `tienda_requerida` | Cambio a rol operativo sin `tienda_id` |
| 422 | `tienda_no_existe` | `tienda_id` no corresponde a tienda activa |
| 422 | `tienda_no_permitida_para_admin` | `rol=admin` no admite `tienda_id` |
| 422 | `tipo_documento_invalido` | `tipo_documento` tiene un valor fuera del conjunto permitido (CC, CE, NUIP, PE) |

---

### 5. Cambiar estado del empleado (activar / inactivar)

```http
PATCH /api/v1/empleados/{id}/estado
Authorization: Bearer {token_admin}
Content-Type: application/json
```

**Request body**:

```json
{ "activo": false }
```

**Response 200 OK**:

```json
{ "id": 1, "activo": false }
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 403 | `acceso_denegado` | El token no corresponde a un `admin` activo |
| 404 | `empleado_no_encontrado` | No existe empleado con ese `id` |
| 422 | `ultimo_admin_activo` | Inactivar dejaría el sistema sin admins activos |

---

### 6. Resetear contraseña

```http
POST /api/v1/empleados/{id}/contrasena
Authorization: Bearer {token_admin}
```

> Sin request body.

**Response 200 OK**:

```json
{ "contrasena_temporal": "aB3xK9mP2nQr" }
```

> La contraseña temporal se muestra **una única vez**. El empleado deberá cambiarla en su próximo login.

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 403 | `acceso_denegado` | El token no corresponde a un `admin` activo |
| 404 | `empleado_no_encontrado` | No existe empleado con ese `id` |

---

## Contratos Angular (Frontend)

### Modelo TypeScript

```typescript
// empleado.model.ts
export interface Empleado {
  id: number;
  nombre: string;
  apellido: string;
  usuario: string;
  rol: 'admin' | 'lider_tienda' | 'barista';
  tienda_id: number | null;
  tipo_documento?: string;
  numero_documento?: string;
  telefono?: string;
  email?: string;
  fecha_nacimiento?: string;   // ISO date string 'YYYY-MM-DD'
  activo: boolean;
  requiere_cambio_contrasena?: boolean;
  creado_en?: string;          // datetime Colombia ya aplicado
  actualizado_en?: string;
}

export interface ListaEmpleadosResponse {
  empleados: Empleado[];
  total: number;
  page: number;
  limit: number;
}

export interface CrearEmpleadoResponse extends Empleado {
  contrasena_temporal: string;  // visible solo en creación
}

export interface ResetContrasenaResponse {
  contrasena_temporal: string;
}
```

### Servicio Angular

```typescript
// empleados.service.ts — firma de métodos
@Injectable({ providedIn: 'root' })
export class EmpleadosService {
  private readonly base = '/api/v1/empleados';

  listar(params: ListarEmpleadosParams): Observable<ListaEmpleadosResponse>
  obtener(id: number): Observable<Empleado>
  crear(data: CrearEmpleadoRequest): Observable<CrearEmpleadoResponse>
  editar(id: number, data: EditarEmpleadoRequest): Observable<Empleado>
  cambiarEstado(id: number, activo: boolean): Observable<{ id: number; activo: boolean }>
  resetearContrasena(id: number): Observable<ResetContrasenaResponse>
}
```
