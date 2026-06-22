# Especificación de Feature: Autenticación y Gestión de Sesión

**Branch de Feature**: `001-autenticacion`
**Creado**: 2026-05-18
**Estado**: Cerrada
**Referencia funcional**: [§2.2 Autenticación](../loopi-v2-funcional/spec.md)

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Inicio de sesión exitoso (Prioridad: P1)

Un empleado ingresa su usuario y contraseña en la pantalla de login. Si las credenciales son
correctas y el empleado está activo, el sistema le da acceso y lo lleva a su pantalla principal
según su rol.

**Por qué esta prioridad**: Es la puerta de entrada al sistema. Sin sesión activa no existe
ninguna otra operación.

**Prueba Independiente**: Puede verificarse con un usuario activo de cada rol y validando que
el acceso redirige a la pantalla correcta con los permisos esperados.

**Escenarios de Aceptación**:

1. **Dado** que un administrador tiene usuario y contraseña válidos,
   **Cuando** ingresa sus credenciales correctas,
   **Entonces** el sistema le abre sesión y lo dirige al dashboard con acceso a todas las tiendas.

2. **Dado** que un líder de tienda tiene usuario y contraseña válidos,
   **Cuando** ingresa sus credenciales correctas,
   **Entonces** el sistema le abre sesión y lo dirige al dashboard de su tienda asignada.

3. **Dado** que un barista tiene usuario y contraseña válidos,
   **Cuando** ingresa sus credenciales correctas,
   **Entonces** el sistema le abre sesión y lo dirige a la vista de inventario de su tienda.

4. **Dado** que un lider_compras tiene usuario y contraseña válidos,
   **Cuando** ingresa sus credenciales correctas,
   **Entonces** el sistema le abre sesión y lo dirige al dashboard de pedidos y planeación
   sin tienda asignada fija.

---

### Historia de Usuario 2 — Rechazo de credenciales inválidas o usuario inactivo (Prioridad: P1)

Un empleado intenta ingresar con credenciales incorrectas o con una cuenta que el administrador
ha desactivado. El sistema rechaza el acceso y muestra un mensaje claro sin revelar si el problema
es la contraseña o el estado de la cuenta.

**Por qué esta prioridad**: La seguridad del acceso es fundamental; un rechazo incorrecto o
un mensaje que revele información sensible es un riesgo crítico.

**Prueba Independiente**: Puede verificarse intentando login con contraseña incorrecta y con
usuario inactivo, validando que ambos casos son rechazados con mensaje genérico.

**Escenarios de Aceptación**:

1. **Dado** que un usuario ingresa una contraseña incorrecta,
   **Cuando** envía el formulario de login,
   **Entonces** el sistema muestra un mensaje de error genérico y no abre sesión.

2. **Dado** que el administrador inactivó una cuenta de empleado,
   **Cuando** ese empleado intenta iniciar sesión con credenciales correctas,
   **Entonces** el sistema rechaza el acceso con el mismo mensaje genérico sin indicar el motivo.

3. **Dado** que un usuario envía el formulario de login cinco veces seguidas con error,
   **Cuando** intenta el sexto intento,
   **Entonces** el sistema bloquea temporalmente el intento por 5 minutos.

---

### Historia de Usuario 3 — Cierre de sesión (Prioridad: P2)

El empleado cierra su sesión desde el menú de usuario. Su acceso queda revocado de inmediato
y cualquier acción posterior requiere autenticarse de nuevo.

**Por qué esta prioridad**: El cierre explícito de sesión protege al sistema en dispositivos
compartidos (tablets en el punto de venta).

**Prueba Independiente**: Puede verificarse cerrando sesión y comprobando que las rutas
protegidas ya no son accesibles sin volver a autenticarse.

**Escenarios de Aceptación**:

1. **Dado** que un usuario tiene sesión activa,
   **Cuando** hace clic en "Cerrar sesión",
   **Entonces** el sistema invalida la sesión y redirige a la pantalla de login.

2. **Dado** que un usuario cerró sesión,
   **Cuando** intenta acceder directamente a una ruta protegida (ej. inventario),
   **Entonces** el sistema lo redirige al login sin mostrar el contenido protegido.

---

### Historia de Usuario 4 — Restauración de sesión al recargar la página (Prioridad: P2)

Al recargar la aplicación Angular, el frontend llama al endpoint `/me` para recuperar el rol
y `tienda_id` del usuario a partir de la cookie `jwt` activa, dado que el JWT es inaccesible
desde JavaScript.

