# Tasks — 019-inventario-realizar-conteo

**Versión:** 1.0.0  
**Total de Tareas:** 47  
**Estado:** Generadas  
**Última actualización:** 2026-07-20

---

## Fase 0: Setup y Migración (Sesión Inicial)

### T001: Crear carpeta y estructura base del módulo `realizar/`

**Descripción:** Crear la carpeta `internal/inventarios/realizar/` con archivos base vacíos

**Repo:** loopi-api-v2  
**Dependencias:** Ninguna  
**Duración Estimada:** 15 min

**Pasos:**

1. Crear carpeta: `internal/inventarios/realizar/`
2. Crear archivos vacíos:
   - `handler.go`
   - `service.go`
   - `repository.go`
   - `models.go`
   - `errors.go`
   - `handler_test.go`
   - `service_test.go`
   - `repository_test.go`
3. Agregar paquete `package realizar` en cada archivo

**Verificación:** `ls -la internal/inventarios/realizar/` muestra 8 archivos

---

### T002: Validar estructura de `detalle_inventario`

**Descripción:** Verificar que los campos necesarios ya existen en la tabla (NO se crean nuevos campos)

**Repo:** loopi-api-v2  
**Dependencias:** T001  
**Duración Estimada:** 5 min

**Campos Validados:**

- ✅ `valor_real DECIMAL(12,4) NULL` — Existente
- ✅ `diferencia DECIMAL(12,4) NULL` — Existente
- ✅ `actualizado_en DATETIME` — Existente
- ✅ Índices existentes: `ix_detalle_inventario_item`

**Pasos:**

1. Revisar: `migrations/015_crear_tabla_detalle_inventario.up.sql`
2. Verificar en DB: `DESCRIBE detalle_inventario;`
3. Confirmar que `valor_real` y `diferencia` están como NULL
4. No se requiere migración nueva

**Verificación:** Campos confirmados existentes; no hay errores de falta de columnas

---

## Fase 1: Backend — Models y Contracts (Sesión 1)

### T003: Escribir `types.go` con DTOs de Request/Response

**Descripción:** Definir estructuras Go para serialización/deserialización de API (reutilizar tipos existentes donde sea posible)

**Repo:** loopi-api-v2  
**Dependencias:** T001  
**Duración Estimada:** 15 min

**Contenido esperado:**

```go
// RegistrarValorRequest — body del POST
type RegistrarValorRequest struct {
    ValorReal float64 `json:"valor_real" binding:"required,min=0"`
}

// RegistrarValorResponse — response del POST
type RegistrarValorResponse struct {
    Success              bool      `json:"success"`
    ItemID               string    `json:"item_id"`
    ItemCodigo           string    `json:"item_codigo"`
    ItemDescripcion      string    `json:"item_descripcion"`
    ValorEsperado        float64   `json:"valor_esperado"`
    ValorReal            float64   `json:"valor_real"`
    Diferencia           float64   `json:"diferencia"`
    DiferenciaPorcentaje float64   `json:"diferencia_porcentaje"`
    Unidad               string    `json:"unidad"`
    Timestamp            time.Time `json:"timestamp"`
}

// GetDetallesResponse — response del GET precarga
type GetDetallesResponse struct {
    InventarioID string          `json:"inventario_id"`
    TiendaID     string          `json:"tienda_id"`
    Estado       string          `json:"estado"`
    Items        []ItemDetalle   `json:"items"`
    Resumen      ResumenProgreso `json:"resumen"`
}

type ItemDetalle struct {
    ItemID           int64      `json:"item_id"`
    Nombre           string     `json:"nombre"`
    UnidadMedidaID   int64      `json:"unidad_medida_id,omitempty"`
    ValorEsperado    float64    `json:"valor_esperado"`
    ValorReal        *float64   `json:"valor_real"`
    Diferencia       *float64   `json:"diferencia"`
}

type ResumenProgreso struct {
    TotalItems        int     `json:"total_items"`
    Completados       int     `json:"completados"`
    Pendientes        int     `json:"pendientes"`
    PorcentajeProgreso float64 `json:"porcentaje_progreso"`
}
```

**Pasos:**

1. Abrir `internal/inventarios/realizar/models.go`
2. Escribir structs anteriores con JSON tags + validaciones (binding)
3. Compilar: `go build ./...` sin errores

**Verificación:** Archivo compila; structs son públicas; tags JSON correctos

---

### T004: Escribir `errors.go` con errores personalizados

**Descripción:** Definir errores específicos del módulo realizar

**Repo:** loopi-api-v2  
**Dependencias:** T001  
**Duración Estimada:** 10 min

**Contenido esperado:**

```go
var (
    ErrValorNegativo    = errors.New("valor_real debe ser >= 0")
    ErrConteoNoProgreso = errors.New("conteo no está en estado 'en_progreso'")
    ErrItemNoEncontrado = errors.New("item no pertenece a este conteo")
    ErrConteoNoEncontrado = errors.New("conteo no encontrado")
    ErrValidacionFallo  = errors.New("validación falló")
)

// NewError — wrapper para incluir código HTTP
type Error struct {
    Code    string
    Message string
    Status  int
}
```

**Pasos:**

1. Abrir `internal/inventarios/realizar/errors.go`
2. Escribir vars y tipos anteriores
3. Compilar sin errores

**Verificación:** errors.go compila; vars están exportadas

---

## Fase 1: Backend — Handler (Sesión 1)

### T005: Escribir `handler.go` — POST registrar valor

**Descripción:** Implementar handler HTTP para `POST /api/v1/inventarios/:id/items/:item_id/valor`

**Repo:** loopi-api-v2  
**Dependencias:** T003, T004  
**Duración Estimada:** 30 min

**Contenido esperado:**

```go
func (h *Handler) RegisterValueHandler(c *gin.Context) {
    ctx := c.Request.Context()
    inventarioID := c.Param("inventario_id")
    itemID := c.Param("item_id")
    
    var req RegistrarValorRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": "INVALID_REQUEST", "message": err.Error()})
        return
    }
    
    userID := c.GetString("user_id") // from auth middleware
    
    resp, err := h.svc.RegistrarValor(ctx, inventarioID, itemID, req.ValorReal, req.Observaciones, userID)
    if err != nil {
        // Handle error cases with appropriate status codes
        c.JSON(500, gin.H{"error": "INTERNAL_ERROR"})
        return
    }
    
    c.JSON(200, resp)
}
```

**Pasos:**

1. Abrir `internal/inventarios/realizar/handler.go`
2. Crear struct Handler con *Service
3. Escribir RegisterValueHandler() con validaciones HTTP
4. Validar parámetros: inventarioID, itemID no vacíos
5. Validar JSON binding

