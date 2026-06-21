# Tasks: Fundación de Observabilidad — OTel + Datadog APM

**Input**: Documentos de diseño en `specs/015-observabilidad-otel-datadog/`

**Prerrequisitos**: plan.md ✅ spec.md ✅ research.md ✅ quickstart.md ✅

**Repo de implementación**: `loopi-api-v2`

**Formato**: `[ID] [P?] [Story?] Descripción con ruta exacta`

- **[P]**: Paralelizable (archivos distintos, sin dependencias incompletas)
- **[Story]**: Historia de usuario a la que pertenece (US1–US4)

---

## Phase 1: Setup — Dependencias Go

**Propósito**: Agregar los paquetes OTel SDK y `otelsql` al proyecto Go.
Sin este paso no puede compilar ninguna tarea posterior.

- [x] T001 Agregar los 5 paquetes OTel SDK + `otelsql` al `go.mod` de `loopi-api-v2` (comandos en quickstart.md §Paso 4)
- [x] T002 Ejecutar `go mod tidy` y verificar `go build ./...` sin errores en `loopi-api-v2`

---

## Phase 2: Foundational — Paquete `observability` y Secret Manager

**Propósito**: Crear el paquete compartido Go y confirmar que `DD_API_KEY` está disponible
en Secret Manager. Las trazas se envían directo al intake OTLP de Datadog
(`https://otlp.datadoghq.com`) sin agente intermediario (ver research.md Decisión 10).

**⚠️ CRÍTICO**: La `DD_API_KEY` en Secret Manager es prerequisito para toda verificación
en stage y prod. Sin ella el header `DD-API-KEY` no puede inyectarse en el deploy.

- [x] T003 [P] Crear `loopi-api-v2/internal/observability/setup.go` con la función `Setup()` (código completo en quickstart.md §Paso 5)
- [x] T004 [P] Crear `loopi-api-v2/internal/observability/setup_test.go` con dos casos: no-op (endpoint vacío) y shutdown exitoso (usando `httptest.NewServer` como receptor OTLP)
- [x] T005 [P] Confirmar secret `DD_API_KEY` en GCP Secret Manager del proyecto stage: `gcloud secrets versions access latest --secret=DD_API_KEY --project=loopi-dev-497600`
- [x] T006 [P] Confirmar secret `DD_API_KEY` en GCP Secret Manager del proyecto prod: `gcloud secrets versions access latest --secret=DD_API_KEY --project=loopi-prod-497600`

**Checkpoint**: Paquete `observability` compila, tests pasan ≥ 70% cobertura, `DD_API_KEY` accesible en Secret Manager de stage y prod

---

## Phase 3: US1 — Trazas sin configuración adicional (Prioridad: P1) 🎯 MVP

**Goal**: El backend exporta trazas a Datadog APM al arrancar, sin que ningún feature
configure providers. En entorno local (sin endpoint) arranca sin errores.

**Prueba independiente**: Desplegar en stage, ejecutar un login y verificar en Datadog APM
que aparece un trace `service:loopi-api` con `env:staging` en menos de 30 segundos.

- [x] T010 [US1] Modificar `loopi-api-v2/cmd/api/main.go`: agregar `ctx := context.Background()`, llamar `observability.Setup(ctx)` al inicio de `main()` y diferir el shutdown con timeout de 5 s (código en quickstart.md §Paso 6)
- [x] T011 [P] [US1] Actualizar `loopi-api-v2/app.yaml`: agregar `APP_VERSION: "1.0.0"`, `OTEL_SERVICE_NAME: "loopi-api"`, `OTEL_EXPORTER_OTLP_ENDPOINT: ""` al bloque `env_variables` (endpoint vacío = modo no-op en dev local)
- [x] T012 [P] [US1] Actualizar `loopi-api-v2/app.prod.yaml`: agregar `APP_VERSION: "1.0.0"`, `OTEL_SERVICE_NAME: "loopi-api"`, `OTEL_EXPORTER_OTLP_ENDPOINT: "https://otlp.datadoghq.com"` al bloque `env_variables` (`OTEL_EXPORTER_OTLP_HEADERS` se inyecta desde Secret Manager en el deploy)
- [x] T013 [P] [US1] Crear `loopi-api-v2/app.stage.yaml` copiando la estructura de `app.yaml` y asignando `OTEL_EXPORTER_OTLP_ENDPOINT: "https://otlp.datadoghq.com"` para que el deploy en stage exporte trazas reales (`OTEL_EXPORTER_OTLP_HEADERS` se inyecta desde Secret Manager en el deploy)
- [x] T014 [US1] Verificar modo no-op localmente: ejecutar `go run ./cmd/api/` sin `OTEL_EXPORTER_OTLP_ENDPOINT` configurada y confirmar que stderr no contiene líneas con `otel`, `error` o `panic` en los primeros 5 s de arranque
- [x] T015 [US1] Inyectar `DD_API_KEY` desde Secret Manager y desplegar en stage (ver quickstart.md §Paso 2); ejecutar `POST /api/v1/auth/login`
- [x] T016 [US1] Verificar en Datadog APM → Traces: span `auth.login` con atributos `service.name=loopi-api`, `deployment.environment=staging`, `auth.result=success` visible en menos de 30 s

