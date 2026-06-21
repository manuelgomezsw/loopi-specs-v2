# Tareas: Interfaz Admin y Navegación Global

**Input**: Documentos de diseño en `specs/016-admin-nav/`

**Repositorio afectado**: `loopi-web` (frontend-only; sin cambios en `loopi-api`)

**Historias de usuario**:

- US1 (P1): Admin accede a cualquier módulo desde el menú lateral
- US2 (P1): Admin selecciona tienda desde selector global
- US3 (P2): Lider de tienda y barista ven menú filtrado por rol

## Formato: `[ID] [P?] [Story?] Descripción`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencias incompletas)
- **[Story]**: Historia de usuario a la que pertenece la tarea
- Rutas relativas a `loopi-web/src/app/`

---

## Fase 1: Setup — Tipos e Infraestructura Compartida

**Propósito**: Definir los tipos TypeScript y la configuración estática del menú que todas las
fases siguientes necesitan.

- [X] T001 Crear `shared/models/nav.types.ts` con los tipos: `Rol`, `NavItem`, `StoreContext`, `TiendaOpcion`, `UserSession` (ver data-model.md)
- [X] T002 Crear `nav-config.ts` en `src/app/` con `NAV_ITEMS: NavItem[]` para los 11 módulos del sistema, incluyendo la tabla de roles por módulo (ver data-model.md — tabla de módulos)

**Checkpoint**: Tipos compilables sin errores (`ng build`) — ningún otro archivo los importa aún.

---

## Fase 2: Foundational — Servicios, Guard y Routing Base

**Propósito**: Infraestructura de navegación que bloquea todas las historias de usuario.

**⚠️ CRÍTICO**: Ninguna historia puede comenzar hasta que esta fase esté completa.

- [X] T003 Crear `shared/services/store-context.service.ts` — `WritableSignal<StoreContext>`, método `setTienda(tienda: TiendaOpcion | null)`, método `initFromSession(session: UserSession)` (ver contracts/ui-shell.md — StoreContextService)
- [X] T004 [P] Crear `shared/services/nav-config.service.ts` — `computed<NavItem[]>` que filtra `NAV_ITEMS` según el rol del usuario activo leído desde `AuthService.session()` (ver contracts/ui-shell.md — NavConfigService)
- [X] T005 [P] Crear `core/guards/role.guard.ts` — functional guard `CanActivateFn`; redirige a `/login` si no hay sesión, a la ruta principal del rol si el rol no está en la lista permitida; retorna `true` si autorizado (ver contracts/ui-shell.md — roleGuard)
- [X] T006 Crear `shared/services/store-context.service.spec.ts` — tests unitarios de `StoreContextService`: valor inicial consolidado, `setTienda()` con tienda y con `null`, `initFromSession()` para admin y para lider_tienda, restricción de cambio para roles no-admin (cobertura ≥ 95%)
- [X] T007 [P] Crear `shared/services/nav-config.service.spec.ts` — tests unitarios de `NavConfigService`: filtrado correcto por cada rol (`admin`, `lider_compras`, `lider_tienda`, `barista`), sesión nula devuelve `[]`, orden ascendente por `NavItem.orden` (cobertura ≥ 95%)
- [X] T008 [P] Crear `core/guards/role.guard.spec.ts` — tests unitarios de `roleGuard`: sin sesión → redirige a `/login`; rol no autorizado → redirige a ruta por defecto del rol; rol autorizado → retorna `true` (cobertura ≥ 95%)
- [X] T009 Actualizar `app.routes.ts` — definir layout raíz con `ShellComponent` como `component`, `canActivate: [() => roleGuard(['admin','lider_compras','lider_tienda','barista'])]`, y rutas hijas lazy-loaded para cada módulo (sin guards por ruta aún — se agregan en T019)

**Checkpoint**: `ng build` sin errores; tests de servicios y guard en verde (`ng test --watch=false`).

---

## Fase 3: Historia de Usuario 1 — Admin navega por el menú lateral (P1) 🎯 MVP

