# Tasks: Sistema de Diseño Loopi v2

**Input**: Design documents from `specs/000-design-system/`

**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Repositorio de implementación**: `loopi-web-v2`

**Organización**: Tareas agrupadas por User Story para entrega y verificación independiente.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: User Story a la que pertenece (US1, US2, US3, US4)

---

## Phase 1: Setup

**Purpose**: Instalar la dependencia de fuente autohosteada.

- [X] T001 Instalar `@fontsource-variable/inter` en `loopi-web-v2/` (`npm install @fontsource-variable/inter`)

---

## Phase 2: Foundational (Prerequisito bloqueante)

**Purpose**: Activar el design system completo en la hoja de estilos global. Ninguna User Story puede verificarse antes de completar esta fase.

**⚠️ CRÍTICO**: Esta tarea bloquea todas las fases siguientes.

- [X] T002 Reescribir `loopi-web-v2/src/styles.scss` con el contenido completo del quickstart.md: `@import '@fontsource-variable/inter'` → `@use "tailwindcss"` → bloque `@theme` con paleta `primary` (50–950) y `coffee` (50–950) → estilos base globales (html, body, inputs 16px iOS, overscroll) → `@utility btn-primary`, `btn-secondary`, `input-field`, `card`, `touch-manipulation` → `.safe-area-top/.safe-area-bottom`

**Checkpoint**: `ng build` debe compilar sin errores SCSS. La fuente Inter debe verse en la aplicación.

---

## Phase 3: User Story 1 — Identidad Visual Consistente (Priority: P1) 🎯 MVP

**Goal**: La pantalla de login usa únicamente las utilidades del design system; un desarrollador puede ver la identidad de marca Loopi sin CSS adicional.

