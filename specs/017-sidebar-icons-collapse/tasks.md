# Tasks: Mejoras del Menú Lateral Admin

**Input**: Artefactos de diseño en `specs/017-sidebar-icons-collapse/`

**Prerrequisitos**: plan.md ✅ · spec.md ✅ · research.md ✅ · data-model.md ✅ · contracts/ui-shell-v2.md ✅ · quickstart.md ✅

**Tests**: Los tests de componentes están incluidos porque la feature modifica componentes
existentes con contratos ya establecidos en la feature 016-admin-nav.

**Organización**: Las tareas están agrupadas por historia de usuario para permitir implementación
y validación incremental e independiente.

## Formato: `[ID] [P?] [Story?] Descripción con ruta de archivo`

- **[P]**: Puede correr en paralelo (archivos distintos, sin dependencias activas)
- **[Story]**: Historia de usuario a la que pertenece (US1, US2, US3)
- Todas las rutas son relativas a `loopi-web/src/app/`

---

## Phase 1: Setup

**Propósito**: Verificar baseline antes de modificar el shell.

- [x] T001 Compilar `loopi-web` sin errores para establecer baseline: ejecutar `ng build` desde `loopi-web/`

---

## Phase 2: Fundacional — Componente `app-icon`

**Propósito**: El componente `IconComponent` es prerrequisito de HU-1 y HU-2. Debe
completarse antes de modificar el sidebar.

**⚠️ CRÍTICO**: Las fases 3 y 4 no pueden comenzar hasta completar esta fase.

- [x] T002 Crear `shared/components/icon/icon.component.ts` — componente standalone con `@Input({ required: true }) name: string`; template con `<svg class="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">` y bloque `@switch (name)` con un `@case` para cada uno de los 13 íconos: `home`, `building-storefront`, `users`, `squares-2x2`, `book-open`, `clipboard-document-list`, `trash`, `shopping-cart`, `banknotes`, `chart-bar`, `presentation-chart-line`, `chevron-left`, `chevron-right`; `@default` con `<circle cx="12" cy="12" r="4" fill="currentColor" />`; paths SVG obtenidos de Heroicons v2 outline
- [x] T003 [P] Crear `shared/components/icon/icon.component.spec.ts` — test que verifica que cada uno de los 13 nombres registrados produce un elemento `<svg>`; test que un nombre inválido produce el elemento fallback sin romper el componente

**Checkpoint**: `app-icon` disponible para ser importado por el sidebar.

---

## Phase 3: Historia de Usuario 1 — Íconos SVG en el menú lateral (P1) 🎯 MVP

**Goal**: Reemplazar los emojis del menú lateral por íconos SVG Heroicons v2 uniformes
que heredan el color del enlace padre via `currentColor`.

**Prueba Independiente**: Abrir la app en Chrome/macOS y Chrome/Windows y confirmar que
los 11 ítems del menú muestran SVG line-icons idénticos en ambas plataformas, con color
correcto en estado normal y activo.

### Implementación HU-1

- [x] T004 [US1] Importar `IconComponent` en el array `imports` de `sidebar.component.ts` y eliminar completamente el método `iconEmoji()` de `shared/components/shell/sidebar/sidebar.component.ts`
- [x] T005 [US1] Reemplazar `<span class="flex h-5 w-5 ...">{{ iconEmoji(item.icon) }}</span>` por `<app-icon [name]="item.icon" />` en `shared/components/shell/sidebar/sidebar.component.html`
- [x] T006 [US1] Verificar que cada `<a>` del sidebar tiene `[attr.title]="item.label"` y que `[attr.aria-label]="item.label"` está presente para accesibilidad en modo colapsado en `shared/components/shell/sidebar/sidebar.component.html`
- [x] T007 [US1] Actualizar `shared/components/shell/sidebar/sidebar.component.spec.ts` — eliminar cualquier test que referencie `iconEmoji`; agregar test que verifica que el template contiene `app-icon` para cada ítem del menú

**Checkpoint**: Los 11 ítems del menú muestran SVG. Ningún emoji visible. Tests de sidebar pasan.

---

## Phase 4: Historia de Usuario 2 — Colapso manual del sidebar en desktop (P1)

**Goal**: Agregar un botón chevron en el pie del sidebar (solo visible en desktop ≥ 1024px)
que colapsa/expande el menú. El estado se persiste en `localStorage` con la clave
`loopi_sidebar_collapsed`.

**Prueba Independiente**: En desktop, hacer clic en el chevron, cerrar y reabrir el
navegador — el sidebar debe mantener el estado colapsado.

### Implementación HU-2

