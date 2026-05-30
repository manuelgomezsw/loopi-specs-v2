# Research: Fundación de Observabilidad — OTel + Datadog APM

**Feature**: `015-observabilidad-otel-datadog` | **Fase**: 0 | **Fecha**: 2026-05-26

---

## Decisión 1 — Paquetes OTel SDK a agregar

**Decisión**: Agregar cinco paquetes nuevos al `go.mod`; versiones alineadas a `v1.43.0`
ya presente en el módulo:

```
go.opentelemetry.io/otel/sdk                                    v1.43.0
go.opentelemetry.io/otel/sdk/metric                             v1.43.0
go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp v1.43.0
go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp v1.43.0
go.opentelemetry.io/otel/semconv/v1.27.0                        (última)
```

**Rationale**: El `go.mod` ya tiene las interfaces (`otel`, `otel/metric`, `otel/trace`)
pero no las implementaciones del SDK ni los exporters. Usar la misma versión `v1.43.0`
evita conflictos de dependencias. `semconv/v1.27.0` es la versión estable más reciente
de las convenciones semánticas de OpenTelemetry.

**Alternativa descartada**: `go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc`
(gRPC). Descartada porque App Engine Standard no tiene configuración especial de HTTP/2
y gRPC añade ~10 MB de dependencias sin beneficio a esta escala.

---

## Decisión 2 — Instrumentación automática de BD (`otelsql`)

**Decisión**: `go.opentelemetry.io/contrib/instrumentation/database/sql/otelsql` v0.60.0

Reemplazar en `main.go`:

```go
// Antes
db, err := sql.Open("mysql", dsn)

// Después (una línea, cero cambios en repositorios)
db, err := otelsql.Open("mysql", dsn,
    otelsql.WithAttributes(semconv.DBSystemMySQL),
    otelsql.WithSpanOptions(otelsql.SpanOptions{Ping: false}),
)
```

Cada `db.QueryRow()`, `db.Exec()`, `db.Query()` generará automáticamente un span hijo
con `db.system=mysql`, `db.operation` y `db.sql.table`.

**Rationale**: Wrapper del driver estándar `database/sql`. Los 6 repositorios existentes
(`auth/repository.go`, etc.) reciben la instrumentación sin ninguna modificación.
Es el paquete oficial del proyecto `opentelemetry-go-contrib`.

**Alternativa descartada**: `github.com/XSAM/otelsql` — popular pero mantenimiento
de tercero; el paquete contrib oficial tiene garantías de compatibilidad de versiones.

**`Ping: false`**: deshabilita el span en `db.Ping()` del health check para no contaminar
las trazas con checks internos de infraestructura.

---

## Decisión 3 — Transport OTLP: HTTP vs gRPC

**Decisión**: OTLP sobre HTTP (`otlptracehttp` / `otlpmetrichttp`), puerto 4318.

**Rationale**:

- App Engine Standard no requiere configuración especial para HTTP/1.1 o HTTP/2.
- El exporter HTTP del SDK OTel usa `http.DefaultClient` con TLS por defecto;
  no hay dependencia adicional de grpc ni balanceo complejo.
- El Datadog Agent 7.x soporta OTLP/HTTP en puerto 4318 y OTLP/gRPC en 4317;
  ambos protocolos son equivalentes funcionalmente.
- Cloud Run con ingress interno expone el puerto configurado sin restricciones de protocolo.

**Alternativa descartada**: gRPC (puerto 4317). Añade ~10 MB de dependencias Go y
requiere configurar `WithInsecure()` o certificados para la comunicación interna.

---

## Decisión 4 — Seguridad del agente: ingress interno vs IAM tokens

**Decisión**: Cloud Run con `--ingress=internal` (sin `--no-allow-unauthenticated`).

**Cómo funciona**:

- `--ingress=internal` restringe el acceso al servicio Cloud Run al tráfico proveniente
  del mismo proyecto GCP (App Engine Standard incluido) y descarta todo tráfico de internet.
- App Engine Standard puede llamar a servicios Cloud Run internos del mismo proyecto
  usando la URL `.run.app` directamente, sin headers de autenticación adicionales.
- El exporter OTLP HTTP envía la petición directamente sin necesidad de tokens IAM.

**Por qué no `--no-allow-unauthenticated`**:

- Requeriría que el exporter OTLP incluyera un `Authorization: Bearer <ID_TOKEN>` en cada
  petición. El SDK OTel soporta headers custom (`otlptracehttp.WithHeaders()`), pero los
  tokens de identidad de GCP expiran cada hora y requieren lógica de refresco.
- La gestión de tokens en el exporter añade complejidad sin beneficio real: el ingress
  interno ya garantiza que solo tráfico interno GCP llega al agente.

**Alternativa descartada**: `--ingress=all` + `--no-allow-unauthenticated` + token refresh.
Más seguro en teoría pero innecesariamente complejo para tráfico interno entre servicios
del mismo proyecto.

---

## Decisión 5 — Sampling

**Decisión**: `sdktrace.AlwaysSample()` en dev y stage. En producción, configurable
via variable de entorno `OTEL_TRACES_SAMPLER=parentbased_traceidratio` y
`OTEL_TRACES_SAMPLER_ARG=1.0` (default 100%). Se ajusta si el volumen genera costos.

**Rationale**: Con < 100 usuarios activos y < 20 tiendas, el volumen de trazas en
producción es bajo. `AlwaysSample` simplifica la configuración inicial y garantiza
visibilidad completa desde el primer deploy. Si el costo de Datadog APM escala, se
cambia `OTEL_TRACES_SAMPLER_ARG` a `0.1` (10%) sin tocar código.

