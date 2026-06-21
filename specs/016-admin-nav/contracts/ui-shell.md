# Contrato de UI: Shell de Administración

**Feature**: 016-admin-nav
**Fecha**: 2026-06-21

> Los contratos de esta feature son interfaces de componentes Angular y servicios.
> No hay endpoints de backend nuevos (solo se consume `GET /api/v1/tiendas` ya existente).

---

## ShellComponent

Componente raíz que envuelve todas las rutas autenticadas. Implementa el layout completo.

**Selector**: `app-shell`

**Entradas (Inputs)**:

Ninguna — el shell obtiene su estado desde `AuthService` y `StoreContextService` vía `inject()`.

**Salidas (Outputs)**:

Ninguna.

**Responsabilidades**:
- Renderizar `SidebarComponent` y `TopbarComponent`.
- Mantener el signal `sidebarOpen: WritableSignal<boolean>` para el toggle en móvil.
- Exponer `<router-outlet>` para el contenido del módulo activo.
- Redirigir a `/login` si `AuthService.session()` es `null`.

**Layout DOM**:

```
app-shell
├── app-topbar          (cabecera; incluye botón hamburguesa en móvil)
├── app-sidebar         (menú lateral; adapta presentación por breakpoint)
└── <main>
    └── <router-outlet> (contenido del módulo activo)
```

---

## SidebarComponent

Menú lateral responsive con ítems filtrados por rol.

**Selector**: `app-sidebar`

**Inputs**:

```typescript
@Input() isOpen: boolean;   // Controlado por ShellComponent; solo relevante en móvil
```

**Outputs**:

```typescript
@Output() closed = new EventEmitter<void>(); // El usuario cierra el sidebar en móvil (tap fuera o botón X)
```

**Comportamiento responsive**:

| Breakpoint | Clase Tailwind principal | Estado |
|------------|--------------------------|--------|
| `< 640px` (móvil) | `fixed w-full translate-x-[-100%]` | Oculto por defecto; `translate-x-0` cuando `isOpen=true` |
| `≥ 640px` (`sm:`) | `sm:relative sm:w-16 sm:translate-x-0` | Siempre visible, colapsado a íconos |
| `≥ 1024px` (`lg:`) | `lg:w-64` | Siempre visible, expandido con texto + ícono |

**Ítems de menú**: consumidos desde `NavConfigService.menuForCurrentUser()` (computed por rol).

**Estado activo**: detectado comparando `router.url` con `navItem.route` en cada ítem.

**Accesibilidad**:
- `<nav role="navigation" aria-label="Menú principal">`
- Cada ítem: `<a [routerLink]="item.route" [attr.aria-current]="isActive ? 'page' : null">`
- En versión colapsada (solo ícono): `title` y `aria-label` con el nombre del módulo.

---

## TopbarComponent

Cabecera de la aplicación con selector de tienda y datos de sesión.

**Selector**: `app-topbar`

**Inputs**:

```typescript
@Input() sidebarOpen: boolean; // Para ícono hamburguesa activo/inactivo en móvil
```

**Outputs**:

```typescript
@Output() menuToggled = new EventEmitter<void>(); // El usuario pulsa el botón hamburguesa
```

**Contenido**:
- Botón hamburguesa (visible solo en `< 640px`)
- Logo / nombre de la aplicación
- `StoreSelectorComponent` (visible solo si `userSession.rol === 'admin'`)
- Nombre del usuario autenticado + botón de cierre de sesión

---

## StoreSelectorComponent

Dropdown para que el admin seleccione el contexto de tienda.

**Selector**: `app-store-selector`

**No tiene inputs ni outputs**: consume `StoreContextService` y `AuthService` directamente vía `inject()`.

**Comportamiento**:
1. Al inicializarse: llama `GET /api/v1/tiendas?activo=true`. Muestra spinner inline durante la carga (ver constitución §Estados de Carga).
2. Renderiza un `<select>` nativo (accesible por teclado) con opciones:
   - "Vista consolidada" (valor: `null`)
   - `{tienda.nombre}` por cada tienda activa
3. Al cambiar: llama `StoreContextService.setTienda(tienda | null)`.
4. En tablet/móvil: el selector se mueve dentro del sidebar cuando no cabe en la cabecera.

**Contrato con el backend**:

```
GET /api/v1/tiendas?activo=true
Authorization: Bearer {jwt}

Response 200:
{
  "tiendas": [
    { "id": 1, "nombre": "Tienda Norte", "codigo": "TN01" },
    { "id": 2, "nombre": "Tienda Sur",   "codigo": "TS01" }
  ]
}
```

*(Endpoint ya definido en feature 002-gestion-tiendas. No se crea endpoint nuevo.)*

---

## StoreContextService

Servicio singleton que mantiene el contexto de tienda seleccionada.

**Interface**:

```typescript
class StoreContextService {
  // Solo lectura para el resto de la app
  readonly context: Signal<StoreContext>;

  // Solo el admin puede cambiar el contexto
  setTienda(tienda: TiendaOpcion | null): void;

  // Inicializar contexto desde el JWT (para roles no-admin)
  initFromSession(session: UserSession): void;
}
```

**Reglas**:
- `setTienda` solo tiene efecto si el usuario activo tiene rol `admin`. Para cualquier otro rol, la llamada es ignorada silenciosamente.
- `initFromSession` se llama en el `ShellComponent.ngOnInit()` para fijar el contexto de tienda para `lider_tienda` y `barista`.

---

## roleGuard (Functional Guard)

Guard reutilizable para proteger rutas según rol.

**Firma**:

```typescript
// En app.routes.ts:
{
  path: 'tiendas',
  component: TiendasComponent,
  canActivate: [() => roleGuard(['admin'])],
  data: { roles: ['admin'] }
}

// Implementación:
function roleGuard(allowedRoles: Rol[]): boolean | UrlTree {
  const session = inject(AuthService).session();
  const router = inject(Router);

  if (!session) return router.createUrlTree(['/login']);
  if (!allowedRoles.includes(session.rol)) {
    return router.createUrlTree([defaultRouteForRole(session.rol)]);
  }
  return true;
}
```

**Comportamiento en acceso denegado**:
- Sin sesión → `/login`
- Rol insuficiente → ruta principal del rol (ej. `/inventario` para `lider_tienda`, `/dashboard` para `lider_compras`)
