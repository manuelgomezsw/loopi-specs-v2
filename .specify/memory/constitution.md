<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0 → 1.1.1 → 1.2.0 → 1.3.0 → 1.3.4 → 1.4.0 → 1.4.1 → 1.5.0 → 1.6.0 → 1.7.0 → 1.8.0 → 1.9.0 → 1.10.0 → 1.11.0
Reason: 1.1.0 — nueva sección ambientes + correcciones de stack (MINOR).
        1.1.1 — dev environment redefinido: GCP en todos los ambientes (PATCH).
        1.2.0 — rol lider_compras, convenciones API, convenciones de datos y jobs programados (MINOR).
        1.3.0 — OTel+Datadog, Ristretto, zona horaria Colombia, CI gates, estructura multi-repo (MINOR).
        1.3.1 — golangci-lint (lean) agregado al gate de backend (PATCH).
        1.3.2 — gosec, govulncheck, npm audit, gitleaks agregados a los gates de seguridad (PATCH).
        1.3.3 — Trivy CI agregado como gate obligatorio en GitHub Actions (PATCH).
        1.3.4 — HTTP 423 (cuenta bloqueada) añadido a la tabla de códigos (PATCH).
        1.4.0 — nueva sección "Diseño de Interfaz (UX/UI)": responsive mobile-first,
                accesibilidad WCAG 2.1 AA, estados de carga/error/vacío, convenciones
                de formularios, feedback de acciones y estructura mínima de vistas (MINOR).
        1.4.1 — patrón de listas y formularios: navegación por clic de fila, zona de precaución
                en formulario de edición para acciones destructivas (PATCH).
        1.5.0 — nueva subsección "Arquitectura del backend Go — separación de capas":
                tabla Handler/Service/Repository con responsabilidades exclusivas,
                reglas de cruce, test corolario. Previene SQL en la capa service (MINOR).
        1.6.0 — estrategia de testing backend Go: técnica por capa (httptest/mock/sqlmock/t.Setenv),
                thresholds (≥ 95% lógica, ≥ 90% infraestructura, ≥ 70% OTel), gate CI,
                qué cubrir obligatoriamente en service y middleware (MINOR).
        1.7.0 — §VI Monitoreo Preventivo ampliado: logs exclusivamente en GCP Cloud Logging
                (Datadog no recibe logs), reglas de cardinalidad de métricas (tienda_id ✅ / user_id ❌),
                convención de nomenclatura de métricas y referencia a spec 015 (MINOR).
        1.8.0 — §Diseño de Interfaz: nueva subsección "Convenciones de Botones de Acción":
                prefijo '+ ' obligatorio en botones de creación en vistas de lista;
                títulos de formulario sin prefijo (MINOR).
        1.9.0 — §Diseño de Interfaz: nueva subsección "Superficie de Formulario": card blanca
                obligatoria sobre fondo gris de página; bg-white explícito en inputs;
                jerarquía visual de tres capas; ancho máximo por densidad (MINOR).
        1.10.0 — §Stack Técnico: nuevo bloque normativo "Caché Transversal — Ristretto":
                 patrón decorador obligatorio (cached_repository.go por módulo + paquete
                 internal/cache/ compartido), helper ReadThrough[T] para eliminar boilerplate,
                 TTL 24 h para todas las entidades de catálogo, esquema de claves, política de
                 invalidación en escrituras, restricción multi-instancia explícita,
                 tabla de entidades con caché obligatoria (MINOR).
        1.11.0 — §Diseño de Interfaz: Superficie de Listado (jerarquía 3 capas para tablas),
                 Filtros en Listados (chip pattern, default Estado=Activo), Estados de
                 Registros (badge verde/gris + opacity-60), Inputs Read-Only (tabla de estados
                 con clases explícitas), Sub-menú Lateral (expansión controlada por router) y
                 Componentes Angular Transversales (catálogo normativo 10 componentes +
                 FilterStateService, prohibición de re-implementaciones) (MINOR).

Changes in 1.10.0:
  - Nuevo bloque normativo §Caché Transversal — Ristretto dentro de §Stack Técnico
  - Patrón decorador: cached_repository.go por dominio + paquete internal/cache/ compartido
  - Función genérica ReadThrough[T] reduce boilerplate de cada método cacheado a 1 línea
  - TTL: 24 h para todas las entidades de catálogo; sin excepción salvo justificación en spec
  - Esquema de claves: "list", "id:<id>", "<campo>:<valor>" para filtros
  - Política de invalidación: Clear() solo de la entidad afectada; sin afectar otras entidades
  - Restricción multi-instancia documentada como tradeoff aceptable para catálogo de baja volatilidad
  - Tabla normativa de 7 entidades que DEBEN tener caché (002 a 008)
  - cached_repository_test.go obligatorio con cobertura ≥ 90%
  - Wiring canónico en main.go

Changes in 1.11.0:
  - §Superficie de Listado: jerarquía 3 capas para listas (card blanca, thead bg-gray-50, hover bg-blue-50/30)
  - §Filtros en Listados: chip pattern, fondo bg-gray-50/70, default Estado=Activo para entidades con campo activo
  - §Estados de Registros: badge verde/gris (StatusBadgeComponent) + opacity-60 en filas inactivas
  - §Inputs Read-Only: tabla de estados (editable/readonly/disabled) con clases explícitas; label con ícono candado
  - §Sub-menú Lateral: expansión controlada por routerLinkActive; abierto en rutas hijas activas
  - §Componentes Transversales: catálogo normativo (10 componentes + FilterStateService); prohibición de re-implementaciones

