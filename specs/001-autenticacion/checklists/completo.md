# Lista de Verificación Completa: Autenticación y Gestión de Sesión

**Propósito**: Revisión integral de calidad de requisitos — cubre seguridad, contratos de API,
modelo de datos y spec general. Válida para auto-revisión del autor y para gate de PR.
**Creado**: 2026-05-23
**Feature**: [spec.md](../spec.md) · [plan.md](../plan.md)

> 🔒 **CRÍTICO** — Ítem de seguridad; debe resolverse antes de pasar a `/speckit-tasks`.
> Los demás ítems son revisión integral sin bloqueo obligatorio.

---

## Seguridad — Calidad de Requisitos

- [x] CHK001 — 🔒 **CRÍTICO** ¿El algoritmo de firma JWT (HS256) está especificado en la spec
  o solo en `research.md`? Sin este dato en la spec, un implementador podría elegir un
  algoritmo diferente. [Completitud, Gap, Spec §RF-AUTH-01.2]

- [x] CHK002 — 🔒 **CRÍTICO** ¿El requisito de mitigación de timing attack (aplicar bcrypt
  con un hash dummy cuando el usuario no existe, para normalizar el tiempo de respuesta)
  está en la spec? Actualmente solo aparece en `contracts/POST_api_v1_auth_login.md`.
  [Cobertura, Gap, Spec §RF-AUTH-02]

- [x] CHK003 — 🔒 **CRÍTICO** ¿La spec distingue explícitamente entre la cookie `jwt`
  (httpOnly, inaccesible por JS) y la cookie `XSRF-TOKEN` (legible por JS para el
  double-submit pattern)? Actualmente RF-AUTH-01.5 menciona el CSRF token pero no define
  las dos cookies como artefactos separados. [Completitud, Gap, Spec §RF-AUTH-01.5]

- [x] CHK004 — 🔒 **CRÍTICO** ¿Hay un requisito sobre la rotación del `JWT_SECRET` y el
  impacto en tokens activos al cambiar el secret? Si el secret rota, todos los JWT activos
  quedan invalidados — esto puede ser intencional, pero debe estar documentado.
  [Cobertura, Gap, Spec §Suposiciones]

- [x] CHK005 — 🔒 **CRÍTICO** ¿Los requisitos de CORS para los endpoints de autenticación
  están documentados? Frontend (`app.loopi.com`) y backend (`api.loopi.com`) son
  subdominios distintos; las peticiones cross-origin requieren headers CORS explícitos
  aunque sean same-site. [Completitud, Gap]

- [x] CHK006 — ¿El requisito de CSRF diferencia explícitamente entre solicitudes GET
  (excluidas del token) y mutaciones POST/PUT/DELETE (requieren `X-XSRF-TOKEN`)?
  RF-AUTH-01.5 lo menciona pero sin separar los dos casos. [Claridad, Spec §RF-AUTH-01.5]
  → Aceptado: RF-AUTH-01.5 especifica "(POST/PUT/DELETE)" explícitamente; GET excluido por omisión.

- [x] CHK007 — ¿Los requisitos cubren el escenario de dispositivo robado con cookie activa
  (no solo logout explícito)? La limitación del blacklist ante reset de contraseña está
  documentada; ¿está también el caso de robo de dispositivo y sus implicaciones?
  [Cobertura, Spec §Suposiciones]
  → Documentado como limitación conocida en Suposiciones; mitigación = TTL mínimo operativo.

---

## Contratos de API — Completitud

- [x] CHK008 — ¿El endpoint `GET /api/v1/auth/me` tiene un requisito funcional en la spec
  (RF-AUTH-XX)? Actualmente solo existe en `research.md` y en `contracts/GET_api_v1_auth_me.md`
  — no hay RF que lo respalde en la spec. [Completitud, Gap]
  → Agregado RF-AUTH-07 en spec.

