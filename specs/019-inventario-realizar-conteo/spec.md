# 019-inventario-realizar-conteo

**Versión:** 1.0.0  
**Estado:** Especificación  
**Dependencias:** 018-inventario-iniciar-conteo (mergeada ✅)  
**Phase:** 3 de Refactorización Inventario

---

## 1. Resumen Ejecutivo

La feature **019** implementa la **HU2 (Histórico de Usuario 2)**: registro del conteo item-por-item durante un conteo en progreso. Incluye autosave automático y recuperación de sesión para que el usuario pueda pausar y reanudar sin perder datos.

**Principales entregables:**

- Backend: módulo `realizar/` con API REST y observabilidad OTel
- Frontend: componente `realizar-conteo/` con validación y autosave
- Recuperación de sesión automática

---

## 2. Historias de Usuario

### HU2: Registrar Valores de Conteo Item-por-Item

**Como** empleado contando inventario  
**Quiero** registrar el valor (cantidad) de cada item conforme avanzo  
**Para que** el sistema registre automáticamente mi progreso sin perder datos

**Criterios de Aceptación:**

1. **CA2.1: Navego a formulario item-por-item**
   - El sistema carga automáticamente los items del conteo en progreso
   - Cada item muestra: código, descripción, unidad, valor_esperado
   - Orden: el primero sin valor registrado (si hay 0 registrados, el primero del listado)
   - Los items ya registrados se marcan visualmente como completados

2. **CA2.2: Registro un valor y autosave dispara**
   - Ingreso un valor numérico ≥ 0
   - Valido en tiempo real (no negativo, no vacío)
   - Al salir del campo (blur), dispara POST `/api/v1/inventarios/:id/items/:item_id/valor`
   - Backend retorna { success, item_id, valor_real, diferencia }
   - Indicador de carga momentáneo ("guardando...")
   - Transito al siguiente item si hay

3. **CA2.3: Manejo de errores de autosave**
   - Si falla la POST, muestro notificación de error en rojo
   - Botón "Reintentar" vuelve a disparar el autosave
   - El campo conserva el valor ingresado (no se pierde)
   - No avanzo al siguiente item si no confirmo el reintento

4. **CA2.4: Indicadores de progreso**
   - Barra de progreso: X de Y items completados
   - Resumen: "5 items registrados, 3 pendientes"
   - Badge en items con diferencia > 10% (valor_esperado vs valor_real)

5. **CA2.5: Recuperación de sesión**
   - Si cierro el navegador o sesión expira
   - Al volver a la URL `/inventarios/:id/realizar`, cargo automáticamente los datos registrados
   - Precargo valores ya ingresados en los campos
   - Sigo desde donde paré

6. **CA2.6: Abandono del conteo**
   - Botón "Cancelar" sin confirmación (datos se guardan)
   - Botón "Pausar" lleva a vista de resumen del conteo
   - Botón "Guardar y salir" (equivalente a pausar)

---

## 3. Requerimientos Funcionales

### RF-INV-02: Autosave y Recuperación de Sesión

#### RF-INV-02.1: Autosave POST

- **Endpoint:** `POST /api/v1/inventarios/:id/items/:item_id/valor`
- **Request:**

  ```json
  {
    "valor_real": 15
  }
  ```

- **Response (200 OK):**

  ```json
  {
    "success": true,
    "item_id": 123,
    "valor_real": 15,
    "valor_esperado": 20,
    "diferencia": -5,
    "diferencia_porcentaje": -25.0
  }
  ```

- **Errors:**
  - 400: valor < 0, item_id no existe
  - 404: inventario no existe
  - 409: conteo no está en estado "en_progreso"
  - 500: error de base de datos

#### RF-INV-02.2: Precarga de Datos en Sesión

- Al cargar `/inventarios/:id/realizar`:
  - Backend GET `/api/v1/inventarios/:id/detalles?estado=en_progreso`
  - Retorna lista de items con campos: { item_id, valor_esperado, valor_real (null si no registrado) }
  - Frontend precarga los valores en los campos

#### RF-INV-02.3: Validación Valor Registrado

- Valor debe ser ≥ 0 (validación en frontend + backend)
- Validación en tiempo real en frontend (onChange)
- Mensaje: "El valor debe ser 0 o mayor"
- Si ingreso carácter no numérico, no se acepta

#### RF-INV-02.4: Indicadores de Diferencia