Changes in 1.4.1:
  - Patrón de listas: filas clickeables con cursor-pointer, tabindex="0", role="button", keydown.enter
  - Patrón de formularios: acciones destructivas en "Zona de precaución" al pie del formulario
  - Texto de impacto en lenguaje no técnico; modal de confirmación antes de acción irreversible

Changes in 1.9.0:
  - §Diseño de Interfaz: nueva subsección "Superficie de Formulario"
  - Jerarquía de tres capas obligatoria: página bg-gray-50 → tarjeta bg-white → inputs bg-white explícito
  - Tabla de ancho máximo según densidad del formulario (max-w-lg / max-w-2xl / max-w-4xl)
  - Regla de separación de zona destructiva con hr + mt-8
  - Ejemplo canónico HTML de referencia para todos los formularios del sistema

Changes in 1.3.2:
  - golangci-lint: agrega gosec (G101, G201, G202, G404, G402, G501-G505); excluye G104 (cubierto por errcheck)
  - loopi-api: govulncheck y gitleaks como gates obligatorios
  - loopi-web: npm audit --audit-level=high y gitleaks como gates obligatorios
  - loopi-specs-v2: gitleaks como gate obligatorio

Changes in 1.3.3:
  - Flujo de Trabajo: Trivy fs scan obligatorio en CI de GitHub (PRs y push a develop/master)
  - Principio: la política va en la constitución; el workflow YAML va en cada repo

Changes in 1.4.0:
  - Nueva sección §Diseño de Interfaz (UX/UI) después de §Stack Técnico
  - Stack UI: Tailwind CSS v4 puro, componentes propios (loopi-web/src/app/shared/components/)
  - Responsive mobile-first: breakpoints estándar de Tailwind, mínimo 320 px
  - Accesibilidad WCAG 2.1 AA: contraste, labels, errores con texto, navegación por teclado
  - Convenciones de estados de carga (< 300 ms sin indicador; 300 ms–3 s spinner inline)
  - Manejo de errores en UI: errores de campo, errores de API, 401/403 con mensajes claros
  - Empty states obligatorios para toda lista/tabla
  - Convenciones de formularios: validación on blur + on submit; botón deshabilitado en loading
  - Feedback de acciones: toasts 3 s en éxito; modal de confirmación en destructivas
  - Estructura mínima de vistas: h1 único, breadcrumb contextual, acción primaria identificada

Changes in 1.4.1:
  - Patrón de listas: las filas son clickeables y navegan al formulario de edición
    (cursor-pointer, tabindex="0", role="button", keydown.enter). Sin botones por fila.
  - Patrón de formularios: las acciones destructivas (inactivar, eliminar) van en una
    sección "Zona de precaución" al pie del formulario en modo edición, nunca en la lista.
    El texto explica el impacto en lenguaje para usuarios no técnicos (no jerga interna).
    Un modal de confirmación precede toda acción destructiva irreversible.

Templates reviewed:
  - .specify/templates/plan-template.md — pendiente de revisión
  - .specify/templates/spec-template.md ✅ — estructura compatible
  - .specify/templates/tasks-template.md — pendiente de revisión

Deferred items: actualizar checklist "Verificación de Constitución" en plan-template.md para reflejar 7 puertas
-->

# Loopi v2 — Constitución del Proyecto

## Principios Centrales

### I. Especificación Funcional Primero (Spec-First)

Toda funcionalidad nueva o cambio a una funcionalidad existente DEBE comenzar con una especificación
aprobada antes de cualquier línea de código. La especificación funcional en
`specs/` es la fuente de verdad del producto.

- DEBE existir una spec aprobada (PR mergeado a `develop`) antes de comenzar el plan de implementación.
- El plan de implementación DEBE referenciar la sección de spec correspondiente.
- Cambios al comportamiento del sistema que no estén en la spec son regresiones, no mejoras.
- Decisiones pendientes (DP-01, DP-02, DP-03) NO pueden implementarse hasta que el equipo las valide.

### II. Arquitectura Multi-Tienda

Loopi v2 opera bajo el modelo: **catálogo compartido por marca, datos operacionales aislados por tienda**.

- Todo dato operacional (inventario, mermas, pedidos, compras, ventas) DEBE llevar `tienda_id` explícito.
- Un empleado (`lider_tienda`, `barista`) JAMÁS puede acceder a datos de una tienda que no sea la suya.
- El catálogo (items, recetas, menú, categorías, proveedores) es compartido: modificarlo en una tienda
  lo modifica para todas.
- El `admin` puede operar en modo consolidado (todas las tiendas) o en modo por tienda (selección explícita
  en la interfaz); su token JWT no lleva `tienda_id` fijo.

### III. Control de Acceso por Rol (RBAC)

Los cuatro roles del sistema (`admin`, `lider_compras`, `lider_tienda`, `barista`) son la única fuente
de verdad de permisos. La matriz de permisos en §2.5 de la spec es normativa.

- **`admin`**: acceso total. Su JWT no lleva `tienda_id` fijo; opera en modo consolidado o por tienda.
- **`lider_compras`**: opera a nivel de marca. Ve pedidos y planeación de todas las tiendas.
  Su JWT no lleva `tienda_id` fijo.