**Meta**: Un admin autenticado puede acceder a cualquier módulo del sistema en 1 clic desde el menú lateral, sin conocer la URL.

**Prueba independiente**: Login como `admin` → sidebar visible con los 11 ítems → hacer clic en cada uno → llegar al módulo correcto; el ítem activo queda resaltado.

- [X] T010 [US1] Crear `shared/components/shell/sidebar/sidebar.component.ts` y `.html` — menú lateral con `@Input() isOpen` y `@Output() closed`; ítems desde `NavConfigService.navItems()`; estado activo con `RouterLinkActive`; tres comportamientos responsive: drawer full-width en base, `w-16` íconos en `sm:`, `w-64` texto+ícono en `lg:`; atributos ARIA completos (`role="navigation"`, `aria-label`, `aria-current`) (ver contracts/ui-shell.md — SidebarComponent)
- [X] T011 [US1] Crear `shared/components/shell/topbar/topbar.component.ts` y `.html` — estructura base de la cabecera: `@Output() menuToggled`; botón hamburguesa visible solo en `base` (`sm:hidden`); logo/nombre de app; espacio reservado para `StoreSelectorComponent` (vacío en esta tarea — se agrega en T017)
- [X] T012 [US1] Crear `shared/components/shell/shell.component.ts` y `.html` — layout raíz: `signal<boolean> sidebarOpen`; componer `app-topbar` + `app-sidebar` + `<main><router-outlet>` ; manejar evento `menuToggled` del topbar para toggle del sidebar; llamar `StoreContextService.initFromSession()` en `ngOnInit` (ver contracts/ui-shell.md — ShellComponent)
- [X] T013 [US1] Crear `shared/components/shell/sidebar/sidebar.component.spec.ts` — tests unitarios: renderiza solo los ítems del rol activo, resalta ítem activo, emite `closed` al hacer clic en overlay de móvil, clases CSS correctas por breakpoint
- [X] T014 [P] [US1] Crear `shared/components/shell/shell.component.spec.ts` — tests unitarios: `sidebarOpen` inicia en `false`, toggle correcto al recibir `menuToggled`, `initFromSession()` se llama en init, estructura DOM correcta (topbar + sidebar + outlet)

**Checkpoint**: Historia 1 completa y verificable. Login como admin → sidebar visible con 11 módulos → navegación en 1 clic → ítem activo resaltado → sin recargar la página.

---

## Fase 4: Historia de Usuario 2 — Selector global de tienda (P1)

**Meta**: El admin puede cambiar el contexto de tienda desde un selector en la cabecera; el contexto se mantiene al navegar entre módulos.

**Prueba independiente**: Admin autenticado con ≥ 2 tiendas activas → selector visible en cabecera → "Vista consolidada" por defecto → seleccionar "Tienda Norte" → navegar a Inventario → datos de "Tienda Norte" → cambiar a otra tienda → datos actualizados.

- [X] T015 [US2] Crear `shared/components/shell/store-selector/store-selector.component.ts` y `.html` — consume `StoreContextService` y `AuthService`; llama `GET /api/v1/tiendas?activo=true` al inicializarse; renderiza `<select>` nativo con "Vista consolidada" (null) + tiendas activas; llama `StoreContextService.setTienda()` al cambiar; estado de carga (spinner inline) y error con "Reintentar"; `aria-label="Seleccionar tienda"` (ver contracts/ui-shell.md — StoreSelectorComponent; contrato API en contracts/ui-shell.md)
- [X] T016 [US2] Crear `shared/components/shell/store-selector/store-selector.component.spec.ts` — tests unitarios: carga correcta de tiendas desde HTTP mock, "Vista consolidada" como primera opción, cambio de selección actualiza `StoreContextService`, estado de carga durante petición, estado de error con opción de reintento
- [X] T017 [US2] Actualizar `shared/components/shell/topbar/topbar.component.ts` y `.html` — agregar: `<app-store-selector>` condicional (solo si `userSession.rol === 'admin'`); nombre de tienda fija para `lider_tienda`/`barista`; nombre del usuario autenticado; botón de cierre de sesión que llama `AuthService.logout()`
- [X] T018 [P] [US2] Crear `shared/components/shell/topbar/topbar.component.spec.ts` — tests unitarios: `app-store-selector` visible solo para admin, nombre de tienda fija visible para lider_tienda, hamburguesa visible solo en `base`, evento `menuToggled` emitido al pulsar hamburguesa

