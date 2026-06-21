# Plan de Implementación: Interfaz Admin y Navegación Global

**Branch**: `016-admin-nav` | **Fecha**: 2026-06-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification desde `specs/016-admin-nav/spec.md`

---

## Resumen

El admin shell es un layout persistente (sidebar + topbar) que envuelve todas las rutas
autenticadas de `loopi-web`. Resuelve el problema inmediato: tras el login, el usuario
no puede navegar entre módulos sin conocer la URL. La implementación es **frontend-only**
(`loopi-web`); no requiere cambios en `loopi-api` más allá de consumir el endpoint
`GET /api/v1/tiendas` ya existente.

El shell adapta su presentación a tres breakpoints (desktop / tablet / móvil), filtra el
menú según el rol JWT del usuario y gestiona el contexto de tienda del admin mediante
Angular Signals.

---

## Contexto Técnico

| Campo | Valor |
|-------|-------|
| **Lenguaje/Versión** | TypeScript 5.x — Angular 19+ (standalone, signals) |
| **Dependencias principales** | @angular/router, Tailwind CSS v4, @angular/common/http |
| **Almacenamiento** | `localStorage` (JWT); `WritableSignal` en memoria (contexto de tienda) |
| **Testing** | Karma/Jasmine (`ng test`); Playwright para flujos P1 |
| **Plataforma destino** | Web SPA — Firebase Hosting (GCP); navegadores modernos |
| **Tipo de proyecto** | Frontend Angular — módulo de shell en `loopi-web` |
| **Metas de rendimiento** | Transición entre rutas < 200ms; apertura de sidebar < 100ms |
| **Restricciones** | Responsive desde 320px; WCAG 2.1 AA; sin librerías de componentes externas; Tailwind CSS v4 únicamente |
| **Escala/Alcance** | 11 módulos en menú; 4 roles; ≤ 20 tiendas en selector |

---

## Verificación de Constitución

*GATE: Debe superarse antes de Phase 0. Re-verificado después de Phase 1.*

| # | Principio | Estado | Nota |
|---|-----------|--------|------|
| I | Spec-First | ✅ | `spec.md` completa y commitada en branch `016-admin-nav` |
| II | Multi-Tienda | ✅ | `StoreContextService` mantiene `tienda_id=null` (consolidado) o tienda explícita; contexto propagado a todos los módulos vía signal |
| III | RBAC | ✅ | `roleGuard` verifica rol en carga de cada ruta protegida; menú filtra ítems por rol; validación normativa sigue en backend (no cambia) |
| IV | Trazabilidad | ✅ | N/A — no hay movimientos de inventario ni stock en esta feature |
| V | Prevención de Pérdidas | ✅ | N/A — no hay operaciones financieras ni de stock |
| VI | Monitoreo Preventivo | ✅ | Feature de UI pura; no hay endpoints críticos nuevos; sección Observabilidad omitida correctamente en spec |
| UI | Diseño de Interfaz §IV | ✅ | Mobile-first (base → sm: → lg:); Tailwind CSS v4; componentes propios en `shared/components/`; WCAG 2.1 AA (ARIA, navegación por teclado) |

**Sin violaciones. Sin registro de complejidad requerido.**

---

## Estructura del Proyecto

### Documentación (esta feature)

```text
specs/016-admin-nav/
├── plan.md           # Este archivo
├── research.md       # Phase 0: decisiones de diseño técnico
├── data-model.md     # Phase 1: tipos TypeScript del dominio de navegación
├── quickstart.md     # Phase 1: guía de implementación
├── contracts/
│   └── ui-shell.md   # Phase 1: contratos de componentes y servicios
└── tasks.md          # Phase 2: generado por /speckit-tasks (no creado aquí)
```

### Código fuente (loopi-web)

Feature exclusiva de `loopi-web`. No requiere cambios en `loopi-api`.

```text
loopi-web/src/app/
├── nav-config.ts                              # Array estático NAV_ITEMS con 11 módulos y roles
├── shared/
│   ├── models/
│   │   └── nav.types.ts                       # Tipos: NavItem, StoreContext, TiendaOpcion, UserSession, Rol
│   ├── components/
│   │   └── shell/
│   │       ├── shell.component.ts             # Layout raíz: sidebar + topbar + router-outlet
│   │       ├── shell.component.html
│   │       ├── shell.component.spec.ts
│   │       ├── sidebar/
│   │       │   ├── sidebar.component.ts       # Menú lateral responsive (colapsable en sm:, oculto en base)
│   │       │   ├── sidebar.component.html
│   │       │   └── sidebar.component.spec.ts
│   │       ├── topbar/
│   │       │   ├── topbar.component.ts        # Cabecera: hamburguesa + store-selector + sesión
│   │       │   ├── topbar.component.html
│   │       │   └── topbar.component.spec.ts
│   │       └── store-selector/
│   │           ├── store-selector.component.ts    # Dropdown tiendas; GET /api/v1/tiendas (solo admin)
│   │           ├── store-selector.component.html
│   │           └── store-selector.component.spec.ts
│   └── services/
│       ├── store-context.service.ts           # WritableSignal<StoreContext>; setTienda(); initFromSession()
│       ├── store-context.service.spec.ts
│       ├── nav-config.service.ts              # computed<NavItem[]> filtrado por rol del usuario activo
│       └── nav-config.service.spec.ts
├── core/
│   └── guards/
│       ├── role.guard.ts                      # Functional guard: verifica rol; redirige si no autorizado
│       └── role.guard.spec.ts
└── app.routes.ts                              # [MODIFICAR] Rutas envueltas en ShellComponent + guards por módulo
```