**Por qué esta prioridad**: Sin esta restauración, el estado de sesión en memoria se pierde
al recargar y el usuario es redirigido al login aunque tenga sesión válida.

**Prueba Independiente**: Puede verificarse recargando la página con sesión activa y validando
que el frontend recupera el rol y muestra la pantalla correcta sin pedir credenciales.

**Escenarios de Aceptación**:

1. **Dado** que un usuario tiene sesión activa y recarga la página,
   **Cuando** Angular inicializa la aplicación,
   **Entonces** el frontend llama a `/me`, recupera el rol y `tienda_id` desde la cookie
   activa, y muestra la pantalla correspondiente al rol sin solicitar credenciales.

2. **Dado** que un usuario recarga la página con la sesión expirada o revocada,
   **Cuando** Angular llama a `/me` y recibe 401,
   **Entonces** el frontend redirige al login sin mostrar el contenido protegido.

---

### Historia de Usuario 5 — Expiración automática de sesión (Prioridad: P2)

Si el empleado no cierra sesión manualmente, la sesión expira automáticamente tras el tiempo
configurado (por defecto 24 horas). Al intentar cualquier acción tras la expiración, el sistema
lo devuelve al login.

**Por qué esta prioridad**: Protege el sistema cuando el empleado olvida cerrar sesión en
un dispositivo compartido.

**Prueba Independiente**: Puede verificarse configurando un tiempo de expiración corto y
verificando que las operaciones fallan tras ese tiempo.

**Escenarios de Aceptación**:

1. **Dado** que la sesión de un usuario expiró,
   **Cuando** intenta realizar cualquier operación,
   **Entonces** el sistema rechaza la solicitud y lo redirige al login.

2. **Dado** que el administrador configuró la expiración en 8 horas,
   **Cuando** un usuario lleva más de 8 horas con sesión abierta,
   **Entonces** la próxima operación que intente requiere autenticarse nuevamente.

3. **Dado** que el JWT de un usuario expira mientras éste está realizando una operación activa,
   **Cuando** el frontend envía la solicitud con el token ya expirado,
   **Entonces** el backend responde 401 y el frontend interrumpe la operación, descarta
   cualquier cambio no guardado y redirige al login con un mensaje de sesión expirada.

---

## Requisitos Funcionales

### RF-AUTH-01: Autenticación con credenciales

- RF-AUTH-01.1: El sistema permite iniciar sesión con usuario (texto) y contraseña. Durante el
  proceso de autenticación (mientras el request está en curso), el botón de envío del formulario
  de login queda deshabilitado y se muestra un indicador visual de carga para evitar envíos
  duplicados.
- RF-AUTH-01.2: Tras una autenticación exitosa, el sistema emite un JWT firmado con algoritmo
  HS256 que contiene como claims: `jti` (identificador único del token), el rol del empleado
  y, para lider_tienda y barista, el identificador de su tienda asignada. El administrador y
  el lider_compras no tienen tienda asignada fija en su token. La validez se determina por:
  firma válida, claim `exp` no vencido y ausencia del `jti` en la tabla `tokens_revocados`
  de Cloud SQL.
- RF-AUTH-01.3: El tiempo de expiración de sesión es configurable mediante la variable de
  entorno `JWT_EXPIRY_HOURS` (gestionada vía GCP Secret Manager en stage/prod). El valor
  por defecto es 24 horas. Este parámetro lo gestiona el administrador técnico del sistema,
  no el rol `admin` de la aplicación.
- RF-AUTH-01.4: Tras cinco intentos fallidos consecutivos desde el mismo usuario, el sistema
  bloquea nuevos intentos durante 5 minutos y responde con HTTP 423 (cuenta bloqueada) a
  cualquier intento posterior durante ese período.
- RF-AUTH-01.5: El JWT se entrega al cliente mediante una `httpOnly cookie` con atributos
  `Secure` y `SameSite=Strict`. El JavaScript del frontend no tiene acceso al valor del token.
  El atributo `Secure` se aplica en todos los ambientes; en `localhost` los navegadores modernos
  lo aceptan sobre HTTP sin certificado. En stage y prod, frontend y backend DEBEN estar bajo
  el mismo dominio raíz (ej. `app.loopi.com` y `api.loopi.com`) para que `SameSite=Strict`
  permita el envío de la cookie en las llamadas API cross-subdomain. El backend configura CORS
  para permitir solicitudes exclusivamente desde el origen del frontend por ambiente
  (`localhost:4200` en dev, `app.stage.loopi.com` en stage, `app.loopi.com` en prod),
  incluyendo `Access-Control-Allow-Credentials: true`. El origen CORS nunca es wildcard (`*`)
  cuando se usan cookies con credenciales.
