# Contratos de API REST: 007-items-catalogo

**Prefijo base**: `/api/v1/`
**Autenticación**: Bearer token JWT en header `Authorization`
**Autorización**:

- Solo `admin` puede crear, editar, inactivar, reactivar y gestionar costos por tienda.
- Todos los roles autenticados pueden leer el catálogo de items (el catálogo es de consulta
  para módulos consumidores), **excepto** el historial de costos por tienda: consultar
  `GET /items/{id}/costos_tienda` es exclusivo de `admin`, según la matriz de permisos
  `§2.5` ("Ver historial de costos") de [loopi-v2-funcional/spec.md](../../loopi-v2-funcional/spec.md).

**Formato de error**:

```json
{ "error": "codigo_snake_case", "mensaje": "Texto para el usuario", "campo": "opcional", "detalles": [] }
```

---

## Endpoints — Items

### 1. Listar items (paginado)

```http
GET /api/v1/items
Authorization: Bearer {token}
```

**Query parameters**:

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `tipo` | string | — | Filtrar por tipo: `insumo`, `material_consumo` o `activo` |
| `frecuencia` | string | — | Filtrar por frecuencia: `diario`, `semanal` o `mensual` |
| `activo` | boolean | — | Sin valor: retorna todos; `true`: solo activos; `false`: solo inactivos |
| `pagina` | int | 1 | Página (1-based) |
| `por_pagina` | int | 50 | Registros por página (máx 200) |

**Response 200 OK**:

```json
{
  "items": [
    {
      "id": 1,
      "codigo": "LEC-001",
      "nombre": "Leche Entera",
      "tipo": "insumo",
      "subcategoria_id": 3,
      "subcategoria_nombre": "Lácteos > Líquidos",
      "proveedor_id": 2,
      "proveedor_nombre": "Distribuidora Norte",
      "unidad_medida_id": 5,
      "unidad_medida_simbolo": "ml",
      "costo_unitario": 3200,
      "frecuencia_inventario": "diario",
      "stock_seguridad": "10000.0000",
      "tiempo_entrega_dias": 2,
      "activo": true,
      "creado_por": 1,
      "creado_en": "2026-05-24T10:00:00",
      "actualizado_por": 1,
      "actualizado_en": "2026-05-24T10:00:00"
    }
  ],
  "total": 87,
  "pagina": 1,
  "total_paginas": 2
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 400 | `parametro_invalido` | `tipo`, `frecuencia` o `activo` con valor no reconocido |
| 401 | `no_autenticado` | Token ausente o expirado |

---

### 2. Detalle de item

```http
GET /api/v1/items/{id}
Authorization: Bearer {token}
```

**Response 200 OK**:

```json
{
  "id": 1,
  "codigo": "LEC-001",
  "nombre": "Leche Entera",
  "tipo": "insumo",
  "subcategoria_id": 3,
  "subcategoria_nombre": "Lácteos > Líquidos",
  "proveedor_id": 2,
  "proveedor_nombre": "Distribuidora Norte",
  "unidad_medida_id": 5,
  "unidad_medida_simbolo": "ml",
  "costo_unitario": 3200,
  "frecuencia_inventario": "diario",
  "stock_seguridad": "10000.0000",
  "tiempo_entrega_dias": 2,
  "activo": true,
  "esta_en_uso": true,
  "creado_por": 1,
  "creado_en": "2026-05-24T10:00:00",
  "actualizado_por": 1,
  "actualizado_en": "2026-05-24T10:00:00"
}
```

> `esta_en_uso`: indica si el código es editable (`false`) o está bloqueado (`true`).
> El frontend lo usa para deshabilitar el campo `codigo` en el formulario de edición.

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 404 | `item_no_encontrado` | No existe un item con ese ID |

---

### 3. Crear item

```http
POST /api/v1/items
Authorization: Bearer {token}
Content-Type: application/json
```

**Request body**:

```json
{
  "codigo": "LEC-001",
  "nombre": "Leche Entera",
  "tipo": "insumo",
  "subcategoria_id": 3,
  "proveedor_id": 2,
  "unidad_medida_id": 5,
  "costo_unitario": 3200,
  "frecuencia_inventario": "diario",
  "stock_seguridad": "10000.0000",
  "tiempo_entrega_dias": 2
}
```

> Campos opcionales: `proveedor_id`, `costo_unitario`, `tiempo_entrega_dias`.

**Response 201 Created**: Mismo schema que el detalle de item (con `esta_en_uso: false`).

**Errores**:

| Código HTTP | `error` | `campo` | Situación |
|-------------|---------|---------|-----------|
| 400 | `codigo_requerido` | `codigo` | Campo vacío o ausente |
| 400 | `nombre_requerido` | `nombre` | Campo vacío o ausente |
| 400 | `tipo_invalido` | `tipo` | Valor fuera de `insumo`, `material_consumo`, `activo` |
| 400 | `subcategoria_requerida` | `subcategoria_id` | Campo ausente o ≤ 0 |
| 400 | `unidad_medida_requerida` | `unidad_medida_id` | Campo ausente o ≤ 0 |
| 400 | `frecuencia_invalida` | `frecuencia_inventario` | Valor fuera de `diario`, `semanal`, `mensual` |
| 400 | `stock_seguridad_requerido` | `stock_seguridad` | Campo ausente o valor negativo |
| 401 | `no_autenticado` | — | Token ausente o expirado |
| 403 | `sin_permiso` | — | El rol no es `admin` |
| 404 | `subcategoria_no_encontrada` | `subcategoria_id` | Subcategoría no existe |
| 404 | `proveedor_no_encontrado` | `proveedor_id` | Proveedor no existe |
| 404 | `unidad_medida_no_encontrada` | `unidad_medida_id` | Unidad de medida no existe |
| 409 | `codigo_duplicado` | `codigo` | Ya existe un item con ese código |
| 409 | `nombre_duplicado` | `nombre` | Ya existe un item con ese nombre (case-insensitive) |
| 422 | `subcategoria_inactiva` | `subcategoria_id` | La subcategoría está inactiva |
| 422 | `proveedor_inactivo` | `proveedor_id` | El proveedor está inactivo |
| 422 | `unidad_medida_inactiva` | `unidad_medida_id` | La unidad de medida está inactiva |

---

### 4. Editar item

```http
PUT /api/v1/items/{id}
Authorization: Bearer {token}
Content-Type: application/json
```

**Request body**:

```json
{
  "codigo": "LEC-002",
  "nombre": "Leche Entera Premium",
  "subcategoria_id": 3,
  "proveedor_id": 4,
  "unidad_medida_id": 5,
  "costo_unitario": 3500,
  "frecuencia_inventario": "diario",
  "stock_seguridad": "15000.0000",
  "tiempo_entrega_dias": 1,
  "confirmar_cambio_unidad": false
}
```

> - `codigo`: ignorado (con advertencia silenciosa) si `esta_en_uso = true`; el backend
>   rechaza el cambio con `422 codigo_en_uso`. El frontend debe deshabilitar el campo.
> - `confirmar_cambio_unidad`: requerido como `true` si se está cambiando `unidad_medida_id`
>   y el item ya tiene historial de stock. Si se omite o es `false`, el backend retorna
>   `422 cambio_unidad_requiere_confirmacion`.

**Response 200 OK**: Mismo schema que el detalle de item.

**Errores**:

| Código HTTP | `error` | `campo` | Situación |
|-------------|---------|---------|-----------|
| 400 | `nombre_requerido` | `nombre` | Campo vacío o ausente |
| 401 | `no_autenticado` | — | Token ausente o expirado |
| 403 | `sin_permiso` | — | El rol no es `admin` |
| 404 | `item_no_encontrado` | — | No existe un item con ese ID |
| 404 | `subcategoria_no_encontrada` | `subcategoria_id` | Subcategoría no existe |
| 404 | `proveedor_no_encontrado` | `proveedor_id` | Proveedor no existe |
| 404 | `unidad_medida_no_encontrada` | `unidad_medida_id` | Unidad de medida no existe |
| 409 | `nombre_duplicado` | `nombre` | Ya existe otro item con ese nombre (case-insensitive) |
| 422 | `codigo_en_uso` | `codigo` | El item ya tiene usos en inventarios/pedidos/recetas |
| 422 | `subcategoria_inactiva` | `subcategoria_id` | La subcategoría está inactiva |
| 422 | `proveedor_inactivo` | `proveedor_id` | El proveedor está inactivo |
| 422 | `unidad_medida_inactiva` | `unidad_medida_id` | La unidad de medida está inactiva |
| 422 | `cambio_unidad_requiere_confirmacion` | `unidad_medida_id` | El item tiene historial de stock; se requiere `confirmar_cambio_unidad: true` |

---

### 5. Inactivar item

```http
PATCH /api/v1/items/{id}/inactivar
Authorization: Bearer {token}
```

**Response 200 OK**:

```json
{
  "id": 1,
  "codigo": "LEC-001",
  "nombre": "Leche Entera",
  "activo": false,
  "actualizado_por": 1,
  "actualizado_en": "2026-05-24T12:00:00"
}
```

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `sin_permiso` | El rol no es `admin` |
| 404 | `item_no_encontrado` | No existe un item con ese ID |
| 422 | `item_ya_inactivo` | El item ya está inactivo |

---

### 6. Reactivar item

```http
PATCH /api/v1/items/{id}/reactivar
Authorization: Bearer {token}
```

**Response 200 OK**:

```json
{
  "id": 1,
  "codigo": "LEC-001",
  "nombre": "Leche Entera",
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
| 404 | `item_no_encontrado` | No existe un item con ese ID |
| 422 | `item_ya_activo` | El item ya está activo |

---

## Endpoints — Costos por tienda

### 7. Listar historial de costos por tienda

```http
GET /api/v1/items/{id}/costos_tienda
Authorization: Bearer {token}
```

> Exclusivo de rol `admin` — a diferencia del resto de endpoints de lectura del catálogo,
> el historial de costos no es visible para `lider_tienda` ni `barista` (matriz `§2.5`).

Retorna el historial completo de costos registrados para cada tienda, con el costo vigente
identificado (primera entrada de cada tienda, ordenada por `vigente_desde DESC`).

**Response 200 OK**:

```json
{
  "item_id": 1,
  "costo_global": 3200,
  "costos_por_tienda": [
    {
      "tienda_id": 1,
      "tienda_nombre": "Sede Norte",
      "costo_vigente": 3400,
      "historial": [
        {
          "id": 5,
          "costo_unitario": 3400,
          "vigente_desde": "2026-05-20T09:00:00",
          "creado_por": 1,
          "creado_en": "2026-05-20T09:00:00"
        },
        {
          "id": 2,
          "costo_unitario": 3200,
          "vigente_desde": "2026-05-10T08:00:00",
          "creado_por": 1,
          "creado_en": "2026-05-10T08:00:00"
        }
      ]
    }
  ]
}
```

> Las tiendas sin registro en `items_costos_tienda` no aparecen en la lista;
> para ellas aplica el `costo_global` (`Item.costo_unitario`).

**Errores**:

| Código HTTP | `error` | Situación |
|-------------|---------|-----------|
| 401 | `no_autenticado` | Token ausente o expirado |
| 403 | `sin_permiso` | El rol no es `admin` |
| 404 | `item_no_encontrado` | No existe un item con ese ID |

---

### 8. Registrar costo por tienda

```http
POST /api/v1/items/{id}/costos_tienda
Authorization: Bearer {token}
Content-Type: application/json
```

Inserta un nuevo registro histórico con el costo actualizado para la tienda indicada.
El `vigente_desde` es asignado por el servidor (`NOW()`).

**Request body**:

```json
{
  "tienda_id": 1,
  "costo_unitario": 3400
}
```

**Response 201 Created**:

```json
{
  "id": 5,
  "item_id": 1,
  "tienda_id": 1,
  "costo_unitario": 3400,
  "vigente_desde": "2026-05-20T09:00:00",
  "creado_por": 1,
  "creado_en": "2026-05-20T09:00:00"
}
```

**Errores**:

| Código HTTP | `error` | `campo` | Situación |
|-------------|---------|---------|-----------|
| 400 | `tienda_requerida` | `tienda_id` | Campo ausente o ≤ 0 |
| 400 | `costo_invalido` | `costo_unitario` | Valor ausente o ≤ 0 |
| 401 | `no_autenticado` | — | Token ausente o expirado |
| 403 | `sin_permiso` | — | El rol no es `admin` |
| 404 | `item_no_encontrado` | — | No existe un item con ese ID |
| 404 | `tienda_no_encontrada` | `tienda_id` | No existe la tienda indicada |