- Diferencia = valor_real - valor_esperado
- % = (Diferencia / valor_esperado) × 100
- Badge rojo si % < -10% o % > 10%
- Badge amarillo si -10% ≤ % ≤ 10%

---

## 4. Requerimientos No Funcionales

### RNF-INV-04: Observabilidad y Métricas

#### RNF-INV-04.1: OpenTelemetry Spans

- **Spans principales:**
  - `inventario.realizar.registrar_valor` — tiempo total POST
    - Atributos: inventario_id, item_id, valor_real, resultado (success/error)
  - `inventario.realizar.validar_valor` — validación value >= 0
    - Atributos: valor, valido (true/false)
  - `inventario.realizar.actualizar_detalle` — UPDATE en DB
    - Atributos: filas_afectadas, duracion_ms

#### RNF-INV-04.2: Datadog Métricas

- **Histogram:** `inventario.realizar.registrar_valor.duration_ms`
  - Tags: inventario_id, tienda_id, resultado
  - Buckets: 10, 50, 100, 500, 1000ms
- **Counter:** `inventario.realizar.registrar_valor.total`
  - Tags: tienda_id, resultado (success/error)
  - Incremental en cada POST
- **Gauge:** `inventario.realizar.items_completados`
  - Tags: tienda_id, inventario_id
  - Actualizarse en cada éxito

#### RNF-INV-04.3: Logging

- Level DEBUG: inicio de POST, parámetros recibidos
- Level INFO: éxito de registros (cada 5 registros)
- Level ERROR: fallos de validación, errores de DB

### RNF-INV-05: Seguridad

- Validar propietario de conteo (usuario.tienda_id == conteo.tienda_id)
- No permitir edición si conteo no está en estado "en_progreso"
- Validar item_id existe en detalle_inventario del conteo

### RNF-INV-06: Performance

- GET precarga: < 500ms (< 500 items)
- POST autosave: < 200ms (índices en item_id, inventario_id)
- Frontend sin bloques: loader mientras autosave está en vuelo

---

## 5. Modelo de Datos

### Tabla: `detalle_inventario` (Existente, Sin Cambios)

| Campo | Tipo | Estado |
|-------|------|--------|
| id | BIGINT UNSIGNED | PK — Existente |
| inventario_id | BIGINT UNSIGNED | FK → inventarios — Existente |
| item_id | BIGINT UNSIGNED | FK → items — Existente |
| valor_sugerido | DECIMAL(12,4) | Valor de referencia — Existente |
| valor_esperado | DECIMAL(12,4) | Del snapshot stock_actual — Existente |
| **valor_real** | DECIMAL(12,4) NULL | ✅ Campo existente — Se completa en 019 |
| **diferencia** | DECIMAL(12,4) NULL | ✅ Campo existente — Se calcula en 019 |
| creado_en | DATETIME | Existente |
| actualizado_en | DATETIME | ✅ Se actualiza con cada registro de valor_real |

**Nota:** No se agregan nuevos campos. 019 reutiliza campos existentes de `detalle_inventario`.

---

## 6. API Contracts

### 6.1 POST Registrar Valor

```text
POST /api/v1/inventarios/:inventario_id/items/:item_id/valor
```

**Headers:**

```text
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**

```json
{
  "valor_real": 15,
  "observaciones": "Daño en 2 unidades"
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "item_id": "550e8400-e29b-41d4-a716-446655440000",
  "item_codigo": "ITEM-001",
  "item_descripcion": "Arroz Integral 1kg",
  "valor_esperado": 20,
  "valor_real": 15,
  "diferencia": -5,
  "diferencia_porcentaje": -25.0,
  "unidad": "bolsas",
  "timestamp": "2026-07-20T14:30:00Z"
}
```

**Response (400 Bad Request):**

```json
{
  "error": "INVALID_VALOR",
  "message": "valor_real debe ser >= 0",
  "field": "valor_real"
}
```

**Response (409 Conflict):**

```json
{
  "error": "CONTEO_NO_EN_PROGRESO",
  "message": "El conteo no está en estado 'en_progreso'",
  "estado_actual": "completado"
}
```

### 6.2 GET Precarga Items

```text
GET /api/v1/inventarios/:inventario_id/detalles?estado=en_progreso
```

**Response (200 OK):**

```json
{
  "inventario_id": 1001,
  "tienda_id": 5,
  "estado": "en_progreso",
  "items": [
    {
      "item_id": 201,
      "item_codigo": "ITEM-001",
      "item_descripcion": "Arroz Integral 1kg",
      "unidad_id": 12,
      "valor_esperado": 20.0,
      "valor_real": null,
      "completado": false,
      "diferencia": null
    },
    {
      "item_id": 202,
      "item_codigo": "ITEM-002",
      "item_descripcion": "Aceite de Oliva 1L",
      "unidad_id": 13,
      "valor_esperado": 10.0,
      "valor_real": 10.0,
      "completado": true,
      "diferencia": 0.0
    }
  ],
  "resumen": {
    "total_items": 2,
    "completados": 1,
    "pendientes": 1,
    "porcentaje_progreso": 50.0
  }
}
```

---

## 7. Componentes Frontend

### 019-realizar-conteo Component

**Ubicación:** `src/app/modules/inventario/realizar-conteo/`

**Estructura:**

```text
realizar-conteo/
  ├── realizar-conteo.component.ts       (200 líneas aprox)
  ├── realizar-conteo.component.html     (120 líneas aprox)
  ├── realizar-conteo.component.css      (80 líneas aprox)
  ├── realizar-conteo.component.spec.ts  (180 líneas aprox)
  └── services/
      └── realizar-conteo.service.ts     (100 líneas aprox)