**Checkpoint**: US1 completo — trazas visibles en Datadog APM para cualquier request al backend

---

## Phase 4: US2 — Queries de BD visibles como spans hijo (Prioridad: P2)

**Goal**: Cada `db.Query/Exec` del repositorio genera automáticamente un span hijo
en el trace HTTP, con `db.system`, `db.operation` y `db.sql.table`.

**Prueba independiente**: Ejecutar `POST /api/v1/auth/login` en stage y verificar en
Datadog APM que el trace muestra spans hijos con `db.system:mysql`.

- [x] T017 [US2] Modificar `loopi-api-v2/cmd/api/main.go`: reemplazar `sql.Open("mysql", dsn)` por `otelsql.Open("mysql", dsn, otelsql.WithAttributes(semconv.DBSystemMySQL), otelsql.WithSpanOptions(otelsql.SpanOptions{Ping: false}))` (código completo en quickstart.md §Paso 6)
- [x] T018 [US2] Desplegar en stage y ejecutar `POST /api/v1/auth/login`
- [x] T019 [US2] Verificar en Datadog APM: el trace de `auth.login` muestra spans hijos con `db.system:mysql`, `db.operation:SELECT` y `db.sql.table` para cada query de `tokens_revocados` y `usuarios`

**Checkpoint**: US2 completo — latencia de cada query de BD visible como span hijo en Datadog APM

---

## Phase 5: US3 — Métricas del feature visibles en Datadog (Prioridad: P2)

**Goal**: Las métricas de autenticación (`auth.login.duration`, `auth.login.result`,
`auth.blacklist.check.duration`) ya implementadas en `internal/auth/metrics.go`
se conectan al `MeterProvider` real y aparecen en Datadog Metrics Explorer.

**Prueba independiente**: Ejecutar logins exitosos y fallidos en stage y verificar
histograma y contador en Datadog Metrics Explorer, filtrados por `resultado` y `env`.

- [x] T020 [US3] Modificar `loopi-api-v2/cmd/api/main.go`: reemplazar `auth.NewHandler(authSvc, authRepo)` por `auth.NewHandlerWithMetrics(authSvc, authRepo, m)` donde `m, err := auth.NewMetrics()` se llama después de `observability.Setup()` (el `MeterProvider` global ya está configurado en ese punto)
- [x] T021 [US3] Desplegar en stage y ejecutar: 1 login exitoso, 1 login con credenciales inválidas, 1 logout
- [x] T022 [US3] Verificar en Datadog Metrics Explorer: histograma `auth.login.duration` con percentiles p50/p90/p99 visibles, unidad `ms`
- [x] T023 [US3] Verificar en Datadog Metrics Explorer: contador `auth.login.result` con etiqueta `result` diferenciando `success` e `invalid_credentials`

**Checkpoint**: US3 completo — métricas de autenticación visibles y filtrables en Datadog

---

## Phase 6: US4 — Verificación de protección de credenciales (Prioridad: P3)

**Goal**: Confirmar que la `DD_API_KEY` no aparece en texto plano en ningún archivo del
repositorio. El envío directo al intake OTLP de Datadog elimina la superficie de ataque
del agente en Cloud Run; el único vector es la exposición accidental de la clave en el repo.

**Prueba independiente**: `gitleaks` no detecta secrets; `grep` en los `app*.yaml` no muestra el valor real.

- [x] T025 [P] [US4] Verificar que no hay secrets en el repositorio: ejecutar `gitleaks detect --no-git` en `loopi-api-v2` y confirmar que la clave real de `DD_API_KEY` no aparece en ningún resultado
- [x] T026 [P] [US4] Verificar que `app.yaml`, `app.stage.yaml` y `app.prod.yaml` no contienen el valor real de `DD_API_KEY` ni de `OTEL_EXPORTER_OTLP_HEADERS`: `grep -r "DD-API-KEY\|DD_API_KEY" loopi-api-v2/app*.yaml` no debe mostrar ningún valor hardcodeado

**Checkpoint**: US4 completo — credenciales solo en Secret Manager, nunca en texto plano en el repositorio

---

## Phase 7: Polish y Calidad

**Propósito**: Garantizar cobertura mínima (≥ 70%), linting, gates CI y conformidad RF-OBS-08.