- **`lider_tienda`** y **`barista`**: acceso restringido a su tienda asignada. Su JWT incluye `tienda_id`.
- El backend DEBE validar el rol en cada endpoint. El frontend oculta opciones según el rol,
  pero la validación del backend es la que tiene carácter vinculante.
- Agregar o modificar permisos REQUIERE actualizar §2.5 de la spec y hacer la implementación pasar
  por el flujo spec-first completo.
- Un usuario inactivo NUNCA puede autenticarse, independientemente del rol.
- Los tokens JWT DEBEN incluir `rol` y, para `lider_tienda`/`barista`, el `tienda_id` asignado.

### IV. Trazabilidad Total de Inventario

Todo movimiento que afecte el stock DEBE quedar registrado con: quién lo hizo, cuándo, en qué tienda
y por qué motivo. No existe modificación de inventario sin rastro auditable.

- Entradas: recepción de pedidos, compras caja menor.
- Salidas: consumo por ventas POS, mermas registradas.
- Correcciones: conteo físico confirmado (ajuste automático al cierre del inventario).
- El historial de movimientos NUNCA se borra; solo se anulan con contra-registro.
- El stock se ajusta automáticamente al confirmar un inventario físico (RN-INV-05).

### V. Prevención de Pérdidas

El diseño funcional y técnico DEBE cerrar activamente posibilidades de hurto, maquillaje de información
y brechas operacionales. Un flujo que crea oportunidad de fraude DEBE rediseñarse antes de implementarse.

### VI. Monitoreo Preventivo

Cada feature DEBE ser monitoreable desde el primer deploy en producción. El sistema DEBE permitir
diagnosticar degradaciones en menos de 5 segundos.

**Stack de observabilidad**:

- **Trazas y métricas**: **OpenTelemetry** (OTel) como SDK de instrumentación en el backend Go;
  **Datadog** exclusivamente para APM (trazas) y métricas. Datadog NO recibe logs.
- **Logs**: stdout → **GCP Cloud Logging** exclusivamente. No se configura ningún reenvío de
  logs a Datadog. Los logs se consultan en GCP Log Explorer.

**Qué instrumentar:**

- Todo endpoint crítico (autenticación, conteo de inventario, movimientos de stock, generación
  y recepción de pedidos, integración con ventas) DEBE tener trazas OTel y métricas de latencia
  y tasa de errores visibles en Datadog APM.
- Los logs DEBEN ser estructurados (JSON) e incluir: `tienda_id`, `user_id`, `rol`, timestamp,
  operación y nivel (`info`/`warn`/`error`).
- Las alertas DEBEN configurarse en Datadog y ser preventivas: detectar anomalías antes de que
  impacten al usuario final.
- El monitoreo es responsabilidad del equipo de desarrollo, no solo de operaciones.

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

**Implementación de la fundación**: ver [spec 015-observabilidad-otel-datadog](../../specs/015-observabilidad-otel-datadog/spec.md)
para el paquete `internal/observability`, configuración del agente Datadog en Cloud Run
e instrumentación automática de queries de BD.

**Declaración en specs de feature**: todo feature con endpoints críticos DEBE incluir una
sección `## Observabilidad` en su `spec.md` con las tablas de spans y métricas que define.
Ver plantilla en `.specify/templates/spec-template.md`.

---

## Stack Técnico y Lineamientos de Implementación

**Frontend**: Angular (última versión estable), componentes standalone y signals, Tailwind CSS v4.
Despliegue en **Firebase Hosting** (GCP). Ver §Diseño de Interfaz (UX/UI) para convenciones de UI.

**Backend**: **Golang**, desplegado en **GCP App Engine**.

**Base de datos**: **MySQL** en **GCP Cloud SQL**. Toda migración DEBE ser versionada, reversible
y aplicada mediante herramienta de migración declarativa (ej. Flyway, golang-migrate).

**Autenticación**: JWT con expiración configurable (default 24 h).

**Arquitectura del backend Go — separación de capas:**

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

**Lineamientos transversales:**

- Paginación: SIEMPRE del lado del servidor (base de datos). Prohibida la paginación en memoria
  para colecciones que puedan crecer ilimitadamente.
- Caché: **Ristretto** (in-process por instancia de App Engine). Solo catálogo de baja
  volatilidad; datos operacionales NUNCA se cachean. Patrón y TTL normativo: ver
  §Caché Transversal — Ristretto.
- Pruebas frontend: unitarias por componente + funcionales automatizadas para flujos críticos (P1).
- Pruebas backend: las integraciones con base de datos y servicios externos (POS, GCP services) DEBEN
  testearse mediante **mocks**. Prohibida la integración directa en tests — los entornos de CI no
  tienen acceso a infraestructura real y la paridad mock/real se valida en stage (ver sección Ambientes).

**Caché Transversal — Ristretto**

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
   Cobertura mínima: ≥ 90% (gate de infraestructura).

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

**Estrategia de testing backend Go — técnica por capa:**

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

Un PR no puede mergearse si algún paquete bajo `internal/` cae por debajo del 90%.

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
- Markdown: sub-listas con indentación de 2 espacios; línea en blanco antes/después de headings
  y listas; archivo termina con newline (markdownlint MD007, MD022, MD032, MD047).

