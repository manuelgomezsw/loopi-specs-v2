<!--
SYNC IMPACT REPORT
==================
Version: 1.0.0 → 1.1.0 (MINOR)
Cambio: Nueva regla BE-ARCH-02 agregada (sub-dominios dentro de un dominio grande).
        Complementa BE-ARCH-01 sin reemplazarla. Habilita la separación de la feature
        009-inventario-conteo en 6 features independientes (018–023).
Reglas: BE-ARCH-01, BE-ARCH-02 (NUEVA), BE-CACHE-01, BE-TEST-01, BE-API-01, BE-DATA-01,
        BE-JOBS-01, BE-OBS-01, BE-CI-01
Propagar a:
  ✓ loopi-api-v2/CLAUDE.md (sección Git Workflow + Standards, cabecera synced)
-->

# Estándares de Backend — Loopi v2 (`loopi-api-v2`)

Este documento es normativo (mismo nivel de obligatoriedad que la constitución) y
cubre el **cómo** se implementa el backend Go. Los **principios** de por qué el
sistema es como es viven en [`constitution.md`](../constitution.md); este archivo
cambia con más frecuencia que la constitución y tiene su propio versionado semver.

Toda tarea backend-only o full-stack DEBE verificar cumplimiento de estas reglas
en el `Constitution Check` de `plan.md` (ver `.specify/templates/plan-template.md`).

**`loopi-api-v2/CLAUDE.md` DEBE mantenerse sincronizado con la versión de este
documento** (ver cabecera de versión al inicio de ese archivo). Toda enmienda
aquí requiere propagar el cambio a `loopi-api-v2/CLAUDE.md` en el mismo PR o
en un PR inmediato de seguimiento en ese repositorio.

---

## [BE-ARCH-01] Arquitectura del backend Go — separación de capas

Cada módulo del backend (`internal/<dominio>/`) sigue tres capas con responsabilidades
exclusivas y no negociables:

| Capa | Archivo | Responsabilidad única |
|------|---------|----------------------|
| **Handler** | `handler.go` | HTTP: parsear request, llamar al service, escribir response. Sin lógica de negocio ni SQL. |
| **Service** | `service.go` | Lógica de negocio: decisiones, validaciones, orquestación. **Sin ninguna sentencia SQL ni dependencia directa a `*sql.DB`.** |
| **Repository** | `repository.go` | **Todo** acceso a la base de datos. Es la única capa que importa `database/sql`. Una sentencia SQL fuera del repository es una violación. |

Reglas de cruce entre capas:

- El handler llama al service. El handler NUNCA llama al repositorio directamente
  (salvo en handlers de jobs que no tienen lógica de negocio).
- El service declara **qué datos necesita** a través de métodos de la interfaz `Repository`;
  nunca sabe que existe MySQL, `sql.Row` ni `db.Exec`.
- Si el service necesita un dato de la BD que no está en el repositorio, la solución es
  **agregar el método al repositorio**, no agregar un `dbQuerier` al service.
- Los métodos del repositorio tienen nombres de dominio (`BuscarUsuarioPorNombre`,
  `ResetearIntentosLogin`), no nombres de SQL (`QueryUsuarios`, `ExecUpdate`).

**Test corolario:** si un test del service requiere una conexión real a BD (o un mock de
`*sql.DB`), el service tiene SQL que no le pertenece.

**Lineamiento de paginación**: SIEMPRE del lado del servidor (base de datos). Prohibida la
paginación en memoria para colecciones que puedan crecer ilimitadamente.

---

## [BE-ARCH-02] Sub-dominios dentro de un dominio grande

Complementa BE-ARCH-01. Permite dividir un dominio `internal/<dominio>/` en sub-paquetes
cuando la escala justifica la separación.

**Cuándo aplicar:**

Un dominio (`internal/<dominio>/`) **puede** dividirse en sub-paquetes
`internal/<dominio>/<subdominio>/` cuando se cumplen ambas condiciones:

1. **Cada sub-dominio corresponde a una spec independiente** en `specs/` con su propio ciclo de
   vida — no son "trozos técnicos" de una misma funcionalidad, sino capacidades distintas del
   dominio que pueden priorizar, versionar y evolucionar por separado.