```

**Responsabilidades:**

1. **TypeScript (Component Logic)**
   - OnInit: cargar precarga de items via GET
   - Método: registrarValor() → autosave POST
   - Método: siguienteItem() → navega al siguiente sin valor
   - Método: irAPausa() → navegar a resumen
   - Manejo de errores de autosave con reintentos
   - Calcular diferencias y % automáticamente

2. **HTML (Plantilla)**
   - Iteración sobre items con \*ngFor
   - Input para valor_real con validación (tipo="number", min="0")
   - Barra de progreso (progress bar)
   - Indicadores: "X de Y completados"
   - Botones: Pausar, Cancelar, Siguiente (si hay)
   - Loader de autosave en transición

3. **CSS (Estilos)**
   - Responsive (mobile + desktop)
   - Badge rojo/amarillo para diferencias
   - Animación suave en transiciones
   - Indicador visual de "guardando..."

4. **Service**
   - POST registrarValor()
   - GET precargaItems()
   - Manejo de errores con retry logic

---

## 8. Módulo Backend

### internal/inventarios/realizar/

**Estructura:**

```text
internal/inventarios/realizar/
├── handler.go          (150 líneas aprox)
├── service.go          (200 líneas aprox)
├── repository.go       (100 líneas aprox)
├── types.go            (50 líneas aprox)
├── errors.go           (30 líneas aprox)
├── otel.go             (30 líneas aprox)
├── metrics.go          (80 líneas aprox)
├── handler_test.go     (200 líneas aprox)
├── service_test.go     (180 líneas aprox)
└── repository_test.go  (120 líneas aprox)
```

**Nota:** Estructura y patrón copiado de `internal/inventarios/iniciar/` (ya existente en 018)

**Responsabilidades:**

1. **handler.go**
   - `RegisterValueHandler()` — POST `/api/v1/inventarios/:id/items/:item_id/valor`
   - Validación de parámetros (id, item_id, body)
   - Llamar a service.RegistrarValor()
   - Retornar JSON con spans OTel

2. **service.go**
   - `RegistrarValor(ctx, inventarioID, itemID, valor_real, observaciones)`
   - Validar estado conteo = "en_progreso"
   - Validar valor_real ≥ 0
   - Validar pertenencia: conteo.tienda_id == usuario.tienda_id
   - Calcular diferencia
   - Llamar a repository.UpdateDetalle()
   - Retornar DTO de respuesta

3. **repository.go**
   - `UpdateDetalle(ctx, inventarioID, itemID, valor_real, observaciones, registradoPor)`
   - UPDATE detalle_inventario SET valor_real, observaciones, registrado_en, registrado_por
   - Retornar registro actualizado

4. **models.go**
   - `RegistrarValorRequest` — estructura de entrada
   - `RegistrarValorResponse` — estructura de salida
   - `ItemDetalle` — modelo de item con valores

---

## 9. Observabilidad (OTel + Datadog)

### Spans Principales

```go
// En service.RegistrarValor()
span := tracer.Start(ctx, "inventario.realizar.registrar_valor")
defer span.End()

// Atributos
span.SetAttributes(
  attribute.String("inventario.id", inventarioID),
  attribute.String("item.id", itemID),
  attribute.Float64("valor.real", valorReal),
  attribute.String("resultado", "success"),
)