- [x] T008 [US2] Agregar `readonly sidebarCollapsed: WritableSignal<boolean>` inicializado con `(() => { try { return localStorage.getItem('loopi_sidebar_collapsed') === 'true'; } catch { return false; } })()` y método `toggleCollapse()` con try/catch para `localStorage.setItem` en `shared/components/shell/shell.component.ts`
- [x] T009 [US2] Agregar `@Input() collapsed = false` y `@Output() collapseToggled = new EventEmitter<void>()` en `shared/components/shell/sidebar/sidebar.component.ts`; añadir `EventEmitter` a los imports de `@angular/core`
- [x] T010 [US2] Agregar botón chevron al final del `<ul>` de ítems (antes de cerrar el `<nav>`) en `shared/components/shell/sidebar/sidebar.component.html`: `class="hidden lg:flex items-center justify-center w-full p-3 text-gray-500 hover:bg-gray-100 hover:text-gray-700 border-t border-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"`, `(click)="collapseToggled.emit()"`, `[attr.aria-label]="collapsed ? 'Expandir menú' : 'Colapsar menú'"`, con `<app-icon [name]="collapsed ? 'chevron-right' : 'chevron-left'" />`
- [x] T011 [US2] Agregar `transition-[width] duration-200 ease-in-out` al `<nav>` del sidebar y aplicar `[class.lg:w-16]="collapsed"` y `[class.lg:w-64]="!collapsed"` (reemplazando el `lg:w-64` hardcoded actual) en `shared/components/shell/sidebar/sidebar.component.html`
- [x] T012 [US2] Agregar `[class.lg:hidden]="collapsed"` al `<span>` del label del ítem (el que ya tiene `class="truncate sm:hidden lg:block"`) en `shared/components/shell/sidebar/sidebar.component.html`
- [x] T013 [US2] Pasar `[collapsed]="sidebarCollapsed()"` y `(collapseToggled)="toggleCollapse()"` al elemento `<app-sidebar>` en `shared/components/shell/shell.component.html`
- [x] T014 [P] [US2] Actualizar `shared/components/shell/shell.component.spec.ts` — agregar test que `sidebarCollapsed()` inicia en `false` cuando `localStorage` está vacío; test que `toggleCollapse()` alterna el signal y escribe en `localStorage`; mockear `localStorage` con `spyOn(window.localStorage, 'getItem')`
- [x] T015 [P] [US2] Actualizar `shared/components/shell/sidebar/sidebar.component.spec.ts` — agregar test que cuando `collapsed=true` el texto del ítem tiene clase `lg:hidden`; test que el botón chevron emite el evento `collapseToggled` al hacer clic

**Checkpoint**: El sidebar se colapsa y expande en desktop con animación < 200ms. Estado persiste al recargar. Tests pasan.

---

## Phase 5: Historia de Usuario 3 — Sidebar full-height (P2)

**Goal**: Refactorizar el layout del shell para que el sidebar sea la columna exterior
izquierda que ocupa toda la altura de la ventana (`h-screen`). La topbar y el contenido
van en la columna derecha.

**Prueba Independiente**: En desktop, verificar que el sidebar llega al borde superior
de la ventana (sin espacio de topbar encima) y que el logo "Loopi" aparece dentro del sidebar.

### Implementación HU-3

- [x] T016 [US3] Refactorizar `shared/components/shell/shell.component.html` — cambiar el div raíz de `flex-col` a `flex-row`; el `<app-sidebar>` es el primer hijo directo del div raíz; el segundo hijo es `<div class="flex flex-col flex-1 overflow-hidden">` que contiene `<app-topbar>` y `<main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">` con `<router-outlet />`; eliminar el div intermedio `flex flex-1 overflow-hidden` que envolvía sidebar + main
- [x] T017 [US3] Ajustar la sección de logo en `shared/components/shell/sidebar/sidebar.component.html` — el logo desktop expandido (`hidden lg:flex items-center px-4 py-5`) ahora lleva `border-b border-gray-100`; el logo tablet colapsado (`hidden sm:flex lg:hidden`) también lleva `border-b border-gray-100`; verificar que ambos bloques de logo se ven correctos sin topbar encima
- [x] T018 [US3] Ajustar `shared/components/shell/topbar/topbar.component.html` — eliminar cualquier sección de logo/branding de la topbar (el logo ahora vive en el sidebar); quitar la clase `sticky top-0` del `<header>` (ya no necesaria; la posición la garantiza la estructura flex del shell); verificar que el `border-b border-gray-200` y `shadow-sm` se mantienen
- [x] T019 [P] [US3] Actualizar `shared/components/shell/shell.component.spec.ts` si existen tests que verifican estructura DOM del layout (clases del div raíz, posición del topbar)
- [ ] T020 [US3] Verificación manual de regresión responsive: abrir la app y confirmar mobile (< 640px) — drawer con overlay funciona; tablet (640-1023px) — sidebar `w-16` siempre visible; desktop (≥ 1024px) — sidebar full-height, logo en sidebar, topbar en columna derecha