---

## Diseño de Interfaz (UX/UI)

### Stack de UI

- **Framework CSS**: Tailwind CSS v4 — utility-first, sin librerías de componentes externas.
- **Componentes**: construidos a medida sobre Tailwind CSS. No se usan PrimeNG, Angular Material,
  DaisyUI ni otras librerías de componentes. Los componentes propios viven en
  `loopi-web/src/app/shared/components/`.
- **Fuente y colores**: escala base de Tailwind CSS v4 hasta que el sistema de diseño de marca
  quede definido. Cuando se defina, los tokens van en `tailwind.config.ts` como extensión del
  tema. Ningún color de marca DEBE hardcodearse en clases arbitrarias; siempre como variable
  de diseño.

### Responsive (Mobile-First)

La aplicación DEBE funcionar correctamente en todos los dispositivos: baristas usan celular en
tienda, administradores y líderes trabajan en desktop. La estrategia es **mobile-first**: los
estilos base aplican a pantallas pequeñas y se extienden con breakpoints de Tailwind.

| Breakpoint | Prefijo Tailwind | Dispositivo objetivo |
| --- | --- | --- |
| < 640 px | (base) | Móvil — baristas en tienda |
| ≥ 640 px | `sm:` | Móvil grande / tablet portrait |
| ≥ 768 px | `md:` | Tablet landscape |
| ≥ 1024 px | `lg:` | Desktop — admin y líderes |
| ≥ 1280 px | `xl:` | Desktop ancho |

Toda vista DEBE ser usable desde el breakpoint base. No se permiten layouts que rompan o
queden inutilizables en pantallas menores a 320 px.

### Accesibilidad

- **Estándar mínimo**: WCAG 2.1 nivel AA.
- Contraste de color: mínimo 4.5:1 para texto normal, 3:1 para texto grande (≥ 18 pt o 14 pt bold).
- Todo campo de formulario DEBE tener un `<label>` asociado. No se usa `placeholder` como
  reemplazo del label.
- Los errores de validación DEBEN comunicarse con texto descriptivo, no solo con cambio de color.
- Navegación por teclado (Tab / Shift+Tab / Enter / Esc / flechas) DEBE funcionar en todos los
  flujos críticos: login, formularios, modales y menús.
- Los componentes interactivos sin elemento HTML semántico equivalente DEBEN tener atributos
  ARIA (`role`, `aria-label`, `aria-describedby`, `aria-expanded`) según corresponda.
- Las imágenes decorativas llevan `alt=""`. Las imágenes informativas llevan `alt` descriptivo.

### Estados de Carga

| Duración estimada | Indicador |
| --- | --- |
| < 300 ms | Sin indicador (evitar parpadeo innecesario) |
| 300 ms – 3 s | Spinner inline o skeleton loader en el área afectada |
| > 3 s (poco común) | Barra de progreso o mensaje de estado con texto |

Los spinners y skeletons DEBEN estar en el componente afectado, no superpuestos sobre toda la
pantalla, salvo que la acción bloquee realmente toda la interfaz (ej. login inicial).

### Manejo de Errores en UI

- **Error de validación de campo**: texto de error debajo del campo, `text-red-600`, ícono
  opcional. El campo recibe `border-red-500`.
- **Error de API recuperable (4xx)**: toast no intrusivo, esquina superior derecha, auto-cierre
  en 5 s. Nunca bloquear toda la pantalla.
- **Error 401 (sesión expirada)**: `AuthInterceptor` captura y redirige a `/login` con mensaje:
  "Tu sesión expiró. Inicia sesión nuevamente."
- **Error 403 (sin permiso)**: pantalla "No tienes permiso para ver esto" con botón de regreso.
  No revelar datos del recurso al que se intentó acceder.
- **Error 500 / red caída**: mensaje genérico "Ocurrió un error. Intenta de nuevo." con opción
  de reintentar. Registrar en consola para debugging.
- Los mensajes de error al usuario DEBEN ser en español, concisos y accionables. Nunca exponer
  stack traces, IDs internos ni mensajes técnicos al usuario final.

### Estados Vacíos (Empty States)

Toda lista, tabla o sección que pueda estar vacía DEBE mostrar un estado vacío con:

- Texto explicativo en primera persona ("Aún no hay pedidos registrados.").
- Acción sugerida cuando aplique ("Crea el primer pedido →").
- Ícono opcional para contexto visual.

Nunca mostrar una lista en blanco sin contexto. El empty state es parte del diseño, no un
caso excepcional.

### Convenciones de Formularios

- **Validación**: on blur por campo + validación completa on submit.
- **Envío**: el botón de submit DEBE deshabilitarse durante el envío (estado `loading`) para
  prevenir doble-clic. Mostrar spinner inline en el botón o texto "Guardando...".
- **Campos obligatorios**: marcados con `*` junto al label. Leyenda al pie: "* Campo obligatorio".
- **Placeholders**: solo como ejemplo de formato (ej. "ej. usuario@loopi.com"), nunca como
  reemplazo del label.
- **Autocompletar**: habilitar `autocomplete` en credenciales (`current-password`); deshabilitar
  solo cuando el llenado automático sea perjudicial para el flujo.

### Patrón Lista–Formulario

Toda entidad de catálogo o maestro sigue este patrón de navegación y acciones:

- **Lista**: cada fila es clickeable y navega al formulario de edición del registro. No se
  colocan botones de "Editar" ni "Inactivar" por fila. Atributos obligatorios en el `<tr>`:
  `cursor-pointer`, `tabindex="0"`, `role="button"`, handler `(keydown.enter)` para
  accesibilidad por teclado.
- **Formulario (modo edición)**: contiene todas las acciones posibles sobre el registro,
  incluidas las destructivas. Las acciones destructivas van en una sección **"Zona de
  precaución"** al pie del formulario (borde rojo, fondo rojo claro), separada visualmente
  del resto. Un modal de confirmación precede toda acción irreversible.
- **Texto de impacto**: escrito en lenguaje para usuarios no técnicos. No usar jerga interna
  ("unidad canónica", "soft delete", "FK"). Describir el efecto real en el negocio.
  Ejemplo correcto: "Los ítems que usen esta unidad de medida no podrán registrar nuevas
  transacciones." Ejemplo incorrecto: "Los ítems con unidad canónica inactiva quedarán
  bloqueados."

### Superficie de Listado

Todo listado de entidades (tabla, lista de registros) DEBE seguir la misma jerarquía visual
de tres capas que los formularios, adaptada a la presentación tabular:

| Capa | Elemento | Clases Tailwind obligatorias |
|------|----------|------------------------------|
| 1 — Página | `<main>` del shell | `bg-gray-50` |
| 2 — Card del listado | `<div>` wrapper | `bg-white rounded-xl border border-gray-100 shadow-sm` |
| 3 — Encabezado de tabla | `<thead>` | `bg-gray-50 border-b border-gray-200` |
| 3 — Filas de datos | `<tbody> <tr>` | `bg-white hover:bg-blue-50/30 transition-colors cursor-pointer` |

**Reglas:**

- El card del listado ocupa el ancho disponible (`w-full`); sin `max-w-*` (a diferencia de los formularios).
- El elemento raíz de la vista de listado es un `<div>` directo sin restricción de ancho.
- No usar `<main>` propio en la vista — sería `<main>` anidado (HTML inválido).
- Implementar con `ListCardComponent` (ver §Componentes Angular Transversales).

### Filtros en Listados

**Posición**: Dentro del card del listado, entre el encabezado y la tabla, separada por
`border-b border-gray-200`. La barra de filtros usa `bg-gray-50/70` para distinguirse del
área de datos. Los controles de filtro usan `h-8` o `h-9` — más compactos que los inputs de
formulario — para comunicar que son controles de navegación, no campos de datos.

**Patrón de chips/pills**: Los filtros activos se representan como chips removibles
(`bg-blue-100 text-blue-700 border border-blue-200 rounded-full`). El chip "Estado: Activo"
aparece azul por defecto; quitarlo explícitamente cambia la vista a todos los registros.

**Regla de default obligatoria**: Todo listado de una entidad con campo `activo` DEBE
preseleccionar el filtro de estado en **Activos** al cargar por primera vez en la sesión.
El usuario puede cambiarlo a Inactivos o Todos de forma explícita.

**Implementación**: Usar `FilterBarComponent` con `FilterStateService` (ver §Componentes
Angular Transversales). Prohibido implementar filtros ad-hoc por feature.

### Estados de Registros en Listados

Todo listado con campo `activo` DEBE diferenciar visualmente registros activos e inactivos
con dos mecanismos complementarios:

**1. Badge de estado** — obligatorio en la columna Estado de toda tabla con campo `activo`:

| Estado | Clases del `<span>` |
|--------|---------------------|
| Activo | `inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700` |
| Inactivo | `inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-500` |

Implementación: usar `StatusBadgeComponent` (ver §Componentes Angular Transversales).

**2. Deemphasis de fila inactiva**: La `<tr>` de un registro inactivo lleva `class="opacity-60"`.
El badge NO recibe `opacity-60` — debe permanecer legible para identificar el estado.

### Superficie de Formulario

Todo formulario de creación o edición DEBE establecer una jerarquía visual de tres capas para
garantizar que los inputs sean percibidos como activos e interactivos en todos los sistemas
operativos y navegadores:

| Capa | Elemento | Clases Tailwind obligatorias |
|------|----------|------------------------------|
| 1 — Página | `<main>` o contenedor raíz | `bg-gray-50` |
| 2 — Tarjeta | `<div>` que envuelve el `<form>` | `bg-white rounded-xl border border-gray-100 shadow-sm p-6 lg:p-8` |
| 3 — Inputs | `<input>`, `<select>`, `<textarea>` | `bg-white` explícito (no depender del default del navegador) |

**Reglas:**

- El contenedor de la tarjeta DEBE tener ancho máximo apropiado a la densidad del formulario:
  - Formularios simples (≤ 6 campos): `max-w-lg` (512 px)
  - Formularios medios (7–15 campos): `max-w-2xl` (672 px)
  - Formularios complejos (> 15 campos o secciones): `max-w-4xl` (896 px)
- La tarjeta se centra horizontalmente con `mx-auto`.
- El `<main>` o página que contenga la tarjeta DEBE usar `bg-gray-50` para que el
  contraste tarjeta/fondo sea visible. Nunca fondo blanco en la página y tarjeta blanca.