2. **Existe justificación documentada** en el plan de la spec principal (ver Ejemplo: 009 en la
   sección de Arquitectura) — no es una división arbitraria de un módulo pequeño.

**Estructura interna — las tres capas dentro de cada sub-paquete:**

Cada sub-dominio es **autónomo** respecto a handler + service + repository:

```text
internal/inventarios/
├── core/                  (sin handler, ver regla 3)
│   ├── models.go
│   └── repository.go      (solo métodos compartidos por 2+ subdominios o dominios externos)
├── iniciar/
│   ├── handler.go         (HTTP specifico a "iniciar conteo")
│   ├── service.go         (lógica de iniciar: determinar tipo, horario, etc.)
│   └── repository.go      (SQL y métodos exclusivos a iniciar)
├── realizar/
│   ├── handler.go
│   ├── service.go
│   └── repository.go
├── completar/
│   ├── handler.go
│   ├── service.go
│   └── repository.go
└── ... (más subdominios)
```

- **BE-ARCH-01 se cumple dentro de cada sub-paquete, no se relaja a nivel del dominio entero.**
- El handler llama al service; el service usa el repository. Sin cruzar capas.
- **Cada sub-dominio importa la interfaz `Repository` de `core/` si necesita datos compartidos.**
  El wiring en `main.go` inyecta el repositorio de core a través de interfaz.

**Regla de promoción a `core/` — cuándo compartir:**

Un método de acceso a datos (`repository.go`) **solo se mueve** a `internal/<dominio>/core/repository.go`
cuando existe una **segunda consumidora real** — es decir:

- Otro sub-dominio del mismo dominio, O
- Un dominio externo (ej. `internal/mermas/`, `internal/caja-menor/` consumiendo
  `CanRecordMovimiento` de `inventarios/core/repository.go`).

**No se promueve anticipadamente** "por si acaso en el futuro". Si hoy es usado por un único
sub-dominio, vive en el `repository.go` de ese sub-dominio. Cuando surge una segunda consumidora,
se extrae.

**`core/` es un paquete sin `handler.go`:**

- `core/` contiene solo `models.go` (tipos compartidos) y `repository.go` (métodos compartidos).
- **No expone HTTP** — no hay handler en `core/`. Las operaciones de core se acceden **solo**
  a través de las interfaces de cada sub-dominio.
- Se inyecta por interfaz a los sub-dominios que lo necesiten en `main.go`.

**Ejemplo de aplicación (009 → 018–023):**

`internal/inventarios/core/` contiene solo:
- `CanRecordMovimiento(tiendaID, itemID) error` (RF-INV-05: bloqueo de movimientos, consumido
  por `010-mermas`, `011-caja-menor`, `012-ventas-integracion-pos`).
- `RecordMovimiento(tiendaID, itemID, cantidad, tipo, motivo)` (idem, registrar movimiento).
- `GetInventarioDetalle(inventarioID) (*Detalle, error)` (usado por historial, completar y
  editar).
- `SnapshotStockActual(tiendaID) (map[itemID]cantidad, error)` (usado por iniciar y completar).

`internal/inventarios/iniciar/repository.go` contiene:
- `CreateInventario(...)` — exclusivo a iniciar.
- `GetItemsActivosPorTipo(...)` — exclusivo a iniciar.
- Valida unicidad (tienda + tipo + horario + fecha).

`internal/inventarios/realizar/repository.go` contiene:
- `UpdateDetalle(...)` — exclusivo a realizar (registrar valor_real item por item).

Y así sucesivamente.

---

## [BE-CACHE-01] Caché Transversal — Ristretto

**Alcance**: datos de catálogo de lectura intensiva y baja volatilidad únicamente.
Los datos operacionales (stock, pedidos, inventarios, tokens de sesión) NUNCA se cachean.

**Entidades que DEBEN tener caché** (normativo desde la feature indicada en adelante):

| Entidad | Feature | TTL |
|---------|---------|-----|
| Tiendas | 002 | 24 h |
| Empleados | 003 | 24 h |
| Unidades de medida | 004 | 24 h |
| Categorías de catálogo | 005 | 24 h |
| Proveedores | 006 | 24 h |
| Ítems | 007 | 24 h |
| Menú / Recetas | 008 | 24 h |

