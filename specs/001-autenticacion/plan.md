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
- Angular `HttpClientXsrfModule` — doble-submit CSRF automático en frontend

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
|---|-----------|--------|-----------|
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
        └── auth/
            ├── login/
            │   ├── login.component.ts
            │   └── login.component.html
            ├── auth.service.ts          # login(), logout(), getMe()
            ├── auth.guard.ts            # CanActivate para rutas protegidas
            └── auth.interceptor.ts      # Redirige 401 al login
```

**Decisión de Estructura**: Full-stack — backend en `loopi-api/internal/auth/`,
frontend en `loopi-web/src/app/auth/`.

## Registro de Complejidad

> No hay violaciones de constitución. Esta sección no aplica.