- [x] CHK009 — ¿El uso del código HTTP 423 (Locked) para bloqueo de cuenta está justificado
  en la spec o solo en el contrato? La spec define el comportamiento (RF-AUTH-01.4) pero no
  especifica el código de respuesta. [Claridad, Gap, Spec §RF-AUTH-01.4]
  → HTTP 423 agregado explícitamente en RF-AUTH-01.4.

- [x] CHK010 — ¿Los contratos definen el comportamiento cuando los campos `usuario` o
  `contrasena` llegan como cadena vacía (`""`) versus ausentes (`null`)? Son dos casos
  distintos con posible diferencia de respuesta. [Cobertura, Edge Case, Gap]
  → Aceptado: detalle de validación pertenece al contrato, no a la spec funcional.

- [x] CHK011 — ¿Están documentados los requisitos de timeout para la consulta a
  `tokens_revocados` en el middleware de validación? Un timeout de Cloud SQL en el
  happy-path no tiene comportamiento definido en la spec. [Completitud, Gap]
  → Política fail-closed documentada en Suposiciones: Cloud SQL no disponible → 503.

- [x] CHK012 — ¿El formato exacto del campo `bloqueado_hasta` (zona horaria Colombia,
  ISO 8601) está especificado en la spec y es consistente con las convenciones de datos
  de la constitución? [Claridad, Spec §RF-AUTH-01.4 / Constitución §Datos]
  → Aceptado: cubierto por las convenciones de datos de la constitución (América/Bogotá, sufijo _en).

---

## Modelo de Datos — Consistencia

- [x] CHK013 — ¿La eliminación física de registros en `tokens_revocados` (job de limpieza)
  está justificada explícitamente frente a la regla de la constitución "nunca DELETE físico
  sobre datos operacionales"? El `data-model.md` lo menciona pero la spec no lo justifica.
  [Consistencia, Spec §Suposiciones / Constitución §Datos]
  → Excepción justificada en Suposiciones: tabla técnica, sin valor histórico; auditoría en RF-AUTH-06.

- [x] CHK014 — ¿El campo `actualizado_en` en `tokens_revocados` tiene semántica definida,
  dado que los registros de esta tabla nunca se actualizan después de la inserción?
  Actualmente `data-model.md` indica que es igual a `creado_en` pero no explica por qué
  existe si no cumple su función habitual. [Claridad, Spec §data-model.md]
  → Aceptado: data-model.md ya lo explica; convención de constitución exige el campo aunque sea redundante.

- [x] CHK015 — ¿La migración documenta que debe ejecutarse antes del primer request de
  autenticación en producción? Sin este prerequisito explícito, un deploy sin migración
  causa errores en el middleware de validación (la tabla `tokens_revocados` no existe).
  [Completitud, Gap, Spec §data-model.md]
  → Aceptado: cubierto por constitución (auto-migración en stage/prod antes del tráfico) y quickstart.md (dev).

- [x] CHK016 — ¿Está documentada la propiedad cruzada de las columnas `intentos_fallidos`
  y `bloqueado_hasta` — que pertenecen a `001-autenticacion` pero residen en la tabla
  `usuarios` de `004-empleados` — en la spec de `004-empleados` también? [Consistencia,
  Spec §Dependencias]
  → Nota de dependencia cruzada añadida en §Dependencias; pendiente replicar en spec de 004-empleados.

- [x] CHK017 — ¿El comportamiento del contador `intentos_fallidos` ante un desbordamiento
  de INT (límite: 2,147,483,647) está definido? Aunque improbable, un valor inesperado
  podría desencadenar bloqueos permanentes no intencionados. [Edge Case, Gap]
  → Aceptado: el contador se resetea a 0 en cada login exitoso; overflow es físicamente imposible en condiciones normales.

---

## Spec — Completitud y Consistencia