**Checkpoint**: Historia 2 completa. Admin → seleccionar tienda → navegar a cualquier módulo → contexto de tienda conservado → cambiar tienda → módulo actualiza.

---

## Fase 5: Historia de Usuario 3 — Menú filtrado por rol (P2)

**Meta**: Lider de tienda y barista ven solo los módulos autorizados; intentar acceder a rutas prohibidas por URL redirige a su módulo principal.

**Prueba independiente**: Login como `lider_tienda` → sidebar muestra Dashboard, Inventario, Mermas, Pedidos, Caja Menor, Ventas (sin Tiendas, Empleados, Catálogo, Menú, Demanda) → intentar navegar a `/tiendas` directamente → redirigido a `/inventario`.

- [X] T019 [US3] Actualizar `app.routes.ts` — agregar `canActivate: [() => roleGuard([...])]` a cada ruta hija según la tabla de roles de `data-model.md`: `/tiendas` solo admin, `/empleados` solo admin, `/catalogo` solo admin, `/menu` solo admin, `/demanda` solo admin y lider_compras, `/inventario` admin + lider_tienda + barista, `/mermas` admin + lider_tienda, `/pedidos` todos, `/caja-menor` admin + lider_tienda, `/ventas` admin + lider_tienda, `/dashboard` todos
- [X] T020 [US3] Crear tests de integración del guard en `core/guards/role.guard.spec.ts` (extender T008) — escenarios adicionales: lider_tienda intenta `/tiendas` → redirige a `/inventario`; barista intenta `/mermas` → redirige a `/inventario`; lider_compras intenta `/tiendas` → redirige a `/dashboard`; admin puede acceder a todos
- [X] T021 [P] [US3] Verificar accesibilidad completa del `SidebarComponent` — navegación por teclado: Tab navega entre ítems, Enter activa la ruta, Esc cierra el drawer en móvil; `aria-expanded` correcto en sidebar colapsado; `title` y `aria-label` en ítems con solo ícono (tablet)
- [X] T022 [P] [US3] Verificar manejo de sesión expirada — confirmar que el `AuthInterceptor` (existente de `001-autenticacion`) captura `401` durante la navegación y redirige a `/login` con mensaje "Tu sesión expiró. Inicia sesión nuevamente." Si el interceptor no existe, crearlo en `core/interceptors/auth.interceptor.ts`

**Checkpoint**: Las tres historias funcionan. Todos los roles ven exactamente los módulos autorizados; acceso directo por URL a rutas prohibidas redirige correctamente.

---

## Fase Final: Polish y Aspectos Transversales

**Propósito**: Pulir la experiencia, cubrir casos límite y validar los gates de CI.

- [X] T023 Completar página de "Sin permiso" (403) en `shared/components/forbidden/forbidden.component.ts` y `.html` — texto "No tienes permiso para ver esto", botón "Volver" que navega a la ruta principal del rol; sin revelar detalles del recurso restringido (ver constitución §Manejo de Errores en UI)
- [X] T024 [P] Verificar estado vacío del selector de tiendas cuando el admin no tiene tiendas activas — el selector muestra solo "Vista consolidada"; no hay error ni selector en blanco
- [X] T025 [P] Validar responsive completo por breakpoint — desktop (≥1024px): sidebar `w-64` siempre visible, sin hamburguesa; tablet (640–1023px): sidebar `w-16` íconos, siempre visible; móvil (<640px): sidebar oculto, hamburguesa en topbar, drawer full-width al abrirse, cierre con ✕ o tap en overlay, Esc key cierra; verificar que nada se rompe en 320px
- [X] T026 Ejecutar gates de CI completos según constitución: `ng build` (sin errores TypeScript), `npm audit --audit-level=high` (cero vulnerabilidades altas/críticas — 3 vulnerabilidades pre-existentes en toolchain de Angular sin fix disponible), `gitleaks detect --no-git` (no disponible en entorno), `ng test --watch=false` (110/110 tests pasan)
- [ ] T027 Ejecutar verificación manual completa según `quickstart.md` — validar los 6 flujos detallados: admin con 11 módulos, selector de tienda, lider_tienda filtrado, acceso directo prohibido, móvil hamburguesa, tablet colapsado

