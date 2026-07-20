# Plan de Implementación — 019-inventario-realizar-conteo

**Versión:** 1.0.0  
**Estado:** Plan  
**Última actualización:** 2026-07-20

---

## 1. Visión Arquitectónica

019 implementa el **segundo paso del flujo de conteo**: registro item-por-item con autosave y recuperación de sesión.

**Principios:**

- Sub-dominio independiente en backend (siguiendo BE-ARCH-02)
- Frontend: componente standalone (sin monolítico)
- Observabilidad: spans OTel + métricas Datadog (heredadas de 018)
- Estado persistente: backend guarda cada cambio
- Recuperación automática: si sesión cae, usuario vuelve donde paró

**Diagrama de flujo:**

```text
Usuario en 018 → Selecciona tipo/horario → Va a 019 realizar-conteo
                                               ↓
                                    Carga items (GET precarga)
                                               ↓
                                    Ingresa valor_real item 1
                                               ↓
                                    Autosave POST (spinner)
                                               ↓
                               Éxito → Siguiente item ✓
                               Error → Reintentar
                                               ↓
                                    Repite hasta completar
                                               ↓
                                    Botón Pausar → resumen (HU4)
```

---

## 2. Alcance: Backend (loopi-api-v2)

### 2.1 Módulo `internal/inventarios/realizar/`

**Responsabilidades:**

- Handler REST: `POST /api/v1/inventarios/:id/items/:item_id/valor`
- Service: validar estado, calcular diferencias, OTel spans
- Repository: UPDATE detalle_inventario
- Models: Request/Response DTOs

**No incluir en 019:**

- Lógica de cambiar estado a "completado" (eso es 020)
- Historial de modificaciones (eso es 021)
- Cálculo automático de stock_movimiento (eso es 020)

### 2.2 Cambios en `internal/inventarios/core/`

**Nuevas funciones:**

- `GetDetallesInventario(ctx, inventarioID, estado)` — retorna items con valores_real
  - Usada en precarga frontend

**Sin cambios:**

- Mantener `GetInventarioDetalle()` existente
- No modificar `SnapshotStockActual()`

### 2.3 Base de Datos

**Tabla: `detalle_inventario`**

```sql
-- Nueva columna para guardar valor real ingresado
ALTER TABLE detalle_inventario
ADD COLUMN IF NOT EXISTS valor_real DECIMAL(10,2) NULL AFTER valor_esperado;

ALTER TABLE detalle_inventario
ADD COLUMN IF NOT EXISTS observaciones TEXT NULL AFTER valor_real;

ALTER TABLE detalle_inventario
ADD COLUMN IF NOT EXISTS registrado_en TIMESTAMP NULL AFTER observaciones;

ALTER TABLE detalle_inventario
ADD COLUMN IF NOT EXISTS registrado_por UUID NULL AFTER registrado_en;

-- Índices para performance
CREATE INDEX idx_detalle_inventario_id_valor_real ON detalle_inventario(inventario_id, valor_real);
CREATE INDEX idx_detalle_inventario_item_id ON detalle_inventario(item_id);

-- Foreign key para registrado_por
ALTER TABLE detalle_inventario
ADD CONSTRAINT fk_detalle_inventario_usuario
FOREIGN KEY (registrado_por) REFERENCES usuarios(id) ON DELETE SET NULL;
```

**Nota:** Las columnas son **NULL hasta que se registre un valor**. Esto permite distinguir "sin registrar" vs "registrado como 0".

### 2.4 Archivos Go a Crear

```text
loopi-api-v2/internal/inventarios/realizar/
├── handler.go           (150 líneas)
├── service.go           (200 líneas)
├── repository.go        (100 líneas)
├── models.go            (60 líneas)
├── errors.go            (30 líneas)
├── handler_test.go      (200 líneas)
├── service_test.go      (180 líneas)
└── repository_test.go   (120 líneas)
```

**Patrón: copiar estructura de `018-inventario-iniciar-conteo/handler.go` y adaptar.**

### 2.5 Observabilidad (Go)

**En `service.go`:**

