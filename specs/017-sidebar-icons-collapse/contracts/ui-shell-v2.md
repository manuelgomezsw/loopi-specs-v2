# Contrato de UI: Shell v2 — Íconos, Colapso y Layout Full-Height

**Feature**: 017-sidebar-icons-collapse
**Fecha**: 2026-06-21

> Contrato de componentes Angular. Solo se documentan componentes nuevos o con cambios
> de interfaz respecto a la feature 016-admin-nav.

---

## IconComponent *(nuevo)*

Componente centralizado de íconos SVG. Renderiza el path Heroicons v2 outline
correspondiente al nombre recibido.

**Selector**: `app-icon`

**Input**:

```typescript
@Input({ required: true }) name: string = '';
// Valores válidos: IconName union type
// Fallback: círculo sólido si el nombre no está registrado
```

**Template interno** (esquema):

```html
<svg
  class="h-5 w-5 shrink-0"
  fill="none"
  viewBox="0 0 24 24"
  stroke-width="1.5"
  stroke="currentColor"
  aria-hidden="true"
>
  @switch (name) {
    @case ('home') { <path stroke-linecap="round" stroke-linejoin="round" d="..." /> }
    @case ('building-storefront') { <path ... /> }
    <!-- ... un @case por ícono ... -->
    @default { <circle cx="12" cy="12" r="4" fill="currentColor" /> }
  }
</svg>
```

**Reglas**:

- `aria-hidden="true"` siempre: el ícono es decorativo; el contexto semántico lo da el enlace padre.
- `stroke="currentColor"`: hereda automáticamente el color del texto del elemento padre
  (activo: `text-blue-700`; normal: `text-gray-500`).
- Tamaño fijo `h-5 w-5`: no escala con el `font-size`. Si se necesita otro tamaño, usar
  clases Tailwind vía `[class]` binding en el padre, o definir un `@Input() size`.

**Archivo**: `loopi-web/src/app/shared/components/icon/icon.component.ts`

---

## SidebarComponent *(modificado)*

**Cambios respecto a 016-admin-nav**:

**Inputs nuevos**:

```typescript
@Input() collapsed = false;
// true  → ancho w-16 (solo íconos)
// false → ancho w-64 (ícono + texto) — comportamiento por defecto
```

**Outputs nuevos**:

```typescript
@Output() collapseToggled = new EventEmitter<void>();
// Emitido al hacer clic en el botón chevron (solo desktop)
```

**Comportamiento responsive completo**:

| Breakpoint | Ancho | Estado colapsado (`collapsed=true`) | Estado expandido (`collapsed=false`) |
|------------|-------|--------------------------------------|--------------------------------------|
| `< 640px` (móvil) | `w-64` | N/A (controlled por `isOpen`) | N/A (controlled por `isOpen`) |
| `≥ 640px` (`sm:`) | `w-16` | `sm:w-16` (siempre) | `sm:w-16` (siempre) |
| `≥ 1024px` (`lg:`) | `w-64` o `w-16` | `lg:w-16` | `lg:w-64` |

**Clases de transición en el `<nav>`**:

```text
transition-[width] duration-200 ease-in-out
```

**Botón de colapso** (solo visible en `lg:`):

```html
<button
  type="button"
  class="hidden lg:flex items-center justify-center w-full p-3 text-gray-500
         hover:bg-gray-100 hover:text-gray-700 border-t border-gray-100
         focus:outline-none focus:ring-2 focus:ring-blue-500"
  (click)="collapseToggled.emit()"
  [attr.aria-label]="collapsed ? 'Expandir menú' : 'Colapsar menú'"
>
  <!-- Chevron izquierdo cuando expandido, derecho cuando colapsado -->
  <app-icon [name]="collapsed ? 'chevron-right' : 'chevron-left'" />
</button>
```

**Ítems de menú — cambio en el ícono**:

```html
<!-- Antes (016): -->
<span>{{ iconEmoji(item.icon) }}</span>

<!-- Después (017): -->
<app-icon [name]="item.icon" />
```

