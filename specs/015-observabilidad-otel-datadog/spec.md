# Feature Specification: Fundación de Observabilidad — OTel + Datadog APM

**Feature Branch**: `015-observabilidad-otel-datadog`

**Creado**: 2026-05-26

**Estado**: Draft

**Tipo**: Infraestructura transversal — base para todos los demás use cases

**Input**: Establecer las bases de observabilidad (trazas y métricas) compartidas por
todos los use cases de Loopi v2, usando OpenTelemetry como SDK y Datadog exclusivamente
para APM y métricas. Los logs permanecen en GCP Cloud Logging. Incluye la convención
que cada feature spec debe seguir para definir su propia instrumentación.

---

## Contexto y Alcance

Esta feature es **infraestructura transversal**, no un caso de uso de negocio. Su propósito
es doble:

1. **Implementar la fundación técnica**: el paquete compartido de observabilidad que todo
   use case importa para obtener trazas y métricas en Datadog APM sin configurar nada
   adicional.

2. **Establecer la convención**: la plantilla estándar que cada spec de feature DEBE
   incluir para declarar sus propias métricas y spans, garantizando consistencia a lo
   largo de todo el sistema.

**Lo que NO cubre esta spec:**

- Logs: permanecen en GCP Cloud Logging. No se configura ningún reenvío de logs a Datadog.
- Métricas específicas de negocio de cada feature: cada spec define las suyas.
- Datadog DBM (Database Monitoring full): diferido. Esta spec incluye instrumentación
  de queries vía OTel, que da visibilidad suficiente sin infra adicional.
- Dashboards y alertas específicos de features: responsabilidad de cada feature.

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia 1 — Nuevo use case obtiene trazas sin configuración adicional (Prioridad: P1)

Un desarrollador implementa el feature "Gestión de Tiendas". Al importar el paquete de
observabilidad compartido e iniciar los spans en su handler, las trazas del nuevo feature
aparecen automáticamente en Datadog APM bajo el servicio `loopi-api`, sin que tenga que
configurar ningún exporter, provider ni credencial. La fundación ya lo resuelve.

**Por qué esta prioridad**: Si cada feature tuviera que configurar su propio pipeline de
observabilidad, habría inconsistencias, errores de configuración y duplicación. La fundación
elimina esa fricción para todos los use cases futuros.

**Prueba independiente**: Implementar un handler mínimo de prueba que use el paquete
`observability`, desplegarlo en stage y verificar que el span aparece en Datadog APM.
Entrega valor completo de la fundación de forma aislada.

**Escenarios de Aceptación**:

1. **Dado** que el backend está desplegado en App Engine con `OTEL_EXPORTER_OTLP_ENDPOINT`
   configurado, **Cuando** cualquier handler inicia un span usando el paquete compartido,
   **Entonces** el span aparece en Datadog APM dentro de los 30 segundos con los atributos
   de recurso: `service.name=loopi-api`, `deployment.environment` y `service.version`.

2. **Dado** que el entorno es local (dev) y `OTEL_EXPORTER_OTLP_ENDPOINT` no está
   configurado, **Cuando** el backend arranca, **Entonces** no hay errores relacionados
   con OTel y la aplicación funciona con normalidad (modo no-op silencioso).

3. **Dado** que el Datadog Agent en Cloud Run no está disponible temporalmente,
   **Cuando** el backend intenta exportar trazas, **Entonces** el backend no falla ni
   degrada su rendimiento: el exporter descarta silenciosamente los datos no enviados.

---

### Historia 2 — Queries de BD visibles como spans hijo (Prioridad: P2)

Un desarrollador observa que un endpoint está tardando más de lo esperado. Abre el trace
en Datadog APM y puede ver, dentro del span del handler HTTP, los spans hijos de cada
consulta a Cloud SQL: cuál tabla se consultó, qué operación (SELECT/INSERT/DELETE) y
cuánto tardó exactamente. Puede identificar qué query específico es el cuello de botella
sin necesidad de logs adicionales ni acceso directo a la BD.

**Por qué esta prioridad**: Las queries de BD son la fuente más común de degradación
en un API Go + Cloud SQL. La instrumentación automática del driver de BD da visibilidad
al costo real de cada request sin instrumentación manual en cada repositorio.

