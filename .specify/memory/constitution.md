<!--
SYNC IMPACT REPORT
==================
Version change: 1.12.0 → 2.0.0 (MAJOR)
Reason: Reestructuración de gobernanza. La constitución mezclaba dos tipos de contenido con
        volatilidad muy distinta: (a) principios de producto/arquitectura (rara vez cambian) y
        (b) estándares de implementación muy detallados (TTL de caché, clases Tailwind exactas,
        tabla HTTP, nomenclatura de métricas, thresholds de cobertura — cambiaron en 8 de las
        últimas 12 versiones MINOR). Esta mezcla causó violaciones constitucionales reales en
        specs generadas por IA (ver commit 77fad40, feature 005-categorias-catalogo): el "gate"
        de verificación en plan-template.md era un placeholder de texto libre que dependía de
        que el modelo recordara ~1000 líneas de prosa, y las reglas más recientes (caché
        decorador, `?estado`, sección Observabilidad) se perdieron.

        Esto es un cambio MAYOR de gobernanza (no de principios en sí): redefine qué vive en
        este archivo, introduce documentos normativos hermanos con su propio versionado, y
        cambia el procedimiento de enmienda (toda enmienda ahora debe decidir a qué documento
        pertenece y propagar a los `CLAUDE.md` de los tres repos). Los 6 Principios Centrales
        NO cambian de contenido normativo — solo se les asignan IDs estables (P-I a P-VI) y se
        extraen de aquí los detalles de implementación que no son principios.

Contenido extraído a documentos hermanos (mismo nivel normativo, versionado propio):
  - .specify/memory/standards/backend.md (v1.0.0) — arquitectura de capas, caché Ristretto,
    testing por capa, convenciones API REST, convenciones de datos, jobs programados,
    implementación de observabilidad, gates de CI backend.
  - .specify/memory/standards/frontend.md (v1.0.0) — stack UI, responsive, accesibilidad,
    estados, formularios, patrón lista-formulario, componentes transversales, gates de CI frontend.
  - .specify/memory/standards/environments-ci.md (v1.0.0) — ambientes dev/stage/prod, Gitflow,
    gate Trivy.

Qué permanece en este archivo:
  - Principios Centrales I-VI (contenido sin cambios de fondo, con IDs P-I..P-VI añadidos).
  - Stack Técnico de alto nivel (qué tecnología, no cómo se usa — el "cómo" está en standards/).
  - Estructura de Repositorios y reglas de alcance por tipo de tarea.
  - Governance, con procedimiento de enmienda actualizado para cubrir standards/ y CLAUDE.md
    de los tres repos.

Corrección adicional: se eliminó una viñeta de markdownlint mal ubicada dentro de "Qué cubrir
obligatoriamente en cada middleware" (constitution.md v1.12.0, líneas 405-406) — era contenido
de otra sección pegado por error de edición. La regla de markdownlint sigue vigente sin cambios
en el gate de `loopi-specs-v2` (ver environments-ci.md).