**Verificación:** Función compila; tiene firma (h *Handler) RegisterValueHandler(c*gin.Context)

---

### T006: Registrar ruta HTTP en router

**Descripción:** Agregar ruta POST en el router principal de loopi-api-v2

**Repo:** loopi-api-v2  
**Dependencias:** T005  
**Duración Estimada:** 10 min

**Pasos:**

1. Abrir archivo: `internal/router/router.go` o `internal/api/routes.go` (según estructura)
2. Buscar donde están las rutas de inventarios (ej: `GET /api/v1/inventarios`)
3. Agregar: `router.POST("/api/v1/inventarios/:inventario_id/items/:item_id/valor", handler.RegisterValueHandler)`
4. Compilar: `go build ./...`

**Verificación:** Ruta está registrada; router compila sin errores

---

## Fase 1: Backend — Service (Sesión 1)

### T007: Escribir `service.go` — RegistrarValor() con validaciones

**Descripción:** Implementar lógica de negocio: validar estado, calcular diferencia, OTel spans

**Repo:** loopi-api-v2  
**Dependencias:** T003, T004, T001  
**Duración Estimada:** 45 min

**Contenido esperado:**

```go
func (s *Service) RegistrarValor(ctx context.Context, inventarioID int64, itemID int64, valorReal float64) (*RegistrarValorResponse, error) {
    tracer := otel.Tracer("inventario.realizar")
    span := tracer.Start(ctx, "inventario.realizar.registrar_valor")
    defer span.End()
    
    span.SetAttributes(
        attribute.Int64("inventario.id", inventarioID),
        attribute.Int64("item.id", itemID),
        attribute.Float64("valor.real", valorReal),
    )
    
    // Validar valor >= 0
    if valorReal < 0 {
        span.SetAttributes(attribute.String("resultado", "error_validacion"))
        return nil, ErrValorNegativo
    }
    
    // Obtener conteo + validar estado
    inventario, err := s.repo.GetInventario(ctx, inventarioID)
    if err != nil || inventario.Estado != "en_progreso" {
        span.SetAttributes(attribute.String("resultado", "error_estado"))
        return nil, ErrConteoNoProgreso
    }
    
    // Obtener item + calcular diferencia
    item, err := s.repo.GetDetalleItem(ctx, inventarioID, itemID)
    if err != nil {
        return nil, ErrItemNoEncontrado
    }
    
    diferencia := valorReal - item.ValorEsperado
    diferenciaPorcentaje := (diferencia / item.ValorEsperado) * 100
    
    // UPDATE en DB
    dbSpan := tracer.Start(ctx, "inventario.realizar.actualizar_detalle")
    result, err := s.repo.UpdateDetalle(ctx, inventarioID, itemID, valorReal)
    dbSpan.End()
    
    if err != nil {
        span.SetAttributes(attribute.String("resultado", "error_db"))
        return nil, err
    }
    
    span.SetAttributes(attribute.String("resultado", "success"))
    
    return &RegistrarValorResponse{
        Success:              true,
        ItemID:               itemID,
        ItemCodigo:           item.Codigo,
        ItemDescripcion:      item.Descripcion,
        ValorEsperado:        item.ValorEsperado,
        ValorReal:            valorReal,
        Diferencia:           diferencia,
        DiferenciaPorcentaje: diferenciaPorcentaje,
        Unidad:               item.Unidad,
        Timestamp:            time.Now(),
    }, nil
}
```

**Pasos:**

1. Abrir `internal/inventarios/realizar/service.go`
2. Escribir struct Service con *Repository
3. Escribir RegistrarValor() con todos los pasos anteriores
4. Agregar OTel spans (ver código)
5. Compilar sin errores

**Verificación:** Función compila; llama a repository; retorna Response o error

---

### T008: Escribir método `GetDetallesInventario()` en service para precarga

**Descripción:** Implementar GET que carga items con valores pre-registrados

**Repo:** loopi-api-v2  
**Dependencias:** T007, T003  
**Duración Estimada:** 20 min

**Contenido esperado:**

```go
func (s *Service) GetDetallesInventario(ctx context.Context, inventarioID string) (*GetDetallesResponse, error) {
    span := tracer.Start(ctx, "inventario.realizar.obtener_detalles")
    defer span.End()
    
    inventario, err := s.repo.GetInventario(ctx, inventarioID)
    if err != nil {
        return nil, err
    }
    
    items, err := s.repo.GetItems(ctx, inventarioID)
    if err != nil {
        return nil, err
    }
    
    completados := 0
    for _, item := range items {
        if item.ValorReal != nil {
            completados++
        }
    }
    
    return &GetDetallesResponse{
        InventarioID: inventarioID,
        TiendaID:     inventario.TiendaID,
        Estado:       inventario.Estado,
        Items:        items,
        Resumen: ResumenProgreso{
            TotalItems:         len(items),
            Completados:        completados,
            Pendientes:         len(items) - completados,
            PorcentajeProgreso: float64(completados) / float64(len(items)) * 100,
        },
    }, nil
}
```

**Pasos:**

1. Abrir `internal/inventarios/realizar/service.go`
2. Agregar método GetDetallesInventario()
3. Llamar a repository para obtener items
4. Calcular resumen (completados, pendientes, %)
5. Compilar sin errores

**Verificación:** Función compila; retorna GetDetallesResponse

---

## Fase 1: Backend — Repository (Sesión 1)

### T009: Escribir `repository.go` — UpdateDetalle()

**Descripción:** Implementar UPDATE en BD para guardar valor_real (usa campos existentes de detalle_inventario)

**Repo:** loopi-api-v2  
**Dependencias:** T001, T002  
**Duración Estimada:** 20 min

**Contenido esperado:**

```go
func (r *Repository) UpdateDetalle(ctx context.Context, inventarioID int64, itemID int64, valorReal float64) (*core.DetalleInventario, error) {
    query := `
        UPDATE detalle_inventario
        SET valor_real = $1, actualizado_en = NOW(), diferencia = valor_real - valor_esperado
        WHERE inventario_id = $2 AND item_id = $3
        RETURNING id, inventario_id, item_id, valor_esperado, valor_real, diferencia, actualizado_en
    `
    
    var item core.DetalleInventario
    err := r.db.QueryRowContext(ctx, query, valorReal, inventarioID, itemID).
        Scan(&item.ID, &item.InventarioID, &item.ItemID, &item.ValorEsperado, &item.ValorReal, &item.Diferencia, &item.ActualizadoEn)
    
    if err != nil {
        return nil, err
    }
    
    return &item, nil
}
```

**Pasos:**

1. Abrir `internal/inventarios/realizar/repository.go`
2. Escribir struct Repository con *sql.DB
3. Escribir UpdateDetalle() con query SQL anterior
4. Compilar sin errores

