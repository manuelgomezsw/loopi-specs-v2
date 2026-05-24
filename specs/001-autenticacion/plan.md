# Plan de Implementación: Autenticación y Gestión de Sesión

**Branch**: `feature/001-autenticacion-clarify` | **Fecha**: 2026-05-23 | **Spec**: [spec.md](spec.md)
**Entrada**: Especificación de feature desde `specs/001-autenticacion/spec.md`

## Resumen

Implementar el sistema de autenticación de Loopi v2: login con usuario/contraseña,
emisión de JWT firmado (HS256) con blacklist en Cloud SQL para revocación real en
logout, cookie `httpOnly` con `Secure; SameSite=Strict`, bloqueo por intentos
fallidos, expiración automática configurable y auditoría de eventos via OTel+Datadog.
Sin infraestructura nueva: todo corre sobre Go + Cloud SQL + Angular existentes.

## Contexto Técnico

**Lenguaje/Versión**: Go 1.22+ (backend), TypeScript/Angular 18+ (frontend)

**Dependencias Principales**:

- `github.com/golang-jwt/jwt/v5` — emisión y validación de JWT
- `golang.org/x/crypto/bcrypt` — hash de contraseñas (cost 12)
- `github.com/google/uuid` — generación de `jti` (UUID v4)
- Angular `provideHttpClient(withXsrfConfiguration(...))` — doble-submit CSRF en standalone (Angular 18+)

**Almacenamiento**: MySQL en GCP Cloud SQL; tabla `tokens_revocados` nueva;
columnas `intentos_fallidos` y `bloqueado_hasta` en `usuarios`

**Testing**: `go test ./...` con mocks de BD (política de constitución); `ng test`
para componentes Angular

**Plataforma Objetivo**: GCP App Engine (Go backend), Firebase Hosting (Angular);
dominios `api.loopi.com` y `app.loopi.com` en stage/prod

**Tipo de Proyecto**: Servicio web full-stack (API REST Go + SPA Angular)

**Objetivos de Rendimiento**: Login e2e < 3 s; logout < 1 s; verificación JWT < 5 ms

**Restricciones**:

- Sin Redis ni Firestore; Cloud SQL es el único almacén de datos
- `JWT_SECRET` vía GCP Secret Manager en stage/prod; `.env` en dev
- Dominio raíz compartido en stage/prod obligatorio para `SameSite=Strict`

**Escala/Alcance**: < 100 empleados activos, < 20 tiendas; carga moderada

## Verificación de Constitución

*GATE: Debe pasar antes de la investigación de Fase 0. Re-verificar tras el diseño de Fase 1.*

| # | Principio | Estado | Evidencia |
| --- | --- | --- | --- |
| I | Spec-First | ✅ PASA | Spec en PR #29 antes de este plan |
| II | Multi-Tienda | ✅ PASA | JWT incluye `tienda_id` para lider_tienda/barista; admin sin tienda_id fija |
| III | RBAC | ✅ PASA | 4 roles definidos; JWT lleva `rol`; backend valida en cada endpoint (RF-AUTH-05) |
| IV | Stack técnico | ✅ PASA | Go + Cloud SQL + Angular + App Engine + Firebase; sin Redis, sin Firestore, sin Docker |
| V | Caché (Ristretto) | ✅ PASA | `tokens_revocados` es dato operacional → BD directa; Ristretto solo para catálogo |
| VI | Observabilidad | ✅ PASA | Auth es endpoint crítico; trazas OTel + métricas Datadog (RF-AUTH-06, research §7) |
| VII | Secrets | ✅ PASA | `JWT_SECRET` en GCP Secret Manager (stage/prod); nunca hardcodeado |

**Resultado**: Todos los gates pasan. Sin violaciones. Registro de Complejidad no aplica.

## Estructura del Proyecto

### Documentación (esta feature)

```text
specs/001-autenticacion/
├── plan.md              # Este archivo
├── research.md          # Decisiones técnicas de Fase 0
├── data-model.md        # Esquema SQL y migraciones de Fase 1
├── quickstart.md        # Guía de setup local de Fase 1
├── contracts/           # Contratos de API de Fase 1
│   ├── POST_api_v1_auth_login.md
│   ├── POST_api_v1_auth_logout.md
│   ├── GET_api_v1_auth_me.md
│   └── POST_internal_jobs_limpiar_tokens_revocados.md
└── tasks.md             # Output de /speckit-tasks (NO creado aquí)
```