- [x] CHK018 — ¿El rol `lider_compras` (uno de los 4 roles definidos en la constitución)
  está cubierto en los escenarios de aceptación de la spec? HU1 cubre admin, lider_tienda
  y barista, pero no `lider_compras`. ¿Es una omisión intencional o un gap?
  [Cobertura, Gap, Spec §HU1]
  → Escenario 4 agregado en HU1; RF-AUTH-01.2 actualizado: lider_compras sin tienda_id fija.

- [x] CHK019 — ¿El mecanismo por el cual el administrador configura el tiempo de expiración
  de sesión tiene requisitos de interfaz (pantalla, campo, validación)? RF-AUTH-01.3 dice
  "configurable por el administrador" pero no define cómo ni dónde. [Completitud, Gap,
  Spec §RF-AUTH-01.3]
  → RF-AUTH-01.3 actualizado: variable de entorno JWT_EXPIRY_HOURS vía GCP Secret Manager; administrador técnico, no rol admin.

- [x] CHK020 — ¿Los identificadores RF-AUTH-01.1, 01.2, 01.5, 01.3, 01.4 están en orden
  secuencial correcto en la spec? Actualmente 01.5 precede a 01.3 y 01.4, lo que puede
  confundir la trazabilidad en implementación. [Consistencia, Spec §RF-AUTH-01]
  → RF-AUTH-01 reordenado: 01.1 → 01.2 → 01.3 → 01.4 → 01.5 → 01.6; RF-AUTH-01.7 (CORS) fusionado en 01.5.

- [x] CHK021 — ¿RF-AUTH-06 (Auditoría) aparece antes de RF-AUTH-05 (Control de acceso)
  en la spec, y este orden de numeración refleja la intención? Si 06 es posterior a 05,
  el orden sugiere que fue añadido después — ¿debería renumerarse? [Consistencia,
  Spec §RF-AUTH]
  → Bloques reordenados: RF-AUTH-05 (Control de acceso) ahora precede a RF-AUTH-06 (Auditoría). Sin renumeración.

- [x] CHK022 — ¿El mecanismo de generación y validación del CSRF token (double-submit
  cookie) está especificado en la spec, o solo en `research.md` y `contracts/`?
  RF-AUTH-01.5 menciona "CSRF token válido" sin definir qué lo hace válido.
  [Completitud, Gap, Spec §RF-AUTH-01.5]
  → RF-AUTH-01.6 ya define el mecanismo completo: cookie XSRF-TOKEN con valor aleatorio,
  frontend envía X-XSRF-TOKEN en header, backend valida coincidencia en POST/PUT/DELETE.

- [x] CHK023 — ¿Los criterios de éxito son medibles para todos los casos, incluyendo
  "Seguridad de acceso: 100% de rutas inaccesibles sin sesión válida"? ¿Cómo se verifica
  ese 100% de forma objetiva? [Medibilidad, Spec §Criterios de Éxito]
  → Criterio actualizado: verificado mediante escenarios HU2, HU3 y tests de integración
  del middleware que cubren todas las rutas registradas del sistema.

---

## Cobertura de Escenarios y Flujos

- [x] CHK024 — ¿Existe un escenario de aceptación que cubra la restauración de sesión
  en Angular al recargar la página (el frontend llama a `/me` para recuperar rol y
  tienda_id desde el JWT en cookie)? [Cobertura, Gap]
  → Agregada HU4 con dos escenarios: reload con sesión activa (→ pantalla correcta sin
  pedir credenciales) y reload con sesión expirada/revocada (→ redirect al login).

- [x] CHK025 — ¿El flujo de expiración automática de sesión durante una operación activa
  (ej. el usuario guarda un conteo de inventario y el JWT expira en ese instante) tiene
  un escenario de aceptación definido? [Cobertura, Edge Case, Gap, Spec §HU4]
  → Escenario 3 agregado en HU5 (ex HU4): backend responde 401, frontend interrumpe
  operación, descarta cambios no guardados y redirige al login con mensaje de sesión expirada.