**Prueba independiente**: Ejecutar cualquier request que consulte la BD y verificar en
Datadog APM que el trace muestra spans hijos con el nombre de la operación SQL y la tabla.

**Escenarios de Aceptación**:

1. **Dado** que la instrumentación de BD está activa, **Cuando** el repositorio ejecuta
   cualquier consulta (`SELECT`, `INSERT`, `UPDATE`, `DELETE`), **Entonces** aparece un
   span hijo en el trace con los atributos `db.system=mysql`, `db.operation` y
   `db.sql.table`.

2. **Dado** que una query tarda más de 200 ms, **Cuando** el desarrollador abre el trace
   en Datadog APM, **Entonces** puede identificar el span exacto de la query lenta y su
   duración, sin necesidad de instrumentación adicional en el repositorio.

3. **Dado** que el repositorio ejecuta múltiples queries en un solo request,
   **Cuando** el trace se visualiza en Datadog APM, **Entonces** cada query aparece como
   un span hijo separado, con su duración individual, bajo el span padre del handler HTTP.

---

### Historia 3 — Feature define sus métricas y aparecen en Datadog (Prioridad: P2)

Un desarrollador implementa el feature "Conteo de Inventario". Siguiendo la convención
de la Constitución §VI y la plantilla de spec, declara en su propia spec las métricas
`inventario.conteo.duration` e `inventario.conteo.total`. Al implementarlas usando el
paquete compartido de observabilidad,
esas métricas aparecen en Datadog Metrics Explorer correctamente etiquetadas con
`service:loopi-api` y `env:staging`, listas para configurar alertas y dashboards.

**Por qué esta prioridad**: Sin una convención clara, cada desarrollador nombra métricas
de forma distinta, los dashboards son inconsistentes y las alertas no cubren todos los
casos. La convención asegura uniformidad desde el primer feature hasta el último.

**Prueba independiente**: Implementar las métricas del feature de autenticación (ya
existentes en código) usando la fundación y verificar que aparecen en Datadog Metrics
Explorer con las etiquetas correctas.

**Escenarios de Aceptación**:

1. **Dado** que un feature registra una métrica siguiendo la convención de nomenclatura,
   **Cuando** el evento ocurre en el sistema, **Entonces** la métrica aparece en Datadog
   Metrics Explorer con las etiquetas estándar: `service`, `env` y `version`.

2. **Dado** que un feature registra un histograma de duración, **Cuando** el desarrollador
   busca la métrica en Datadog, **Entonces** puede visualizar los percentiles p50, p90 y
   p99, y la unidad aparece correctamente como milisegundos.

3. **Dado** que un feature registra un contador de resultados con etiquetas por resultado,
   **Cuando** el desarrollador construye un monitor en Datadog, **Entonces** puede filtrar
   por cualquier valor de la etiqueta sin configuración adicional.

---

### Historia 4 — Acceso seguro al agente desde App Engine (Prioridad: P3)

El equipo de seguridad revisa la configuración del agente Datadog en Cloud Run y confirma
que el servicio no es accesible públicamente: solo el service account de App Engine tiene
permiso para invocarlo. La API Key de Datadog no está en ningún archivo de configuración
del repositorio.

**Por qué esta prioridad**: Una API Key de Datadog expuesta permite a terceros enviar
datos arbitrarios a la cuenta y agotar la cuota. Un agente expuesto públicamente amplía
la superficie de ataque.

**Prueba independiente**: Intentar llamar al endpoint del agente en Cloud Run sin
autenticación IAM debe retornar 403. Verificar en GCP IAM que solo el service account
de App Engine tiene `roles/run.invoker`.

**Escenarios de Aceptación**:

1. **Dado** que el agente está desplegado en Cloud Run sin acceso público,
   **Cuando** cualquier origen externo intenta llamar al endpoint OTLP del agente,
   **Entonces** recibe una respuesta de acceso denegado (HTTP 403).

2. **Dado** que `DD_API_KEY` está almacenada en GCP Secret Manager,
   **Cuando** un desarrollador revisa el repositorio (incluyendo `app.yaml` y
   `app.prod.yaml`), **Entonces** no encuentra la clave de API en texto plano en ningún
   archivo.