```go
import "go.opentelemetry.io/otel"

func (s *Service) RegistrarValor(ctx context.Context, req RegistrarValorRequest) (*RegistrarValorResponse, error) {
    tracer := otel.Tracer("inventario.realizar")
    span := tracer.Start(ctx, "inventario.realizar.registrar_valor")
    defer span.End()

    // Atributos principales
    span.SetAttributes(
        attribute.String("inventario.id", req.InventarioID),
        attribute.String("item.id", req.ItemID),
        attribute.Float64("valor.real", float64(req.ValorReal)),
    )

    // Validación sub-span
    validSpan := tracer.Start(ctx, "inventario.realizar.validar_valor")
    if err := s.validarValor(req.ValorReal); err != nil {
        validSpan.SetAttributes(attribute.Bool("valido", false))
        validSpan.End()
        span.SetAttributes(attribute.String("resultado", "error_validacion"))
        return nil, err
    }
    validSpan.SetAttributes(attribute.Bool("valido", true))
    validSpan.End()

    // DB UPDATE sub-span
    dbSpan := tracer.Start(ctx, "inventario.realizar.actualizar_detalle")
    result, err := s.repo.UpdateDetalle(ctx, req.InventarioID, req.ItemID, req.ValorReal, req.Observaciones, userID)
    if err != nil {
        dbSpan.SetAttributes(attribute.String("error", err.Error()))
        dbSpan.End()
        span.SetAttributes(attribute.String("resultado", "error_db"))
        return nil, err
    }
    dbSpan.SetAttributes(attribute.Int64("filas_afectadas", 1))
    dbSpan.End()

    span.SetAttributes(attribute.String("resultado", "success"))
    return &RegistrarValorResponse{...}, nil
}
```

**Métricas en `metrics.go`:**

```go
type Metrics struct {
    registrarDuration    metric.Float64Histogram
    registrarTotal       metric.Int64Counter
    itemsCompletados     metric.Int64UpDownCounter
}

func (m *Metrics) RecordRegistrar(ctx context.Context, tiendaID string, duracion float64, resultado string) {
    m.registrarDuration.Record(ctx, duracion,
        metric.WithAttributes(
            attribute.String("tienda_id", tiendaID),
            attribute.String("resultado", resultado),
        ),
    )
    m.registrarTotal.Add(ctx, 1,
        metric.WithAttributes(
            attribute.String("tienda_id", tiendaID),
            attribute.String("resultado", resultado),
        ),
    )
}
```

---

## 3. Alcance: Frontend (loopi-web-v2)

### 3.1 Componente `realizar-conteo/`

**Ubicación:** `src/app/modules/inventario/realizar-conteo/`

**Estructura:**

```text
realizar-conteo/
├── realizar-conteo.component.ts       (200 líneas)
├── realizar-conteo.component.html     (120 líneas)
├── realizar-conteo.component.css      (80 líneas)
├── realizar-conteo.component.spec.ts  (180 líneas)
└── services/
    └── realizar-conteo.service.ts     (100 líneas)
```

### 3.2 Responsabilidades TypeScript

**En `realizar-conteo.component.ts`:**

```typescript
export class RealizarConteoComponent implements OnInit {
  inventarioID: string;
  items: ItemDetalle[] = [];
  currentIndex: number = 0;
  progreso: { completados: number; pendientes: number } = { completados: 0, pendientes: 0 };
  autosaving: boolean = false;
  error: string | null = null;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private service: RealizarConteoService,
  ) {}

  ngOnInit() {
    this.route.params.subscribe(params => {
      this.inventarioID = params['id'];
      this.cargarItems();
    });
  }

  cargarItems() {
    this.service.getPrecargaItems(this.inventarioID).subscribe(
      data => {
        this.items = data.items;
        this.actualizarProgreso();
        this.irAlPrimeroSinRegistro();
      },
      err => (this.error = 'Error al cargar items'),
    );
  }

  registrarValor(itemID: string, valor: number) {
    if (valor < 0) return;
    this.autosaving = true;
    this.error = null;

    this.service.registrarValor(this.inventarioID, itemID, valor).subscribe(
      response => {
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
      err => {
        this.autosaving = false;
        this.error = `Error: ${err.error?.message || 'No se pudo guardar'}`;
      },
    );
  }

  irAlPrimeroSinRegistro() {
    this.currentIndex = this.items.findIndex(i => !i.completado);
    if (this.currentIndex === -1) {
      this.currentIndex = 0;
    }
  }

  siguienteItem() {
    this.currentIndex++;
    if (this.currentIndex < this.items.length) {
      this.irAlPrimeroSinRegistro();
    }
  }

  actualizarProgreso() {
    this.progreso.completados = this.items.filter(i => i.completado).length;
    this.progreso.pendientes = this.items.length - this.progreso.completados;
  }

  pausar() {
    this.router.navigate([`/inventarios/${this.inventarioID}/resumen`]);
  }

  cancelar() {
    this.router.navigate(['/inventarios']);
  }
}
```

