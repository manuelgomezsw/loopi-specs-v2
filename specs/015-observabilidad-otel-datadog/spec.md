# Feature Specification: Observabilidad — OTel + Datadog

**Feature Branch**: `015-observabilidad-otel-datadog`

**Creado**: 2026-05-26

**Estado**: Draft

**Input**: Configurar la plataforma de observabilidad de Loopi v2 con OpenTelemetry como SDK
de instrumentación y Datadog como backend, incluyendo la integración nativa GCP → Datadog
para logs y el pipeline OTel para trazas y métricas.

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia 1 — Diagnóstico de degradación en tiempo real (Prioridad: P1)

Un desarrollador de Loopi detecta que el tiempo de login está aumentando. Abre Datadog
APM, busca el servicio `loopi-api`, y en menos de 5 segundos puede ver el histograma
`auth.login.duration` desglosado por resultado (`success`, `invalid_credentials`,
`account_locked`). Identifica que las consultas a `tokens_revocados` en Cloud SQL están
tardando más de lo esperado y puede correlacionar el span de blacklist con el trace completo
del request de login.

**Por qué esta prioridad**: Sin observabilidad funcional, cualquier degradación en producción
se detecta cuando el usuario final ya fue impactado. Esta es la promesa central del principio
VI de la constitución.

**Prueba independiente**: Se puede verificar haciendo un login exitoso y uno fallido,
luego buscando en Datadog Metrics Explorer `auth.login.result` con etiqueta `result`.
Entrega valor completo de monitoreo de autenticación sin otros módulos.

**Escenarios de Aceptación**:

1. **Dado** que el backend de Loopi está desplegado en App Engine con OTel configurado,
   **Cuando** se realiza un login exitoso,
   **Entonces** aparece un trace en Datadog APM con atributo `auth.result=success` y
   `user.role` dentro de los 30 segundos.

2. **Dado** que un usuario falla el login 5 veces consecutivas,
   **Cuando** el sistema bloquea la cuenta,
   **Entonces** el contador `auth.login.result` con etiqueta `result=account_locked`
   incrementa en 1 en Datadog Metrics Explorer.

3. **Dado** que la consulta a `tokens_revocados` tarda más de 100 ms,
   **Cuando** el desarrollador abre el trace en Datadog,
   **Entonces** el histograma `auth.blacklist.check.duration` refleja la latencia real
   observada.

---

### Historia 2 — Correlación de logs con trazas (Prioridad: P2)

Un desarrollador quiere entender por qué un logout falló para un usuario específico.
Busca en Datadog Log Management por `user_id` y encuentra el log JSON estructurado del
evento. Desde ese log puede navegar directamente al trace de Datadog APM usando el
`trace_id` incluido en el log, viendo el span completo del request fallido.

**Por qué esta prioridad**: La correlación logs-trazas multiplica el valor diagnóstico.
Sin ella, los logs y trazas son silos separados.

**Prueba independiente**: Se puede verificar ejecutando un logout y buscando el log en
Datadog Log Management. El log debe contener `tienda_id`, `user_id`, `rol` y un
`trace_id` navigable.

**Escenarios de Aceptación**:

1. **Dado** que el backend emite logs JSON estructurados a stdout,
   **Cuando** Cloud Logging los recibe vía Pub/Sub,
   **Entonces** aparecen en Datadog Log Management con los campos `tienda_id`,
   `user_id`, `rol`, `timestamp` y `operacion` indexados y buscables.

2. **Dado** que un log de error incluye un `trace_id`,
   **Cuando** el desarrollador hace clic en el `trace_id` en Datadog Logs,
   **Entonces** navega directamente al trace correspondiente en Datadog APM.

---

### Historia 3 — Alerta preventiva ante anomalías (Prioridad: P3)

El equipo recibe una alerta de Datadog antes de que los usuarios reporten problemas.
La alerta se dispara cuando la tasa de `auth.login.result{result:invalid_credentials}`
supera 3 desviaciones estándar respecto al baseline de la última hora, indicando un
posible ataque de fuerza bruta.

**Por qué esta prioridad**: Las alertas reactivas (cuando el usuario ya fue impactado)
no cumplen el principio de monitoreo preventivo de la constitución.

**Prueba independiente**: Se puede simular disparando 20 logins fallidos seguidos y
verificando que la alerta se activa en Datadog Monitors antes de que pasen 5 minutos.

