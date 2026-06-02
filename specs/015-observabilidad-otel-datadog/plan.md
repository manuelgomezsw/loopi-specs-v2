# Plan de Implementación: Fundación de Observabilidad — OTel + Datadog APM

**Branch**: `015-observabilidad-otel-datadog` | **Fecha**: 2026-05-26 | **Spec**: [spec.md](spec.md)

**Entrada**: Especificación de feature desde `specs/015-observabilidad-otel-datadog/spec.md`

## Resumen

Implementar la fundación de observabilidad de Loopi v2: paquete `internal/observability`
que inicializa `TracerProvider` y `MeterProvider` globales con exportación OTLP/HTTP hacia
un Datadog Agent desplegado en Cloud Run. Incluye instrumentación automática de queries
MySQL vía `otelsql` (wrapper del driver, cero cambios en repositorios). Los logs permanecen
en GCP Cloud Logging exclusivamente; Datadog recibe solo trazas y métricas.

## Contexto Técnico

**Lenguaje/Versión**: Go 1.25 (backend — siempre la versión estable más reciente del `go.mod` del repo)

**Dependencias Principales**:

- `go.opentelemetry.io/otel v1.43.0` — ya en go.mod (interfaces)
- `go.opentelemetry.io/otel/sdk` v1.43.0 — **nuevo**: implementación TracerProvider
- `go.opentelemetry.io/otel/sdk/metric` v1.43.0 — **nuevo**: implementación MeterProvider
- `go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp` v1.43.0 — **nuevo**: exporter OTLP HTTP
- `go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp` v1.43.0 — **nuevo**: exporter OTLP HTTP
- `go.opentelemetry.io/contrib/instrumentation/database/sql/otelsql` v0.60.0 — **nuevo**: spans automáticos de BD
- `go.opentelemetry.io/otel/semconv/v1.27.0` — **nuevo**: atributos semánticos de recurso

**Almacenamiento**: sin nuevas tablas; GCP Secret Manager para `DD_API_KEY`

**Testing**: `go test ./...` con OTel noop provider (incluido en SDK); sin dependencia de Datadog real en tests

**Plataforma Objetivo**: GCP App Engine Standard (Go backend); Datadog Agent en GCP Cloud Run (`us-central1`)

**Tipo de Proyecto**: Infraestructura transversal — paquete Go compartido + servicio Cloud Run

**Objetivos de Rendimiento**: Overhead OTel < 5 ms p99 por request; trazas visibles en Datadog < 30 s

**Restricciones**:

- App Engine Standard no soporta sidecars → agente como servicio Cloud Run separado
- Cloud Run con `--ingress=internal` → solo tráfico interno del proyecto GCP (sin gestión de IAM tokens en el exporter)
- `DD_API_KEY` exclusivamente en GCP Secret Manager; nunca en `app.yaml` ni en repo
- El paquete `internal/observability` es el único lugar que configura providers; ningún feature lo hace

**Escala/Alcance**: < 100 empleados, < 20 tiendas; carga moderada; `AlwaysSample` en dev/stage

## Verificación de Constitución

*GATE: Debe pasar antes de la investigación de Fase 0. Re-verificar tras el diseño de Fase 1.*

| # | Principio | Estado | Evidencia |
|---|---|---|---|
| I | Spec-First | ✅ PASA | Spec commiteada antes de este plan |
| II | Multi-Tienda | ✅ PASA | Infra transversal; `tienda_id` se añade como etiqueta de métricas en cada feature de negocio (convención §VI) |
| III | RBAC | ✅ PASA | No expone endpoints de negocio; el agente OTLP es interno y sin acceso público |
| IV | Trazabilidad | ✅ PASA | Esta feature provee la capa de trazabilidad técnica que todos los módulos de inventario usarán |
| V | Prevención de Pérdidas | ✅ PASA | RF-OBS-06 (ingress interno) + RF-OBS-07 (Secret Manager) cierran vectores de exfiltración de API Key |
| VI | Monitoreo Preventivo | ✅ PASA | Esta feature ES la fundación del §VI; conecta `internal/auth/` al provider global como primer cliente |

**Resultado**: Todos los gates pasan. Sin violaciones. Registro de Complejidad no aplica.

## Estructura del Proyecto

### Documentación (esta feature)

```text
specs/015-observabilidad-otel-datadog/
├── plan.md              # Este archivo
├── research.md          # Decisiones técnicas de Fase 0
├── quickstart.md        # Guía de setup GCP + verificación
└── tasks.md             # Output de /speckit-tasks (NO creado aquí)
```

### Código Fuente (`loopi-api-v2`)

```text
loopi-api-v2/
├── cmd/api/
│   └── main.go                   # Modificar: observability.Setup() + otelsql.Open()
├── internal/
│   ├── auth/
│   │   ├── handler.go            # Sin cambios — ya usa otel.Tracer() global
│   │   ├── metrics.go            # Sin cambios — ya usa otel.Meter() global
│   │   └── otel.go               # Sin cambios — constantes de atributos
│   └── observability/
│       └── setup.go              # NUEVO: bootstrap TracerProvider + MeterProvider
├── app.yaml                      # Modificar: agregar OTEL_EXPORTER_OTLP_ENDPOINT y APP_VERSION
└── app.prod.yaml                 # Modificar: agregar OTEL_EXPORTER_OTLP_ENDPOINT y APP_VERSION
```

El paquete `internal/observability` es infraestructura pura — no tiene handler, service ni
repository. Los repositorios existentes no se modifican: el driver BD instrumentado se
inyecta en `main.go` al abrir la conexión, transparentemente para todos los packages.

## Fase 0: Investigación

Ver [research.md](research.md) para todas las decisiones técnicas resueltas.

Decisiones principales:

1. **Transport OTLP**: HTTP (puerto 4318) sobre gRPC — más simple en App Engine Standard
2. **DB instrumentation**: `otelsql.Open()` en `main.go` — reemplaza `sql.Open()`, cero cambios en repositorios
3. **Seguridad agente**: Cloud Run `--ingress=internal` — tráfico GCP-interno sin tokens en el exporter
4. **Sampling**: `AlwaysSample` en dev/stage; ratio configurable en prod via `OTEL_TRACES_SAMPLER_ARG`
5. **No-op silencioso**: ausencia de `OTEL_EXPORTER_OTLP_ENDPOINT` → noop providers, sin errores

## Fase 1: Diseño

Esta feature no crea entidades de base de datos ni endpoints HTTP públicos.
Ver [quickstart.md](quickstart.md) para los comandos GCP exactos (Secret Manager, Cloud Run,
IAM) y la guía de verificación de trazas en Datadog APM.