Templates actualizados en este mismo cambio:
  - .specify/templates/plan-template.md ✅ — "Constitution Check" ahora es una checklist de IDs
    de regla (P-*, BE-*, FE-*) condicionada al tipo de tarea, en vez de un placeholder de texto libre.
  - .specify/templates/tasks-template.md ✅ — nueva fase final "Cumplimiento Constitucional" que
    exige citar los IDs de regla cubiertos.
  - .claude/skills/speckit-constitution/SKILL.md ✅ — el paso de propagación ahora incluye
    explícitamente standards/*.md y los CLAUDE.md de loopi-api-v2 / loopi-web-v2.
  - .specify/templates/spec-template.md — sin cambios (la sección Observabilidad ya estaba
    correctamente parametrizada desde el fix de 005).

Historial de versiones 1.x: ver git history de este archivo (git log -p -- .specify/memory/constitution.md)
para el detalle completo de 1.0.0 → 1.12.0.
-->

# Loopi v2 — Constitución del Proyecto

Este archivo contiene **principios**: por qué el producto y la arquitectura son como son.
Rara vez cambia. El **cómo** se implementa (patrones de código, convenciones exactas,
clases CSS, thresholds de testing) vive en documentos normativos hermanos, con el mismo
nivel de obligatoriedad pero versionado independiente porque cambian con cada feature:

- [`standards/backend.md`](standards/backend.md) — normativo para `loopi-api-v2`.
- [`standards/frontend.md`](standards/frontend.md) — normativo para `loopi-web-v2`.
- [`standards/environments-ci.md`](standards/environments-ci.md) — normativo para los tres repos.

**Toda spec, plan o tarea DEBE verificar cumplimiento contra este archivo Y contra los
documentos de `standards/` que apliquen al tipo de tarea.** El mecanismo de verificación es
la sección `Constitution Check` de `.specify/templates/plan-template.md`, que enumera IDs de
regla explícitos en vez de depender de la memoria del modelo sobre un documento largo.

## Principios Centrales

### P-I. Especificación Funcional Primero (Spec-First)

Toda funcionalidad nueva o cambio a una funcionalidad existente DEBE comenzar con una especificación
aprobada antes de cualquier línea de código. La especificación funcional en
`specs/` es la fuente de verdad del producto.

- DEBE existir una spec aprobada (PR mergeado a `develop`) antes de comenzar el plan de implementación.
- El plan de implementación DEBE referenciar la sección de spec correspondiente.
- Cambios al comportamiento del sistema que no estén en la spec son regresiones, no mejoras.
- Decisiones pendientes (DP-01, DP-02, DP-03) NO pueden implementarse hasta que el equipo las valide.

### P-II. Arquitectura Multi-Tienda

Loopi v2 opera bajo el modelo: **catálogo compartido por marca, datos operacionales aislados por tienda**.

- Todo dato operacional (inventario, mermas, pedidos, compras, ventas) DEBE llevar `tienda_id` explícito.
- Un empleado (`lider_tienda`, `barista`) JAMÁS puede acceder a datos de una tienda que no sea la suya.
- El catálogo (items, recetas, menú, categorías, proveedores) es compartido: modificarlo en una tienda
  lo modifica para todas.
- El `admin` puede operar en modo consolidado (todas las tiendas) o en modo por tienda (selección explícita
  en la interfaz); su token JWT no lleva `tienda_id` fijo.

### P-III. Control de Acceso por Rol (RBAC)

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

### P-IV. Trazabilidad Total de Inventario

Todo movimiento que afecte el stock DEBE quedar registrado con: quién lo hizo, cuándo, en qué tienda
y por qué motivo. No existe modificación de inventario sin rastro auditable.

- Entradas: recepción de pedidos, compras caja menor.
- Salidas: consumo por ventas POS, mermas registradas.
- Correcciones: conteo físico confirmado (ajuste automático al cierre del inventario).
- El historial de movimientos NUNCA se borra; solo se anulan con contra-registro.
- El stock se ajusta automáticamente al confirmar un inventario físico (RN-INV-05).

### P-V. Prevención de Pérdidas

El diseño funcional y técnico DEBE cerrar activamente posibilidades de hurto, maquillaje de información
y brechas operacionales. Un flujo que crea oportunidad de fraude DEBE rediseñarse antes de implementarse.

### P-VI. Monitoreo Preventivo

Cada feature DEBE ser monitoreable desde el primer deploy en producción. El sistema DEBE permitir
diagnosticar degradaciones en menos de 5 segundos. El monitoreo es responsabilidad del equipo de
desarrollo, no solo de operaciones.

- Todo endpoint crítico (autenticación, conteo de inventario, movimientos de stock, generación
  y recepción de pedidos, integración con ventas) DEBE tener trazas y métricas de latencia y
  tasa de errores.
- Las alertas DEBEN ser preventivas: detectar anomalías antes de que impacten al usuario final.
- Todo feature con endpoints críticos DEBE incluir una sección `## Observabilidad` en su `spec.md`.

**Implementación normativa** (stack, nomenclatura de métricas, qué instrumentar, formato de logs):
ver [`standards/backend.md#BE-OBS-01`](standards/backend.md). Este principio define el *qué* y
el *porqué*; ese documento define el *cómo* exacto.

---

## Stack Técnico (decisiones de arquitectura)

Estas son decisiones de plataforma, estables por diseño. Las convenciones de implementación
sobre este stack viven en `standards/backend.md` y `standards/frontend.md`.

- **Frontend**: Angular (última versión estable), Tailwind CSS v4. Despliegue en **Firebase Hosting** (GCP).
- **Backend**: **Golang**, desplegado en **GCP App Engine**.
- **Base de datos**: **MySQL** en **GCP Cloud SQL**.
- **Autenticación**: JWT con expiración configurable (default 24 h).
- **Caché**: **Ristretto** (in-process), solo para catálogo de baja volatilidad. Patrón obligatorio:
  ver [`standards/backend.md#BE-CACHE-01`](standards/backend.md).

---

## Estructura de Repositorios

Loopi v2 vive en tres repositorios independientes bajo la misma organización GitHub:

| Repo | Tecnología | Propósito |
|------|------------|-----------|
| `loopi-specs-v2` | Markdown | Specs, planes, tareas, constitución y estándares — fuente de verdad del producto |
| `loopi-api-v2` | Go | Backend: API REST, jobs programados, lógica de negocio |
| `loopi-web-v2` | Angular | Frontend: SPA, componentes, flujos de usuario |

**Reglas de alcance por tipo de tarea** — seguirlas reduce el contexto cargado innecesariamente:

- **Spec / plan / análisis funcional**: solo `loopi-specs-v2`. Nunca se lee código de `loopi-api-v2`
  o `loopi-web-v2` para generar una spec o un plan de implementación.
- **Tarea backend-only** (endpoint, job, migración, lógica de negocio): solo `loopi-api-v2`.
  Normativo: `standards/backend.md`.
- **Tarea frontend-only** (componente, vista, flujo UI, servicio Angular): solo `loopi-web-v2`.
  Normativo: `standards/frontend.md`.
- **Tarea full-stack** (feature que requiere endpoint + UI): el plan DEBE declarar explícitamente
  qué partes van a `loopi-api-v2` y cuáles a `loopi-web-v2`. Se implementan de forma secuencial:
  primero el contrato de API (request/response), luego backend, luego frontend. Normativo:
  `standards/backend.md` + `standards/frontend.md`.
- Dentro de cada repo, cargar únicamente los archivos relevantes al módulo en cuestión,
  no el árbol completo.

**Gitflow y CI**: los tres repos siguen Gitflow y gates de CI obligatorios — ver
[`standards/environments-ci.md`](standards/environments-ci.md) para la política común, y el
`Git Workflow` en el `CLAUDE.md` de cada repo para los comandos exactos.

---

## Governance

La constitución (este archivo) y los documentos de `standards/` son, en conjunto, la fuente de
verdad de cómo se desarrolla Loopi v2. Todos los PRs DEBEN verificar cumplimiento contra ambos
antes del merge, usando la checklist de IDs de regla en `Constitution Check` (plan.md).

**Qué va en constitution.md vs. en standards/:**

- Un cambio va en **constitution.md** si redefine un principio de producto/arquitectura
  (P-I a P-VI), la estructura de repos, o el procedimiento de gobernanza mismo.
- Un cambio va en **standards/backend.md** o **standards/frontend.md** si es una convención de
  implementación: nombres, formatos, TTLs, clases CSS, thresholds, patrones de código.
  Estos documentos cambian con más frecuencia y tienen su propio versionado semver — no requieren
  bump de versión de la constitución.

**Procedimiento de enmienda:**

1. Abrir un PR con el cambio propuesto (a `constitution.md` y/o a `standards/*.md`) y la justificación.
2. Requiere aprobación del equipo de producto (mínimo 1 revisión).
3. Si el cambio es a `constitution.md`: actualizar `LAST_AMENDED_DATE` e incrementar
   `CONSTITUTION_VERSION` según semver (MAJOR: eliminación o redefinición de un principio o de la
   gobernanza misma; MINOR: nuevo principio; PATCH: aclaraciones). Si el cambio es a un `standards/*.md`,
   ese documento incrementa su propia versión según la misma lógica semver, independiente de la
   constitución.
4. **Propagar el cambio** (obligatorio, no opcional) a:
   - `.specify/templates/plan-template.md` — si cambia qué debe verificar el `Constitution Check`.
   - `.specify/templates/tasks-template.md` — si cambia qué tareas de cumplimiento deben generarse.
   - **`loopi-api-v2/CLAUDE.md`** — si el cambio toca `standards/backend.md` (actualizar también su
     cabecera `<!-- synced: ... -->` a la nueva versión).
   - **`loopi-web-v2/CLAUDE.md`** — si el cambio toca `standards/frontend.md` (ídem cabecera).
   - Estos dos últimos viven en otros repos: el PR de la enmienda DEBE abrir (o dejar registrada como
     tarea de seguimiento inmediata) el PR correspondiente en `loopi-api-v2` / `loopi-web-v2`. Una
     enmienda a `standards/` no se considera completa hasta que esos `CLAUDE.md` estén sincronizados.
5. Registrar los cambios en el Sync Impact Report al inicio del archivo modificado.

**Revisión de cumplimiento:** En cada sprint review se verifica que la implementación no haya
introducido violaciones. Las violaciones DEBEN documentarse con justificación en el Registro
de Complejidad del plan correspondiente. Si una violación revela que un `CLAUDE.md` estaba
desincronizado de `standards/`, corregir la sincronización es parte de la resolución, no un
seguimiento opcional.

**Version**: 2.0.0 | **Ratified**: 2026-05-18 | **Last Amended**: 2026-07-11