- Los campos en estado deshabilitado o read-only: ver §Inputs en Estado Read-Only o Deshabilitado.
- La zona de acciones destructivas (inactivar, eliminar) DEBE separarse del formulario principal
  con un `<hr>` y un margen de al menos `mt-8`, ubicada al final de la vista.

**Integración con el Shell:**

Los formularios se renderizan dentro del `<main>` del `ShellComponent`, que ya aplica
`bg-gray-50` al fondo de la página y `p-4 sm:p-6 lg:p-8` como padding base. Por lo tanto:

- **No usar `<main>` propio** en la vista del formulario (sería `<main>` anidado, HTML inválido).
- **No repetir el padding** del shell en el contenedor raíz de la vista.
- El elemento raíz de la vista es un `<div>` con `max-w-{tamaño} mx-auto` para centrar el contenido.

**Ejemplo canónico:**

```html
<!-- Vista del formulario (renderizada dentro del <main> del shell) -->
<div class="max-w-lg mx-auto">
  <!-- Breadcrumb + título fuera de la tarjeta -->
  <nav ...>...</nav>
  <h1 ...>Nueva tienda</h1>

  <!-- Tarjeta del formulario -->
  <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6 lg:p-8">
    <form ...>
      <input class="bg-white w-full border border-gray-300 rounded-lg px-3 py-2 ..." />
      ...
    </form>
  </div>

  <!-- Zona destructiva (solo en edición) -->
  <div class="mt-8 pt-6 border-t border-gray-200">...</div>
</div>
```

### Inputs en Estado Read-Only o Deshabilitado

Los campos no editables en formularios de edición (ej. `codigo` de tienda, nombre de usuario
de empleado) DEBEN comunicar inequívocamente su estado mediante contraste con los campos activos:

| Estado | Atributo HTML | Clases del `<input>` |
|--------|--------------|----------------------|
| Editable | — | `bg-white border border-gray-300 text-gray-900 focus:ring-2 focus:ring-blue-500` |
| Read-only | `readonly` | `bg-gray-100 border border-gray-200 text-gray-500 cursor-not-allowed` |
| Deshabilitado | `disabled` | `bg-gray-100 border border-gray-200 text-gray-400 cursor-not-allowed opacity-60` |

**Label del campo read-only**: DEBE incluir una señal visual de no editable. Opciones
(elegir una por módulo, mantenerla consistente):

- Ícono de candado (`LockClosedIcon`, 14 px, `text-gray-400`) junto al label.
- Texto `(no editable)` en `text-xs text-gray-400` junto al label.

**Nunca** usar `bg-white` en un campo `readonly` o `disabled`. El contraste `bg-gray-100`
vs. `bg-white` es el mecanismo primario de comunicación del estado.

**Implementación**: Usar `ReadonlyFieldComponent` (ver §Componentes Angular Transversales).

### Convenciones de Botones de Acción

- **Botón de creación (acción primaria de lista)**: lleva el prefijo `+ ` antes del texto.
  Ejemplos correctos: `+ Nueva tienda`, `+ Nuevo empleado`, `+ Nuevo pedido`.
- **Título de formulario**: NO lleva `+ `. Es un encabezado de página (`<h1>`), no un botón.
  Ejemplos correctos: `Nueva tienda`, `Editar empleado`.
- El prefijo `+ ` aplica solo a los botones/enlaces de acción primaria en vistas de lista.
  No aplica a acciones secundarias (Editar, Inactivar, Reactivar, Cancelar).

### Feedback de Acciones

- **Éxito (guardar, crear, actualizar)**: toast verde, esquina superior derecha, auto-cierre
  3 s. Texto conciso: "Pedido guardado correctamente."
- **Éxito (eliminar / inactivar)**: toast neutro con opción de deshacer si es reversible en
  la sesión.
- **Acciones destructivas irreversibles**: confirmar con modal antes de ejecutar. El botón de
  confirmación es el más llamativo; el de cancelar es secundario.

### Estructura Mínima de Vistas

Cada vista de la aplicación DEBE tener:

- **Título de página** (`<h1>`) único y descriptivo — visible en pantalla y en el `<title>`
  del documento.
- **Breadcrumb o navegación contextual** cuando la vista tiene jerarquía padre. En el nivel
  raíz no aplica.
- **Acción primaria** claramente identificada cuando la vista tiene una acción principal
  (ej. "Nuevo pedido", "Confirmar inventario").
- **Layout consistente** con el resto del módulo: mismo padding, misma estructura de header.

### Sub-menú Lateral — Estabilidad de Expansión

Cuando el menú lateral contiene grupos con sub-ítems, el estado de expansión del grupo DEBE
estar determinado exclusivamente por el router Angular:

- Un grupo **permanece expandido** mientras la URL activa corresponda a cualquier ruta hija
  del grupo, independientemente de si el usuario navega entre el listado y el formulario del mismo módulo.
- La expansión se implementa con `routerLinkActive` o inspeccionando `router.url` —
  nunca con una variable booleana local que se colapse al navegar.
- El ítem activo dentro del grupo lleva `bg-blue-50 text-blue-700 font-medium`.
- El grupo padre lleva `text-blue-700` cuando algún hijo está activo.
- Un grupo puede colapsarse manualmente solo cuando **ninguna ruta hija está activa**.

### Componentes Angular Transversales