---

### Casos Límite

- Si el agente Datadog en Cloud Run tiene un cold start en el primer request del día,
  las primeras trazas del período se pierden. Mitigación: configurar `--min-instances=1`
  en Cloud Run para eliminar cold starts.
- Si se rota la `DD_API_KEY` en Secret Manager sin actualizar la variable de entorno del
  agente en Cloud Run, el agente rechaza el envío hasta que se redespliega. Los logs en
  GCP no se ven afectados.
- En entorno local, si un desarrollador configura `OTEL_EXPORTER_OTLP_ENDPOINT` apuntando
  a un agente inexistente, los errores de conexión deben ser silenciosos (no crashear el
  proceso ni llenar los logs de errores).
- Si dos features definen métricas con el mismo nombre pero unidades distintas, el segundo
  registro sobreescribe la definición del primero en el MeterProvider global. La convención
  de nomenclatura previene esto.

---

## Requisitos *(obligatorio)*

### Requisitos Funcionales

**RF-OBS-01 — Paquete de observabilidad compartido**

El sistema DEBE proveer un paquete reutilizable (`internal/observability`) que inicialice
el `TracerProvider` y el `MeterProvider` globales de OTel, configurados para exportar
a Datadog via OTLP/HTTP. Este paquete DEBE ser el único lugar donde se configuran los
providers; ningún feature lo hace por su cuenta.

**RF-OBS-02 — Modo no-op en entornos sin configuración**

Cuando `OTEL_EXPORTER_OTLP_ENDPOINT` no está definida en el entorno, el paquete DEBE
operar en modo no-op: los instrumentos retornan implementaciones vacías, no hay errores
ni goroutines extra, y el arranque del servidor no se ve afectado.

**RF-OBS-03 — Atributos de recurso estándar**

Cada traza y métrica exportada DEBE incluir los atributos de recurso:
`service.name` (valor: `loopi-api`), `deployment.environment` (dev/staging/production)
y `service.version` (valor: variable de entorno `APP_VERSION`).

**RF-OBS-04 — Instrumentación automática de queries de BD**

El driver de base de datos DEBE estar envuelto para generar spans automáticos por cada
operación: `SELECT`, `INSERT`, `UPDATE`, `DELETE`. Cada span DEBE incluir los atributos
`db.system`, `db.operation` y `db.sql.table`. Esta instrumentación NO requiere cambios
en los repositorios existentes ni en los futuros.

**RF-OBS-05 — Agente Datadog como receptor OTLP**

DEBE existir un servicio Datadog Agent desplegado en Cloud Run con el receptor OTLP
habilitado en el protocolo HTTP (puerto 4318). Este agente DEBE recibir trazas y métricas
de todos los features de Loopi v2 y reenviarlos a Datadog SaaS.

**RF-OBS-06 — Acceso interno al agente (sin acceso público)**

El agente en Cloud Run DEBE estar configurado sin acceso público. El único principal
autorizado para invocarlo DEBE ser el service account de App Engine mediante IAM.
El backend DEBE autenticarse con el agente usando credenciales de la cuenta de servicio
de GCP (no credenciales embebidas).

**RF-OBS-07 — Credenciales en Secret Manager**

La `DD_API_KEY` DEBE almacenarse en GCP Secret Manager. No debe aparecer en texto plano
en ningún archivo del repositorio, incluyendo `app.yaml`, `app.prod.yaml` y archivos
de CI/CD. El agente en Cloud Run la lee desde Secret Manager al arrancar.

**RF-OBS-08 — Logs en GCP Cloud Logging exclusivamente**

Los logs del backend DEBEN emitirse a stdout en formato JSON estructurado. GCP Cloud
Logging los captura automáticamente. No se configura ningún reenvío de logs a Datadog:
Datadog se usa exclusivamente para APM (trazas) y métricas.

**RF-OBS-09 — Overhead máximo tolerable**

El overhead introducido por la instrumentación OTel (spans + métricas) NO DEBE superar
5 ms adicionales por request en el percentil 99, medido en stage bajo carga representativa.

