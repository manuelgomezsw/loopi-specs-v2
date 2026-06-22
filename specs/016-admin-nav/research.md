# Investigación: Interfaz Admin y Navegación Global

**Feature**: 016-admin-nav
**Fecha**: 2026-06-21

---

## D-01 — State management para contexto de tienda

**Decisión**: `WritableSignal<StoreContext>` en un servicio Angular singleton (`StoreContextService`).

**Justificación**: La constitución exige Angular con signals. Un `WritableSignal` expuesto como `computed()` de solo lectura al resto de la app es la solución idiomática en Angular 17+: reactivo, sin boilerplate de NgRx, sin dependencias externas. El contexto de tienda es un estado de navegación (no de servidor), por lo que no requiere caché ni persistencia entre sesiones.

**Alternativas descartadas**:

- NgRx Store: overhead injustificado para un solo valor de contexto.
- BehaviorSubject (RxJS): válido pero redundante cuando signals ya cubre el caso.
- localStorage para contexto: innecesario; si el usuario recarga, el contexto se puede restaurar desde el JWT o iniciarse en "consolidado".

---

## D-02 — Patrón de route guards para RBAC

**Decisión**: Functional guards (`CanActivateFn`) con `inject()` — un único `roleGuard` factory que recibe el array de roles permitidos como parámetro de ruta (`data.roles`).

**Justificación**: Angular 15+ recomienda functional guards sobre guards basados en clases. El patrón `canActivate: [() => roleGuard(['admin', 'lider_tienda'])]` es composable y testeable sin instanciar clases. El guard lee el claim `rol` del JWT almacenado en `localStorage` y compara contra `route.data['roles']`. Si el rol no está autorizado, redirige a la ruta principal del usuario (no a 403 genérico).

**Alternativas descartadas**:

- Guards basados en clase (`implements CanActivate`): patrón deprecated en Angular 15+.
- Validar permisos solo en el menú (frontend-only): insuficiente — la constitución exige validación en carga de ruta.

---

## D-03 — Patrón de sidebar responsive con Tailwind CSS v4

**Decisión**: Un único `SidebarComponent` con tres comportamientos controlados por clases Tailwind y un `signal<boolean>` de estado (`sidebarOpen`):

| Breakpoint Tailwind | Comportamiento | Clases clave |
|---------------------|---------------|--------------|
| base (< 640px) | Drawer oculto; aparece sobre contenido al pulsar hamburguesa | `fixed inset-y-0 left-0 z-50 w-full sm:hidden` + `translate-x-[-100%]` / `translate-x-0` |
| `sm:` (≥ 640px) | Sidebar colapsado a íconos, ancho fijo `w-16` | `sm:relative sm:flex sm:w-16 sm:translate-x-0` |
| `lg:` (≥ 1024px) | Sidebar expandido con texto + ícono, ancho `w-64` | `lg:w-64` |

El toggle hamburguesa (solo visible en base) actualiza el signal. En `md:` y `lg:` el sidebar es siempre visible (no hay toggle). El `TopbarComponent` en móvil incluye el botón hamburguesa y emite el evento de apertura al `ShellComponent` padre.

**Alternativas descartadas**:

- CDK Overlay de Angular Material: introduce dependencia de componentes externos (prohibido por constitución).
- Dos componentes separados (MobileSidebar + DesktopSidebar): duplica lógica de ítems de menú y estado activo.

---

## D-04 — Lectura del JWT en el frontend Angular

**Decisión**: Decode manual del payload base64 sin librería (`atob` + `JSON.parse`). El `AuthService` (ya existente en 001-autenticacion) expone un `computed<UserSession | null>` que lee el token de `localStorage` y devuelve los claims decodificados.

**Justificación**: El payload JWT es simplemente base64url. `atob(payload.replace(/-/g,'+').replace(/_/g,'/'))` es suficiente. No se necesita `jwt-decode` ni otra librería. El `AuthService` es el único punto que lee del storage; el `ShellComponent` y el `roleGuard` consumen el signal resultante.

**Claims necesarios**: `rol`, `tienda_id` (solo para `lider_tienda`/`barista`), `sub` (user_id), `exp`.

**Alternativas descartadas**:

- `jwt-decode` npm: dependencia innecesaria para un decode simple.
- Llamada al backend para obtener perfil en cada carga: latencia innecesaria; el JWT ya contiene los claims.

---

## D-05 — Configuración del menú por rol

**Decisión**: Archivo de configuración estático `nav-config.ts` con el array completo de `NavItem[]`, cada uno con un campo `roles: Rol[]`. El `NavConfigService` filtra el array según el rol del usuario activo y lo expone como `computed<NavItem[]>`.

**Módulos y roles autorizados**:

| Módulo | Ruta | admin | lider_compras | lider_tienda | barista |
|--------|------|:-----:|:-------------:|:------------:|:-------:|
| Dashboard | `/dashboard` | ✓ | ✓ | ✓ | ✓ |
| Tiendas | `/tiendas` | ✓ | — | — | — |
| Empleados | `/empleados` | ✓ | — | — | — |
| Catálogo | `/catalogo` | ✓ | — | — | — |
| Menú y Recetas | `/menu` | ✓ | — | — | — |
| Inventario | `/inventario` | ✓ | — | ✓ | ✓ |
| Mermas | `/mermas` | ✓ | — | ✓ | — |
| Pedidos | `/pedidos` | ✓ | ✓ | ✓ (recep.) | ✓ (ver) |
| Caja Menor | `/caja-menor` | ✓ | — | ✓ | — |
| Ventas / POS | `/ventas` | ✓ | — | ✓ | — |
| Demanda | `/demanda` | ✓ | ✓ | — | — |

**Alternativas descartadas**:

- Configuración del menú desde el backend (API): añade latencia en carga inicial sin beneficio real; los roles son estáticos y están en el JWT.
- Permisos granulares por acción en el menú: complejidad innecesaria; el menú navega a módulos, los permisos granulares se aplican dentro de cada módulo.

---

## D-06 — Selector de tienda para el rol admin

**Decisión**: El `StoreSelectorComponent` hace `GET /api/v1/tiendas?activo=true` al inicializarse (una sola vez por sesión) y persiste la lista en un signal. El admin ve un `<select>` (o dropdown custom) con "Vista consolidada" + las tiendas activas. Cambiar la selección actualiza el `StoreContextService`.

**Endpoint**: `GET /api/v1/tiendas` — ya definido en feature `002-gestion-tiendas`. No se crea endpoint nuevo.

**Justificación**: La lista de tiendas activas es relativamente estática (≤ 20 tiendas). Cargarla una vez al montar el selector es eficiente. Si una tienda se inactiva durante la sesión, el efecto es mínimo (el módulo activo mostrará "sin datos" o el backend rechazará la tienda_id con 403/404).

**Alternativas descartadas**:

- Recargar lista en cada cambio de módulo: innecesario para datos tan estáticos.
- Hardcodear tiendas: inviable; el número de tiendas es dinámico.