**Patrón de implementación obligatorio — decorador con paquete compartido:**

1. **`internal/cache/`** — paquete compartido, único en `loopi-api`. Provee dos artefactos:
   - `EntityCache[T any]`: wrapper tipado (genérico Go 1.21+) sobre una instancia propia de
     Ristretto. Cada entidad crea su propia instancia para que `Clear()` afecte solo a esa entidad.
   - `ReadThrough[T any](cache *EntityCache[T], key string, fetch func() (T, error)) (T, error)`:
     función auxiliar que encapsula el patrón get → miss → fetch → set en una sola llamada.
     Reduce cada método de lectura del decorador a una línea.

2. **`internal/<dominio>/cached_repository.go`** — por módulo de dominio. Implementa la misma
   interfaz `Repository` del módulo y envuelve el `repository.go` SQL existente. El
   `repository.go` original **NO se modifica**: conserva su responsabilidad exclusiva de SQL.
   El nombre del constructor es `NewCachedRepository(inner Repository, ttl time.Duration) Repository`.

3. **`internal/<dominio>/cached_repository_test.go`** — obligatorio. Prueba el decorador
   inyectando un mock de la interfaz `Repository` (inner). Cubre como mínimo:
   - Lectura con hit de caché (el inner NO se invoca).
   - Lectura con miss de caché (el inner SÍ se invoca y el resultado se almacena).
   - Escritura invalida la caché correctamente.
   - Error del inner en lectura no almacena ningún valor en caché.
   Cobertura mínima: ≥ 90% (gate de infraestructura, ver BE-TEST-01).

**Esquema de claves de caché** (convención en todo el proyecto):

| Operación | Clave |
|-----------|-------|
| Listar todos | `"list"` |
| Buscar por ID | `"id:<id>"` |
| Buscar por campo específico | `"<campo>:<valor>"` (ej. `"activo:true"`) |

**Política de invalidación en operaciones de escritura:**

- **Crear**: llama a `cache.Clear()` (el nuevo registro no está en ninguna lista cacheada).
- **Actualizar**: llama a `cache.Delete("id:<id>")` + `cache.Clear()` de la lista.
- **Inactivar / reactivar**: igual que Actualizar.
- La invalidación afecta **solo** la instancia `EntityCache` de la entidad modificada.
  Las demás entidades (otras `EntityCache` instancias) no se tocan.
- Si el repositorio SQL retorna error, **no se invalida** la caché.

**Fallback al expirar el TTL**: Ristretto elimina la entrada automáticamente al vencer el TTL.
El próximo acceso genera un cache miss natural → el decorador consulta la BD y recarga la caché.
No se requiere código adicional para este comportamiento.

**Restricción multi-instancia**: Ristretto es in-process. La invalidación de caché en una
instancia de App Engine **no se propaga** a otras instancias. Las demás instancias sirven datos
cacheados hasta que el TTL expire (máximo 24 h). Este tradeoff es aceptable para datos de
catálogo de baja volatilidad. Si una entidad cambia con frecuencia o requiere consistencia
inmediata entre instancias, **no debe cachearse**.

**Wiring canónico en `main.go`:**

```go
const cacheTTL = 24 * time.Hour

rawRepo    := tiendas.NewRepository(db)
cachedRepo := tiendas.NewCachedRepository(rawRepo, cacheTTL)
svc        := tiendas.NewService(cachedRepo)
```

Sin caché implícito: si `NewCachedRepository` no se invoca en `main.go`, no hay caché activa.

---

## [BE-TEST-01] Estrategia de testing backend Go — técnica por capa

Cada capa usa una técnica específica que aísla exactamente lo que prueba:

| Capa | Archivo de test | Técnica | Qué valida |
|------|----------------|---------|-----------|
| **Handler** | `handler_test.go` | `httptest.NewRecorder()` + mock `Service` + mock `Repository` | Contrato HTTP: códigos de status, headers, cookies, body JSON |
| **Service** | `service_test.go` | Mock de interfaz `Repository` (sin BD) | Lógica de negocio: flujos, decisiones, manejo de errores de dominio |
| **Middleware** | `middleware_test.go` | `httptest` + JWT generado en el test + mock `Repository` | Validación de tokens: todos los caminos de aceptación y rechazo |
| **Repository** | `repository_test.go` | `go-sqlmock` (`github.com/DATA-DOG/go-sqlmock`) | Construcción correcta de queries SQL y manejo de errores de BD |
| **Config** | `config_test.go` | `t.Setenv()` | Carga de variables de entorno, defaults y errores de configuración |
| **Metrics/OTel** | cubierto desde `handler_test.go` o `service_test.go` | OTel noop provider (incluido en SDK) | Wiring de instrumentos; no se requiere Datadog real |

**Cobertura mínima obligatoria:**

- Paquetes de lógica (`internal/<dominio>/service.go`, `internal/<dominio>/middleware.go`): **≥ 95%**
- Paquetes de infraestructura (`internal/<dominio>/repository.go`, `config/`): **≥ 90%**
- Paquetes de wiring OTel (`metrics.go`, `otel.go`): **≥ 70%** — la inicialización del SDK depende de providers externos; se prioriza el wiring sobre los caminos de error del SDK
- **Excluidos** del gate de cobertura: `cmd/` (punto de entrada), `main.go` (inyección de dependencias)

El gate se verifica con:

```bash
go test ./internal/... ./config/... -coverprofile=coverage.out -covermode=atomic
go tool cover -func=coverage.out
```

Un PR no puede mergearse si algún paquete bajo `internal/` cae por debajo del threshold aplicable.

**Qué cubrir obligatoriamente en cada service:**

- Todos los caminos `if/switch` en funciones exportadas.
- El camino de error de cada llamada al repositorio (simular `error != nil`).
- La rama de bloqueo de cuenta cuando el contador llega al límite.
- El camino "usuario no existe" y "usuario inactivo" como distintos casos de test,
  aunque devuelvan el mismo error de dominio.

**Qué cubrir obligatoriamente en cada middleware:**

- Token ausente, vacío, firma inválida, expirado, algoritmo incorrecto.
- Token revocado (blacklist = true).
- BD no disponible durante la verificación de blacklist (política fail-closed → 503).
- Token válido: el handler siguiente recibe los claims en el contexto.

**Integraciones externas**: las integraciones con base de datos y servicios externos (POS, GCP
services) DEBEN testearse mediante **mocks**. Prohibida la integración directa en tests — los
entornos de CI no tienen acceso a infraestructura real y la paridad mock/real se valida en stage
(ver [`environments-ci.md`](environments-ci.md)).

---

## [BE-API-01] Convenciones de API REST

Todos los endpoints del backend siguen estas reglas sin excepción.

**Estructura de URLs:**

- Prefijo obligatorio: `/api/v1/`
- Recursos en snake_case, plural: `/api/v1/pedidos`, `/api/v1/lineas_pedido`
- Identificadores de recurso en la URL: `/api/v1/pedidos/{id}`
- Acciones no-CRUD como sub-recursos: `/api/v1/pedidos/{id}/confirmar`

**Query parameter `?estado` — filtro de estado de entidades con campo `activo`** (normativo):

Todo endpoint de listado (`GET /api/v1/{recurso}`) sobre entidades con campo `activo TINYINT(1)`
DEBE aceptar el parámetro `estado` con valores exactamente:

| Valor | Semántica |
|-------|-----------|
| `activo` | Solo registros con `activo = true` |
| `inactivo` | Solo registros con `activo = false` |
| `todos` | Sin filtro por estado (todos los registros) |

Reglas:

- El servidor DEBE validar que `estado` sea uno de los tres valores. Valor inválido → `400`
  con `error: "estado_invalido"`.
- Default server-side cuando el parámetro se omite: `todos`. Este default aplica a clientes
  API directos; el frontend **siempre** envía el parámetro explícitamente vía `FilterBarComponent`
  (que tiene `defaultValue: 'activo'`, ver [`frontend.md#FE-FILTER-01`](frontend.md)).