**Escenarios de Aceptación**:

1. **Dado** que existe un Monitor de Datadog configurado sobre `auth.login.result`,
   **Cuando** la tasa de `invalid_credentials` supera el umbral configurado,
   **Entonces** el equipo recibe una notificación (email / canal configurado) en
   menos de 5 minutos.

2. **Dado** que la latencia media de `auth.login.duration` supera 2 500 ms,
   **Cuando** el monitor de SLO detecta la violación,
   **Entonces** se genera una alerta de severidad `warning` en Datadog.

---

### Casos Límite

- ¿Qué ocurre si el receptor OTLP (Datadog Agent en Cloud Run) no está disponible?
  Las trazas y métricas del período se pierden; los logs siguen llegando por la
  integración nativa GCP → Datadog de forma independiente.
- ¿Qué ocurre si Pub/Sub tiene un backlog de logs? Los logs llegan con retraso a Datadog
  pero no se pierden (retención configurable en Pub/Sub).
- ¿Qué ocurre en entorno local (dev)? Sin `OTEL_EXPORTER_OTLP_ENDPOINT` configurado,
  el SDK opera en modo no-op; no hay errores ni trazas exportadas.
- ¿Qué ocurre si la API Key de Datadog caduca o es inválida? El agente rechaza el envío
  y lo reporta en sus propios logs; Cloud Logging sigue funcionando independientemente.

---

## Requisitos *(obligatorio)*

### Requisitos Funcionales

**Canal de Logs (GCP → Datadog nativo)**

- **RF-OBS-01**: El sistema DEBE emitir todos los logs a stdout en formato JSON estructurado,
  incluyendo los campos obligatorios: `tienda_id`, `user_id`, `rol`, `timestamp`,
  `operacion` y `nivel` (info/warn/error).
- **RF-OBS-02**: GCP Cloud Logging DEBE capturar automáticamente los logs de App Engine
  desde stdout sin configuración adicional en el código.
- **RF-OBS-03**: Un sink de Cloud Logging DEBE exportar los logs del recurso `gae_app`
  a un topic de Pub/Sub dedicado (`datadog-logs`).
- **RF-OBS-04**: La integración nativa de Datadog con GCP DEBE consumir el topic Pub/Sub
  y hacer los logs disponibles en Datadog Log Management en menos de 60 segundos.
- **RF-OBS-05**: Los logs DEBEN ser buscables en Datadog por `tienda_id`, `user_id`,
  `operacion` y `nivel`.

**Canal de Trazas y Métricas (OTel → Datadog Agent)**

- **RF-OBS-06**: El backend Go DEBE inicializar un `TracerProvider` y un `MeterProvider`
  globales al arrancar, configurados para exportar vía OTLP/HTTP al agente Datadog.
- **RF-OBS-07**: En ausencia de `OTEL_EXPORTER_OTLP_ENDPOINT`, el sistema DEBE operar
  en modo no-op sin errores (soporte para entorno local/dev).
- **RF-OBS-08**: El Datadog Agent DEBE desplegarse como servicio independiente (no sidecar)
  con el receptor OTLP habilitado en puerto HTTP 4318.
- **RF-OBS-09**: El agente DEBE enriquecer las trazas con los atributos de recurso:
  `service.name=loopi-api`, `deployment.environment` (staging/production) y
  `service.version`.
- **RF-OBS-10**: La clave de API de Datadog (`DD_API_KEY`) DEBE almacenarse en
  GCP Secret Manager; nunca en texto plano en repositorios ni en `app.yaml`.

**Instrumentación de Autenticación (RF-AUTH-06 de la feature 001)**

- **RF-OBS-11**: Cada request a `POST /api/v1/auth/login` DEBE generar un span OTel con
  los atributos `auth.result`, `user.role` (solo en éxito) y `http.route`.
- **RF-OBS-12**: El sistema DEBE registrar el histograma `auth.login.duration` (ms)
  por cada intento de login, etiquetado por resultado.
- **RF-OBS-13**: El sistema DEBE incrementar el contador `auth.login.result` (etiqueta
  `result`) por cada intento de login.
- **RF-OBS-14**: El sistema DEBE registrar el histograma `auth.blacklist.check.duration`
  (ms) por cada consulta a `tokens_revocados`.

**Alertas y Dashboards**