### Código Fuente

```text
loopi-api/
├── internal/
│   ├── auth/
│   │   ├── handler.go          # Handlers HTTP: login, logout, me
│   │   ├── middleware.go        # Middleware JWT: firma → exp → blacklist
│   │   ├── service.go          # Lógica: authenticate, revokeToken, validateSession
│   │   ├── repository.go       # Cloud SQL: tokens_revocados INSERT/SELECT
│   │   └── handler_test.go     # Tests con mocks de BD y service
│   └── jobs/
│       └── limpiar_tokens.go   # Handler: DELETE tokens_revocados WHERE expira_en < NOW()
├── migrations/
│   └── XXXX_auth_tokens_revocados.sql
└── config/
    └── config.go               # JWT_SECRET, JWT_EXPIRY_HOURS desde env

loopi-web/
└── src/
    └── app/
        ├── app.config.ts            # provideHttpClient(withXsrfConfiguration, withInterceptors)
        ├── app.routes.ts            # Rutas con canActivate: [authGuard]
        └── auth/
            ├── login/
            │   ├── login.component.ts
            │   └── login.component.html
            ├── auth.service.ts      # login(), logout(), getMe()
            ├── auth.guard.ts        # CanActivate funcional para rutas protegidas
            └── auth.interceptor.ts  # Interceptor funcional — redirige 401 al login
```

**Patrón Angular**: componentes standalone (Angular 18+), sin NgModule. Providers en
`app.config.ts`, rutas en `app.routes.ts`.

**Decisión de Estructura**: Full-stack — backend en `loopi-api/internal/auth/`,
frontend en `loopi-web/src/app/auth/`.

## Diseño UX — Autenticación

### User Flows

**Happy path — Login:**

```text
[/login — pantalla pública]
  → usuario ingresa email + contraseña
  → clic "Iniciar sesión" → [botón deshabilitado + spinner]
  → AuthService.login() → POST /api/v1/auth/login
  → 200 OK + cookie httpOnly
  → GET /api/v1/auth/me → rol resuelto
  → redirigir según rol:
      ├─ admin / lider_compras  → /dashboard  (sin tienda_id fijo)
      └─ lider_tienda / barista → /tienda/:id/dashboard
```

**Error paths — Login:**

```text
Credenciales incorrectas (< 5 intentos):
  → API 401 → mensaje inline debajo del formulario:
     "Email o contraseña incorrectos."
  → campo contraseña se vacía; campo email conserva el valor
  → botón re-habilitado

Cuenta bloqueada (≥ 5 intentos fallidos):
  → API 423 → mensaje:
     "Cuenta bloqueada temporalmente. Intenta de nuevo en 15 minutos."
  → botón deshabilitado mientras dure el bloqueo

Cuenta inactiva:
  → API 401 con código "cuenta_inactiva" → mensaje:
     "Tu cuenta está inactiva. Contacta al administrador."
```

**Happy path — Logout:**

```text
[Header — botón "Cerrar sesión"]
  → clic → AuthService.logout() → POST /api/v1/auth/logout
  → cookie eliminada + token añadido a blacklist en BD
  → redirigir a /login
  → toast verde: "Sesión cerrada correctamente." (3 s, auto-cierre)
```

**Sesión expirada (JWT exp o token revocado):**

```text
Cualquier vista protegida → AuthGuard o AuthInterceptor detecta 401
  → redirigir a /login
  → mensaje informativo: "Tu sesión expiró. Inicia sesión nuevamente."
```

### Wireframe — Pantalla Login

```text
┌────────────────────────────────────┐
│                                    │
│           🔄  Loopi                │  ← Logo centrado, sin navegación
│                                    │
│  ┌──────────────────────────────┐  │
│  │  Email *                     │  │
│  │  [__________________________]│  │  ← type="email", autocomplete="email"
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │  Contraseña *                │  │
│  │  [____________________]  👁  │  │  ← toggle mostrar/ocultar contraseña
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │  ⚠ Mensaje de error aquí    │  │  ← visible solo en estado error/blocked
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │      Iniciar sesión  [⟳]    │  │  ← spinner durante submit
│  └──────────────────────────────┘  │
│                                    │
│  * Campo obligatorio               │
│                                    │
└────────────────────────────────────┘
```

**Layout**: centrado vertical y horizontal. `max-w-sm` en móvil, `max-w-md` en tablet/desktop.
Sin sidebar ni header de navegación — única pantalla pública de la aplicación.
Sin enlace "¿Olvidaste tu contraseña?" — fuera de alcance de esta feature.