**Decisión de estructura**: Feature frontend-only. Los componentes del shell son `shared/` porque
son transversales a todos los módulos. Los guards van en `core/` siguiendo la convención Angular de
código de infraestructura sin lógica de dominio específica.

---

## Seguimiento de Complejidad

*No aplica — sin violaciones de constitución.*

---

## Phase 0: Investigación

Ver [research.md](research.md) para el detalle completo. Decisiones principales:

| ID | Decisión |
|----|----------|
| D-01 | `WritableSignal<StoreContext>` en `StoreContextService` (sin NgRx) |
| D-02 | Functional guards (`CanActivateFn`) con `inject()` y array `roles` en `route.data` |
| D-03 | Un único `SidebarComponent` con tres comportamientos CSS por breakpoint (no dos componentes) |
| D-04 | Decode del JWT con `atob` + `JSON.parse` nativo (sin librería) |
| D-05 | Menú definido como array estático `NAV_ITEMS` filtrado por rol en runtime |
| D-06 | `StoreSelectorComponent` llama `GET /api/v1/tiendas?activo=true` una vez por sesión |

---

## Phase 1: Diseño y Contratos

### Artefactos generados

| Artefacto | Descripción |
|-----------|-------------|
| [data-model.md](data-model.md) | Tipos TypeScript: `NavItem`, `StoreContext`, `TiendaOpcion`, `UserSession`, `Rol` + tabla de módulos |
| [contracts/ui-shell.md](contracts/ui-shell.md) | Contratos de componentes (`ShellComponent`, `SidebarComponent`, `TopbarComponent`, `StoreSelectorComponent`), `StoreContextService` y `roleGuard` |
| [quickstart.md](quickstart.md) | Lista de archivos, orden de implementación y checklist de verificación manual |

### Decisiones de diseño clave

**Responsive sidebar** (ver D-03 en research.md):

| Breakpoint | Ancho sidebar | Visibilidad | Trigger |
|------------|---------------|-------------|---------|
| `< 640px` | `w-full` | Oculto (drawer) | Botón hamburguesa en topbar |
| `≥ 640px` (`sm:`) | `w-16` | Siempre visible | — (colapsado a íconos) |
| `≥ 1024px` (`lg:`) | `w-64` | Siempre visible | — (expandido: texto + ícono) |

**Flujo de inicialización**:

```
Login exitoso (001-autenticacion)
  → AuthService.session() != null
  → ShellComponent.ngOnInit()
      → StoreContextService.initFromSession(session)
          → Si admin: StoreContext = { tienda_id: null, nombre: null }
          → Si lider_tienda/barista: StoreContext = { tienda_id: session.tienda_id, nombre: ... }
      → NavConfigService.menuForCurrentUser() → NavItem[] filtrado
      → SidebarComponent renderiza ítems filtrados
```

**Propagación del contexto de tienda**:

Los módulos existentes (inventario, mermas, etc.) leen `StoreContextService.context()` para
incluir `tienda_id` en sus llamadas a la API. Este contrato se define en el plan de cada módulo;
la presente feature establece el servicio y el signal.

---

## Módulos: Asignación de Roles

| Módulo | admin | lider_compras | lider_tienda | barista |
|--------|:-----:|:-------------:|:------------:|:-------:|
| Dashboard | ✓ | ✓ | ✓ | ✓ |
| Tiendas | ✓ | — | — | — |
| Empleados | ✓ | — | — | — |
| Catálogo | ✓ | — | — | — |
| Menú y Recetas | ✓ | — | — | — |
| Inventario | ✓ | — | ✓ | ✓ |
| Mermas | ✓ | — | ✓ | — |
| Pedidos | ✓ | ✓ | ✓ | ✓ |
| Caja Menor | ✓ | — | ✓ | — |
| Ventas / POS | ✓ | — | ✓ | — |
| Demanda | ✓ | ✓ | — | — |

---

## Notas de Implementación

- **No crear backend**: toda la feature vive en `loopi-web`. No hay endpoints nuevos.
- **`app.routes.ts`**: el `ShellComponent` actúa como `component` del layout raíz de rutas autenticadas (patrón Angular nested routes). Las rutas de login/public quedan fuera del shell.
- **Tests requeridos**: `StoreContextService`, `NavConfigService`, `roleGuard` deben tener ≥ 95% de cobertura de lógica. Los componentes de shell necesitan tests unitarios para el filtrado de menú y el toggle de sidebar.
- **Accesibilidad obligatoria**: el sidebar debe soportar navegación completa por teclado (Tab, Enter, Esc para cerrar en móvil).
