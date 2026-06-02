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

## Decisión 4 — Seguridad del exporter OTLP (descartada en su forma original)

**Decisión original**: Cloud Run con `--ingress=internal` para restringir el acceso al
agente Datadog a tráfico interno del proyecto GCP.

**Motivo del descarte**: Con la adopción del intake OTLP directo a Datadog (ver Decisión
10), ya no existe un agente en Cloud Run que proteger. La seguridad del exporter ahora
recae en la `DD_API_KEY` que viaja como header `DD-API-KEY` en cada request OTLP. Ver
RF-OBS-06 en la spec para los requisitos de protección de esa clave.

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

## Decisión 7 — Imagen del Datadog Agent (descartada)

**Decisión original**: `datadog/agent:7` en Cloud Run como receptor OTLP intermediario.

**Motivo del descarte**: El `datadog/agent:7` ejecuta dos procesos separados dentro del
mismo contenedor — Core Agent y Trace Agent — que se comunican via gRPC interno en el
puerto 5001. En Cloud Run, el Trace Agent no puede establecer esa conexión (logs reiterados
de `connection refused` y `DeadlineExceeded` en `:5001`) porque el entorno sandboxed
interfiere con la comunicación inter-proceso del agente.

Consecuencia: el receptor OTLP HTTP arranca en el puerto 4318 (el TCP probe de Cloud Run
pasa), pero el path `/v1/traces` devuelve HTTP 404 porque el pipeline de trazas completo
nunca se inicializa sin la conexión Core↔Trace.

Ver **Decisión 10** para la alternativa adoptada.

---

## Decisión 8 — Configuración de `app.yaml`

**Variables a agregar** (dev local — `.env` excluido de git):

```bash
ENV=dev
GCP_PROJECT=loopi-dev-497600
APP_VERSION=1.0.0
OTEL_SERVICE_NAME=loopi-api
OTEL_EXPORTER_OTLP_ENDPOINT=   # vacío → modo no-op (sin envío a Datadog)
OTEL_EXPORTER_OTLP_HEADERS=    # vacío en modo no-op
# Para validar instrumentación desde dev, definir ambas:
# OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.datadoghq.com
# OTEL_EXPORTER_OTLP_HEADERS=DD-API-KEY=<clave-desde-secret-manager>
```

**Variables a agregar** (prod en `app.prod.yaml`):

```yaml
env_variables:
  ENV: prod
  GCP_PROJECT: loopi-prod-497600
  APP_VERSION: "1.0.0"
  OTEL_SERVICE_NAME: "loopi-api"
  OTEL_EXPORTER_OTLP_ENDPOINT: "https://otlp.datadoghq.com"
  # OTEL_EXPORTER_OTLP_HEADERS se inyecta desde Secret Manager; nunca en texto plano.
  # Valor esperado en runtime: "DD-API-KEY=<valor>"
```

**Nota**: La `DD_API_KEY` nunca aparece en el repositorio. Se almacena en Secret Manager
y se inyecta en la variable `OTEL_EXPORTER_OTLP_HEADERS` durante el deploy de App Engine.

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

---

## Decisión 10 — Intake OTLP directo a Datadog vs agente intermediario

**Decisión**: Enviar trazas y métricas directamente a `https://otlp.datadoghq.com` con
`DD-API-KEY` como header HTTP, sin Datadog Agent intermediario.

**Rationale**:
- `datadog/agent:7` en Cloud Run no funciona para OTLP ingestion: la arquitectura
  multi-proceso del agente (Core Agent + Trace Agent) es incompatible con el entorno
  sandboxed de Cloud Run (ver Decisión 7 descartada).
- Datadog soporta OTLP/HTTP nativo en su intake público desde la versión 7.35+ del
  protocolo. No requiere componente intermediario.
- Elimina el servicio Cloud Run del agente: menos infraestructura, sin costos de cómputo
  adicionales y sin complejidad de IAM entre App Engine y Cloud Run.

**Implicación de seguridad**: la `DD_API_KEY` viaja como header `DD-API-KEY` en cada
request OTLP. En stage y producción se inyecta desde Secret Manager como variable de
entorno en el momento del deploy; nunca aparece en archivos del repositorio.

**Alternativa descartada**: Datadog Agent slim para contenedores serverless
(`datadog/agent:7-serverless`). Requiere investigación adicional sobre compatibilidad con
Cloud Run y no ofrece ventajas sobre el intake directo para este caso de uso.

---

## Decisión 11 — Temporalidad delta para el exporter de métricas

**Decisión**: Configurar `otlpmetrichttp.WithTemporalitySelector` para retornar
`metricdata.DeltaTemporality` en todos los tipos de instrumento.

**Rationale**: El SDK OTel Go usa temporalidad `cumulative` por defecto para contadores
e histogramas. El intake OTLP de Datadog rechaza con HTTP 400 cualquier payload que
contenga `AGGREGATION_TEMPORALITY_CUMULATIVE` en histogramas o sumas monotónicas.

**Implicación**: Los contadores se resetean a cero en cada export; el SDK no acumula
estado entre intervalos. Datadog recibe los deltas y reconstruye los acumulativos
internamente para sus dashboards y monitores.

---

## Decisión 12 — Wrapper para omitir exports de métricas vacíos

**Decisión**: Envolver el `otlpmetrichttp.Exporter` con `skipEmptyExporter`, un tipo que
implementa `metric.Exporter` retornando `nil` sin hacer el HTTP call cuando
`ResourceMetrics.ScopeMetrics` está vacío.

**Rationale**: El `PeriodicReader` del SDK OTel Go llama a `Export()` cada 15 s
independientemente de si hay datos registrados. Si ningún instrumento ha registrado
mediciones en ese intervalo, el payload enviado al intake es vacío y Datadog responde
con HTTP 400 `Payload is empty`. El wrapper elimina ese error estructural sin suprimir
exports con datos reales.

**Alternativa considerada**: Incrementar el intervalo del `PeriodicReader`. No resuelve
el problema: un intervalo mayor reduce la frecuencia del error pero no lo elimina.