### Estados del Componente Login

| Estado | Botón | Campos | Área de mensaje |
| --- | --- | --- | --- |
| Default | Habilitado, "Iniciar sesión" | Editables, vacíos | Oculta |
| Cargando | Deshabilitado, spinner `⟳` | Deshabilitados | Oculta |
| Error credenciales | Habilitado | Email conservado, contraseña vacía | "Email o contraseña incorrectos." |
| Cuenta bloqueada | Deshabilitado | Deshabilitados | "Cuenta bloqueada. Intenta en 15 min." |
| Cuenta inactiva | Habilitado | Editables | "Tu cuenta está inactiva. Contacta al admin." |

### Validaciones del Formulario Login

| Campo | Regla | Mensaje de error |
| --- | --- | --- |
| Email | Requerido | "El email es obligatorio." |
| Email | Formato válido (`Validators.email`) | "Ingresa un email válido." |
| Contraseña | Requerido | "La contraseña es obligatoria." |
| Contraseña | Mínimo 8 caracteres | "La contraseña debe tener al menos 8 caracteres." |

Validación: **on blur** por campo + **validación completa on submit**.
Los errores de campo aparecen debajo del input con `text-red-600`.
El mensaje de error de API (credenciales / bloqueo / inactivo) aparece en el área
de mensaje general, entre el formulario y el botón de submit.

### Componentes Angular

| Archivo | Responsabilidad UX |
| --- | --- |
| `login/login.component.ts` | Formulario reactivo; manejo de estados (default/loading/error/blocked) con `FormBuilder` |
| `login/login.component.html` | Template Tailwind; accesibilidad (`label`, `aria-describedby` en errores); toggle contraseña |
| `auth.service.ts` | `login()` y `logout()` con manejo de errores tipados; `getMe()` post-login para resolver rol |
| `auth.guard.ts` | `CanActivateFn` — verifica sesión activa; redirige a `/login` si no hay sesión |
| `auth.interceptor.ts` | `HttpInterceptorFn` — intercepta 401 globalmente; redirige a `/login` con mensaje de sesión expirada |

### Comportamiento Responsive del Login

| Viewport | Layout |
| --- | --- |
| Móvil < 640 px | Full width, `px-4 py-8`; logo arriba, formulario debajo |
| Tablet ≥ 640 px | Formulario centrado `max-w-md`, margen superior `mt-16` |
| Desktop ≥ 1024 px | `max-w-md` centrado; fondo liso o con imagen de marca en split-screen |

---

## Registro de Complejidad

### EC-001 — PK VARCHAR(36) en `tokens_revocados`

**Principio**: Constitución §Datos — "Clave primaria: entero auto-incremental (`BIGINT UNSIGNED`).
No se usan UUIDs."

**Excepción**: La tabla `tokens_revocados` usa `jti VARCHAR(36)` como PK. El `jti` es un UUID v4
proveniente del claim JWT — es la clave natural de la tabla de blacklist. Agregar un `BIGINT`
surrogate sería redundante: el `jti` es el único identificador que el middleware consulta (`ExisteTokenRevocado(jti)`). La excepción está justificada porque `tokens_revocados` es una tabla
técnica de blacklist, no una entidad de dominio; la regla de PK entero aplica a entidades con
identidad de negocio propia.

**Impacto**: Ninguno en consistencia ni rendimiento. La tabla tiene ~50 registros en estado
estable y un índice adicional sobre `expira_en` para el job de limpieza.

### EC-002 — `POST /api/v1/auth/login` retorna 200, no 201

**Principio**: Constitución §API — "Recurso creado (POST): 201."

**Excepción**: El endpoint de autenticación retorna 200. La sesión no es un recurso persistente
en la BD; vive en la `httpOnly cookie` del cliente. No se crea ninguna fila en la BD en login.
Este es el comportamiento estándar para endpoints de autenticación REST; 201 sería semánticamente
incorrecto.

### EC-003 — RF-AUTH-04.1 / RF-AUTH-05.1 overlap intencional

RF-AUTH-04.1 (expiración automática, perspectiva de usuario) y RF-AUTH-05.1 (middleware de
validación, paso 2) describen el mismo comportamiento desde perspectivas distintas. La validación
del claim `exp` se implementa una sola vez en T006; RF-AUTH-04.1 es la perspectiva funcional del
usuario sobre ese mismo mecanismo técnico.