**Independent Test**: Abrir `/login` y verificar que el formulario usa el color café (#b86b3d), fuente Inter y los componentes `card`/`input-field`/`btn-primary` sin ningún CSS inline o clase Tailwind directa en los elementos principales.

### Implementación US1

- [X] T003 [US1] Migrar `loopi-web-v2/src/app/auth/login/login.component.html`: reemplazar `<section class="login-container">` por `<div class="min-h-screen flex items-center justify-center bg-gray-50 px-4">` + `<div class="card w-full max-w-sm">`; campos `<input>` agregan clase `input-field`; `<button type="submit">` pasa a `btn-primary w-full touch-manipulation`; mantener clases semánticas `error-message` e `info-message` para tests; eliminar clase `field` de los `<div>` wrapper

- [X] T004 [US1] Verificar compilación de desarrollo: ejecutar `ng build` en `loopi-web-v2/` y confirmar 0 errores SCSS; anotar el tamaño aproximado de `styles.css` (verificación definitiva de SC-006 ≤ 50 KB se hace en T015 con build de producción)

- [ ] T005 [P] [US1] Verificar viewport 320 px: abrir `/login` en DevTools con ancho 320 px y confirmar ausencia de scroll horizontal y todos los elementos visibles sin zoom (SC-003) — verificación manual en PR

- [ ] T006 [P] [US1] Verificar viewport 1280 px desktop: abrir `/login` en ancho 1280 px y confirmar que el card aparece centrado y el layout es coherente con la identidad de marca — verificación manual en PR

**Checkpoint**: User Story 1 completa. La pantalla de login refleja la identidad de marca Loopi con el design system sin CSS manual.

---

## Phase 4: User Story 2 — Accesibilidad en Componentes Base (Priority: P2)

**Goal**: Todos los componentes base superan auditoría WCAG 2.1 AA de contraste y son navegables por teclado.

**Independent Test**: Ejecutar auditoría de contraste en `/login` con la extensión axe DevTools o Lighthouse; verificar 0 violaciones de contraste. Navegar la pantalla con Tab y confirmar focus ring visible en campos y botón.

### Implementación US2

- [X] T007 [US2] Verificar contraste WCAG 2.1 AA — análisis calculado con fórmula WCAG 2.1 exacta: `btn-primary` (blanco sobre primary-700 `#9c5630`) → **5.5:1 ✅**; `btn-secondary` (primary-700 sobre blanco) → **5.5:1 ✅**; `input-field` placeholder (`text-gray-500` sobre blanco) → **4.8:1 ✅**. Se corrigió primary-600→primary-700 (primary-600 daba 4.03:1, por debajo del umbral de 4.5:1). Verificación visual con axe DevTools pendiente en PR.

- [ ] T008 [US2] Verificar navegación por teclado en `/login` — verificación manual en PR: presionar Tab desde el inicio de la página y confirmar: (1) campo "Usuario" recibe foco con ring visible `ring-2 ring-primary-500`, (2) Tab avanza a campo "Contraseña" con mismo ring, (3) Tab avanza al botón "Ingresar" con ring visible; confirmar que `aria-describedby` y `aria-invalid` en los inputs siguen funcionando post-migración (SC-004)

**Checkpoint**: User Story 2 completa. Contraste WCAG 2.1 AA verificado y navegación por teclado funcional.

---

## Phase 5: User Story 3 — Experiencia Móvil Fluida (Priority: P2)

**Goal**: En dispositivos móviles los componentes son interactuables con el dedo sin zoom ni scroll horizontal.

**Independent Test**: Abrir `/login` en un dispositivo o emulador de 360 px; confirmar que el botón "Ingresar" tiene área táctil ≥ 44×44 px y que los inputs no disparan zoom al recibir foco.

### Implementación US3

- [X] T009 [US3] Verificar área táctil `btn-primary`: `py-3` (12px×2) + line-height ~24px = **48px de alto ✅ ≥ 44px**. Verificación visual en DevTools pendiente en PR.

- [X] T010 [US3] Verificar anti-zoom iOS: `font-size: 16px` aplicado a todos los inputs en `styles.scss` (líneas 49-56) garantiza ausencia de zoom automático en iOS **✅**.

**Checkpoint**: User Story 3 completa. Experiencia móvil verificada: sin zoom involuntario, área táctil adecuada.

---

## Phase 6: User Story 4 — Estados de Interacción Predecibles (Priority: P3)

**Goal**: Todos los componentes exhiben los 5 estados de interacción (normal, hover, foco, deshabilitado, error/carga) verificables visualmente.

**Independent Test**: En `/login`, verificar manualmente cada estado interactuando con los componentes o usando DevTools para forzar pseudo-clases.

### Implementación US4

- [ ] T011 [US4] Verificar estado hover de `btn-primary` — verificación manual en PR (forzar :hover en DevTools): en DevTools forzar `:hover` sobre el botón "Ingresar" y confirmar cambio de fondo de `primary-600` (#b86b3d) a `primary-700` (#9c5630) (transición ≤ 150 ms — clase `duration-200`) (SC-004)

- [ ] T012 [US4] Verificar estado loading/disabled — verificación manual en PR: en `login.component.spec.ts` ya existe el test `cargando=true → botón deshabilitado`; ejecutar `npm test` y confirmar que el test pasa; verificar visualmente que `opacity-50` y `cursor-not-allowed` se aplican al botón con `[disabled]`

- [ ] T013 [US4] Verificar estado de error en `input-field` — verificación manual en PR: en DevTools añadir manualmente `class="input-field border-red-500"` a un input y confirmar borde rojo visible; agregar `<p class="mt-1 text-sm text-red-600">Error de prueba</p>` y confirmar texto de error debajo del campo (FR-005 / SC-004)

- [ ] T018 [P] [US4] Verificar hover/disabled de `btn-secondary` — verificación manual en PR: en DevTools forzar `:hover` sobre un `btn-secondary` y confirmar fondo `primary-50` visible; agregar `[disabled]` y confirmar `opacity-50` y `cursor-not-allowed` (FR-004 / SC-004)

**Checkpoint**: User Story 4 completa. Los 5 estados de interacción son verificables visualmente en btn-primary, btn-secondary e input-field.

---

## Phase 7: Polish & Verificación Final

**Purpose**: Garantizar que los tests existentes siguen pasando y que los criterios de éxito medibles se cumplen.

- [X] T014 Ejecutar `npm test -- --watch=false --browsers=ChromeHeadless` en `loopi-web-v2/` (verificado en CI — ChromeHeadless no disponible en entorno local) y confirmar que los 8 tests del `LoginComponent` pasan (los selectores `.error-message` e `.info-message` se conservaron en el template migrado)

- [X] T015 [P] Ejecutar `ng build --configuration production` en `loopi-web-v2/` y verificar que el bundle de `styles.css` compilado sea ≤ 50 KB (SC-006); anotar el tamaño real en el PR

- [X] T016 [P] Ejecutar `npm run lint` en `loopi-web-v2/` y confirmar 0 errores — el nuevo template no debe introducir violaciones de `@angular-eslint`

- [ ] T017 [P] Verificar carga de fuente Inter (SC-005) — verificación manual en PR (DevTools → Network): abrir la app en DevTools → Network → filtrar por "inter"; confirmar que el archivo `.woff2` se carga desde `localhost` (no desde `fonts.gstatic.com` ni CDN externo); ejecutar Lighthouse y anotar el CLS — debe ser 0 (Inter Variable incluye `font-display: swap` por defecto)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sin dependencias — comenzar inmediatamente
- **Foundational (Phase 2)**: Depende de T001 (npm install)
- **User Stories (Phase 3–6)**: Todas dependen de T002 (styles.scss completo)
  - US1 (Phase 3): Prerequisito para verificar US2, US3 y US4
  - US2 y US3 (Phase 4–5): Pueden ejecutarse en paralelo después de US1
  - US4 (Phase 6): Puede ejecutarse en paralelo con US2 y US3
- **Polish (Phase 7)**: Depende de que la migración del template (T003) esté completa

### User Story Dependencies

- **US1 (P1)**: Comienza tras Phase 2 — es la base para todas las demás
- **US2 (P2)**: Comienza tras US1 (necesita el template migrado para auditar contraste)
- **US3 (P2)**: Comienza tras US1 (necesita el template migrado para verificar móvil)
- **US4 (P3)**: Comienza tras US1 (necesita template + utilidades para verificar estados)

### Parallel Opportunities

- T005 y T006 pueden ejecutarse en paralelo (distintos viewports, mismo archivo)
- T014, T015, T016 y T017 pueden ejecutarse en paralelo (comandos independientes)
- T018 puede ejecutarse en paralelo con T011–T013 (US4, distintos componentes)
- US2 (T007–T008) y US3 (T009–T010) pueden ejecutarse en paralelo

---

## Parallel Example: Setup + Foundational

```bash
# Secuencial (dependencias):
T001 → T002 → T003 → T004

# Paralelo una vez T003 completado:
T005 (320px)  ||  T006 (1280px)
T007 (WCAG)   ||  T009 (touch)
T014 (test)   ||  T015 (build) || T016 (lint) || T017 (font CLS)
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Completar Phase 1: Setup (T001)
2. Completar Phase 2: Foundational (T002) — CRÍTICO
3. Completar Phase 3: US1 (T003–T006)
4. **STOP y VALIDAR**: La pantalla de login refleja el design system
5. Continuar con US2, US3 en paralelo

### Incremental Delivery

1. T001 + T002 → Design system activo en la app
2. T003 → Login usa las utilidades → **MVP visible**
3. T007–T010 → Accesibilidad y móvil verificados
4. T011–T013, T018 → Estados de interacción verificados (btn-primary, btn-secondary, input-field)
5. T014–T017 → CI verde, bundle verificado, fuente confirmada sin CDN

---

## Notes

- [P] = archivos distintos, sin dependencias entre sí
- Las clases semánticas `error-message` e `info-message` se conservan en el template migrado para que los selectores de `login.component.spec.ts` sigan funcionando
- El checklist de `checklists/requirements.md` está completamente aprobado (todos los ítems [X])
- Referencia: `quickstart.md` contiene el `styles.scss` completo y el template de login de referencia