**OTel SDK respeta las variables de entorno estándar** cuando se configura el sampler
explícitamente como `sdktrace.ParentBased(sdktrace.TraceIDRatioBased(ratio))` y
se lee `OTEL_TRACES_SAMPLER_ARG` del entorno. Implementación diferida a prod si aplica.

---

## Decisión 6 — Modo no-op en entorno local

**Decisión**: Si `OTEL_EXPORTER_OTLP_ENDPOINT` está vacía, `Setup()` retorna
`func(context.Context) error { return nil }` sin inicializar ningún provider real.
`otel.GetTracerProvider()` y `otel.GetMeterProvider()` devuelven los providers noop
del SDK (`go.opentelemetry.io/otel/trace/noop`, `go.opentelemetry.io/otel/metric/noop`).

**Rationale**: Los instrumentos del paquete `auth` (`otel.Tracer()`, `otel.Meter()`) ya
usan los providers globales. Si no se llama a `otel.SetTracerProvider()`, el SDK usa
automáticamente sus implementaciones noop. Los `noopMetrics()` en `auth/metrics.go` son
redundantes después de esta implementación pero no causan problemas.

**Implicación para tests**: Los tests existentes (`handler_test.go`) que usan `noopMetrics()`
siguen funcionando sin modificación. El nuevo `observability_test.go` puede verificar
el comportamiento no-op con `OTEL_EXPORTER_OTLP_ENDPOINT=""`.

---

## Decisión 7 — Imagen del Datadog Agent

**Decisión**: `datadog/agent:7` (imagen oficial en Docker Hub; Cloud Run la descarga directamente sin configuración adicional).

Variables de entorno del agente en Cloud Run:

| Variable | Valor | Propósito |
|---|---|---|
| `DD_API_KEY` | desde Secret Manager | Autenticación con Datadog SaaS |
| `DD_SITE` | `datadoghq.com` | Site US (ajustar si se usa EU) |
| `DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_HTTP_ENDPOINT` | `0.0.0.0:4318` | Habilitar OTLP/HTTP |
| `DD_APM_ENABLED` | `true` | Habilitar APM |
| `DD_HOSTNAME` | `loopi-api-agent-<ENV>` | Identidad del agente en Datadog |
| `DD_LOG_LEVEL` | `warn` | Reducir ruido en logs del agente |
| `DD_DOGSTATSD_NON_LOCAL_TRAFFIC` | `false` | Sin DogStatsD (no se usa) |
| `DD_PROCESS_AGENT_ENABLED` | `false` | Deshabilitar proceso agent (no aplica en Cloud Run) |
| `DD_LOGS_ENABLED` | `false` | Sin recolección de logs (solo trazas y métricas) |
| `DD_ENABLE_METADATA_COLLECTION` | `false` | Evitar crasheo por ausencia de metadata de host |

**Rationale**: `gcr.io/datadoghq/agent:7` no existe como imagen pública accesible desde Cloud Run
(verificado en producción — error PERMISSION_DENIED al hacer pull). Cloud Run soporta Docker Hub
directamente con `datadog/agent:7`. El tag `:7` recibe actualizaciones automáticas de patch.
Para producción, se puede fijar a `:7.x.y` para builds reproducibles.

**Prerrequisito de IAM**: el SA de Cloud Run (`<PROJECT_NUMBER>-compute@developer.gserviceaccount.com`)
necesita `roles/secretmanager.secretAccessor` sobre el secret `DD_API_KEY` antes del deploy.

---

## Decisión 8 — Configuración de `app.yaml`

**Variables a agregar** (dev):

```yaml
env_variables:
  ENV: dev
  GCP_PROJECT: loopi-dev-497600
  APP_VERSION: "1.0.0"
  OTEL_SERVICE_NAME: "loopi-api"
  OTEL_EXPORTER_OTLP_ENDPOINT: ""   # vacío en dev local → modo no-op
```

**Variables a agregar** (prod en `app.prod.yaml`):

```yaml
env_variables:
  ENV: prod
  GCP_PROJECT: loopi-prod-497600
  APP_VERSION: "1.0.0"
  OTEL_SERVICE_NAME: "loopi-api"
  OTEL_EXPORTER_OTLP_ENDPOINT: "https://dd-agent-<HASH>-uc.a.run.app"
```

**Nota**: El endpoint del agente en Cloud Run se obtiene tras el primer deploy con
`gcloud run services describe dd-agent --format='value(status.url)'`.
La URL interna de Cloud Run (`.run.app`) es accesible desde App Engine Standard
cuando el servicio tiene `--ingress=internal`.

---

## Decisión 9 — Estructura del paquete `internal/observability`

**Un solo archivo**: `setup.go` con la función pública `Setup(ctx context.Context)`.

```go
// Firma de la función de bootstrap
func Setup(ctx context.Context) (shutdown func(context.Context) error, err error)
```

**Retorna una función de shutdown** para diferirla en `main()` con timeout de 5 s.
Garantiza que los buffers del exporter se vacíen antes de que el proceso termine.

**No se exporta ningún tracer ni meter**: los features usan `otel.Tracer(scope)` y
`otel.Meter(scope)` del paquete global, que apuntan al provider configurado por `Setup()`.
Esto es el patrón estándar del SDK OTel Go y evita acoplamiento al paquete `observability`.