### 3.3 Responsabilidades HTML

**En `realizar-conteo.component.html`:**

```html
<div class="realizar-conteo-container">
  <!-- Encabezado -->
  <h2>Registrar Valores — Conteo #{{ inventarioID }}</h2>

  <!-- Barra de progreso -->
  <div class="progress-bar">
    <progress [value]="progreso.completados" [max]="items.length"></progress>
    <p class="progress-text">
      {{ progreso.completados }} de {{ items.length }} items completados
    </p>
  </div>

  <!-- Item actual -->
  <div class="item-form" *ngIf="currentIndex < items.length">
    <div class="item-info">
      <p><strong>{{ items[currentIndex].item_codigo }}</strong></p>
      <p>{{ items[currentIndex].item_descripcion }}</p>
      <p>Esperado: {{ items[currentIndex].valor_esperado }} {{ items[currentIndex].unidad }}</p>
    </div>

    <div class="form-group">
      <label for="valor">Ingresa el valor registrado:</label>
      <input
        id="valor"
        type="number"
        min="0"
        [(ngModel)]="items[currentIndex].valor_real"
        (blur)="registrarValor(items[currentIndex].item_id, items[currentIndex].valor_real)"
        placeholder="0"
        [disabled]="autosaving"
      />
    </div>

    <!-- Indicador de autosave -->
    <div *ngIf="autosaving" class="autosave-indicator">
      <span class="spinner"></span> Guardando...
    </div>

    <!-- Error de autosave -->
    <div *ngIf="error" class="error-message">
      {{ error }}
      <button (click)="registrarValor(items[currentIndex].item_id, items[currentIndex].valor_real)">
        Reintentar
      </button>
    </div>
  </div>

  <!-- Resumen si se completó -->
  <div class="completion-summary" *ngIf="currentIndex >= items.length">
    <p>¡Todos los items han sido registrados!</p>
    <button (click)="pausar()">Ir a Resumen</button>
  </div>

  <!-- Botones de navegación -->
  <div class="actions">
    <button (click)="pausar()" class="btn-secondary">Pausar</button>
    <button (click)="cancelar()" class="btn-secondary">Cancelar</button>
  </div>
</div>
```

### 3.4 Service TypeScript

**En `realizar-conteo.service.ts`:**

```typescript
@Injectable({ providedIn: 'root' })
export class RealizarConteoService {
  private apiUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getPrecargaItems(inventarioID: string): Observable<PrecargaResponse> {
    return this.http.get<PrecargaResponse>(
      `${this.apiUrl}/inventarios/${inventarioID}/detalles?estado=en_progreso`,
    );
  }

  registrarValor(
    inventarioID: string,
    itemID: string,
    valorReal: number,
  ): Observable<RegistrarValorResponse> {
    return this.http.post<RegistrarValorResponse>(
      `${this.apiUrl}/inventarios/${inventarioID}/items/${itemID}/valor`,
      { valor_real: valorReal },
    );
  }
}
```

### 3.5 Estilos CSS

**En `realizar-conteo.component.css`:**

```css
.realizar-conteo-container {
  max-width: 600px;
  margin: 2rem auto;
  padding: 1rem;
}

.progress-bar {
  margin: 1.5rem 0;
}

progress {
  width: 100%;
  height: 8px;
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

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

input[type="number"] {
  padding: 0.5rem;
  font-size: 1rem;
  border: 1px solid var(--border-color);
  border-radius: 4px;
}

input:disabled {
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
  background: var(--error-bg, #fee);
  color: var(--error-color, #c33);
  padding: 0.75rem;
  border-radius: 4px;
  margin-top: 1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.error-message button {
  background: var(--error-color, #c33);
  color: white;
  border: none;
  padding: 0.25rem 0.75rem;
  border-radius: 3px;
  cursor: pointer;
  font-size: 0.85rem;
}

.actions {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
  justify-content: center;
}

button {
  padding: 0.75rem 1.5rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  border: none;
  transition: all 0.2s;
}

.btn-secondary {
  background: var(--bg-secondary);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
}

.btn-secondary:hover {
  background: var(--bg-hover);
}

.completion-summary {
  text-align: center;
  padding: 2rem;
  background: var(--success-bg, #efe);
  border-radius: 4px;
  margin: 1rem 0;
}
```

---

## 4. Testing Strategy

### Backend Tests (Go)

