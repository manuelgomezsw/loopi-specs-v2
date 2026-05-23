<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0 → 1.1.1 → 1.2.0
Reason: 1.1.0 — nueva sección ambientes + correcciones de stack (MINOR).
        1.1.1 — dev environment redefinido: GCP en todos los ambientes (PATCH).
        1.2.0 — rol lider_compras, convenciones API, convenciones de datos y jobs programados (MINOR).

Changes in 1.2.0:
  - Principio III: agrega rol lider_compras (4º rol introducido en spec 013-pedidos-recepcion-oc)
  - Stack Técnico: nueva subsección "Convenciones de API REST"
  - Stack Técnico: nueva subsección "Convenciones de datos"
  - Stack Técnico: nueva subsección "Jobs programados"

Templates reviewed:
  - .specify/templates/plan-template.md — pendiente de revisión
  - .specify/templates/spec-template.md ✅ — estructura compatible; historias de usuario con criterios de aceptación
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

- Los ajustes post-inventario se registran como mermas (no como edición directa de stock).
- No existe flujo de "corrección silenciosa": toda desviación genera un registro visible para el `admin`.
- El `admin` SIEMPRE tiene acceso a reportes de mermas, diferencias de recepción e historial de conteos.
- Las diferencias en recepción de pedidos (> 10 % en algún ítem) generan estado `parcialmente_completado`
  y DEBEN ser visibles en el dashboard del admin.

### VI. Observabilidad Preventiva

Cada feature DEBE ser monitoreable desde el primer deploy en producción. El sistema DEBE permitir
diagnosticar degradaciones en menos de 5 segundos.

- Todo endpoint crítico (autenticación, movimientos de stock, recepción de pedidos) DEBE tener
  métricas de latencia y tasa de errores.
- Los logs DEBEN ser estructurados (JSON) e incluir: `tienda_id`, `user_id`, `rol`, timestamp, operación.
- Las alertas DEBEN ser preventivas: detectar anomalías antes de que impacten al usuario final.
- El monitoreo es responsabilidad del equipo de desarrollo, no solo de operaciones.

---

## Stack Técnico y Lineamientos de Implementación

**Frontend**: Angular (última versión estable), componentes standalone y signals, Tailwind CSS v4.
Despliegue en **Firebase Hosting** (GCP).

**Backend**: **Golang**, desplegado en **GCP** (Cloud Run o GKE, a definir en plan de implementación).

**Base de datos**: **MySQL** en **GCP Cloud SQL**. Toda migración DEBE ser versionada, reversible
y aplicada mediante herramienta de migración declarativa (ej. Flyway, golang-migrate).

**Autenticación**: JWT con expiración configurable (default 24 h).

**Lineamientos transversales:**

- Paginación: SIEMPRE del lado del servidor (base de datos). Prohibida la paginación en memoria
  para colecciones que puedan crecer ilimitadamente.
- Caché: Definir estrategia explícita por recurso. Sin caché implícito.
- Pruebas frontend: unitarias por componente + funcionales automatizadas para flujos críticos (P1).
- Pruebas backend: las integraciones con base de datos y servicios externos (POS, GCP services) DEBEN
  testearse mediante **mocks**. Prohibida la integración directa en tests — los entornos de CI no
  tienen acceso a infraestructura real y la paridad mock/real se valida en stage (ver sección Ambientes).
- Markdown: sub-listas con indentación de 2 espacios; línea en blanco antes/después de headings
  y listas; archivo termina con newline (markdownlint MD007, MD022, MD032, MD047).

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
| Error interno del servidor | 500 |

---

## Convenciones de Datos

**Identificadores:**

- Clave primaria: entero auto-incremental (`BIGINT UNSIGNED`). No se usan UUIDs.
- Las PKs se exponen como entero en la API.

**Timestamps:**

- Toda tabla DEBE tener `creado_en DATETIME NOT NULL` y `actualizado_en DATETIME NOT NULL`.
- Todos los valores se almacenan en **UTC**. La conversión a zona local es responsabilidad del cliente.
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

**CI obligatorio (markdownlint):** Todo archivo `.md` DEBE pasar el linter antes del merge.

**Resolución de conflictos entre ramas protegidas:** Los PRs de resolución DEBEN mergearse como
"Create a merge commit" (no squash), para preservar historia compartida y evitar conflictos
persistentes en GitHub al intentar PR inversos.

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

**Version**: 1.2.0 | **Ratified**: 2026-05-18 | **Last Amended**: 2026-05-23