- El parámetro se llama `estado` en TODOS los módulos — no `activo`, no `active`, no `status`.
- Nunca usar `boolean` (`true`/`false`) para este filtro: no tiene representación natural para
  "todos" sin omitir el parámetro, lo que genera inconsistencia con los contratos que sí
  tienen default explícito.

**Formato de respuesta de error** (mismo esquema para todos los errores):

```json
{
  "error": "codigo_snake_case",
  "mensaje": "Texto legible para el usuario",
  "campo": "nombre_campo_opcional",
  "detalles": []
}
```

**Códigos HTTP:**

| Situación | Código |
|-----------|--------|
| Operación exitosa (GET, PUT) | 200 |
| Recurso creado (POST) | 201 |
| Sin contenido (DELETE lógico) | 204 |
| Datos de entrada inválidos | 400 |
| No autenticado (sin JWT o expirado) | 401 |
| Sin permiso para el recurso | 403 |
| Recurso no encontrado | 404 |
| Conflicto de estado (ej. duplicado) | 409 |
| Regla de negocio violada | 422 |
| Cuenta bloqueada temporalmente (ej. intentos fallidos de login) | 423 |
| Error interno del servidor | 500 |

---

## [BE-DATA-01] Convenciones de Datos

**Identificadores:**

- Clave primaria: entero auto-incremental (`BIGINT UNSIGNED`). No se usan UUIDs.
- Las PKs se exponen como entero en la API.

**Timestamps:**

- Toda tabla DEBE tener `creado_en DATETIME NOT NULL` y `actualizado_en DATETIME NOT NULL`.
- Todos los valores se almacenan en **hora Colombia** (`America/Bogota`, UTC-5, sin DST).
  El backend Go configura la conexión MySQL con `loc=America%2FBogota` en el DSN.
  Los clientes Angular no necesitan convertir; reciben y muestran la hora tal como viene.
- El resto de campos de fecha/hora del dominio sigue el mismo patrón en español:
  `iniciado_en`, `completado_en`, `enviado_en`, `expira_en`, etc.

**Soft delete:**

- **Nunca se ejecuta `DELETE` físico** sobre datos operacionales.
- Entidades del catálogo usan flag `activo TINYINT(1)` para inactivar.
- Entidades con ciclo de vida usan campo `estado ENUM(...)` con valores terminales
  (`cancelado`, `completado`, `parcialmente_completado`).

**Moneda y cantidades:**

- Moneda: entero `INT` en pesos colombianos (COP), sin decimales.
- Cantidades de items: `DECIMAL(12,4)` en la unidad de medida del item.
- Semanas de pedido: formato ISO 8601 `YYYY-WNN` (ej. `2026-W22`).

**Nomenclatura en base de datos:**

- Tablas y columnas en **snake_case**, en español, plural para tablas
  (ej. `pedidos`, `lineas_pedido`, `despachos`).
- Claves foráneas: `{tabla_referenciada_singular}_id` (ej. `tienda_id`, `item_id`).
- Índices únicos nombrados: `uq_{tabla}_{campos}` (ej. `uq_pedidos_tienda_semana`).

**Migraciones**: toda migración DEBE ser versionada, reversible y aplicada mediante herramienta
de migración declarativa (`golang-migrate/migrate`).

---

## [BE-JOBS-01] Jobs Programados

Las tareas de ejecución automática (generación de pedidos, motor de demanda) usan el patrón:
**Cloud Scheduler → endpoint HTTP interno**.

- El endpoint DEBE estar protegido con el header `X-CloudScheduler: true`.
  Cualquier request sin ese header recibe `403`.
- Los endpoints de jobs NO son parte de la API pública (`/api/v1/`). Usan el prefijo `/internal/jobs/`.
- Toda ejecución de job DEBE registrar en log: tipo de job, `iniciado_en`, `completado_en`,
  resultado (`ok` | `error`), cantidad de registros procesados y, si falla, el mensaje de error.
- Un job que falla no reintenta automáticamente en la misma ejecución; Cloud Scheduler gestiona
  el reintento según su política configurada.

---

## [BE-OBS-01] Observabilidad — implementación backend

El principio normativo ("todo feature monitoreable desde el día 1") vive en
[`constitution.md` §VI](../constitution.md). Esta sección define la implementación concreta.

