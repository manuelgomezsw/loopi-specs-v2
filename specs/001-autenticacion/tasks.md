# Tareas: Autenticación y Gestión de Sesión

**Entrada**: Documentos de diseño desde `specs/001-autenticacion/`
**Prerrequisitos**: [plan.md](plan.md) · [spec.md](spec.md) · [research.md](research.md) · [data-model.md](data-model.md) · [contracts/](contracts/)

**Stack**: Go 1.22+ (loopi-api) · Angular 18+ (loopi-web) · MySQL Cloud SQL
**Organización**: Tareas agrupadas por historia de usuario para implementación y testing independiente.

## Formato: `[ID] [P?] [Historia] Descripción`

- **[P]**: Puede ejecutarse en paralelo (archivos diferentes, sin dependencias incompletas)
- **[Historia]**: A qué historia de usuario pertenece (HU1–HU5)

---

## Fase 1: Configuración (Infraestructura Compartida)

**Propósito**: Dependencias, migración y configuración base — sin estas piezas no puede comenzar
ninguna historia de usuario.

- [ ] T001 Agregar dependencias Go al `loopi-api/go.mod`: `github.com/golang-jwt/jwt/v5`, `golang.org/x/crypto`, `github.com/google/uuid`
- [ ] T002 Crear archivo de migración `loopi-api/migrations/XXXX_auth_tokens_revocados.sql` con el contenido de `data-model.md` (CREATE TABLE tokens_revocados + ALTER TABLE usuarios)
- [ ] T003 [P] Crear struct de configuración JWT en `loopi-api/internal/config/config.go`: campos `JWTSecret` (string) y `JWTExpiryHours` (int), cargados desde variables de entorno `JWT_SECRET` y `JWT_EXPIRY_HOURS` (default 24)
- [ ] T004 [P] Configurar `HttpClientXsrfModule` en `loopi-web/src/app/app.module.ts` con `cookieName: 'XSRF-TOKEN'` y `headerName: 'X-XSRF-TOKEN'`

---

## Fase 2: Fundacional (Prerrequisitos Bloqueantes)

**Propósito**: Repositorio, middleware y enrutamiento — deben estar completos antes de implementar
cualquier historia de usuario.

**⚠️ CRÍTICO**: Ninguna historia de usuario puede comenzar hasta que esta fase esté completa.

- [ ] T005 Crear repositorio de autenticación en `loopi-api/internal/auth/repository.go` con las interfaces y métodos: `InsertTokenRevocado(jti string, expiraEn time.Time) error` e `ExisteTokenRevocado(jti string) (bool, error)` — consultas directas a Cloud SQL sin Ristretto
- [ ] T006 Crear middleware JWT en `loopi-api/internal/auth/middleware.go`: validar en orden (1) firma HS256 con `golang-jwt/jwt/v5`, (2) claim `exp` no vencido, (3) `jti` no existe en `tokens_revocados` vía repositorio; responder 401 y redirigir al login si cualquier verificación falla; política fail-closed: responder 503 si Cloud SQL no está disponible
- [ ] T007 [P] Configurar middleware CORS en `loopi-api` (agregar al router o main.go): origen permitido por ambiente (`localhost:4200` dev, `app.stage.loopi.com` stage, `app.loopi.com` prod), `Access-Control-Allow-Credentials: true`, sin wildcard `*`
- [ ] T008 Registrar rutas de autenticación en el router de `loopi-api` (archivo de rutas o `main.go`): `POST /api/v1/auth/login` (sin middleware JWT), `POST /api/v1/auth/logout` (con middleware JWT), `GET /api/v1/auth/me` (con middleware JWT), `POST /internal/jobs/limpiar_tokens_revocados` (sin middleware JWT, con validación de header `X-CloudScheduler`)

**Punto de control**: Fundación lista — la implementación de historias de usuario puede comenzar.

---

## Fase 3: HU1 + HU2 — Login exitoso y Rechazo de credenciales (Prioridad: P1) 🎯 MVP

**Objetivo**: Un empleado puede autenticarse con usuario y contraseña. Las credenciales incorrectas,
cuentas inactivas y cuentas bloqueadas son rechazadas con mensaje genérico. Se emite JWT en cookie
httpOnly + XSRF-TOKEN cookie legible por Angular.

**Prueba Independiente**: Ejecutar el flujo curl del `quickstart.md §5` (login exitoso → 200 con
cookies) y verificar que credenciales incorrectas devuelven 401, usuario bloqueado devuelve 423.