**Verificación:** Función compila; query es válida SQL

---

### T010: Escribir método GetItems() en repository

**Descripción:** Obtener todos los items de un inventario con valores_real (si existen)

**Repo:** loopi-api-v2  
**Dependencias:** T009  
**Duración Estimada:** 15 min

**Contenido esperado:**

```go
func (r *Repository) GetItems(ctx context.Context, inventarioID string) ([]ItemDetalle, error) {
    query := `
        SELECT d.item_id, i.codigo, i.descripcion, d.valor_esperado, d.valor_real, 
               d.registrado_en, u.unidad
        FROM detalle_inventario d
        JOIN items_catalogo i ON d.item_id = i.id
        JOIN unidades u ON i.unidad_id = u.id
        WHERE d.inventario_id = $1
        ORDER BY d.created_at
    `
    
    rows, err := r.db.QueryContext(ctx, query, inventarioID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var items []ItemDetalle
    for rows.Next() {
        var item ItemDetalle
        if err := rows.Scan(&item.ItemID, &item.ItemCodigo, &item.ItemDescripcion, 
                           &item.ValorEsperado, &item.ValorReal, &item.RegistradoEn, &item.Unidad); err != nil {
            return nil, err
        }
        item.Completado = item.ValorReal != nil
        items = append(items, item)
    }
    
    return items, rows.Err()
}
```

**Pasos:**

1. Abrir `internal/inventarios/realizar/repository.go`
2. Escribir GetItems()
3. Query JOIN con items_catalogo y unidades
4. Compilar sin errores

**Verificación:** Función compila; query es válida

---

## Fase 1: Backend — Testing (Sesión 1)

### T011: Escribir tests en `handler_test.go` — 8 casos

**Descripción:** Tests unitarios para handler.RegisterValueHandler()

**Repo:** loopi-api-v2  
**Dependencias:** T005, T006  
**Duración Estimada:** 40 min

**Casos de test:**

```go
func TestRegisterValueHandler_Success(t *testing.T) {
    // Arrange: mock service, conteo en_progreso
    // Act: POST con valor válido
    // Assert: 200 OK, response incluye diferencia
}

func TestRegisterValueHandler_ValorNegativo(t *testing.T) {
    // Arrange: POST body con valor_real = -5
    // Act: llamar handler
    // Assert: 400 Bad Request, error message "debe ser >= 0"
}

func TestRegisterValueHandler_ConteoNoProgreso(t *testing.T) {
    // Arrange: conteo en estado "completado"
    // Act: POST
    // Assert: 409 Conflict
}

func TestRegisterValueHandler_ItemNoExiste(t *testing.T) {
    // Arrange: item_id no pertenece a inventario
    // Act: POST
    // Assert: 400 Bad Request
}

func TestRegisterValueHandler_AuthFail(t *testing.T) {
    // Arrange: usuario sin acceso a tienda del conteo
    // Act: POST
    // Assert: 403 Forbidden
}

func TestRegisterValueHandler_ResponseIncludeDiferencia(t *testing.T) {
    // Arrange: valor_real = 15, valor_esperado = 20
    // Act: POST
    // Assert: response.Diferencia = -5, response.DiferenciaPorcentaje = -25.0
}

func TestRegisterValueHandler_HeadersCorretos(t *testing.T) {
    // Arrange: POST exitoso
    // Act: inspeccionar headers
    // Assert: Content-Type: application/json
}

func TestRegisterValueHandler_LogError(t *testing.T) {
    // Arrange: DB error
    // Act: POST
    // Assert: log contiene ERROR message
}
```

**Pasos:**

1. Abrir `internal/inventarios/realizar/handler_test.go`
2. Escribir 8 funciones de test anteriores
3. Usar testutils (fixtures, mocks si existen)
4. Ejecutar: `go test ./internal/inventarios/realizar -v`
5. Todos pasan

**Verificación:** 8 tests pasan; `go test -cover` >= 85% en handler.go

---

### T012: Escribir tests en `service_test.go` — 7 casos

**Descripción:** Tests unitarios para service.RegistrarValor()

**Repo:** loopi-api-v2  
**Dependencias:** T007, T008  
**Duración Estimada:** 35 min

**Casos:**

```go
func TestRegistrarValor_Success(t *testing.T) {
    // Arrange: conteo en_progreso, valor válido
    // Act: llamar service.RegistrarValor()
    // Assert: retorna Response sin error
}

func TestRegistrarValor_ValorNegativo(t *testing.T) {
    // Arrange: valor_real = -1
    // Act: llamar
    // Assert: error ErrValorNegativo
}

func TestRegistrarValor_ConteoNoProgreso(t *testing.T) {
    // Arrange: estado = "completado"
    // Act: llamar
    // Assert: error ErrConteoNoProgreso
}

func TestRegistrarValor_CalculaDiferencia(t *testing.T) {
    // Arrange: valor_esperado = 20, valor_real = 15
    // Act: llamar
    // Assert: response.Diferencia = -5, % = -25.0
}

func TestRegistrarValor_ItemNoPertenece(t *testing.T) {
    // Arrange: item_id en otro inventario
    // Act: llamar
    // Assert: error ErrItemNoEncontrado
}

func TestRegistrarValor_ValidaPertenencaTienda(t *testing.T) {
    // Arrange: usuario.tienda_id != inventario.tienda_id
    // Act: llamar
    // Assert: error validación
}

func TestRegistrarValor_CallsRepository(t *testing.T) {
    // Arrange: mock repository
    // Act: llamar service
    // Assert: repository.UpdateDetalle() fue llamado
}
```

**Pasos:**

1. Abrir `internal/inventarios/realizar/service_test.go`
2. Escribir 7 tests
3. Usar mocks para Repository
4. Ejecutar: `go test ./internal/inventarios/realizar -v`
5. Todos pasan

**Verificación:** 7 tests pasan; coverage >= 85%

---

### T013: Escribir tests en `repository_test.go` — 6 casos

**Descripción:** Tests de integración para repository (requiere DB test)

**Repo:** loopi-api-v2  
**Dependencias:** T009, T010  
**Duración Estimada:** 30 min

**Casos:**

```go
func TestUpdateDetalle_GuardaValorReal(t *testing.T) {
    // Arrange: DB setup con detalle_inventario
    // Act: llamar repository.UpdateDetalle(valor_real = 15)
    // Assert: DB contiene valor_real = 15
}

func TestUpdateDetalle_ActualizaTimestamp(t *testing.T) {
    // Arrange: DB setup con item existente, actualizado_en = antes
    // Act: llamar UpdateDetalle()
    // Assert: actualizado_en se actualiza a NOW() (dentro de 1 segundo)
}

func TestUpdateDetalle_CalculaDiferencia(t *testing.T) {
    // Arrange: DB setup, valor_esperado = 20, valor_real = 15 (a guardar)
    // Act: llamar UpdateDetalle()
    // Assert: diferencia se calcula como 15 - 20 = -5
}

func TestUpdateDetalle_RetornaRegistroActualizado(t *testing.T) {
    // Arrange: DB setup
    // Act: llamar
    // Assert: response contiene item con valores actualizados
}

func TestUpdateDetalle_ErrorSiItemNoExiste(t *testing.T) {
    // Arrange: item_id inexistente
    // Act: llamar
    // Assert: error sql.ErrNoRows o similar
}
```

