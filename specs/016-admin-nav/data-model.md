# Modelo de Datos: Interfaz Admin y Navegación Global

**Feature**: 016-admin-nav
**Fecha**: 2026-06-21

> Feature de UI pura. No hay migraciones de base de datos. Los modelos aquí son interfaces
> TypeScript del frontend (`loopi-web`).

---

## Tipos del Dominio de Navegación

### `Rol`

```typescript
type Rol = 'admin' | 'lider_compras' | 'lider_tienda' | 'barista';
```

Valores posibles del claim `rol` en el JWT. Fuente de verdad: constitución §III.

---

### `UserSession`

Estado derivado del JWT decodificado. Expuesto por `AuthService` como `computed<UserSession | null>`.

```typescript
interface UserSession {
  sub: number;          // user_id (del claim JWT)
  rol: Rol;
  tienda_id: number | null; // null para admin y lider_compras
  exp: number;          // Unix timestamp de expiración
}
```

**Reglas**:
- `tienda_id` es `null` para `admin` y `lider_compras`; es un entero positivo para `lider_tienda` y `barista`.
- Si el JWT está ausente, expirado o malformado, `AuthService` retorna `null`.

---

### `NavItem`

Entrada de configuración del menú lateral. Definida estáticamente en `nav-config.ts`.

```typescript
interface NavItem {
  id: string;           // Identificador único, e.g. 'tiendas', 'inventario'
  label: string;        // Texto visible en el menú, e.g. 'Tiendas'
  icon: string;         // Nombre del ícono SVG/heroicon, e.g. 'store'
  route: string;        // Ruta Angular relativa, e.g. '/tiendas'
  roles: Rol[];         // Roles que pueden ver este ítem
  orden: number;        // Posición en el menú (ascendente)
}
```

**Reglas**:
- Cada módulo del sistema tiene exactamente un `NavItem`.
- `roles` nunca está vacío; todo ítem es visible para al menos un rol.
- El `NavConfigService` filtra por `roles.includes(userSession.rol)` para construir el menú renderizado.

---

### `StoreContext`

Estado de selección de tienda del admin. Gestionado por `StoreContextService`.

```typescript
interface StoreContext {
  tienda_id: number | null;  // null = vista consolidada
  nombre: string | null;     // null = 'Vista consolidada'
}

// Valor inicial (por defecto):
const CONSOLIDATED: StoreContext = { tienda_id: null, nombre: null };
```

**Reglas**:
- Solo visible y mutable para el rol `admin`.
- Para `lider_tienda` y `barista`, el contexto está fijo en `{ tienda_id: session.tienda_id, nombre: <nombre de su tienda> }` y no puede cambiar.
- El `StoreContextService` expone el contexto como `Signal<StoreContext>` (solo lectura) y un método `setTienda(tienda: TiendaOpcion | null)` restringido al rol `admin`.

---

### `TiendaOpcion`

Ítem del selector de tiendas del admin. Cargado desde `GET /api/v1/tiendas?activo=true`.

```typescript
interface TiendaOpcion {
  id: number;
  nombre: string;
  codigo: string;
}
```

**Reglas**:
- Solo se cargan tiendas con `activo = true`.
- El selector siempre incluye la opción "Vista consolidada" (`tienda_id: null`) al inicio de la lista.

---

## Configuración Estática: Tabla de Módulos

Definida en `nav-config.ts` (no en base de datos):

| id | label | icon | route | roles | orden |
|----|-------|------|-------|-------|-------|
| `dashboard` | Dashboard | `home` | `/dashboard` | admin, lider_compras, lider_tienda, barista | 1 |
| `tiendas` | Tiendas | `building-storefront` | `/tiendas` | admin | 2 |
| `empleados` | Empleados | `users` | `/empleados` | admin | 3 |
| `catalogo` | Catálogo | `squares-2x2` | `/catalogo` | admin | 4 |
| `menu` | Menú y Recetas | `book-open` | `/menu` | admin | 5 |
| `inventario` | Inventario | `clipboard-document-list` | `/inventario` | admin, lider_tienda, barista | 6 |
| `mermas` | Mermas | `trash` | `/mermas` | admin, lider_tienda | 7 |
| `pedidos` | Pedidos | `shopping-cart` | `/pedidos` | admin, lider_compras, lider_tienda, barista | 8 |
| `caja-menor` | Caja Menor | `banknotes` | `/caja-menor` | admin, lider_tienda | 9 |
| `ventas` | Ventas / POS | `chart-bar` | `/ventas` | admin, lider_tienda | 10 |
| `demanda` | Demanda | `presentation-chart-line` | `/demanda` | admin, lider_compras | 11 |