---

## Dependencias y Orden de Ejecución

### Dependencias entre fases

- **Fase 1 (Setup)**: Sin dependencias — puede comenzar de inmediato
- **Fase 2 (Foundational)**: Depende de Fase 1 — **bloquea todas las historias**
- **Fase 3 (US1)**: Depende de Fase 2 completa
- **Fase 4 (US2)**: Depende de Fase 2 completa; puede ejecutarse en paralelo con Fase 3
- **Fase 5 (US3)**: Depende de Fase 3 (sidebar debe existir para verificar filtrado)
- **Fase Final**: Depende de todas las historias completadas

### Dependencias dentro de cada historia

**US1**:

- T010 (Sidebar) y T011 (Topbar base) → paralelo entre sí
- T012 (Shell) → depende de T010 y T011
- T013 y T014 (tests) → paralelo, pueden escribirse antes de T010-T012 si se hace TDD

**US2**:

- T015 (StoreSelectorComponent) independiente de T017 (TopbarComponent update)
- T017 → depende de T015 (necesita el componente para incluirlo)
- T016 y T018 (tests) → paralelo con sus respectivas implementaciones

**US3**:

- T019 (guards en rutas) independiente de T020 (tests de integración)
- T021 y T022 → paralelo entre sí

---

## Oportunidades de Paralelismo

### Ejemplo: Fase 2 (Foundational)

```text
# Pueden ejecutarse en paralelo:
T004 NavConfigService        (archivo distinto de T003 StoreContextService)
T005 roleGuard               (archivo distinto)
T007 tests NavConfigService  (una vez T004 listo)
T008 tests roleGuard         (una vez T005 listo)
```

### Ejemplo: Fase 3 (US1)

```text
# Paralelo inicial:
T010 SidebarComponent
T011 TopbarComponent base

# Luego (después de T010 y T011):
T012 ShellComponent

# Paralelo con T010-T012 o después:
T013 tests Sidebar
T014 tests Shell
```

### Ejemplo: Fases 3 y 4 en paralelo (2 desarrolladores)

```text
Dev A → Fase 3 (US1): T010 → T011 → T012 → T013+T014
Dev B → Fase 4 (US2): T015 → T016 → T017 → T018
```

---

## Estrategia de Implementación

### MVP — Historia 1 únicamente

1. Completar Fase 1 (Setup): T001–T002
2. Completar Fase 2 (Foundational): T003–T009
3. Completar Fase 3 (US1): T010–T014
4. **PARAR Y VALIDAR**: Login como admin → sidebar visible → navegar entre módulos
5. Demo/deploy si está listo

### Entrega Incremental

1. Fase 1 + Fase 2 → Infraestructura lista
2. Fase 3 (US1) → Admin puede navegar (MVP) ✓ Demo
3. Fase 4 (US2) → Admin tiene selector de tienda ✓ Demo
4. Fase 5 (US3) → Todos los roles funcionan ✓ Demo
5. Fase Final → PR listo para merge

---

## Notas

- **[P]** = archivo distinto, sin dependencias incompletas — se puede ejecutar en paralelo
- **[Story]** = trazabilidad con las historias de usuario de la spec
- Cada historia es verificable independientemente antes de avanzar a la siguiente
- Hacer commit después de cada tarea o grupo lógico
- Detenerse en cada **Checkpoint** para validar manualmente antes de continuar
- La feature es **frontend-only** — no crear endpoints ni modificar `loopi-api`