**Stack**: **OpenTelemetry** (OTel) como SDK de instrumentación; **Datadog** exclusivamente
para APM (trazas) y métricas — Datadog NO recibe logs. **Logs**: stdout → **GCP Cloud Logging**
exclusivamente, sin reenvío a Datadog.

**Qué instrumentar**: todo endpoint crítico (autenticación, conteo de inventario, movimientos
de stock, generación y recepción de pedidos, integración con ventas) DEBE tener trazas OTel y
métricas de latencia y tasa de errores visibles en Datadog APM. Los logs DEBEN ser estructurados
(JSON) e incluir: `tienda_id`, `user_id`, `rol`, timestamp, operación y nivel (`info`/`warn`/`error`).

**Convención de nomenclatura de métricas** (normativa para todos los features):

- Formato: `[dominio].[entidad].[operacion].[tipo]`
  - Dominio: nombre corto del módulo (`auth`, `inventario`, `pedidos`, `ventas`, `mermas`, etc.)
  - Tipo al final: `duration` (histograma en ms), `total` (contador), `size` (gauge)
- Etiqueta `resultado` SIEMPRE presente en operaciones que pueden fallar. Valores descriptivos
  en español: `success`, `not_found`, `validation_error`, `account_locked`, `timeout`, etc.
- Etiqueta `tienda_id` DEBE incluirse en operaciones de negocio (cardinalidad baja: ≤ 20 tiendas).
  Permite filtrado por tienda en dashboards y alertas de Datadog.
- **`user_id` NUNCA como etiqueta de métrica**: cardinalidad alta → coste en Datadog.
  El `user_id` va en el atributo del span (traza), no en la métrica.
- No incluir valores de alta cardinalidad en etiquetas: IPs, UUIDs de request, tokens.

**Implementación de la fundación**: ver [spec 015-observabilidad-otel-datadog](../../../specs/015-observabilidad-otel-datadog/spec.md)
para el paquete `internal/observability`, configuración del agente Datadog en Cloud Run
e instrumentación automática de queries de BD.

**Declaración en specs de feature**: todo feature con endpoints críticos DEBE incluir una
sección `## Observabilidad` en su `spec.md` con las tablas de spans y métricas que define.
Ver plantilla en `.specify/templates/spec-template.md`.

---

## [BE-CI-01] Gates de CI — `loopi-api-v2`

Ejecutar en orden antes de cada commit, push o PR:

```bash
go build ./...              # compila sin errores
golangci-lint run           # linter (govet + errcheck + staticcheck + unused + gosec)
govulncheck ./...           # cero CVEs conocidas en dependencias Go realmente invocadas
gitleaks detect --no-git    # cero secrets detectados
go test ./...               # todos los tests unitarios pasan
```

**Configuración de golangci-lint** (`.golangci.yml` en la raíz de `loopi-api-v2`):

```yaml
linters:
  disable-all: true
  enable:
    - govet       # go vet estándar: errores de construcción comunes
    - errcheck    # errores de retorno no chequeados
    - staticcheck # reglas SA*: bugs reales detectados estáticamente
    - unused      # código declarado pero nunca usado
    - gosec       # OWASP: SQL injection, credenciales hardcodeadas, crypto débil

linters-settings:
  errcheck:
    check-type-assertions: true
  gosec:
    excludes:
      - G104  # errores no chequeados en defer — ya cubiertos por errcheck

issues:
  max-issues-per-linter: 0
  max-same-issues: 0
```

Reglas gosec activas relevantes: G101 (credenciales hardcodeadas), G201/G202 (SQL injection),
G402 (TLS inseguro), G404 (random débil), G501-G505 (crypto débil). G104 se excluye porque
errcheck lo cubre con mayor precisión.

**Gate adicional en CI (GitHub Actions)**: Trivy fs scan (`HIGH,CRITICAL`, `ignore-unfixed: true`).
Ver [`environments-ci.md`](environments-ci.md) para la política común a los tres repos.

---

**Version**: 1.1.0 | **Sincronizado desde**: constitution.md v2.0.0 | **Last Amended**: 2026-07-20