- [ ] T009 [HU1] Implementar `AuthService.Authenticate` en `loopi-api/internal/auth/service.go`: consultar usuario por nombre, verificar `activo`, verificar `bloqueado_hasta > NOW()`, aplicar `bcrypt.CompareHashAndPassword` siempre (incluso si usuario no existe, usar hash dummy para evitar timing attack), en login exitoso emitir JWT HS256 con claims `jti` (UUID v4), `sub`, `rol`, `tienda_id`, `iat`, `exp`; en login fallido incrementar `intentos_fallidos`; al llegar a 5 intentos establecer `bloqueado_hasta = NOW() + 5 min` y resetear contador a 0 en login exitoso
- [ ] T010 [HU1] Implementar handler `POST /api/v1/auth/login` en `loopi-api/internal/auth/handler.go`: leer `usuario` y `contrasena` del body JSON, llamar a `AuthService.Authenticate`, en éxito setear cookie `jwt` (`httpOnly; Secure; SameSite=Strict; Max-Age=JWT_EXPIRY_HOURS*3600`) y cookie `XSRF-TOKEN` (`Secure; SameSite=Strict`, sin `httpOnly`) con valor UUID v4 aleatorio, responder 200 según contrato `POST_api_v1_auth_login.md`; en fallo responder 401 (credenciales) o 423 (bloqueado) con mensaje genérico
- [ ] T011 [P] [HU1] Crear componente de login en `loopi-web/src/app/auth/login/login.component.ts` y `login.component.html`: formulario con campos `usuario` y `contrasena`, botón de envío deshabilitado durante el request con indicador visual de carga (spinner o texto), manejo de errores 401 (mensaje genérico) y 423 (mensaje de cuenta bloqueada)
- [ ] T012 [P] [HU1] Implementar método `login(usuario: string, contrasena: string): Observable<void>` en `loopi-web/src/app/auth/auth.service.ts`: POST a `/api/v1/auth/login` con `withCredentials: true`; en éxito almacenar en memoria el rol y tienda_id (NO en localStorage)
- [ ] T013 [HU1] Registrar ruta `/login` en `loopi-web/src/app/app-routing.module.ts` apuntando al `LoginComponent`; redirigir raíz `/` al login si no hay sesión

**Punto de control**: Login completo y funcionando — HU1 + HU2 deben ser testeables de forma
independiente con `curl` y con el formulario Angular.

---

## Fase 4: HU3 — Cierre de sesión (Prioridad: P2)

**Objetivo**: El empleado puede cerrar su sesión; el token queda revocado en el servidor de forma
inmediata y cualquier request posterior con ese JWT es rechazado.

**Prueba Independiente**: Después de hacer login, ejecutar logout (204), luego intentar `/me`
y recibir 401 — aunque el JWT aún no haya expirado por TTL.

- [ ] T014 [HU3] Implementar `AuthService.RevocarToken` en `loopi-api/internal/auth/service.go`: insertar el `jti` extraído del JWT activo en la tabla `tokens_revocados` con su `expira_en` original; expirar la cookie `jwt` (Max-Age=0) y la cookie `XSRF-TOKEN` (Max-Age=0)
- [ ] T015 [HU3] Implementar handler `POST /api/v1/auth/logout` en `loopi-api/internal/auth/handler.go`: invocar `AuthService.RevocarToken` con el JWT de la cookie, responder 204 según contrato `POST_api_v1_auth_logout.md`; responder 403 si el header `X-XSRF-TOKEN` no coincide con la cookie `XSRF-TOKEN`
- [ ] T016 [P] [HU3] Implementar método `logout(): Observable<void>` en `loopi-web/src/app/auth/auth.service.ts`: POST a `/api/v1/auth/logout` con `withCredentials: true`; en éxito limpiar estado de sesión en memoria y navegar al `/login`

**Punto de control**: Logout revoca el token en el servidor — verificable con curl de quickstart.md.

---

## Fase 5: HU4 — Restauración de sesión al recargar (Prioridad: P2)

**Objetivo**: Al recargar la app Angular, el frontend llama a `/me` para recuperar rol y
`tienda_id` desde la cookie activa sin pedir credenciales nuevamente.

**Prueba Independiente**: Con sesión activa, recargar la app; el usuario llega a su pantalla
sin pasar por el login. Sin sesión activa, la recarga redirige al login.