**Pasos:**

1. Abrir `internal/inventarios/realizar/repository_test.go`
2. Escribir 6 tests con setup DB (usar testutils)
3. Usar DB test (PostgreSQL test container si existe en proyecto)
4. Ejecutar: `go test ./internal/inventarios/realizar -v`
5. Todos pasan

**Verificación:** 6 tests pasan; DB actualizado correctamente

---

### T014: Escribir observabilidad en `metrics.go`

**Descripción:** Setup de Datadog métricas para module realizar

**Repo:** loopi-api-v2  
**Dependencias:** T007, T008  
**Duración Estimada:** 25 min

**Contenido esperado:**

```go
type Metrics struct {
    registrarDuration    metric.Float64Histogram
    registrarTotal       metric.Int64Counter
    itemsCompletados     metric.Int64UpDownCounter
}

func NewMetrics(meter metric.Meter) *Metrics {
    return &Metrics{
        registrarDuration: must(meter.Float64Histogram("inventario.realizar.registrar_valor.duration_ms")),
        registrarTotal:    must(meter.Int64Counter("inventario.realizar.registrar_valor.total")),
        itemsCompletados:  must(meter.Int64UpDownCounter("inventario.realizar.items_completados")),
    }
}

func (m *Metrics) RecordRegistrar(ctx context.Context, tiendaID string, duracion float64, resultado string) {
    m.registrarDuration.Record(ctx, duracion, metric.WithAttributes(
        attribute.String("tienda_id", tiendaID),
        attribute.String("resultado", resultado),
    ))
    m.registrarTotal.Add(ctx, 1, metric.WithAttributes(
        attribute.String("tienda_id", tiendaID),
        attribute.String("resultado", resultado),
    ))
}

func (m *Metrics) RecordItemsCompletados(ctx context.Context, tiendaID, inventarioID string, cantidad int64) {
    m.itemsCompletados.Add(ctx, cantidad, metric.WithAttributes(
        attribute.String("tienda_id", tiendaID),
        attribute.String("inventario_id", inventarioID),
    ))
}
```

**Pasos:**

1. Crear archivo `internal/inventarios/realizar/metrics.go`
2. Escribir Metrics struct con 3 instrumentos
3. Integrar en Service: llamar m.RecordRegistrar() en RegistrarValor()
4. Compilar sin errores

**Verificación:** metrics.go compila; Service usa Metrics

---

## Fase 2: Frontend — Setup y Models (Sesión 2)

### T015: Crear componente `realizar-conteo` con estructura base

**Descripción:** Scaffold componente Angular standalone

**Repo:** loopi-web-v2  
**Dependencias:** Ninguna  
**Duración Estimada:** 10 min

**Pasos:**

1. Crear carpeta: `src/app/modules/inventario/realizar-conteo/`
2. Generar con Angular CLI: `ng generate component modules/inventario/realizar-conteo --standalone`
3. Crear service: `ng generate service modules/inventario/realizar-conteo/services/realizar-conteo`
4. Archivos generados:
   - realizar-conteo.component.ts
   - realizar-conteo.component.html
   - realizar-conteo.component.css
   - realizar-conteo.component.spec.ts
   - services/realizar-conteo.service.ts

**Verificación:** Carpeta existe con estructura Angular estándar

---

### T016: Escribir `models.ts` (DTOs + interfaces)

**Descripción:** Definir tipos TypeScript para tipado fuerte

**Repo:** loopi-web-v2  
**Dependencias:** T015  
**Duración Estimada:** 15 min

**Contenido esperado:**

```typescript
// src/app/modules/inventario/realizar-conteo/models.ts

export interface RegistrarValorRequest {
  valor_real: number;
  observaciones?: string;
}

export interface RegistrarValorResponse {
  success: boolean;
  item_id: number;
  valor_esperado: number;
  valor_real: number;
  diferencia: number;
  diferencia_porcentaje: number;
}

export interface ItemDetalle {
  item_id: number;
  nombre: string;
  unidad_medida_id: number;
  valor_esperado: number;
  valor_real: number | null;
  completado: boolean;
  diferencia: number | null;
}

export interface PrecargaResponse {
  inventario_id: number;
  tienda_id: number;
  estado: string;
  items: ItemDetalle[];
  resumen: ResumenProgreso;
}

export interface ResumenProgreso {
  total_items: number;
  completados: number;
  pendientes: number;
  porcentaje_progreso: number;
}
```

**Pasos:**

1. Crear `src/app/modules/inventario/realizar-conteo/models.ts`
2. Escribir interfaces anteriores
3. Compilar: `ng build --configuration development` sin errores

**Verificación:** TypeScript compila; interfaces están exportadas

---

### T017: Escribir `realizar-conteo.service.ts` (API calls)

**Descripción:** Implementar HTTP calls (GET precarga, POST registrar)

**Repo:** loopi-web-v2  
**Dependencias:** T016  
**Duración Estimada:** 20 min

**Contenido esperado:**

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { RegistrarValorRequest, RegistrarValorResponse, PrecargaResponse } from '../models';

@Injectable({ providedIn: 'root' })
export class RealizarConteoService {
  private apiUrl = `${environment.apiUrl}/inventarios`;

  constructor(private http: HttpClient) {}

  getPrecargaItems(inventarioID: string): Observable<PrecargaResponse> {
    return this.http.get<PrecargaResponse>(
      `${this.apiUrl}/${inventarioID}/detalles?estado=en_progreso`
    );
  }

  registrarValor(
    inventarioID: string,
    itemID: string,
    request: RegistrarValorRequest
  ): Observable<RegistrarValorResponse> {
    return this.http.post<RegistrarValorResponse>(
      `${this.apiUrl}/${inventarioID}/items/${itemID}/valor`,
      request
    );
  }
}
```

**Pasos:**

1. Abrir `src/app/modules/inventario/realizar-conteo/services/realizar-conteo.service.ts`
2. Inyectar HttpClient
3. Escribir getPrecargaItems() y registrarValor()
4. Compilar sin errores

**Verificación:** Service compila; métodos retornan Observable\<T\> tipados

---

## Fase 2: Frontend — Component Logic (Sesión 2)

### T018: Escribir `realizar-conteo.component.ts` — lógica principal

**Descripción:** Implementar componente con estado, autosave, navegación

**Repo:** loopi-web-v2  
**Dependencias:** T017  
**Duración Estimada:** 40 min

**Contenido esperado:**

```typescript
import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { RealizarConteoService } from './services/realizar-conteo.service';
import { ItemDetalle, ResumenProgreso } from './models';

