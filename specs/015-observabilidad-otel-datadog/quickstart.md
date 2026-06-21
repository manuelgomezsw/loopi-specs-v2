# Quickstart: Observabilidad OTel + Datadog APM

**Feature**: `015-observabilidad-otel-datadog` | **Fecha**: 2026-05-26

Esta guía cubre los pasos de configuración en GCP y Datadog, y cómo verificar que
trazas y métricas llegan correctamente.

---

## Prerrequisitos

- `gcloud` CLI autenticado con permisos Owner/Editor en el proyecto GCP
- Una cuenta de Datadog con API Key disponible (Organization Settings → API Keys)
- Secret `DD_API_KEY` creado en GCP Secret Manager (Paso 1)

---

## Paso 1 — Guardar `DD_API_KEY` en Secret Manager

```bash
# Reemplazar YOUR_DD_API_KEY con la clave real (no commitear)
echo -n "YOUR_DD_API_KEY" | \
  gcloud secrets create DD_API_KEY \
    --data-file=- \
    --replication-policy=automatic \
    --project=loopi-dev-497600

# Repetir para producción
echo -n "YOUR_DD_API_KEY" | \
  gcloud secrets create DD_API_KEY \
    --data-file=- \
    --replication-policy=automatic \
    --project=loopi-prod-497600
```

Verificar:

```bash
gcloud secrets versions access latest --secret=DD_API_KEY --project=loopi-dev-497600
```

> **Arquitectura**: el backend envía trazas y métricas **directamente** al intake OTLP de
> Datadog (`https://otlp.datadoghq.com`), sin agente intermediario. El Datadog Agent en
> Cloud Run fue descartado por incompatibilidad con el entorno sandboxed (Core Agent +
> Trace Agent no pueden comunicarse vía gRPC interno). Ver research.md Decisiones 7 y 10.

---

## Paso 2 — Inyectar `DD_API_KEY` en el deploy de App Engine

`OTEL_EXPORTER_OTLP_HEADERS` nunca aparece en texto plano en el repositorio. Se inyecta
en tiempo de deploy leyendo el valor desde Secret Manager:

```bash
# Leer la clave desde Secret Manager
DD_API_KEY=$(gcloud secrets versions access latest \
  --secret=DD_API_KEY \
  --project=loopi-dev-497600)

# Agregar temporalmente en app.stage.yaml (NO commitear este valor):
#   OTEL_EXPORTER_OTLP_HEADERS: "DD-API-KEY=<valor-de-DD_API_KEY>"
# Luego desplegar y restaurar el archivo:
gcloud app deploy app.stage.yaml --project=loopi-dev-497600
git checkout app.stage.yaml   # restaurar sin el valor hardcodeado
```

Para prod, repetir con `--project=loopi-prod-497600` y `app.prod.yaml`.

**Nota**: App Engine Standard no tiene equivalente al `--set-secrets` de Cloud Run. La
inyección manual antes del deploy es el mecanismo más directo; en CI/CD se automatiza
leyendo el secret en un step previo al `gcloud app deploy`.

---

## Paso 3 — Actualizar `app.yaml` (dev local), `app.stage.yaml` y `app.prod.yaml`

Agregar al bloque `env_variables` de cada archivo:

```yaml
# app.yaml (dev local — endpoint vacío = modo no-op, sin envío a Datadog)
env_variables:
  ENV: dev
  GCP_PROJECT: loopi-dev-497600
  APP_VERSION: "1.0.0"
  OTEL_SERVICE_NAME: "loopi-api"
  OTEL_EXPORTER_OTLP_ENDPOINT: ""
  OTEL_EXPORTER_OTLP_HEADERS: ""
```

```yaml
# app.stage.yaml (stage — intake OTLP directo a Datadog)
env_variables:
  ENV: stage
  GCP_PROJECT: loopi-dev-497600
  APP_VERSION: "1.0.0"
  OTEL_SERVICE_NAME: "loopi-api"
  OTEL_EXPORTER_OTLP_ENDPOINT: "https://otlp.datadoghq.com"
  # OTEL_EXPORTER_OTLP_HEADERS se inyecta desde Secret Manager antes del deploy (Paso 2)
  # Valor en runtime: "DD-API-KEY=<valor>"
```

```yaml
# app.prod.yaml (producción)
env_variables:
  ENV: prod
  GCP_PROJECT: loopi-prod-497600
  APP_VERSION: "1.0.0"
  OTEL_SERVICE_NAME: "loopi-api"
  OTEL_EXPORTER_OTLP_ENDPOINT: "https://otlp.datadoghq.com"
  # OTEL_EXPORTER_OTLP_HEADERS se inyecta desde Secret Manager antes del deploy (Paso 2)
  # Valor en runtime: "DD-API-KEY=<valor>"
```

---

## Paso 4 — Agregar dependencias Go

```bash
cd loopi-api-v2

go get go.opentelemetry.io/otel/sdk@v1.43.0
go get go.opentelemetry.io/otel/sdk/metric@v1.43.0
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp@v1.43.0
go get go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp@v1.43.0
go get go.opentelemetry.io/contrib/instrumentation/database/sql/otelsql@v0.60.0
go get go.opentelemetry.io/otel/semconv/v1.27.0@latest

go mod tidy
```

---

## Paso 5 — Crear `internal/observability/setup.go`