**Organización:**

- 1 file per layer: handler_test.go, service_test.go, repository_test.go
- Setup común: testutils.go con fixtures de test
- Coverage target: ≥ 85%

**Casos principales:**

1. **handler_test.go (8 tests)**
   - ✅ Registra valor válido → 200
   - ✅ Rechaza valor negativo → 400
   - ✅ Rechaza conteo no en_progreso → 409
   - ✅ Rechaza item_id inexistente → 400
   - ✅ Valida pertenencia a tienda → 403
   - ✅ Response incluye diferencia
   - ✅ Headers correctos (application/json)
   - ✅ Logs en DEBUG/INFO/ERROR

2. **service_test.go (7 tests)**
   - ✅ RegistrarValor() con OK
   - ✅ Rechaza valor < 0
   - ✅ Rechaza conteo estado ≠ en_progreso
   - ✅ Calcula diferencia correctamente
   - ✅ Calcula % diferencia
   - ✅ Valida item pertenece a conteo
   - ✅ Llama repository.UpdateDetalle()

3. **repository_test.go (6 tests)**
   - ✅ UpdateDetalle() guarda valor_real
   - ✅ UpdateDetalle() guarda registrado_en (NOW)
   - ✅ UpdateDetalle() guarda registrado_por
   - ✅ UpdateDetalle() guarda observaciones
   - ✅ Retorna registro actualizado
   - ✅ Error si item_id no existe

### Frontend Tests (Angular)

**En `realizar-conteo.component.spec.ts` (10+ tests)**

1. ✅ Component se inicializa
2. ✅ Carga items al OnInit
3. ✅ Input rechaza valores < 0
4. ✅ Autosave POST dispara en blur
5. ✅ Muestra "Guardando..." durante POST
6. ✅ Actualiza item tras éxito
7. ✅ Muestra error y botón reintentar si falla
8. ✅ Navega a siguiente item sin valor
9. ✅ Barra de progreso actualiza
10. ✅ Botón Pausar navega a resumen
11. ✅ Botón Cancelar navega a /inventarios

**En `realizar-conteo.service.spec.ts` (4 tests)**

1. ✅ GET precarga retorna items
2. ✅ POST registrar retorna response con diferencia
3. ✅ Maneja HTTP 400 (valor negativo)
4. ✅ Maneja HTTP 409 (conteo no en_progreso)

---

## 5. Roadmap de Implementación

### Fase 1: Backend (Sesión 1-2)

| # | Tarea | Duración | Dependencias |
|---|-------|----------|--------------|
| 1.1 | Crear módulo `realizar/` con estructura base | 15 min | - |
| 1.2 | Migrations: agregar columnas a detalle_inventario | 20 min | - |
| 1.3 | Escribir models.go (DTOs) | 15 min | 1.1 |
| 1.4 | Escribir handler.go (POST endpoint) | 30 min | 1.1, 1.3 |
| 1.5 | Escribir service.go (validaciones + OTel) | 45 min | 1.1, 1.3, 1.4 |
| 1.6 | Escribir repository.go (UPDATE) | 20 min | 1.1 |
| 1.7 | Escribir errors.go (custom errors) | 10 min | 1.1 |
| 1.8 | Tests: handler_test.go (8 tests) | 40 min | 1.4, 1.5 |
| 1.9 | Tests: service_test.go (7 tests) | 35 min | 1.5 |
| 1.10 | Tests: repository_test.go (6 tests) | 30 min | 1.6 |
| 1.11 | Metrics.go: setup Datadog | 25 min | 1.5 |
| 1.12 | Integración con router de loopi-api-v2 | 15 min | 1.4, 1.8 |

**Total Fase 1:** ~4 horas

### Fase 2: Frontend (Sesión 2-3)

| # | Tarea | Duración | Dependencias |
|---|-------|----------|--------------|
| 2.1 | Crear componente realizar-conteo/ | 10 min | - |
| 2.2 | Generar models.ts (DTOs, interfaces) | 15 min | 2.1 |
| 2.3 | Escribir service.ts (GET precarga + POST) | 20 min | 2.1, 2.2 |
| 2.4 | Escribir component.ts (lógica, autosave) | 40 min | 2.3 |
| 2.5 | Escribir component.html (form + progreso) | 30 min | 2.4 |
| 2.6 | Escribir component.css (responsive) | 20 min | 2.5 |
| 2.7 | Tests: component.spec.ts (10+ tests) | 50 min | 2.4, 2.5 |
| 2.8 | Tests: service.spec.ts (4 tests) | 20 min | 2.3 |
| 2.9 | Setup routing (en routing.module) | 15 min | 2.1 |
| 2.10 | Integración en navbar/menú | 10 min | 2.9 |