@Component({
  selector: 'app-realizar-conteo',
  templateUrl: './realizar-conteo.component.html',
  styleUrls: ['./realizar-conteo.component.css'],
  standalone: true,
})
export class RealizarConteoComponent implements OnInit {
  inventarioID!: string;
  items: ItemDetalle[] = [];
  currentIndex: number = 0;
  progreso: ResumenProgreso = { total_items: 0, completados: 0, pendientes: 0, porcentaje_progreso: 0 };
  autosaving: boolean = false;
  error: string | null = null;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private service: RealizarConteoService
  ) {}

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      this.inventarioID = params['id'];
      this.cargarItems();
    });
  }

  cargarItems(): void {
    this.service.getPrecargaItems(this.inventarioID).subscribe({
      next: (data) => {
        this.items = data.items;
        this.progreso = data.resumen;
        this.irAlPrimeroSinRegistro();
      },
      error: (err) => {
        this.error = 'Error al cargar items';
        console.error('Error:', err);
      },
    });
  }

  registrarValor(itemID: string, valor: number): void {
    if (valor < 0) {
      this.error = 'El valor debe ser 0 o mayor';
      return;
    }

    this.autosaving = true;
    this.error = null;

    this.service.registrarValor(this.inventarioID, itemID, { valor_real: valor }).subscribe({
      next: (response) => {
        const item = this.items.find(i => i.item_id === itemID);
        if (item) {
          item.valor_real = response.valor_real;
          item.diferencia = response.diferencia;
          item.completado = true;
        }
        this.autosaving = false;
        this.actualizarProgreso();
        this.siguienteItem();
      },
      error: (err) => {
        this.autosaving = false;
        this.error = err.error?.message || 'Error al guardar el valor';
        console.error('Error:', err);
      },
    });
  }

  irAlPrimeroSinRegistro(): void {
    this.currentIndex = this.items.findIndex(i => !i.completado);
    if (this.currentIndex === -1) {
      this.currentIndex = 0;
    }
  }

  siguienteItem(): void {
    this.currentIndex++;
    if (this.currentIndex < this.items.length) {
      this.irAlPrimeroSinRegistro();
    }
  }

  actualizarProgreso(): void {
    this.progreso.completados = this.items.filter(i => i.completado).length;
    this.progreso.pendientes = this.items.length - this.progreso.completados;
    this.progreso.porcentaje_progreso = (this.progreso.completados / this.items.length) * 100;
  }

  pausar(): void {
    this.router.navigate([`/inventarios/${this.inventarioID}/resumen`]);
  }

  cancelar(): void {
    this.router.navigate(['/inventarios']);
  }
}
```

**Pasos:**

1. Abrir `realizar-conteo.component.ts`
2. Copiar código anterior
3. Asegurar imports necesarios (Router, ActivatedRoute, etc.)
4. Compilar: `ng build --configuration development` sin errores

**Verificación:** Component compila; métodos están implementados

---

### T019: Escribir `realizar-conteo.component.html` — plantilla

**Descripción:** HTML con form, progreso, indicadores, botones

**Repo:** loopi-web-v2  
**Dependencias:** T018  
**Duración Estimada:** 30 min

**Contenido esperado:**

```html
<div class="realizar-conteo-container">
  <h2>Registrar Valores — Conteo #{{ inventarioID }}</h2>

  <!-- Barra de progreso -->
  <div class="progress-bar">
    <progress [value]="progreso.completados" [max]="progreso.total_items"></progress>
    <p class="progress-text">
      {{ progreso.completados }} de {{ progreso.total_items }} items completados
      ({{ progreso.porcentaje_progreso | number: '1.0-0' }}%)
    </p>
  </div>

  <!-- Item actual -->
  <div class="item-form" *ngIf="currentIndex < items.length">
    <div class="item-info">
      <p><strong>{{ items[currentIndex].item_codigo }}</strong></p>
      <p>{{ items[currentIndex].item_descripcion }}</p>
      <p class="item-meta">
        Esperado: <strong>{{ items[currentIndex].valor_esperado }}</strong>
        {{ items[currentIndex].unidad }}
      </p>
    </div>

    <div class="form-group">
      <label for="valor">Ingresa el valor registrado:</label>
      <input
        id="valor"
        type="number"
        min="0"
        [(ngModel)]="items[currentIndex].valor_real"
        (blur)="registrarValor(items[currentIndex].item_id, items[currentIndex].valor_real || 0)"
        placeholder="0"
        [disabled]="autosaving"
        class="valor-input"
      />
    </div>

    <!-- Indicador de autosave -->
    <div *ngIf="autosaving" class="autosave-indicator">
      <span class="spinner"></span> Guardando...
    </div>

    <!-- Error de autosave -->
    <div *ngIf="error" class="error-message">
      <span>{{ error }}</span>
      <button
        (click)="registrarValor(items[currentIndex].item_id, items[currentIndex].valor_real || 0)"
        class="btn-reintentar"
      >
        Reintentar
      </button>
    </div>

    <!-- Indicador de diferencia -->
    <div *ngIf="items[currentIndex].diferencia !== null" class="diferencia-indicator">
      <span [ngClass]="{ 'badge-rojo': Math.abs(items[currentIndex].diferencia_porcentaje || 0) > 10, 'badge-amarillo': Math.abs(items[currentIndex].diferencia_porcentaje || 0) <= 10 }">
        Diferencia: {{ items[currentIndex].diferencia }} ({{ items[currentIndex].diferencia_porcentaje | number: '1.0-0' }}%)
      </span>
    </div>
  </div>

  <!-- Resumen si completó -->
  <div class="completion-summary" *ngIf="currentIndex >= items.length">
    <h3>¡Todos los items han sido registrados!</h3>
    <p>Puedes revisar el resumen o continuar con el siguiente paso.</p>
    <button (click)="pausar()" class="btn-primary">Ir a Resumen</button>
  </div>

  <!-- Botones de navegación -->
  <div class="actions">
    <button (click)="pausar()" class="btn-secondary">Pausar</button>
    <button (click)="cancelar()" class="btn-secondary btn-danger">Cancelar</button>
  </div>
