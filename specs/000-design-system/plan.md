# Implementation Plan: Sistema de Diseño Loopi v2

**Branch**: `feature/000-design-system` | **Date**: 2026-05-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/000-design-system/spec.md`

## Summary

Adoptar la paleta café de Loopi v1 y las utilidades de componente
(`btn-primary`, `btn-secondary`, `input-field`, `card`) en Loopi v2.
La implementación se concentra en `loopi-web-v2/src/styles.scss` (tokens
`@theme` + `@utility` de Tailwind v4) y en la migración completa de los
templates de `001-autenticacion` para usar las nuevas utilidades.
La fuente Inter se servirá autohosteada via `@fontsource-variable/inter`.

## Technical Context

**Language/Version**: TypeScript 5.x / SCSS — Angular 20 (standalone components, signals)

**Primary Dependencies**:

- Tailwind CSS v4 (ya integrado en `loopi-web-v2`)
- `@fontsource-variable/inter` (nueva dependencia npm)

**Storage**: N/A — design system es puramente CSS/SCSS

**Testing**: Karma + Jasmine (Angular); auditoría visual WCAG con axe-core

**Target Platform**: Web — Angular SPA desplegada en Firebase Hosting (GCP)

**Project Type**: Frontend — web-application

**Performance Goals**:

- CSS compilado ≤ 50 KB (SC-006)
- Fuente Inter carga ≤ 1 s; CLS = 0 (SC-005)

**Constraints**:

- Mobile-first: breakpoint base ≥ 320 px (constitución §Responsive)
- WCAG 2.1 AA: contraste ≥ 4.5:1 para texto normal (constitución §Accesibilidad)
- Sin librerías de componentes externas (constitución §Stack de UI)
- Sin Google Fonts CDN — solo autohosting (clarificación Q3)

**Scale/Scope**: 1 archivo SCSS global + migración de 1–2 templates existentes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Requisito constitución | Estado |
|---|---|---|
| Mobile-first | Breakpoints Tailwind, mínimo 320 px | ✅ PASS — tokens y utilidades son mobile-first |
| Sin CDN externo | Fuente autohosteada | ✅ PASS — `@fontsource-variable/inter` |
| Sin librerías de componentes | Solo Tailwind + CSS propio | ✅ PASS — `@utility` en styles.scss |
| Tokens en `@theme`, no hardcoded | Variables CSS semánticas | ✅ PASS — toda la paleta en `@theme` |
| WCAG 2.1 AA | Contraste ≥ 4.5:1 | ✅ PASS — btn-primary: ~4.8:1 verificado |
| Tailwind CSS v4 | `@use "tailwindcss"` | ✅ PASS — ya en uso en la rama |
| Observabilidad | N/A — sin endpoints ni lógica de negocio | ✅ N/A |
| RBAC / JWT | N/A — solo CSS | ✅ N/A |

**Sin violaciones. Sin Complexity Tracking necesario.**

## Project Structure

### Documentation (this feature)

```text
specs/000-design-system/
├── plan.md              ← este archivo
├── spec.md
├── research.md          ← paleta v1, Inter self-host, Tailwind v4 patterns
├── data-model.md        ← token schema (color, tipografía, utilidades, estados)
├── quickstart.md        ← guía de uso + styles.scss completo
├── contracts/
│   ├── design-tokens.md ← contrato de tokens CSS
│   └── utilities.md     ← contrato de clases utilitarias
├── checklists/
│   └── requirements.md
└── tasks.md             ← generado por /speckit-tasks
```

### Source Code (`loopi-web-v2`)

```text
loopi-web-v2/
└── src/
    ├── styles.scss                          ← MODIFICAR: tokens + utilidades
    └── app/
        └── auth/
            └── login/
                ├── login.component.html     ← MIGRAR: btn-primary, input-field, card
                └── login.component.scss     ← REVISAR: eliminar overrides manuales
```

**Dependencia nueva** (agregar a `package.json`):

```bash
npm install @fontsource-variable/inter
```

**Sin cambios en**:

- `angular.json` — Tailwind v4 ya está configurado
- `tsconfig.json` — sin cambios
- Backend (`loopi-api-v2`) — sin cambios
- Base de datos — sin cambios

## Phase 0: Research (completado)

Ver [research.md](research.md).

Decisiones resueltas:

- ✅ Valores hex de la paleta extraídos de `loopi-web/src/styles.scss` (v1, rama `master`)
- ✅ Inter self-hosted vía `@fontsource-variable/inter`
- ✅ Patrón `@utility` de Tailwind v4 (no `@layer components`)
- ✅ `btn-secondary` cambiado de gray-soft a outline primary (clarificación spec)
- ✅ Optimizaciones iOS incluidas (font-size 16px, overscroll, safe areas)

## Phase 1: Design & Contracts (completado)

Artefactos generados:

- [data-model.md](data-model.md) — modelo de tokens y utilidades
- [contracts/design-tokens.md](contracts/design-tokens.md) — contrato de variables CSS
- [contracts/utilities.md](contracts/utilities.md) — contrato de clases `@utility`
- [quickstart.md](quickstart.md) — guía de integración con `styles.scss` completo

## Tareas de Implementación (resumen para /speckit-tasks)

### Bloque 1 — Setup

- Instalar `@fontsource-variable/inter`
- Reemplazar `styles.scss`: `@import` fuente + `@use tailwindcss` + `@theme` con paleta
  completa + estilos base globales (iOS, body, html) + todas las `@utility`

### Bloque 2 — Migración `001-autenticacion`

- `login.component.html`: botón submit → `btn-primary`, campos → `input-field`,
  contenedor del formulario → `card`
- `login.component.scss`: eliminar cualquier override manual que duplique estilos
  ahora cubiertos por las utilidades

### Bloque 3 — Verificación

- `ng build` sin errores ni advertencias SCSS
- `npm test` pasa (tests existentes de LoginComponent)
- Auditoría visual WCAG: contraste en btn-primary y btn-secondary
- Verificar en viewport 320 px (sin scroll horizontal)
- Verificar en viewport 1280 px (layout correcto en desktop)

## Complexity Tracking

Sin violaciones de constitución — no aplica.