// Sub-span de validación
validationSpan := tracer.Start(ctx, "inventario.realizar.validar_valor")
validationSpan.SetAttributes(attribute.Float64("valor", valorReal), attribute.Bool("valido", true))
validationSpan.End()

// Sub-span de UPDATE
dbSpan := tracer.Start(ctx, "inventario.realizar.actualizar_detalle")
defer dbSpan.End()
```

### Métricas Datadog

```go
// Histogram de duración
meter.Float64Histogram("inventario.realizar.registrar_valor.duration_ms").Record(ctx, duracion, 
  metric.WithAttributes(
    attribute.String("tienda_id", tiendaID),
    attribute.String("resultado", "success"),
  ),
)

// Counter de totales
meter.Int64Counter("inventario.realizar.registrar_valor.total").Add(ctx, 1,
  metric.WithAttributes(
    attribute.String("tienda_id", tiendaID),
    attribute.String("resultado", "success"),
  ),
)

// Gauge de items completados
meter.Int64UpDownCounter("inventario.realizar.items_completados").Add(ctx, 1,
  metric.WithAttributes(
    attribute.String("tienda_id", tiendaID),
    attribute.String("inventario_id", inventarioID),
  ),
)
```

---

## 10. Testing

### Backend Tests (Go)

1. **handler_test.go**
   - ✅ POST con valor válido → 200 OK
   - ✅ POST con valor negativo → 400 Bad Request
   - ✅ POST a conteo no en_progreso → 409 Conflict
   - ✅ POST con item_id no existe → 400 Bad Request
   - ✅ Validar respuesta incluye diferencia calculada

2. **service_test.go**
   - ✅ RegistrarValor() con valores válidos
   - ✅ RegistrarValor() rechaza valor < 0
   - ✅ RegistrarValor() verifica estado "en_progreso"
   - ✅ Calcular diferencia % correctamente
   - ✅ RegistrarValor() valida pertenencia a tienda

3. **repository_test.go**
   - ✅ UpdateDetalle() guarda valor_real
   - ✅ UpdateDetalle() guarda registrado_en (NOW)
   - ✅ UpdateDetalle() guarda registrado_por (usuario_id)
   - ✅ UpdateDetalle() transacción completa

### Frontend Tests (Angular)

1. **realizar-conteo.component.spec.ts**
   - ✅ Component carga items al init
   - ✅ Input bloquea valores < 0
   - ✅ Autosave POST dispara en blur
   - ✅ Indica "guardando..." durante POST
   - ✅ Maneja error de autosave con botón reintentar
   - ✅ Navega al siguiente item tras éxito
   - ✅ Barra de progreso actualiza correctamente
   - ✅ Botón Pausar navega a resumen

---

## 11. Criterios de Aceptación Técnicos

- ✅ Backend: 3 tests por función (handler, service, repository)
- ✅ Frontend: 8+ tests en spec.ts (coverage ≥ 85%)
- ✅ Lint: 0 errores markdown + Go + Angular
- ✅ Spans: 3 spans (registrar, validar, actualizar_detalle)
- ✅ Métricas: 3 instrumentos (histogram, counter, gauge)
- ✅ DB: migrations creadas y testeadas
- ✅ API: documentada en OpenAPI v3
- ✅ No hay logs de error en CI

---

## 12. Dependencias

| Proyecto | Feature | Estado |
|----------|---------|--------|
| loopi-specs-v2 | 018-inventario-iniciar-conteo | ✅ Mergeada |
| loopi-api-v2 | 018 (backend completado) | ✅ Mergeada |
| loopi-web-v2 | 018 (frontend completado) | ✅ Mergeada |

---

## 13. Próximos Pasos Después de 019

- **020-inventario-completar-conteo:** HU3 (confirmación/ajuste automático stock)
- **021-inventario-historial-conteo:** HU4 (listar/filtrar/ver detalle)
- **022-inventario-editar-conteo:** RF-INV-03.3 (admin edita completado)
- **023-inventario-eliminar-conteo:** admin elimina en_progreso

---

## Referencias

- [Plan de Separación 009→018-023](../../../.specify/memory/plan-separation-009-018-023.md)
- [018-inventario-iniciar-conteo](../018-inventario-iniciar-conteo/spec.md)
- Estándares Backend: loopi-api-v2/CLAUDE.md (BE-ARCH-02 sub-dominios)
- Componentes Transversales: [[FE-COMP-01]]