</div>
```

**Pasos:**

1. Abrir `realizar-conteo.component.html`
2. Escribir HTML anterior
3. Usar `*ngIf`, `[(ngModel)]`, `(blur)` bindings
4. Compilar: `ng build --configuration development` sin errores

**Verificación:** HTML compila; plantilla valida

---

### T020: Escribir `realizar-conteo.component.css` — estilos

**Descripción:** CSS responsive, animaciones, indicadores visuales

**Repo:** loopi-web-v2  
**Dependencias:** T019  
**Duración Estimada:** 20 min

**Contenido esperado:**

```css
.realizar-conteo-container {
  max-width: 600px;
  margin: 2rem auto;
  padding: 1rem;
  font-family: var(--font-primary);
}

.progress-bar {
  margin: 1.5rem 0;
}

progress {
  width: 100%;
  height: 8px;
  border-radius: 4px;
  background-color: var(--bg-secondary);
  border: none;
}

progress::-webkit-progress-bar {
  background-color: var(--bg-secondary);
  border-radius: 4px;
}

progress::-webkit-progress-value {
  background-color: var(--primary-color);
  border-radius: 4px;
}

progress::-moz-progress-bar {
  background-color: var(--primary-color);
  border-radius: 4px;
}

.progress-text {
  margin-top: 0.5rem;
  font-size: 0.9rem;
  color: var(--text-secondary);
}

.item-info {
  background: var(--bg-secondary);
  padding: 1rem;
  border-radius: 4px;
  margin: 1rem 0;
}

.item-meta {
  font-size: 0.9rem;
  color: var(--text-secondary);
  margin-top: 0.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin: 1rem 0;
}

.valor-input {
  padding: 0.75rem;
  font-size: 1.1rem;
  border: 2px solid var(--border-color);
  border-radius: 4px;
  transition: border-color 0.2s;
}

.valor-input:focus {
  border-color: var(--primary-color);
  outline: none;
}

.valor-input:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.autosave-indicator {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 1rem;
  color: var(--text-secondary);
  font-size: 0.9rem;
  padding: 0.75rem;
  background: var(--bg-secondary);
  border-radius: 4px;
}