- RF-AUTH-01.6: El login emite dos cookies con propósitos distintos. La cookie `jwt`
  (`httpOnly; Secure; SameSite=Strict`) transporta el token de autenticación y es
  inaccesible desde JavaScript. La cookie `XSRF-TOKEN` (`Secure; SameSite=Strict`,
  sin `httpOnly`) contiene un valor aleatorio legible por el frontend para implementar
  el patrón doble-submit CSRF. El backend valida que el header `X-XSRF-TOKEN` enviado
  por el cliente coincida con el valor de la cookie `XSRF-TOKEN` en todas las mutaciones
  (POST/PUT/DELETE).

### RF-AUTH-02: Rechazo de acceso

- RF-AUTH-02.1: El sistema rechaza el login de cualquier usuario con credenciales incorrectas.
- RF-AUTH-02.2: El sistema rechaza el login de cualquier usuario marcado como inactivo,
  aunque sus credenciales sean correctas.
- RF-AUTH-02.3: El mensaje de error no distingue si el fallo es por contraseña incorrecta
  o cuenta inactiva, para evitar revelar información sobre las cuentas existentes.
- RF-AUTH-02.4: El tiempo de respuesta del login no debe revelar si el usuario existe.
  El sistema aplica la operación de verificación de hash en todos los intentos de
  autenticación, independientemente de si el usuario existe en la base de datos.

### RF-AUTH-03: Cierre de sesión

- RF-AUTH-03.1: El usuario puede cerrar su sesión explícitamente desde cualquier pantalla
  del sistema.
- RF-AUTH-03.2: Al cerrar sesión, el backend inserta el `jti` del token en la tabla
  `tokens_revocados` con su `expira_en` original, y expira la `httpOnly cookie` (Max-Age=0).
  Cualquier solicitud posterior con ese `jti` es rechazada por el backend, incluso si el JWT
  aún tiene firma válida y `exp` no vencido. Cualquier intento de acceder a rutas protegidas
  redirige al login.

### RF-AUTH-04: Expiración automática

- RF-AUTH-04.1: Las sesiones expiran automáticamente según el claim `exp` del JWT;
  el backend rechaza cualquier token con `exp` vencido independientemente de su firma.
  Este comportamiento se implementa como el paso (2) del middleware RF-AUTH-05.1.
- RF-AUTH-04.2: Una sesión expirada es rechazada igual que una sesión inexistente: el sistema
  redirige al login sin mostrar el contenido protegido.

### RF-AUTH-05: Control de acceso por sesión

- RF-AUTH-05.1: Toda ruta y acción del sistema verifica, en este orden, que: (1) la cookie
  contiene un JWT con firma válida, (2) el claim `exp` no está vencido, y (3) el `jti` no
  aparece en la tabla `tokens_revocados`. Si cualquier verificación falla, el sistema responde
  401 y redirige al login.
- RF-AUTH-05.2: El rol contenido en la sesión es la única fuente de verdad para determinar
  qué acciones puede realizar el usuario en el resto del sistema.

### RF-AUTH-06: Auditoría de eventos de autenticación

- RF-AUTH-06.1: El sistema registra en log estructurado JSON (formato OTel + Datadog, conforme
  a la constitución §VI) los siguientes eventos: login exitoso, login fallido y bloqueo de
  cuenta. Cada entrada incluye los campos: `user_id`, `usuario`, `rol`, `tienda_id` (cuando
  aplica), `timestamp` (UTC ISO 8601), `ip`, `evento` y, en login fallido, un `motivo`
  genérico que no revela si la cuenta existe.
- RF-AUTH-06.2: Los logs de auditoría no incluyen contraseñas ni el valor del JWT.

### RF-AUTH-07: Consulta de sesión activa

- RF-AUTH-07.1: El sistema expone un endpoint que permite al frontend recuperar el rol y el
  identificador de tienda del usuario autenticado a partir de la cookie `jwt` activa. Este
  endpoint es necesario para que el frontend restaure el estado de sesión en memoria al
  recargar la página, dado que el JWT viaja en una `httpOnly cookie` inaccesible desde
  JavaScript.

---

## Criterios de Éxito

- **Acceso sin fricción**: Un empleado con credenciales válidas completa el inicio de sesión
  y llega a su pantalla principal en menos de 3 segundos.
- **Seguridad de acceso**: El 100% de las rutas protegidas son inaccesibles sin sesión válida
  (verificado mediante los escenarios de HU2, HU3 y los tests de integración del middleware
  de autenticación que cubren todas las rutas registradas del sistema);
  ninguna respuesta del sistema revela si una cuenta existe o está inactiva.