- [x] T027 [P] Ejecutar `go test ./internal/observability/... -coverprofile=coverage.out -covermode=atomic` en `loopi-api-v2` y verificar cobertura ≥ 70% en `setup.go`
- [x] T028 [P] Ejecutar `golangci-lint run ./internal/observability/...` en `loopi-api-v2` y confirmar cero issues
- [x] T029 [P] Ejecutar `go test ./...` en `loopi-api-v2` y confirmar que todos los tests existentes (incluidos `internal/auth/`) siguen pasando sin modificaciones
- [x] T030 Ejecutar `go build ./...` final en `loopi-api-v2` y confirmar compilación limpia
- [x] T031 [P] Verificar RF-OBS-08: ejecutar `grep -rn "datadog" loopi-api-v2/internal/ --include="*.go"` y confirmar que ningún archivo Go configura un exporter de logs hacia Datadog; confirmar que `main.go` escribe logs a stdout (no a un writer externo)

---

## Dependencias y Orden de Ejecución

### Dependencias entre fases

- **Phase 1 (Setup)**: Sin dependencias — arrancar inmediatamente
- **Phase 2 (Foundational)**: Depende de Phase 1 — **bloquea todas las historias**
- **Phase 3 (US1)**: Depende de Phase 2 — MVP entregable al completarla
- **Phase 4 (US2)**: Depende de Phase 3 (necesita trazas activas para verificar spans hijo)
- **Phase 5 (US3)**: Depende de Phase 3 (necesita `MeterProvider` global activo)
- **Phase 6 (US4)**: Depende de Phase 2 (`DD_API_KEY` debe estar en Secret Manager para verificar que no está en texto plano en el repo)
- **Phase 7 (Polish)**: Depende de todas las fases anteriores

### Dependencias dentro de las fases

- T003 y T004 son independientes entre sí [P] — pueden crearse en paralelo
- T005 y T006 son independientes entre sí [P] — pueden verificarse en paralelo
- T010 es independiente de T005/T006 — el endpoint ya es fijo (`https://otlp.datadoghq.com`)
- T011, T012 y T013 son independientes de T010 [P] — pueden editarse en paralelo con T010
- T015 depende de T010, T011, T012, T013 (deploy requiere todos los cambios de config y código)
- T020 depende de T010 (el `MeterProvider` global lo configura `observability.Setup()`)

### Oportunidades de paralelismo

```bash
# Phase 2 — Tasks paralelas (distintos archivos/recursos):
T003: internal/observability/setup.go
T004: internal/observability/setup_test.go
T005: verificar Secret Manager stage (GCP)
T006: verificar Secret Manager prod (GCP)

# Phase 3 — Tasks paralelas dentro de US1:
T011: app.yaml
T012: app.prod.yaml
T013: app.stage.yaml  ← paralela con T011 y T012
# (T010 modifica main.go — no paralela con T011/T012/T013 si el mismo dev las hace)
```

---

## Estrategia de Implementación

### MVP (solo US1)

1. Completar Phase 1 — dependencias Go
2. Completar Phase 2 — paquete + verificar `DD_API_KEY` en Secret Manager (T003, T005)
3. Completar Phase 3 — US1 (T010–T016)
4. **PARAR y VALIDAR**: trazas visibles en Datadog APM
5. Desplegar en stage — foundation operativa

### Entrega incremental

1. MVP (Phase 1–3) → Trazas activas en Datadog APM
2. Agregar US2 (Phase 4) → Latencia de queries visible en traces
3. Agregar US3 (Phase 5) → Métricas de negocio en Datadog Metrics Explorer
4. Agregar US4 (Phase 6) → Verificación de seguridad
5. Polish (Phase 7) → Gates CI verdes

---

## Notas

- `[P]` = archivos distintos, sin dependencias entre sí — pueden ejecutarse en paralelo
- `[USn]` = historia de usuario a la que pertenece la tarea
- Hacer commit después de cada fase o grupo lógico
- El código exacto de `setup.go` y las modificaciones a `main.go` están en `quickstart.md`
- El endpoint OTLP es siempre `https://otlp.datadoghq.com` en stage y prod; no hay agente intermediario
- `OTEL_EXPORTER_OTLP_HEADERS` (`DD-API-KEY=<valor>`) se inyecta desde Secret Manager en el momento del deploy; nunca en texto plano en el repo (ver quickstart.md §Paso 2)
- `app.yaml` = dev local (endpoint vacío, no-op); `app.stage.yaml` = stage; `app.prod.yaml` = prod
- En dev local, `OTEL_EXPORTER_OTLP_ENDPOINT: ""` garantiza modo no-op; el backend no envía nada a Datadog
- `NewHandlerWithMetrics` ya existe en `internal/auth/handler.go:30` — T020 solo requiere cambiar la llamada en `main.go`