- **RF-OBS-15**: DEBE existir al menos un Monitor de Datadog sobre `auth.login.result`
  que alerte cuando la tasa de `invalid_credentials` supere el umbral configurado.
- **RF-OBS-16**: DEBE existir al menos un Monitor sobre `auth.login.duration` que alerte
  cuando la latencia media supere 2 500 ms en una ventana de 5 minutos.

**Seguridad y Control de Acceso**

- **RF-OBS-17**: El service account de GCP para la integración Datadog DEBE tener
  únicamente los roles mínimos necesarios: `roles/logging.viewer`,
  `roles/monitoring.viewer`, `roles/cloudasset.viewer`, `roles/browser` y
  `roles/pubsub.subscriber`.
- **RF-OBS-18**: El servicio del agente Datadog en Cloud Run DEBE estar configurado
  sin acceso público (`--no-allow-unauthenticated`); solo el service account de
  App Engine tendrá el rol `roles/run.invoker`.

### Entidades Clave

- **Datadog Agent**: Servicio intermediario desplegado en Cloud Run que recibe datos OTLP
  del backend Go y los reenvía a la plataforma Datadog. Actúa como receptor OTLP y
  enriquecedor de metadata.
- **Sink de Cloud Logging**: Regla de exportación en GCP que filtra logs del recurso
  `gae_app` y los publica en Pub/Sub.
- **Topic Pub/Sub `datadog-logs`**: Canal de transporte de logs entre Cloud Logging
  y la integración Datadog. Actúa como buffer con retención configurable.
- **Service Account Datadog**: Identidad GCP con permisos mínimos para que Datadog SaaS
  lea métricas de Cloud Monitoring y consuma logs de Pub/Sub.
- **Secret `DD_API_KEY`**: Credencial almacenada en GCP Secret Manager, accesible
  únicamente por el service account de App Engine y el agente en Cloud Run.

---

## Criterios de Éxito *(obligatorio)*

### Resultados Medibles

- **SC-OBS-01**: Un desarrollador puede identificar la causa raíz de una degradación de
  autenticación en **menos de 5 minutos** desde que detecta el síntoma, usando solo
  Datadog (trazas + métricas + logs).
- **SC-OBS-02**: Los logs de App Engine aparecen en Datadog Log Management en **menos de
  60 segundos** desde que se emiten.
- **SC-OBS-03**: Las trazas OTel de autenticación aparecen en Datadog APM en **menos de
  30 segundos** desde que ocurre el evento.
- **SC-OBS-04**: Las alertas de anomalía se disparan en **menos de 5 minutos** desde que
  se supera el umbral definido.
- **SC-OBS-05**: El sistema opera **sin degradación de rendimiento** atribuible a la
  instrumentación: el overhead de OTel no supera 5 ms adicionales por request de login.
- **SC-OBS-06**: En entorno local (sin configuración de observabilidad), el backend arranca
  y opera **sin errores** relacionados con OTel o Datadog.
- **SC-OBS-07**: **100 % de los eventos críticos** de autenticación (login exitoso, login
  fallido, logout, bloqueo de cuenta) son visibles en Datadog dentro de la ventana de
  retención configurada.

---

## Supuestos

- El proyecto despliega en **GCP App Engine Standard**, que no soporta sidecars; el
  agente Datadog corre como servicio independiente en Cloud Run.
- Los logs ya se emiten como JSON estructurado a stdout desde el backend Go; este feature
  no requiere cambiar el formato de logging existente, sino garantizar el pipeline completo.
- El Datadog site es `datadoghq.com` (US); si se usara el site EU, los endpoints
  cambian y debe actualizarse la configuración.
- Cloud Run está habilitado en el proyecto GCP de stage y producción.
- El equipo tiene permisos de Owner o Editor en GCP para crear service accounts y sinks.
- La instrumentación específica de autenticación (RF-OBS-11 a RF-OBS-14) ya tiene
  implementación parcial en `internal/auth/metrics.go` y `internal/auth/otel.go`;
  este feature completa el bootstrap del provider global y el pipeline de transporte.
- Los dashboards de Datadog se crean manualmente en la interfaz web en una primera
  iteración; la gestión como código (Terraform / Datadog provider) es diferida.
- La retención de logs en Pub/Sub se configura en 7 días como mínimo para garantizar
  que no haya pérdida ante backlog temporal.