- **Protección por inactividad**: Las sesiones sin actividad son invalidadas automáticamente
  al cumplirse el tiempo configurado, sin excepción.
- **Bloqueo por intentos fallidos**: Tras cinco intentos fallidos, el acceso queda bloqueado
  5 minutos antes de permitir nuevos intentos.
- **Trazabilidad de accesos**: Todo login exitoso, login fallido y bloqueo de cuenta queda
  registrado en log estructurado con usuario, timestamp e IP; sin exponer credenciales ni tokens.
- **Cierre inmediato y real**: Al cerrar sesión, el token queda revocado en el servidor
  en menos de 1 segundo; cualquier solicitud posterior con ese JWT es rechazada por el backend
  aunque la firma sea válida.
- **Rendimiento de sesión activa**: El endpoint `/me` responde en menos de 200 ms (p99) bajo
  carga normal. La verificación de blacklist en el middleware de autenticación añade menos de
  5 ms al tiempo de respuesta de cualquier endpoint protegido (índice PK sobre `jti`).

---

## Entidades Clave

| Entidad | Atributos relevantes |
|---------|----------------------|
| `Usuario` | usuario, contraseña (hasheada), rol, tienda_asignada, activo |
| `JWT (payload)` | jti, sub (usuario_id), rol, tienda_id, iat, exp — no se persiste en BD |
| `tokens_revocados` | jti (PK), expira_en — registro en Cloud SQL; limpieza automática por job |

---

## Dependencias y Suposiciones

### Dependencias

- Los usuarios (empleados) deben existir en el sistema previamente creados por el administrador.
  La creación y gestión de empleados corresponde a la feature `004-empleados`.
- El campo `tienda_id` en la sesión de lider_tienda y barista proviene del atributo
  `tienda_asignada` del empleado al momento del login.
- La migración de `001-autenticacion` agrega las columnas `intentos_fallidos` y
  `bloqueado_hasta` a la tabla `usuarios`, cuya propiedad estructural pertenece a
  `004-empleados`. La spec de `004-empleados` debe documentar estas columnas como
  pertenecientes a `001-autenticacion` para evitar que sean eliminadas o modificadas
  al implementar esa feature.
- **Configuración de dominio (bloqueante para stage y prod)**: el frontend y el backend deben
  estar configurados bajo el mismo dominio raíz antes del primer deploy. Sin esta configuración,
  `SameSite=Strict` impide el envío de la cookie en llamadas API y el sistema no funciona.
  Dominios requeridos por ambiente:

  | Ambiente | Frontend | Backend |
  |----------|----------|---------|
  | Dev | `localhost:4200` | `localhost:8080` |
  | Stage | `app.stage.loopi.com` (o equivalente) | `api.stage.loopi.com` |
  | Prod | `app.loopi.com` | `api.loopi.com` |

### Suposiciones

- Las contraseñas se almacenan con hash seguro; nunca en texto plano.
- No existe recuperación de contraseña por correo en esta versión; el administrador la resetea
  manualmente (alcance de `004-empleados`).
- El tiempo de expiración de sesión es configurable a nivel de sistema, no por usuario.
- El bloqueo por intentos fallidos es por usuario (no por IP), ya que los usuarios operan
  desde dispositivos fijos en el punto de venta.
- Un mismo usuario puede tener múltiples JWTs válidos activos en paralelo (múltiples dispositivos).
  El sistema no limita ni rastrea la cantidad de sesiones concurrentes por usuario.
- El JWT viaja exclusivamente en una `httpOnly cookie` con `Secure` y `SameSite=Strict`;
  nunca en localStorage ni en cabeceras Authorization del frontend.
- En stage y prod, el frontend (Firebase Hosting) y el backend (App Engine) DEBEN estar
  configurados bajo el mismo dominio raíz. Los certificados TLS son gestionados automáticamente
  por GCP (Google-managed certificates); no se requiere gestión manual de certificados.
  Los hostnames por defecto de GCP no se usan en stage ni en prod para endpoints públicos.
- Desactivar una cuenta de empleado (feature `004-empleados`) impide nuevos logins pero no
  revoca los JWT activos ya emitidos. Un dispositivo robado con cookie activa mantiene acceso
  hasta la expiración del token. La mitigación es mantener el TTL configurado en el valor
  mínimo operativo aceptable para el negocio. Esta es una limitación conocida y aceptada del
  diseño JWT + blacklist sin consulta de estado de usuario en cada request.