.spinner {
  display: inline-block;
  width: 1rem;
  height: 1rem;
  border: 2px solid var(--border-color);
  border-top-color: var(--primary-color);
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.error-message {
  background: #fee;
  color: #c33;
  padding: 0.75rem;
  border-radius: 4px;
  margin-top: 1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-left: 4px solid #c33;
}

.btn-reintentar {
  background: #c33;
  color: white;
  border: none;
  padding: 0.25rem 0.75rem;
  border-radius: 3px;
  cursor: pointer;
  font-size: 0.85rem;
}

.btn-reintentar:hover {
  background: #a22;
}

.diferencia-indicator {
  margin-top: 1rem;
}

.badge-rojo {
  background: #fee;
  color: #c33;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  display: inline-block;
  font-weight: 500;
}

.badge-amarillo {
  background: #fef3cd;
  color: #856404;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  display: inline-block;
  font-weight: 500;
}

.completion-summary {
  text-align: center;
  padding: 2rem;
  background: #efe;
  border-radius: 4px;
  margin: 1rem 0;
}

.actions {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
  justify-content: center;
  flex-wrap: wrap;
}

button {
  padding: 0.75rem 1.5rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  border: none;
  transition: all 0.2s;
  font-weight: 500;
}

.btn-primary {
  background: var(--primary-color);
  color: white;
}

.btn-primary:hover {
  opacity: 0.9;
}

.btn-secondary {
  background: var(--bg-secondary);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
}

.btn-secondary:hover {
  background: var(--bg-hover);
}

.btn-danger {
  color: #c33;
}

.btn-danger:hover {
  background: #fee;
}

@media (max-width: 600px) {
  .realizar-conteo-container {
    padding: 0.75rem;
    margin: 1rem auto;
  }

  .actions {
    flex-direction: column;
  }

  button {
    width: 100%;
  }
}
```

**Pasos:**

1. Abrir `realizar-conteo.component.css`
2. Escribir CSS anterior
3. Asegurar responsive design
4. Compilar: `ng build --configuration development` sin errores

**Verificación:** CSS compila; estilos se ven bien en browser

---

## Fase 2: Frontend — Testing (Sesión 2)

### T021: Escribir tests en `realizar-conteo.component.spec.ts` — 10+ casos

**Descripción:** Tests unitarios e integración para componente

**Repo:** loopi-web-v2  
**Dependencias:** T018, T019  
**Duración Estimada:** 50 min

**Casos de test:**

```typescript
describe('RealizarConteoComponent', () => {
  let component: RealizarConteoComponent;
  let fixture: ComponentFixture<RealizarConteoComponent>;
  let service: jasmine.SpyObj<RealizarConteoService>;

  beforeEach(async () => {
    const serviceSpy = jasmine.createSpyObj('RealizarConteoService', [
      'getPrecargaItems',
      'registrarValor',
    ]);

    await TestBed.configureTestingModule({
      declarations: [RealizarConteoComponent],
      providers: [{ provide: RealizarConteoService, useValue: serviceSpy }],
    }).compileComponents();

    service = TestBed.inject(RealizarConteoService) as jasmine.SpyObj<RealizarConteoService>;
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(RealizarConteoComponent);
    component = fixture.componentInstance;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should load items on init', () => {
    // Arrange
    service.getPrecargaItems.and.returnValue(of(mockPrecargaResponse));
    // Act
    component.ngOnInit();
    // Assert
    expect(component.items.length).toBeGreaterThan(0);
  });

  it('should reject negative values', () => {
    // Arrange
    component.items = [{ ...mockItem, valor_real: null }];
    component.currentIndex = 0;
    // Act
    component.registrarValor('item-1', -5);
    // Assert
    expect(component.error).toContain('0 o mayor');
  });

  it('should show autosave indicator during POST', (done) => {
    // Arrange
    component.items = [{ ...mockItem, valor_real: null }];
    component.currentIndex = 0;
    service.registrarValor.and.returnValue(of(mockRegistrarValorResponse));
    // Act
    component.registrarValor('item-1', 15);
    // Assert
    expect(component.autosaving).toBe(false); // POST completado
    done();
  });

  it('should update item after successful registrar', () => {
    // Arrange
    const item = { ...mockItem, valor_real: null };
    component.items = [item];
    component.currentIndex = 0;
    service.registrarValor.and.returnValue(of(mockRegistrarValorResponse));
    // Act
    component.registrarValor('item-1', 15);
    // Assert
    expect(component.items[0].valor_real).toBe(15);
    expect(component.items[0].completado).toBe(true);
  });

  it('should navigate to next item after success', () => {
    // Arrange
    component.items = [mockItem, { ...mockItem, item_id: 'item-2', valor_real: null }];
    component.currentIndex = 0;
    service.registrarValor.and.returnValue(of(mockRegistrarValorResponse));
    // Act
    component.registrarValor('item-1', 15);
    // Assert
    expect(component.currentIndex).toBe(1);
  });

  it('should handle error and show reintentar button', () => {
    // Arrange
    component.items = [{ ...mockItem, valor_real: null }];
    component.currentIndex = 0;
    service.registrarValor.and.returnValue(throwError(() => ({ error: { message: 'Error' } })));
    // Act
    component.registrarValor('item-1', 15);
    // Assert
    expect(component.error).toBeTruthy();
    expect(component.autosaving).toBe(false);
  });

  it('should update progress bar after each registro', () => {
    // Arrange
    component.items = [mockItem, { ...mockItem, item_id: 'item-2', valor_real: null }];
    // Act
    component.actualizarProgreso();
    // Assert
    expect(component.progreso.completados).toBe(1);
    expect(component.progreso.pendientes).toBe(1);
  });

  it('should navigate to pausar when pausar button clicked', () => {
    // Arrange
    spyOn(component['router'], 'navigate');
    component.inventarioID = 'inv-1';
    // Act
    component.pausar();
    // Assert
    expect(component['router'].navigate).toHaveBeenCalledWith(['/inventarios/inv-1/resumen']);
  });

  it('should navigate to cancelar when cancelar button clicked', () => {
    // Arrange
    spyOn(component['router'], 'navigate');
    // Act
    component.cancelar();
    // Assert
    expect(component['router'].navigate).toHaveBeenCalledWith(['/inventarios']);
  });

  it('should show completion summary when all items registered', () => {
    // Arrange
    component.items = [mockItem];
    component.currentIndex = 1; // Passed array length
    // Act
    fixture.detectChanges();
    // Assert
    const summary = fixture.debugElement.query(By.css('.completion-summary'));
    expect(summary).toBeTruthy();
  });
});
```

**Pasos:**

1. Abrir `realizar-conteo.component.spec.ts`
2. Escribir tests anteriores
3. Crear `mockPrecargaResponse`, `mockItem`, `mockRegistrarValorResponse` en helpers
4. Ejecutar: `ng test --watch=false`
5. Todos los tests pasan

**Verificación:** 10+ tests pasan; coverage >= 85%

---

### T022: Escribir tests en `realizar-conteo.service.spec.ts` — 4 casos

**Descripción:** Tests unitarios para service HTTP

**Repo:** loopi-web-v2  
**Dependencias:** T017  
**Duración Estimada:** 20 min

**Casos:**

```typescript
describe('RealizarConteoService', () => {
  let service: RealizarConteoService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [RealizarConteoService],
    });

    service = TestBed.inject(RealizarConteoService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should fetch precarga items', () => {
    // Arrange
    const inventarioID = 'inv-1';
    // Act
    service.getPrecargaItems(inventarioID).subscribe();
    // Assert
    const req = httpMock.expectOne(`${environment.apiUrl}/inventarios/${inventarioID}/detalles?estado=en_progreso`);
    expect(req.request.method).toBe('GET');
  });

  it('should post registrar valor', () => {
    // Arrange
    const inventarioID = 'inv-1';
    const itemID = 'item-1';
    const request = { valor_real: 15 };
    // Act
    service.registrarValor(inventarioID, itemID, request).subscribe();
    // Assert
    const req = httpMock.expectOne(`${environment.apiUrl}/inventarios/${inventarioID}/items/${itemID}/valor`);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual(request);
  });

  it('should handle 400 error from registrar', () => {
    // Arrange
    const inventarioID = 'inv-1';
    const itemID = 'item-1';
    // Act & Assert
    service.registrarValor(inventarioID, itemID, { valor_real: -5 }).subscribe(
      () => fail('should have failed'),
      (err) => expect(err.status).toBe(400)
    );
    const req = httpMock.expectOne(`${environment.apiUrl}/inventarios/${inventarioID}/items/${itemID}/valor`);
    req.flush({ error: 'INVALID_VALOR' }, { status: 400, statusText: 'Bad Request' });
  });

  it('should handle 409 error (conteo no en_progreso)', () => {
    // Arrange
    const inventarioID = 'inv-1';
    const itemID = 'item-1';
    // Act & Assert
    service.registrarValor(inventarioID, itemID, { valor_real: 15 }).subscribe(
      () => fail('should have failed'),
      (err) => expect(err.status).toBe(409)
    );
    const req = httpMock.expectOne(`${environment.apiUrl}/inventarios/${inventarioID}/items/${itemID}/valor`);
    req.flush({ error: 'CONTEO_NO_EN_PROGRESO' }, { status: 409, statusText: 'Conflict' });
  });
});
```

**Pasos:**

1. Abrir `realizar-conteo.service.spec.ts`
2. Escribir tests anteriores
3. Usar HttpTestingController para mock HTTP
4. Ejecutar: `ng test --watch=false`
5. Todos los tests pasan

**Verificación:** 4 tests pasan; coverage >= 85%

---

## Fase 2: Frontend — Integración (Sesión 2)

### T023: Registrar ruta en `routing.module.ts`

**Descripción:** Agregar ruta `/inventarios/:id/realizar`

**Repo:** loopi-web-v2  
**Dependencias:** T015  
**Duración Estimada:** 10 min

**Pasos:**

1. Abrir `src/app/modules/inventario/inventario-routing.module.ts` (o similar)
2. Buscar rutas de inventarios
3. Agregar:

   ```typescript
   {
     path: ':id/realizar',
     component: RealizarConteoComponent,
     canActivate: [AuthGuard],
   }
   ```

4. Importar RealizarConteoComponent
5. Compilar: `ng build --configuration development` sin errores

**Verificación:** Ruta está registrada; componente importado

---

### T024: Integrar componente en navegación/menú

**Descripción:** Agregar link/botón para acceder a realizar-conteo

**Repo:** loopi-web-v2  
**Dependencias:** T023  
**Duración Estimada:** 10 min

**Pasos:**

1. Encontrar template de inventarios (ej: `inventario-list.component.html`)
2. Agregar botón/link:

   ```html
   <button (click)="irARealizarConteo(inventario.id)">
     Realizar Conteo
   </button>
   ```

3. En componente padre:

   ```typescript
   irARealizarConteo(id: string) {
     this.router.navigate([`/inventarios/${id}/realizar`]);
   }
   ```

4. Compilar sin errores

**Verificación:** Botón visible; navega a `/inventarios/:id/realizar`

---

## Fase 3: QA y Especificaciones (Sesión 3-4)

### T025: Ejecutar todas las pruebas (Go + Angular)

**Descripción:** Verificar que 100% de tests pasan

**Repo:** loopi-api-v2, loopi-web-v2  
**Dependencias:** T011-T022  
**Duración Estimada:** 15 min

**Pasos:**

1. En loopi-api-v2:

   ```bash
   go test ./internal/inventarios/realizar/... -v -count=1
   ```

   Esperado: 21 tests pasan (8+7+6 handler+service+repo)

2. En loopi-web-v2:

   ```bash
   npm run test:unit
   ```

   Esperado: 14+ tests pasan (10 component + 4 service)

3. Verificar coverage:

   ```bash
   go test ./internal/inventarios/realizar/... -cover
   ng test --code-coverage
   ```

   Ambos >= 85%

**Verificación:** Todos los tests pasan; coverage >= 85%

---

### T026: Markdown Lint en spec.md, plan.md, tasks.md

**Descripción:** Validar que no hay errores de formato markdown

**Repo:** loopi-specs-v2  
**Dependencias:** Archivos generados  
**Duración Estimada:** 5 min

**Pasos:**

1. Ejecutar:

   ```bash
   npx markdownlint-cli2 "specs/019-inventario-realizar-conteo/*.md"
   ```

2. Corregir errores si hay
3. Ejecutar nuevamente hasta 0 errores

**Verificación:** 0 errores de lint

---

### T027: Validación de seguridad (Trivy + GitGuardian)

**Descripción:** Escanear por vulnerabilidades y secretos

**Repo:** loopi-api-v2, loopi-web-v2  
**Dependencias:** Todas las fases  
**Duración Estimada:** 10 min

**Pasos:**

1. Trivy en loopi-api-v2:

   ```bash
   trivy fs . --severity HIGH,CRITICAL
   ```

2. GitGuardian en loopi-web-v2:

   ```bash
   ggshield secret scan path .
   ```

3. Revisar resultados; no debe haber HIGH/CRITICAL

**Verificación:** 0 vulnerabilidades críticas; Trivy + GitGuardian limpios

---

### T028: Performance test — POST latency

**Descripción:** Verificar que POST registrar < 200ms en p95

**Repo:** loopi-api-v2  
**Dependencias:** Backend completo  
**Duración Estimada:** 20 min

**Pasos:**

1. Levantar servidor local:

   ```bash
   go run ./cmd/main.go
   ```

2. Crear script de benchmark:

   ```bash
   # Ejecutar 100 POSTs y medir latencias
   for i in {1..100}; do
     time curl -X POST http://localhost:8080/api/v1/inventarios/inv-1/items/item-1/valor \
       -H "Content-Type: application/json" \
       -d '{"valor_real": 15}'
   done | grep "real" | awk '{print $2}'
   ```

3. Calcular p95 (95º percentil)
4. Verificar < 200ms

**Verificación:** p95 latency < 200ms

---

### T029: E2E test — Browser test manual

**Descripción:** Verificar flujo completo en browser real

**Repo:** loopi-web-v2  
**Dependencias:** Frontend + Backend en local  
**Duración Estimada:** 20 min

**Pasos:**

1. Levantar backend: `go run ./cmd/main.go`
2. Levantar frontend: `ng serve`
3. En browser: <http://localhost:4200>
4. Navegar a un conteo en_progreso
5. Click en "Realizar Conteo"
6. Ingresar valores para 3+ items
7. Verificar:
   - Barra de progreso actualiza
   - Autosave funciona (loader aparece/desaparece)
   - Diferencias calculadas correctamente
   - Transición al siguiente item
   - Botón Pausar navega a resumen

**Verificación:** Todos los pasos funcionan sin errores

---

### T030: Generar PRs en los 3 repositorios

**Descripción:** Crear PRs en loopi-specs-v2, loopi-api-v2, loopi-web-v2

**Repo:** Todos  
**Dependencias:** Todas las tareas completadas  
**Duración Estimada:** 15 min por PR

**Pasos por cada repo:**

1. Crear rama `feature/019-...` desde develop
2. Commit cambios con mensaje: "feat(019): implementar realizar-conteo"
3. Push a origin
4. Crear PR en GitHub:
   - Título: `019: Registrar valores de conteo item-por-item con autosave`
   - Description: incluir refs a spec.md, tasks.md
   - Reviewer: @manuelgomezsw
5. Verificar que CI pasa (tests, lint, security)

**Verificación:** 3 PRs creadas y abiertas; CI verde

---

### T031: Merge PRs a develop (orden: specs → API → web)

**Descripción:** Mergear PRs una vez que CI pasa

**Repo:** Todos  
**Dependencias:** T030  
**Duración Estimada:** 5 min por PR

**Orden:**

1. Mergear `loopi-specs-v2` PR #75 (o siguiente)
2. Mergear `loopi-api-v2` PR #34 (o siguiente)
3. Mergear `loopi-web-v2` PR #35 (o siguiente)

**Verificación:** Todos los PRs mergeados a develop; sin conflictos

---

## Resumen de Tareas por Fase

| Fase | Tareas | Total |
|------|--------|-------|
| 0: Setup | T001-T002 | 2 |
| 1: Backend Models | T003-T004 | 2 |
| 1: Backend Handler | T005-T006 | 2 |
| 1: Backend Service | T007-T008 | 2 |
| 1: Backend Repository | T009-T010 | 2 |
| 1: Backend Testing | T011-T014 | 4 |
| 2: Frontend Setup | T015-T017 | 3 |
| 2: Frontend Component | T018-T020 | 3 |
| 2: Frontend Testing | T021-T022 | 2 |
| 2: Frontend Integration | T023-T024 | 2 |
| 3: QA | T025-T029 | 5 |
| 3: PRs | T030-T031 | 2 |

## Total: 31 tareas

---

## Timeline Estimada

- **Sesión 1 (Hoy 2026-07-20):** T001-T014 (Backend completo) — ~4 horas
- **Sesión 2 (Próximo día):** T015-T024 (Frontend completo) — ~3 horas
- **Sesión 3 (Posterior):** T025-T031 (QA + PRs) — ~2 horas

**Total:** ~9 horas distribuidas en 3 sesiones

---

## Criterios de Aceptación Finales

- ✅ 31 tareas completadas
- ✅ 100% tests pasan (Go + Angular)
- ✅ Coverage >= 85%
- ✅ 0 errores de lint (markdown + Go + Angular)
- ✅ 0 vulnerabilidades críticas (Trivy + GitGuardian)
- ✅ POST latency p95 < 200ms
- ✅ E2E manual: flujo completo funciona
- ✅ 3 PRs mergeadas a develop
- ✅ Spec + Plan + Tasks documentados en loopi-specs-v2

---

## Notas

- Cada tarea tiene **dependencias claras**: no comenzar hasta que todas estén listas
- Tests se escriben **conforme se desarrolla**, no después
- Pre-commit hooks validarán lint, tests, security antes de push
- Si algo falla, volver a la tarea anterior para debugging