**Texto de los ítems** — la clase cambia para incluir `collapsed`:

```html
<!-- Texto oculto cuando colapsado en desktop, visible en mobile y expandido -->
<span class="truncate sm:hidden lg:block" [class.lg:hidden]="collapsed">
  {{ item.label }}
</span>
```

**Método eliminado**: `iconEmoji(icon: string): string` — ya no existe en 017.

---

## ShellComponent *(modificado)*

**Cambios respecto a 016-admin-nav**:

**Signal nuevo**:

```typescript
readonly sidebarCollapsed: WritableSignal<boolean> = signal<boolean>(
  (() => {
    try {
      return localStorage.getItem('loopi_sidebar_collapsed') === 'true';
    } catch {
      return false;
    }
  })()
);
```

**Método nuevo**:

```typescript
toggleCollapse(): void {
  const next = !this.sidebarCollapsed();
  this.sidebarCollapsed.set(next);
  try {
    localStorage.setItem('loopi_sidebar_collapsed', String(next));
  } catch { /* localStorage no disponible — estado en memoria únicamente */ }
}
```

**Template — layout P2** (nueva estructura `flex-row` en la raíz):

```html
<!-- ANTES (016): flex-col raíz con topbar arriba -->
<div class="flex h-screen flex-col overflow-hidden bg-gray-50">
  <app-topbar ... />
  <div class="flex flex-1 overflow-hidden">
    <app-sidebar ... />
    <main>...</main>
  </div>
</div>

<!-- DESPUÉS (017): flex-row raíz con sidebar como columna exterior -->
<div class="flex h-screen overflow-hidden bg-gray-50">
  <app-sidebar
    [isOpen]="sidebarOpen()"
    [collapsed]="sidebarCollapsed()"
    (closed)="closeSidebar()"
    (collapseToggled)="toggleCollapse()"
  />
  <div class="flex flex-col flex-1 overflow-hidden">
    <app-topbar [sidebarOpen]="sidebarOpen()" (menuToggled)="toggleSidebar()" />
    <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
      <router-outlet />
    </main>
  </div>
</div>
```

---

## TopbarComponent *(modificado — P2)*

**Cambios respecto a 016-admin-nav**:

- El logo/nombre de la aplicación ("Loopi") se **elimina** de la topbar — pasa al sidebar.
- La topbar queda: `[hamburguesa móvil] [store-selector o nombre-tienda] [spacer] [usuario + logout]`.
- En el nuevo layout P2, la topbar ya no es `sticky top-0` (es un flex-child normal dentro
  de su columna); su posición fija la garantiza la estructura flex del layout.

**Nuevo header de la topbar** (esquema):

```html
<header class="flex h-16 items-center gap-4 border-b border-gray-200 bg-white px-4 shadow-sm">
  <!-- Hamburguesa: solo móvil -->
  <button class="sm:hidden" ...>...</button>

  <!-- Selector de tienda (admin) o nombre-tienda (lider_tienda/barista) -->
  @if (esAdmin()) { <app-store-selector /> }
  @else if (...) { <span>Tienda #{{ ... }}</span> }

  <div class="flex-1"></div>

  <!-- Usuario + logout -->
  <div class="flex items-center gap-3">...</div>
</header>
```

---

## SidebarComponent — Sección logo en P2

En el nuevo layout, el sidebar incluye una sección de branding en la parte superior
visible en desktop:

```html
<!-- Logo desktop expandido (lg: sin collapsed) -->
<div class="hidden lg:flex items-center px-4 py-5 border-b border-gray-100">
  <span class="text-xl font-bold text-blue-600">Loopi</span>
</div>
<!-- Logo desktop colapsado -->
<div class="hidden lg:flex items-center justify-center py-5 border-b border-gray-100"
     [class.lg:hidden]="!collapsed">
  <span class="text-xl font-bold text-blue-600">L</span>
</div>
```

*Nota*: El logo en mobile y tablet no cambia — la sección de cabecera mobile del sidebar
existente ya lo maneja.