La aplicación provee un catálogo de componentes Angular standalone que toda vista nueva DEBE
usar para garantizar consistencia sin re-implementaciones ad-hoc. Su especificación completa
está en [spec 000-design-system](../../specs/000-design-system/spec.md).

**Catálogo normativo** (todos en `loopi-web/src/app/shared/`):

| Componente / Servicio | Selector | Responsabilidad |
|----------------------|----------|-----------------|
| `ListCardComponent` | `app-list-card` | Card blanca para listados; capa 2 de la jerarquía visual |
| `FilterBarComponent` | `app-filter-bar` | Barra de filtros con chips; default Estado=Activo |
| `StatusBadgeComponent` | `app-status-badge` | Badge verde/gris para el campo `activo` |
| `DataTableComponent` | `app-data-table` | Tabla con filas clickeables; `opacity-60` en filas inactivas |
| `EmptyStateComponent` | `app-empty-state` | Estado vacío con mensaje y acción sugerida |
| `PaginationComponent` | `app-pagination` | Paginación server-side |
| `PageHeaderComponent` | `app-page-header` | H1 + breadcrumb + slot de acción primaria |
| `FormCardComponent` | `app-form-card` | Card blanca para formularios; variantes sm/md/lg |
| `ReadonlyFieldComponent` | `app-readonly-field` | Label + valor no editable con ícono de candado |
| `DangerZoneComponent` | `app-danger-zone` | Sección de acciones destructivas (borde rojo) |
| `FilterStateService` | `@Injectable({providedIn:'root'})` | Estado de filtros por ruta; persiste durante la sesión |
| `FormModeService` | `@Injectable()` (provisto en el feature) | Contexto create/edit; `DangerZoneComponent` se auto-oculta en create sin `@if` en el template |

**Prohibición**: Está prohibido re-implementar la funcionalidad de cualquier componente de
este catálogo en una vista de feature. Si un componente no cubre el caso, extenderlo con
un `@Input()` nuevo y actualizar la spec 000-design-system.

---

## Convenciones de API REST

Todos los endpoints del backend siguen estas reglas sin excepción.

**Estructura de URLs:**

- Prefijo obligatorio: `/api/v1/`
- Recursos en snake_case, plural: `/api/v1/pedidos`, `/api/v1/lineas_pedido`
- Identificadores de recurso en la URL: `/api/v1/pedidos/{id}`
- Acciones no-CRUD como sub-recursos: `/api/v1/pedidos/{id}/confirmar`

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

## Convenciones de Datos

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

---

## Jobs Programados

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

## Ambientes: Dev, Stage y Producción

El proyecto opera con tres ambientes completamente separados. Cada uno tiene su propia base de datos,
variables de entorno y credenciales. Compartir recursos entre ambientes está PROHIBIDO.

| Ambiente | Propósito | Infraestructura | Despliegue |
|----------|-----------|-----------------|------------|
| **Dev** | Desarrollo activo del equipo | GCP Cloud SQL `db-f1-micro` (compartido) + Go local + Firebase Emulators | Manual (`go run .` + `ng serve`) |
| **Stage** | Validación funcional y de integración | GCP (espejo de prod, menor capacidad) | Automático al mergear a `develop` |
| **Prod** | Operación real de los negocios | GCP (Cloud SQL MySQL + Cloud Run/GKE + Firebase Hosting) | Automático al mergear a `master` |

**Detalle del ambiente Dev:**

- **Base de datos**: instancia `db-f1-micro` en GCP Cloud SQL, compartida por el equipo.
  Cada desarrollador trabaja contra su propio schema (ej. `loopi_dev_<nombre>`).
- **Backend**: `go run .` en local, con variable de entorno `DB_DSN` apuntando a Cloud SQL dev.
  El binario Go en desarrollo ocupa < 50 MB de RAM.
- **Frontend**: `ng serve` en local con `firebase emulators` para Auth y Hosting.
- **Docker Compose descartado**: la máquina de desarrollo (4.5 GB RAM, sin swap) no soporta
  MySQL + Docker runtime de forma estable. GCP dev elimina ese cuello de botella.

**Reglas comunes a todos los ambientes:**

- Las variables de entorno (DB credentials, JWT secret, API keys) NUNCA se hardcodean en código.
  Se gestionan mediante **GCP Secret Manager** en stage/prod y archivos `.env` locales (no commiteados)
  en dev.
- Los archivos `.env`, `*.local`, `*-secrets.*` DEBEN estar en `.gitignore`. Un secret en el repo
  es un incidente de seguridad.
- Las migraciones de base de datos se ejecutan automáticamente al desplegar en stage y prod,
  antes de que el servicio reciba tráfico. En dev se aplican manualmente con el CLI de migración.
- Stage DEBE reflejar la configuración de prod (mismas variables de entorno en estructura, diferente
  valor). Es el único ambiente donde se valida la paridad de mocks vs. servicios reales.
- El rollback en prod DEBE ser posible sin pérdida de datos. Toda migración irreversible
  DEBE ser aprobada explícitamente por el equipo antes de aplicarse en prod.
- Los logs van a **GCP Cloud Logging** en stage y prod. En dev se usa stdout.

---

## Flujo de Trabajo de Desarrollo

Este proyecto sigue **Gitflow** estricto. Las ramas `master` y `develop` son protegidas;
todo cambio requiere PR aprobado con CI verde.