- La rotación del `JWT_SECRET` invalida todos los JWT activos de forma inmediata (los tokens
  existentes dejan de verificar su firma). Este es el comportamiento esperado ante un incidente
  de seguridad; ante una rotación de rutina, se debe programar en una ventana de mantenimiento
  o aceptar que los usuarios activos serán desconectados.
- El job `/internal/jobs/limpiar_tokens_revocados` es gestionado por Cloud Scheduler con
  ejecución diaria a las 2:00 AM hora Colombia (`America/Bogotá`), método POST con header
  `X-CloudScheduler: true`, y política de reintentos por defecto de Cloud Scheduler (3
  reintentos con backoff). Si el job falla repetidamente (la tabla no es purgada), la tabla
  crecerá más allá de su tamaño estable (~50 registros), pero el sistema continuará operando
  correctamente dado el índice sobre `expira_en`. El monitoreo del job (éxito/fallo) se
  realiza mediante las métricas estándar de Cloud Scheduler en Datadog. No se define un
  umbral de alerta específico en esta spec; es responsabilidad del equipo de operaciones.
- La tabla `tokens_revocados` solo crece en logout explícito. El reset de contraseña de un
  empleado (feature `004-empleados`) no puede revocar JWTs activos porque el sistema no almacena
  qué `jti` fueron emitidos por usuario; esos tokens permanecen válidos hasta su `exp` natural.
  Es una limitación conocida y aceptada dado el contexto de dispositivos fijos en punto de venta.
- Un job programado (`/internal/jobs/limpiar_tokens_revocados`) elimina periódicamente los
  registros con `expira_en < NOW()` para evitar crecimiento ilimitado de la tabla.
- Si Cloud SQL no está disponible durante la verificación del blacklist en el middleware de
  autenticación, el sistema adopta política fail-closed: responde 503 y rechaza el request.
  La disponibilidad de Cloud SQL es prerequisito para la operación del sistema.
- La tabla `tokens_revocados` aplica DELETE físico en el job de limpieza, como excepción
  justificada a la regla de la constitución ("nunca DELETE físico sobre datos operacionales").
  Esta tabla no contiene datos operacionales del negocio sino artefactos técnicos del mecanismo
  de autenticación; sus registros expirados no tienen valor histórico dado que el evento de
  logout queda registrado en el log de auditoría (RF-AUTH-06).

---

## Observabilidad

### Trazas (Spans OTel)

| Operación | Nombre del Span | Atributos Obligatorios |
|---|---|---|
| Proceso de login | `auth.login` | `auth.result` (`success` \| `invalid_credentials` \| `account_inactive` \| `account_locked`), `http.route` |

### Métricas

| Nombre | Tipo | Unidad | Descripción | Etiquetas |
|---|---|---|---|---|
| `auth.login.duration` | Histograma | ms | Duración total del proceso de login | `result` |
| `auth.login.result` | Contador | — | Conteo de intentos de login por resultado | `result` |
| `auth.blacklist.check.duration` | Histograma | ms | Latencia de la consulta a `tokens_revocados` en el middleware JWT | — |

**Valores de la etiqueta `result`**: `success`, `invalid_credentials`, `account_inactive`, `account_locked`.

**Nota de cardinalidad**: `user_id` nunca se incluye como etiqueta de métrica (alta cardinalidad).
El `user_id` va como atributo del span `auth.login`, no como etiqueta de métrica.

---

## Clarificaciones

### Sesión 2026-05-23

- Q: ¿Cuál es el mecanismo de sesión a utilizar? → A: JWT + blacklist en Cloud SQL — el token incluye `jti`; logout inserta el `jti` en `tokens_revocados`; revocación real en el servidor sin infraestructura adicional (Cloud SQL ya está en el stack).
- Q: ¿Puede un mismo usuario tener sesiones activas simultáneamente desde múltiples dispositivos? → A: Sí, múltiples JWTs activos en paralelo están permitidos.
- Q: ¿Dónde almacena el cliente el JWT? → A: `httpOnly cookie` con `Secure; SameSite=Strict`; frontend y backend bajo mismo dominio raíz en todos los ambientes para evitar bloqueo cross-site.
- Q: ¿Qué eventos de autenticación deben registrarse en logs de auditoría? → A: login exitoso, login fallido, bloqueo de cuenta.
- Q: Al resetear la contraseña de un empleado, ¿qué ocurre con sus JWTs activos? → A: Permanecen válidos hasta su `exp` natural; el blacklist solo cubre logout explícito porque el sistema no almacena qué `jti` fueron emitidos por usuario.
