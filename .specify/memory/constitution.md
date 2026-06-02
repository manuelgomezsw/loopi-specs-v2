<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0 → 1.1.1 → 1.2.0 → 1.3.0 → 1.3.4 → 1.4.0 → 1.5.0 → 1.6.0
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
        1.5.0 — nueva subsección "Arquitectura del backend Go — separación de capas":
                tabla Handler/Service/Repository con responsabilidades exclusivas,
                reglas de cruce, test corolario. Previene SQL en la capa service (MINOR).
        1.6.0 — estrategia de testing backend Go: técnica por capa (httptest/mock/sqlmock/t.Setenv),
                thresholds (≥ 95% lógica, ≥ 90% infraestructura, ≥ 70% OTel), gate CI,
                qué cubrir obligatoriamente en service y middleware (MINOR).
        1.7.0 — §VI Monitoreo Preventivo ampliado: logs exclusivamente en GCP Cloud Logging
                (Datadog no recibe logs), reglas de cardinalidad de métricas (tienda_id ✅ / user_id ❌),
                convención de nomenclatura de métricas y referencia a spec 015 (MINOR).

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
- Caché: Se usa **Ristretto** (librería Go, caché en proceso por instancia). Solo para datos de
  catálogo de lectura intensiva y baja volatilidad: items, unidades de medida, parámetros globales
  del algoritmo. Los datos operacionales (stock, pedidos, inventarios) NUNCA se cachean; siempre
  se leen desde la base de datos para garantizar consistencia entre instancias de App Engine.
  Sin caché implícito; toda entrada de caché DEBE tener TTL explícito definido en el plan.
- Pruebas frontend: unitarias por componente + funcionales automatizadas para flujos críticos (P1).
- Pruebas backend: las integraciones con base de datos y servicios externos (POS, GCP services) DEBEN
  testearse mediante **mocks**. Prohibida la integración directa en tests — los entornos de CI no
  tienen acceso a infraestructura real y la paridad mock/real se valida en stage (ver sección Ambientes).

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

**Version**: 1.7.0 | **Ratified**: 2026-05-18 | **Last Amended**: 2026-05-26