> **Convención de métricas y spans para features**: las reglas de nomenclatura, cardinalidad
> de etiquetas y la plantilla de la sección `## Observabilidad` que cada feature debe incluir
> en su `spec.md` están definidas en la **Constitución §VI** y en
> `.specify/templates/spec-template.md`. Esta spec no las replica.

### Entidades Clave

- **Paquete `internal/observability`**: Módulo Go compartido que inicializa y gestiona
  el ciclo de vida de los providers OTel globales. Es el único componente que conoce
  el endpoint del agente y las credenciales de configuración.

- **Datadog Agent (Cloud Run)**: Servicio intermediario que recibe datos OTLP del backend
  y los reenvía a Datadog SaaS. Actúa como receptor OTLP, enriquecedor de metadata y
  buffer ante inestabilidad de red.

- **Driver BD instrumentado**: Reemplazo transparente del driver MySQL estándar que
  genera spans OTel automáticos por cada operación de base de datos.

- **Secret `DD_API_KEY`**: Credencial en GCP Secret Manager. Accesible solo por el
  service account del agente en Cloud Run y el service account de App Engine.

---

## Criterios de Éxito *(obligatorio)*

### Resultados Medibles

- **SC-OBS-01**: Un desarrollador puede implementar un nuevo feature y obtener sus
  trazas en Datadog APM **sin escribir ningún código de configuración de observabilidad**:
  solo importa el paquete compartido y usa `otel.Tracer()` o `otel.Meter()`.

- **SC-OBS-02**: Las trazas de cualquier request al backend aparecen en Datadog APM
  en **menos de 30 segundos** desde que ocurre el evento.

- **SC-OBS-03**: Los spans de queries de BD aparecen como hijos del span HTTP correspondiente,
  con **latencia por query visible** sin instrumentación adicional en los repositorios.

- **SC-OBS-04**: El overhead de la instrumentación OTel **no supera 5 ms** adicionales
  por request en el percentil 99, medido bajo carga representativa en stage.

- **SC-OBS-05**: El backend arranca y opera **sin errores** en entorno local sin
  `OTEL_EXPORTER_OTLP_ENDPOINT` configurado.

- **SC-OBS-06**: **Ninguna credencial de Datadog** aparece en texto plano en el
  repositorio: ni en `app.yaml`, ni en `app.prod.yaml`, ni en archivos de CI/CD.

- **SC-OBS-07**: El agente Datadog en Cloud Run devuelve **HTTP 403** ante cualquier
  llamada desde un origen no autorizado (sin el service account de App Engine).

- **SC-OBS-08**: Los features futuros pueden declarar sus métricas en su `spec.md`
  siguiendo la convención definida en esta spec y **sin necesidad de aprobar una nueva
  RFC de observabilidad**.

---

## Supuestos

- El proyecto despliega en **GCP App Engine Standard** (sin soporte de sidecars); el
  agente Datadog corre como servicio independiente en Cloud Run en la misma región.
- El Datadog site es `datadoghq.com` (US); si se cambia al site EU, los endpoints del
  agente cambian y debe actualizarse la configuración del agente.
- Cloud Run está habilitado en los proyectos GCP de stage y producción.
- El equipo tiene permisos de Owner o Editor en GCP para crear service accounts y
  configurar IAM.
- La instrumentación de autenticación parcialmente implementada en `internal/auth/`
  (métricas y tracer) se migra para usar el paquete `internal/observability` como
  provider: los instrumentos existentes no se reescriben, solo se conectan al provider
  global que esta feature provee.
- Datadog Database Monitoring (DBM) — que requiere acceso de red directo del agente
  a MySQL — queda diferido. La instrumentación de BD vía OTel (spans automáticos por
  query) cubre el 90% de los casos de diagnóstico sin infra adicional.
- Los dashboards de Datadog se crean manualmente en la interfaz web en la primera
  iteración; la gestión como código (Terraform + Datadog provider) es diferida.
- La tasa de muestreo de trazas (sampling) se configura en `AlwaysSample` en stage;
  en producción puede ajustarse si el volumen genera costos excesivos — esa decisión
  se evalúa post-lanzamiento.