- [x] CHK026 — ¿El escenario de sesiones concurrentes (mismo usuario en dos dispositivos
  simultáneos) tiene casos de aceptación? La suposición está documentada pero no hay
  historia de usuario que la valide. [Cobertura, Spec §Suposiciones]
  → Aceptado: el comportamiento (múltiples JWTs activos independientes) está documentado
  en Suposiciones. No hay lógica especial; no requiere escenario adicional.

- [x] CHK027 — ¿Están definidos los requisitos para el estado de carga del formulario de
  login en el frontend (ej. botón deshabilitado durante el request, indicador visual)?
  [Completitud, Gap, Spec §HU1]
  → Agregado en RF-AUTH-01.1: botón deshabilitado e indicador visual durante el request
  de autenticación para evitar envíos duplicados.

---

## Requisitos No Funcionales

- [x] CHK028 — ¿Los requisitos de observabilidad de la constitución (logs estructurados
  JSON con campos `tienda_id`, `user_id`, `rol`, timestamp) están referenciados en
  RF-AUTH-06, o RF-AUTH-06 define un formato diferente? [Consistencia, Spec §RF-AUTH-06 /
  Constitución §VI]
  → RF-AUTH-06.1 actualizado: log estructurado JSON (OTel + Datadog, constitución §VI)
  con campos user_id, usuario, rol, tienda_id, timestamp, ip, evento, motivo.

- [x] CHK029 — ¿Hay un requisito explícito sobre el comportamiento del sistema cuando
  Cloud SQL está temporalmente no disponible durante la verificación del blacklist? Un
  fallo de BD en el middleware de autenticación bloquea el acceso a todo el sistema.
  [Resiliencia, Gap]
  → Ya resuelto en CHK011: política fail-closed documentada en Suposiciones (503 si Cloud SQL
  no disponible); no requiere cambio adicional.

- [x] CHK030 — ¿Los requisitos de rendimiento para el endpoint `/me` y el middleware de
  blacklist están especificados, más allá del target de "< 3 s para login"? [Completitud,
  Gap, Spec §Criterios de Éxito]
  → Agregado en Criterios de Éxito: /me < 200 ms (p99); middleware blacklist < 5 ms por
  request (índice PK sobre jti).

- [x] CHK031 — ¿La spec define el comportamiento esperado cuando el job
  `/internal/jobs/limpiar_tokens_revocados` falla repetidamente? La tabla crecería
  indefinidamente; ¿hay un requisito de alerta o umbral? [Resiliencia, Gap]
  → Agregado en Suposiciones: sistema continúa operando con tabla más grande (índice sobre
  expira_en); monitoreo vía métricas Cloud Scheduler en Datadog; no se define umbral de alerta
  en esta spec (responsabilidad de operaciones).

- [x] CHK032 — ¿La spec o el plan documentan los requisitos de configuración de Cloud
  Scheduler (frecuencia, timezone, política de reintentos) para el job de limpieza?
  [Completitud, Gap, Spec §Suposiciones]
  → Agregado en Suposiciones: diaria 2:00 AM América/Bogotá, POST con X-CloudScheduler:true,
  3 reintentos con backoff por defecto de Cloud Scheduler. Detalle en contrato
  POST_internal_jobs_limpiar_tokens_revocados.md.

---

## Notas

- Items CHK001–CHK007 marcados como 🔒 CRÍTICO deben resolverse antes de generar tasks.
- CHK018 (rol `lider_compras`) puede ser una omisión intencional — confirmar con el equipo.
- CHK020 y CHK021 son inconsistencias de numeración de bajo riesgo pero alta confusión;
  corregirlos antes de implementación evita errores de trazabilidad.
- CHK013 (DELETE físico en `tokens_revocados`) requiere una línea de justificación en la spec
  para que el equipo no lo señale como violación de la constitución en code review.