| Rama | Origen | Destino | Cuándo |
|------|--------|---------|--------|
| `feature/*` | `develop` | `develop` | Feature nueva o mejora |
| `bugfix/*` | `develop` | `develop` | Bug no urgente |
| `chore/*` | `develop` | `develop` | Infraestructura, config, docs |
| `hotfix/*` | `master` | `master` + `develop` | Bug crítico en producción |
| `release/*` | `develop` | `master` + `develop` | Estabilización de versión |

**Gates obligatorios antes de commit, push o apertura de PR:**

`loopi-api` (en orden):

1. `go build ./...` — compila sin errores.
2. `golangci-lint run` — pasa con los 5 linters configurados (govet, errcheck, staticcheck, unused, gosec).
3. `govulncheck ./...` — cero CVEs conocidas en dependencias Go que el código realmente invoca.
4. `gitleaks detect --no-git` — cero secrets detectados en los archivos del commit.
5. `go test ./...` — todos los tests unitarios pasan.

`loopi-web` (en orden):

1. `ng build` — compila sin errores (incluye chequeo TypeScript estricto).
2. `npm audit --audit-level=high` — cero vulnerabilidades de severidad alta o crítica en dependencias de producción.
3. `gitleaks detect --no-git` — cero secrets detectados en los archivos del commit.
4. `ng test --watch=false` — todos los tests unitarios pasan.

`loopi-specs-v2`:

1. `gitleaks detect --no-git` — cero secrets detectados (DSNs, API keys, tokens en ejemplos).
2. `markdownlint-cli2` — todos los archivos `.md` pasan el linter.

Ningún commit, push ni PR puede abrirse si alguno de estos gates falla.

**Gate adicional en GitHub Actions CI** (corre automáticamente en cada PR y push a `develop`/`master`):

- **Trivy** (`trivy fs`, severidad `HIGH,CRITICAL`, `ignore-unfixed: true`) en `loopi-api` y `loopi-web`.
  Resultados publicados en el Security tab de GitHub vía SARIF. El PR no puede mergearse si Trivy
  reporta vulnerabilidades de severidad alta o crítica con fix disponible.
- La implementación (workflow YAML) vive en `.github/workflows/security.yml` de cada repo.
  La constitución define la política; cada repo define la ejecución.

**Configuración de golangci-lint** (archivo `.golangci.yml` en la raíz de `loopi-api`):

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

Las reglas gosec activas relevantes para este stack: G101 (credenciales hardcodeadas),
G201/G202 (SQL injection), G402 (TLS inseguro), G404 (random débil), G501-G505 (crypto débil).
G104 se excluye porque errcheck lo cubre con mayor precisión.

**Resolución de conflictos entre ramas protegidas:** Los PRs de resolución DEBEN mergearse como
"Create a merge commit" (no squash), para preservar historia compartida y evitar conflictos
persistentes en GitHub al intentar PR inversos.

---

## Estructura de Repositorios

Loopi v2 vive en tres repositorios independientes bajo la misma organización GitHub:

| Repo | Tecnología | Propósito |
|------|------------|-----------|
| `loopi-specs-v2` | Markdown | Specs, planes, tareas — fuente de verdad del producto |
| `loopi-api` | Go | Backend: API REST, jobs programados, lógica de negocio |
| `loopi-web` | Angular | Frontend: SPA, componentes, flujos de usuario |

**Reglas de alcance por tipo de tarea** — seguirlas reduce el contexto cargado innecesariamente:

- **Spec / plan / análisis funcional**: solo `loopi-specs-v2`. Nunca se lee código de `loopi-api`
  o `loopi-web` para generar una spec o un plan de implementación.
- **Tarea backend-only** (endpoint, job, migración, lógica de negocio): solo `loopi-api`.
- **Tarea frontend-only** (componente, vista, flujo UI, servicio Angular): solo `loopi-web`.
- **Tarea full-stack** (feature que requiere endpoint + UI): el plan DEBE declarar explícitamente
  qué partes van a `loopi-api` y cuáles a `loopi-web`. Se implementan de forma secuencial:
  primero el contrato de API (request/response), luego backend, luego frontend.
- Dentro de cada repo, cargar únicamente los archivos relevantes al módulo en cuestión,
  no el árbol completo.

---

## Governance

La constitución es la fuente de verdad de cómo se desarrolla Loopi v2. Todos los PRs DEBEN verificar
cumplimiento con los 6 principios antes del merge.

**Procedimiento de enmienda:**

1. Abrir un PR con el cambio propuesto a esta constitución y la justificación.
2. Requiere aprobación del equipo de producto (mínimo 1 revisión).
3. Actualizar `LAST_AMENDED_DATE` e incrementar `CONSTITUTION_VERSION` según semver:
   - MAJOR: eliminación o redefinición de un principio existente.
   - MINOR: adición de nuevo principio o sección con guía material.
   - PATCH: aclaraciones, redacción, correcciones tipográficas.
4. Propagar cambios a templates afectados (ver checklist en el Sync Impact Report al inicio del archivo).

**Revisión de cumplimiento:** En cada sprint review se verifica que la implementación no haya
introducido violaciones. Las violaciones DEBEN documentarse con justificación en el Registro
de Complejidad del plan correspondiente.

**Version**: 1.11.0 | **Ratified**: 2026-05-18 | **Last Amended**: 2026-06-22