- [ ] T017 [HU4] Implementar handler `GET /api/v1/auth/me` en `loopi-api/internal/auth/handler.go`: extraer claims del JWT validado por el middleware (el middleware pasa los claims en el contexto del request); responder 200 con `usuario_id`, `usuario`, `rol` y `tienda_id` según contrato `GET_api_v1_auth_me.md`
- [ ] T018 [P] [HU4] Implementar método `getMe(): Observable<SesionActual>` en `loopi-web/src/app/auth/auth.service.ts`: GET a `/api/v1/auth/me` con `withCredentials: true`; en éxito almacenar `rol` y `tienda_id` en memoria; exponer estado de sesión como observable para que los componentes reaccionen
- [ ] T019 [P] [HU4] Crear `AuthGuard` en `loopi-web/src/app/auth/auth.guard.ts`: implementar `CanActivate`; si hay sesión activa en memoria permitir navegación; si no, llamar a `getMe()` y en éxito permitir, en error (401) redirigir al `/login`
- [ ] T020 [P] [HU4] Crear `AuthInterceptor` en `loopi-web/src/app/auth/auth.interceptor.ts`: interceptar respuestas 401 de cualquier endpoint protegido, limpiar estado de sesión en memoria y redirigir al `/login`
- [ ] T021 [HU4] Registrar `AuthGuard` en las rutas protegidas de `loopi-web/src/app/app-routing.module.ts` y registrar `AuthInterceptor` como `HTTP_INTERCEPTORS` en `app.module.ts`; llamar a `auth.service.getMe()` en `ngOnInit` de `AppComponent` (`loopi-web/src/app/app.component.ts`) para restaurar sesión en memoria al cargar la app

**Punto de control**: Recargar la app con sesión activa lleva al usuario a su pantalla; sin sesión
activa redirige al login.

---

## Fase 6: HU5 — Expiración automática durante operación activa (Prioridad: P2)

**Objetivo**: Si el JWT expira mientras el usuario realiza una operación, el sistema responde
401, el frontend muestra mensaje de sesión expirada y redirige al login sin perder contexto
de la pantalla actual.

**Prueba Independiente**: Configurar `JWT_EXPIRY_HOURS=0` (o reducir a segundos vía test),
esperar expiración y realizar cualquier operación — el interceptor debe distinguir expiración
de sesión de una falta de autenticación inicial.

- [ ] T022 [HU5] Actualizar `AuthInterceptor` en `loopi-web/src/app/auth/auth.interceptor.ts`: al interceptar 401 en endpoint no-login, verificar si había sesión previa en memoria (el usuario estaba autenticado); si sí, mostrar notificación de "Sesión expirada" antes de redirigir al `/login`; si no había sesión previa, redirigir al login sin mensaje adicional

**Nota**: El backend ya maneja la expiración en el middleware de Fase 2 (validación del claim
`exp` → 401 si vencido).

**Punto de control**: Todas las historias de usuario (HU1–HU5) están completas y testeables
de forma independiente.

---

## Fase 7: Job de limpieza de tokens revocados

**Propósito**: Mantener la tabla `tokens_revocados` pequeña eliminando registros expirados.

- [ ] T023 Implementar handler del job en `loopi-api/internal/jobs/limpiar_tokens.go`: ejecutar `DELETE FROM tokens_revocados WHERE expira_en < NOW()`, registrar `iniciado_en`, `completado_en`, `eliminados` y `resultado` en log estructurado JSON; responder 200 con el body del contrato `POST_internal_jobs_limpiar_tokens_revocados.md`
- [ ] T024 Implementar middleware de validación del header `X-CloudScheduler: true` en el handler del job (rechazar con 403 si el header está ausente o tiene valor distinto); conectar al route registrado en T008

---

## Fase Final: Pulido y Aspectos Transversales

**Propósito**: Observabilidad, tests y validación end-to-end del flujo completo.

- [ ] T025 [P] Agregar spans OTel en los handlers de autenticación en `loopi-api/internal/auth/handler.go`: atributos `auth.result` (`success` | `invalid_credentials` | `account_inactive` | `account_locked`), `user.role` (solo en login exitoso), `http.route`
- [ ] T026 [P] Agregar métricas OTel en `loopi-api/internal/auth/`: histograma `auth.login.duration` (ms), contador `auth.login.result` (por etiqueta `result`), histograma `auth.blacklist.check.duration` (ms) para monitorear latencia de consulta a `tokens_revocados`
- [ ] T027 [P] Escribir tests de handler en `loopi-api/internal/auth/handler_test.go` con mocks del servicio y repositorio (política de constitución): cubrir login exitoso (cada rol), credenciales incorrectas, cuenta bloqueada (423), logout exitoso, logout con CSRF inválido (403), /me con token válido, /me con token revocado (401)
- [ ] T028 [P] Escribir tests de componente Angular en `loopi-web/src/app/auth/login/login.component.spec.ts`: formulario deshabilitado durante request, mensaje de error en 401, mensaje de bloqueo en 423
- [ ] T029 Ejecutar la validación completa del flujo según `quickstart.md §5`: login → 200 + cookies, `/me` → 200 con rol, logout → 204, `/me` → 401; verificar que la cookie `jwt` no es visible en las DevTools y confirmar revocación real en `tokens_revocados`