**Total Fase 2:** ~3 horas

### Fase 3: QA + Specs (Sesión 3-4)

| # | Tarea | Duración | Dependencias |
|---|-------|----------|--------------|
| 3.1 | Generar spec.md final | 30 min | Fase 1, Fase 2 |
| 3.2 | Generar tasks.md (checklist para QA) | 20 min | 3.1 |
| 3.3 | Tests integración E2E (browser) | 40 min | Fase 1, Fase 2 |
| 3.4 | Validar markdown lint | 5 min | 3.1, 3.2 |
| 3.5 | Ejecutar todos los tests (Go + Angular) | 15 min | - |
| 3.6 | Security review (Trivy + GitGuardian) | 10 min | - |
| 3.7 | Performance: medir latencias POST | 20 min | Fase 2 |

**Total Fase 3:** ~2 horas

**Gran Total:** ~9 horas distribuidoras en 3-4 sesiones

---

## 6. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|--------|-----------|
| Autosave POST lento (>200ms) | Media | Alto | Indexar DB en item_id; profile con pprof |
| Sesión cae durante POST | Baja | Medio | Reintentos exponenciales en frontend |
| Diferencia % no calcula correctamente | Baja | Medio | Tests parametrizados para edge cases |
| Validación frontend ≠ backend | Media | Bajo | Validar en ambos lados; tests E2E |
| Estado "completado" se asume antes de terminar HU3 | Alta | Crítico | Deixar status = "en_progreso" hasta 020 |

---

## 7. Relación con Otras Features

**Depende de:**

- 018-inventario-iniciar-conteo ✅ (ya mergeada)

**Precondición para:**

- 020-inventario-completar-conteo (HU3)
- 021-inventario-historial-conteo (HU4, puede ser paralelo)

**No afecta (pueden ser paralelas):**

- 022-inventario-editar-conteo
- 023-inventario-eliminar-conteo

---

## 8. Checklist Pre-Merge

- [ ] Todos los tests pasan: Go + Angular
- [ ] Lint: 0 errores (markdown + Go + Angular)
- [ ] PR loopi-specs-v2: spec.md + plan.md + tasks.md + checklists
- [ ] PR loopi-api-v2: backend completo con tests + migrations
- [ ] PR loopi-web-v2: frontend completo con tests
- [ ] Observabilidad: Spans OTel + Métricas Datadog verificadas en local
- [ ] Security: Trivy + GitGuardian limpios
- [ ] GitHub Actions: CI verde en las 3 PRs
- [ ] Documentación: OpenAPI actualizado
- [ ] Performance: POST < 200ms en 95th percentile

---

## 9. Decisiones Arquitectónicas

| Decisión | Rationale | Alternativas Consideradas |
|----------|-----------|--------------------------|
| Sub-dominio `realizar/` separado | Escalabilidad futura (020, 022, 023) | Monolito en core/ |
| Autosave POST en blur (no onChange) | Reducir tráfico API; evitar spam | onChange: 10x+ requests |
| Valor nullable hasta registro | Distinguir "sin registrar" vs "registrado como 0" | NOT NULL con default 0 (ambigüedad) |
| OTel spans por operación granular | Debug + monitoring detallado | Span único por handler |
| Frontend sin estado: todo en backend | Recuperación de sesión automática | Local storage (sincronización) |

---

## 10. Métricas de Éxito

- ✅ 100% tests pasan
- ✅ Coverage ≥ 85% (Go + Angular)
- ✅ POST latency: p95 < 200ms
- ✅ 0 issues de seguridad (Trivy + GitGuardian)
- ✅ 0 logs de error en CI
- ✅ Span OTel: 3 spans por POST (registrar, validar, actualizar_detalle)
- ✅ Métricas Datadog: histogram + counter + gauge activos
- ✅ Feature branch mergeado a develop sin conflictos

---

## Referencias

- loopi-api-v2/CLAUDE.md — BE-ARCH-02 sub-dominios
- loopi-specs-v2/specs/018-inventario-iniciar-conteo/plan.md — patrón a copiar
- [OpenTelemetry Go Instrumentation](https://opentelemetry.io/docs/instrumentation/go/)
- [Angular Testing](https://angular.io/guide/testing)