**Checkpoint**: El sidebar va de tope a fondo en desktop. Responsive mobile/tablet sin regresiones.

---

## Phase 6: Polish y verificación transversal

**Propósito**: Calidad final, build de producción y checklist manual completo.

- [x] T021 [P] Ejecutar `ng test --watch=false` desde `loopi-web/` y resolver cualquier test que falle por los cambios en `IconComponent`, `SidebarComponent` o `ShellComponent`
- [x] T022 [P] Ejecutar `ng build` desde `loopi-web/` y verificar que la build de producción compila sin errores ni warnings relacionados con la feature
- [ ] T023 Ejecutar el checklist manual completo de `specs/017-sidebar-icons-collapse/quickstart.md` — todos los ítems de P1 (íconos y colapso) y P2 (layout full-height) deben estar marcados como verificados

---

## Dependencias y Orden de Ejecución

### Dependencias entre fases

- **Setup (Phase 1)**: Sin dependencias — comenzar inmediatamente
- **Fundacional (Phase 2)**: Depende de Phase 1 — **BLOQUEA** las fases 3 y 4
- **HU-1 (Phase 3)**: Depende de Phase 2 (necesita `IconComponent`)
- **HU-2 (Phase 4)**: Depende de Phase 2 (sidebar necesita `app-icon` para el chevron); puede hacerse en paralelo con Phase 3
- **HU-3 (Phase 5)**: Depende de Phase 4 completada (el layout es sobre el shell con colapso ya integrado); P2 puede posponerse
- **Polish (Phase 6)**: Depende de todas las fases anteriores deseadas

### Dependencias entre historias de usuario

- **HU-1 (P1)**: Puede comenzar tras Phase 2 — sin dependencias con HU-2 o HU-3
- **HU-2 (P1)**: Puede comenzar tras Phase 2 — puede hacerse en paralelo con HU-1; no depende de HU-1
- **HU-3 (P2)**: Conviene hacerse después de HU-2 (el layout refactorizado incluye el colapso integrado); es independiente funcionalmente

### Dentro de cada historia de usuario

- Componente TS modificado antes del template HTML (T004 antes de T005, T009 antes de T010)
- Bindings del padre (`shell.component.html`) al final de la historia, una vez que el hijo (`sidebar`) ya expone sus inputs/outputs

### Oportunidades de paralelismo

- T003 puede hacerse en paralelo con T002 (archivos distintos)
- T014 y T015 pueden hacerse en paralelo (archivos distintos del mismo componente)
- T019 puede hacerse en paralelo con T016-T018
- T021 y T022 pueden ejecutarse en paralelo

---

## Ejemplo de ejecución paralela: Phase 4 (HU-2)

```text
# Paso 1 — secuencial (prerequisito de todo lo demás en HU-2):
T008: shell.component.ts → sidebarCollapsed + toggleCollapse

# Paso 2 — secuencial (prerequisito de T010-T012):
T009: sidebar.component.ts → @Input collapsed + @Output collapseToggled

# Paso 3 — paralelo (tres cambios independientes en el template del sidebar):
T010: sidebar.component.html → botón chevron
T011: sidebar.component.html → clases de transición + ancho dinámico
T012: sidebar.component.html → ocultar texto cuando collapsed
(Nota: son en el mismo archivo — en la práctica, un desarrollador los aplica juntos)

# Paso 4 — secuencial (conectar el parent una vez que el child tiene los inputs/outputs):
T013: shell.component.html → bindings collapsed + collapseToggled

# Paso 5 — paralelo (archivos distintos):
T014: shell.component.spec.ts
T015: sidebar.component.spec.ts
```

---

## Estrategia de Implementación

### MVP (solo HU-1 + HU-2 — P1)

1. Completar Phase 1: Setup
2. Completar Phase 2: Fundacional (`IconComponent`) ← CRÍTICO
3. Completar Phase 3: HU-1 (íconos SVG)
4. **VALIDAR**: íconos correctos en ambas plataformas, tests pasan
5. Completar Phase 4: HU-2 (colapso)
6. **VALIDAR**: colapso + persistencia, tests pasan
7. Completar Phase 6: Polish

### Entrega completa (P1 + P2)

8. Completar Phase 5: HU-3 (layout full-height)
9. **VALIDAR**: sidebar full-height, responsive sin regresiones
10. Completar Phase 6: Polish final

### Notas

- HU-3 (P2) puede mergearse en una PR separada de HU-1+HU-2 (P1) dado que son
  cambios independientes (P1 no toca el layout raíz; P2 sí).
- Confirmar con el equipo si P2 va en el mismo PR o en uno posterior.
- Cada tarea genera un cambio atómico que puede commitearse de forma independiente.