---

## Dependencias y Orden de Ejecución

### Dependencias de Fase

- **Fase 1 (Configuración)**: Sin dependencias — puede comenzar de inmediato
- **Fase 2 (Fundacional)**: Depende de Fase 1 completa — **BLOQUEA** todas las historias de usuario
- **Fase 3 (HU1+HU2)**: Depende de Fase 2 completa — MVP
- **Fase 4 (HU3)**: Depende de Fase 3 (necesita el JWT emitido por login para revocar)
- **Fase 5 (HU4)**: Puede comenzar en paralelo con Fase 4 (el handler `/me` no depende de logout)
- **Fase 6 (HU5)**: Depende de Fase 5 (interceptor ya existe, solo se actualiza)
- **Fase 7 (Job)**: Independiente — puede ejecutarse en paralelo con Fases 4–6
- **Fase Final (Pulido)**: Depende de que Fases 3–7 estén completas

### Dependencias entre Historias de Usuario

- **HU1 + HU2 (P1)**: Sin dependencias de otras historias — MVP independiente
- **HU3 (P2)**: Requiere HU1 (necesita el JWT emitido para poder revocarlo)
- **HU4 (P2)**: Requiere HU1 (el middleware debe estar activo para validar el JWT en `/me`)
- **HU5 (P2)**: Requiere HU4 (el interceptor debe existir para añadir el mensaje de expiración)

### Dentro de Cada Historia de Usuario

- Backend (service/repository) → handler → registro de ruta
- Frontend (service method) → componente/guard → registro en módulo
- Los tests [P] pueden ejecutarse en paralelo entre sí, pero deben venir después de la implementación

### Oportunidades de Paralelismo

- T003 + T004 (config Go + config Angular) → en paralelo
- T011 + T012 (login component + auth service) → en paralelo dentro de HU1
- T014 + T016 en HU3: backend logout + frontend logout method → en paralelo (archivos distintos)
- T017 + T018 + T019 + T020 en HU4 → en paralelo (archivos distintos)
- T023 + T025 + T026 + T027 + T028 → en paralelo (archivos distintos)

---

## Ejemplo Paralelo: HU1 (MVP)

```bash
# Paso 1: Completar Fase 1 + Fase 2 (secuencial)
T001 → T002 → T003 + T004 (paralelo) → T005 → T006 → T007 + T008 (paralelo)

# Paso 2: HU1 — lanzar T011 y T012 en paralelo mientras T009 y T010 van secuenciales
Backend: T009 → T010
Frontend: T011 (paralelo con T012) → T013

# Paso 3: Validar HU1 + HU2 de forma independiente
curl -c cookies.txt -X POST localhost:8080/api/v1/auth/login \
  -d '{"usuario":"admin","contrasena":"test123"}'
# Espera: 200 + cookies jwt y XSRF-TOKEN
```

---

## Estrategia de Implementación

### MVP Primero (HU1 + HU2 únicamente)

1. Completar Fase 1: Configuración (T001–T004)
2. Completar Fase 2: Fundacional (T005–T008) — **bloqueante**
3. Completar Fase 3: HU1 + HU2 (T009–T013)
4. **PARAR Y VALIDAR**: ejecutar quickstart.md §5 (solo login exitoso e inválido)
5. Demostrar login funcional antes de continuar con logout y sesión

### Entrega Incremental

1. Fases 1–2 → Fundación lista
2. Fase 3 (HU1+HU2) → **MVP**: login funcional → validar → demo
3. Fase 4 (HU3) → Logout funcional → validar revocación real
4. Fases 5–6 (HU4+HU5) → Restauración + expiración → validar reload
5. Fase 7 (Job) → Limpieza automática activa
6. Fase Final → OTel, tests, hardening

### Con Dos Desarrolladores en Paralelo

Una vez completa la Fase 2:
- **Dev A**: Fases 3 + 4 (login + logout — backend y frontend)
- **Dev B**: Fase 7 + T025 + T026 (job + OTel — no comparte archivos)

---

## Notas

- Las tareas `[P]` operan sobre archivos distintos sin dependencias cruzadas incompletas
- La etiqueta `[HUn]` traza cada tarea a su historia de usuario para seguimiento
- El middleware de Fase 2 (T006) es la pieza más crítica: un bug ahí bloquea todas las historias
- La migración (T002) debe ejecutarse antes del primer request en cualquier ambiente
- `JWT_SECRET` nunca en código fuente; `.env` local en dev, GCP Secret Manager en stage/prod
- El interceptor Angular (T020) maneja todos los 401; T022 añade el matiz del mensaje de expiración