```go
package observability

import (
    "context"
    "fmt"
    "os"
    "time"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
    "go.opentelemetry.io/otel/sdk/metric"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.27.0"
)

// Setup inicializa TracerProvider y MeterProvider globales con exporters OTLP/HTTP.
// Si OTEL_EXPORTER_OTLP_ENDPOINT está vacía, opera en modo no-op sin errores.
// El caller debe diferir la función shutdown retornada con un timeout de 5 s.
func Setup(ctx context.Context) (shutdown func(context.Context) error, err error) {
    endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
    if endpoint == "" {
        return func(context.Context) error { return nil }, nil
    }

    res, err := resource.New(ctx,
        resource.WithAttributes(
            semconv.ServiceName(serviceName()),
            semconv.ServiceVersion(os.Getenv("APP_VERSION")),
            semconv.DeploymentEnvironmentName(deploymentEnv()),
        ),
    )
    if err != nil {
        return nil, fmt.Errorf("observability: resource: %w", err)
    }

    traceExp, err := otlptracehttp.New(ctx,
        otlptracehttp.WithEndpoint(endpoint),
        otlptracehttp.WithInsecure(),
    )
    if err != nil {
        return nil, fmt.Errorf("observability: trace exporter: %w", err)
    }
    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(traceExp),
        sdktrace.WithResource(res),
        sdktrace.WithSampler(sdktrace.AlwaysSample()),
    )
    otel.SetTracerProvider(tp)

    metricExp, err := otlpmetrichttp.New(ctx,
        otlpmetrichttp.WithEndpoint(endpoint),
        otlpmetrichttp.WithInsecure(),
    )
    if err != nil {
        return nil, fmt.Errorf("observability: metric exporter: %w", err)
    }
    mp := metric.NewMeterProvider(
        metric.WithReader(
            metric.NewPeriodicReader(metricExp, metric.WithInterval(15*time.Second)),
        ),
        metric.WithResource(res),
    )
    otel.SetMeterProvider(mp)

    return func(ctx context.Context) error {
        _ = tp.Shutdown(ctx)
        _ = mp.Shutdown(ctx)
        return nil
    }, nil
}

func serviceName() string {
    if v := os.Getenv("OTEL_SERVICE_NAME"); v != "" {
        return v
    }
    return "loopi-api"
}

func deploymentEnv() string {
    switch os.Getenv("ENV") {
    case "prod":
        return "production"
    case "stage":
        return "staging"
    default:
        return "development"
    }
}
```

---

## Paso 6 — Modificar `cmd/api/main.go`

Agregar al inicio de `main()`, antes de abrir la conexión a BD:

```go
import (
    "context"
    "time"
    // ... imports existentes ...
    "github.com/manuelgomezsw/loopi-api-v2/internal/observability"
    "go.opentelemetry.io/contrib/instrumentation/database/sql/otelsql"
    semconv "go.opentelemetry.io/otel/semconv/v1.27.0"
)

func main() {
    ctx := context.Background()

    // Bootstrap OTel — no-op si OTEL_EXPORTER_OTLP_ENDPOINT está vacía
    otelShutdown, err := observability.Setup(ctx)
    if err != nil {
        log.Fatalf("error al inicializar observabilidad: %v", err)
    }
    defer func() {
        shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
        defer cancel()
        _ = otelShutdown(shutdownCtx)
    }()

    // ... carga de configuración existente ...

    // Reemplazar sql.Open con otelsql.Open (instrumentación automática de queries)
    db, err := otelsql.Open("mysql", dsn,
        otelsql.WithAttributes(semconv.DBSystemMySQL),
        otelsql.WithSpanOptions(otelsql.SpanOptions{Ping: false}),
    )
    // ... resto del main sin cambios ...
}
```

---

## Paso 7 — Verificar en Datadog APM

1. Inyectar `DD_API_KEY` y desplegar en stage (Paso 2): `gcloud app deploy app.stage.yaml --project=loopi-dev-497600`
2. Ejecutar un login: `curl -X POST https://api.stage.loopi.com/api/v1/auth/login ...`
3. En Datadog → **APM → Services**: buscar `loopi-api`
4. En Datadog → **APM → Traces**: filtrar por `service:loopi-api env:staging`
5. Abrir un trace y verificar spans hijos de BD con `db.system:mysql`
6. En Datadog → **Metrics Explorer**: buscar `auth.login.duration` y `auth.login.result`

---

## Cómo un feature futuro usa la fundación

Un desarrollador implementando "Gestión de Tiendas" no toca ningún código de observabilidad.
Solo usa los globals del SDK OTel:

```go
// En internal/tiendas/handler.go
var tracer = otel.Tracer("loopi-api/tiendas")

func (h *Handler) Crear(w http.ResponseWriter, r *http.Request) {
    ctx, span := tracer.Start(r.Context(), "tiendas.crear",
        trace.WithAttributes(attribute.String("resultado", "pending")),
    )
    defer span.End()
    // ...
}

// En internal/tiendas/metrics.go
func NewMetrics() *Metrics {
    meter := otel.Meter("loopi-api/tiendas")
    // ... igual que auth/metrics.go
}
```

La fundación ya configuró el `TracerProvider` y el `MeterProvider` globales en `main()`.
Los spans y métricas fluyen a Datadog sin ninguna configuración adicional.
