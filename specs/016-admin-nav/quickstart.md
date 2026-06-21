# Guía de Inicio Rápido: Interfaz Admin y Navegación Global

**Feature**: 016-admin-nav
**Fecha**: 2026-06-21

---

## Contexto

Esta feature agrega el **shell de administración** a `loopi-web`: el layout persistente
(sidebar + topbar) que envuelve todas las rutas autenticadas. Es una feature de frontend puro;
no requiere cambios en `loopi-api`.

**Repositorio afectado**: `loopi-web`

---

## Prerrequisitos

- `loopi-web` con Angular 19+ y Tailwind CSS v4 configurados.
- Feature `001-autenticacion` implementada: `AuthService` con `session: Signal<UserSession | null>`.
- Feature `002-gestion-tiendas` con endpoint `GET /api/v1/tiendas` disponible en el backend.

---

## Estructura de archivos a crear/modificar

```text
loopi-web/src/app/
├── shared/
│   ├── components/
│   │   └── shell/
│   │       ├── shell.component.ts          [CREAR]
│   │       ├── shell.component.html        [CREAR]
│   │       ├── shell.component.spec.ts     [CREAR]
│   │       ├── sidebar/
│   │       │   ├── sidebar.component.ts    [CREAR]
│   │       │   ├── sidebar.component.html  [CREAR]
│   │       │   └── sidebar.component.spec.ts [CREAR]
│   │       ├── topbar/
│   │       │   ├── topbar.component.ts     [CREAR]
│   │       │   ├── topbar.component.html   [CREAR]
│   │       │   └── topbar.component.spec.ts [CREAR]
│   │       └── store-selector/
│   │           ├── store-selector.component.ts    [CREAR]
│   │           ├── store-selector.component.html  [CREAR]
│   │           └── store-selector.component.spec.ts [CREAR]
│   └── services/
│       ├── store-context.service.ts        [CREAR]
│       ├── store-context.service.spec.ts   [CREAR]
│       ├── nav-config.service.ts           [CREAR]
│       └── nav-config.service.spec.ts      [CREAR]
├── core/
│   └── guards/
│       ├── role.guard.ts                   [CREAR]
│       └── role.guard.spec.ts              [CREAR]
├── nav-config.ts                           [CREAR] — configuración estática del menú
└── app.routes.ts                           [MODIFICAR] — agregar guards y shell como wrapper
```

---

## Orden de implementación recomendado

1. **Tipos e interfaces** (`UserSession`, `NavItem`, `StoreContext`, `TiendaOpcion`) — pueden vivir en `shared/models/nav.types.ts`.
2. **`nav-config.ts`** — array estático `NAV_ITEMS: NavItem[]` con los 11 módulos.
3. **`StoreContextService`** — signal + `setTienda()` + `initFromSession()`.
4. **`NavConfigService`** — `computed<NavItem[]>` filtrado por rol.
5. **`roleGuard`** — functional guard con `inject(AuthService)`.
6. **`app.routes.ts`** — envolver rutas autenticadas con `ShellComponent` + guards por ruta.
7. **`SidebarComponent`** — menú responsive; estado activo por `router.url`.
8. **`StoreSelectorComponent`** — dropdown de tiendas; llama `GET /api/v1/tiendas?activo=true`.
9. **`TopbarComponent`** — cabecera con hamburguesa + selector de tienda.
10. **`ShellComponent`** — layout raíz que compone sidebar + topbar + `<router-outlet>`.

---

## Verificación rápida

```bash
# Compilación
ng build

# Tests unitarios
ng test --watch=false

# Lint
npm run lint

# Dev server
ng serve
```

**Flujos a verificar manualmente**:

1. Login como `admin` → sidebar visible con los 11 módulos → navegar a cada uno en 1 clic.
2. Login como `admin` → selector de tiendas en cabecera → seleccionar tienda → navegar a Inventario → verificar que muestra datos de esa tienda.
3. Login como `lider_tienda` → sidebar muestra solo: Dashboard, Inventario, Mermas, Pedidos, Caja Menor, Ventas → no aparece selector global de tienda.
4. Intentar acceder directamente a `/tiendas` como `lider_tienda` → redirigido a `/inventario`.
5. Abrir en móvil (< 640px) → sidebar oculto → pulsar hamburguesa → sidebar full-width visible → navegar → sidebar se cierra.
6. Abrir en tablet (640–1023px) → sidebar colapsado a íconos → pulsar ícono de módulo → navega correctamente.

---

## Gates obligatorios antes del PR

Según la constitución:

```bash
ng build                       # Sin errores TypeScript
npm audit --audit-level=high   # Cero vulnerabilidades altas/críticas
gitleaks detect --no-git       # Cero secrets en archivos
ng test --watch=false          # Todos los tests pasan
```
