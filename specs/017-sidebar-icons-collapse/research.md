# Investigación: Mejoras del Menú Lateral Admin

**Feature**: 017-sidebar-icons-collapse
**Fecha**: 2026-06-21

---

## D-01 — Entrega de íconos SVG sin paquete npm

**Decisión**: Copiar los paths SVG de Heroicons v2 outline directamente en el código fuente
dentro de un componente Angular `IconComponent` usando `@switch (name)`. No se instala
`@heroicons/angular` ni ningún paquete adicional.

**Rationale**: La restricción de la constitución prohíbe librerías de componentes externas.
`@heroicons/angular` es técnicamente un paquete de componentes. La alternativa de paths
inline tiene costo nulo de bundle adicional (los paths SVG equivalen a <1 KB minificados
para 11 íconos) y no introduce ninguna dependencia transitiva.

**Alternativas consideradas**:

- `@heroicons/angular` npm — rechazado por política de "sin librerías de componentes externas".
- SVG sprite (`<symbol>` + `<use>`) — rechazado por complejidad de sincronización del sprite
  y dificultad de colorear con `currentColor` en versiones antiguas de Safari.
- `DomSanitizer` + `[innerHTML]` — rechazado por requerir bypass de seguridad Angular y
  ausencia de type-checking en los nombres de íconos.

---

## D-02 — Estructura interna del componente `IconComponent`

**Decisión**: Template con `@switch (name)` y un `@case` por ícono; `@default` con ícono
de círculo sólido como fallback. El SVG tiene `aria-hidden="true"` ya que el enlace padre
lleva el `aria-label` semántico.

**Rationale**: `@switch` es la construcción Angular más legible para un conjunto cerrado de
valores. El switch está en el template (no en el TypeScript) para facilitar la revisión visual
de cada path SVG sin mezclar lógica de componente con datos de presentación.

**Alternativas consideradas**:

- Record<string, string> de paths en TypeScript + `[innerHTML]` — rechazado (ver D-01).
- Archivo de constantes importado por el componente — viable pero agrega un nivel de
  indirección sin beneficio real; los paths SVG pertenecen naturalmente al componente de íconos.

---

## D-03 — Dónde vive el signal `sidebarCollapsed`

**Decisión**: `WritableSignal<boolean>` en `ShellComponent` (misma ubicación que el `sidebarOpen`
existente). Se inicializa leyendo `localStorage` en el constructor con un try/catch silencioso.

**Rationale**: Mantener ambos estados de sidebar en `ShellComponent` es consistente con el
patrón de 016-admin-nav. `ShellComponent` es el orquestador del layout; conocer qué estado
tiene el sidebar es su responsabilidad. Crear un servicio `SidebarStateService` solo para
persistir un booleano sería sobre-ingeniería.

**Alternativas consideradas**:

- Servicio dedicado `SidebarStateService` — rechazado por complejidad innecesaria; un booleano
  de preferencia de UI no justifica un servicio Angular con su ciclo de vida.
- Signal en `SidebarComponent` mismo — rechazado porque el `ShellComponent` necesita el valor
  para ajustar las clases CSS del contenedor de contenido (que no es responsabilidad del sidebar).

---

## D-04 — Refactor de layout (P2): estrategia de migración

**Decisión**: Cambiar el `shell.component.html` de `flex-col` (topbar encima de todo) a
`flex-row` (sidebar a la izquierda como columna raíz). Estructura nueva:

```text
div.flex.h-screen                          ← root: flex-row
├── app-sidebar                            ← columna izquierda full-height
└── div.flex.flex-col.flex-1              ← columna derecha
    ├── app-topbar                         ← cabecera solo en columna derecha
    └── main.flex-1.overflow-y-auto        ← contenido
```

**Rationale**: En el layout actual el sidebar es `sm:relative` dentro de un `flex-row` que
ya es un hijo de `flex-col`. En desktop, el sidebar no llega al tope porque la topbar ocupa
los primeros 64px. Con el nuevo layout, el sidebar es hermano directo de la columna derecha,
arrancando desde el tope del `h-screen` raíz. El sidebar en mobile sigue usando
`fixed inset-y-0 left-0 z-50` (mismo comportamiento).

**Alternativas consideradas**:

- Usar `position: fixed` en el sidebar para desktop — rechazado porque requiere offset manual
  del contenido (`margin-left: 256px`) y no se integra bien con la transición de colapso.
- CSS Grid para el layout — viable pero agrega complejidad sin ventaja real sobre flexbox
  para este caso de dos columnas.

---

## D-05 — Posición y UX del botón de colapso

**Decisión**: El botón de colapso se ubica en el pie del sidebar (después de los ítems de
navegación), visible solo en desktop (lg:). Muestra un ícono chevron que apunta izquierda
cuando expandido (indica "colapsar") y derecha cuando colapsado (indica "expandir").

**Rationale**: La parte inferior del sidebar es el patrón más común en apps de referencia
(Linear, Vercel). No interrumpe el flujo de navegación que empieza arriba. El ícono chevron
es universalmente reconocido como "cerrar/abrir panel lateral". Colocarlo en la parte superior
competiría visualmente con el logo.

**Alternativas consideradas**:

- Botón en el borde derecho del sidebar (overlay sobre el contenido) — rechazado porque cubre
  contenido y su hit-area es pequeña en trackpads.
- Botón en la topbar — rechazado porque la topbar no debería controlar la persistencia de un
  estado de layout que solo afecta al sidebar en desktop.

---

## D-06 — Transición CSS del colapso

**Decisión**: `transition-[width] duration-200 ease-in-out` en el `<nav>` del sidebar.
Ancho expandido: `lg:w-64`; colapsado: `lg:w-16`. El texto de los ítems usa
`overflow-hidden` + `opacity-0` para desvanecerse sin impactar el ancho durante la transición.

**Rationale**: La transición de `width` en Tailwind v4 con la utilidad `transition-[width]`
es la forma más limpia. Los 200ms satisfacen SC-002 (< 200ms). Tailwind v4 soporta valores
arbitrarios en `transition-[...]` sin configuración adicional.

**Alternativas consideradas**:

- `max-width` en lugar de `width` — permite transición más natural en algunos casos pero
  `w-16`/`w-64` con `transition-[width]` es más predecible en este layout flex.
- `transform: translateX` — solo aplica a drawers (mobile); para colapso de columna en desktop
  lo que cambia es el ancho, no la posición.

---

## D-07 — Íconos seleccionados por módulo (Heroicons v2 outline)

Los nombres en `nav-config.ts` ya coinciden con los nombres de Heroicons v2. Mapeo definitivo:

| Módulo | Nombre en `nav-config.ts` | Ícono Heroicons v2 outline |
|--------|--------------------------|---------------------------|
| Dashboard | `home` | `HomeIcon` |
| Tiendas | `building-storefront` | `BuildingStorefrontIcon` |
| Empleados | `users` | `UsersIcon` |
| Catálogo | `squares-2x2` | `Squares2X2Icon` |
| Menú y Recetas | `book-open` | `BookOpenIcon` |
| Inventario | `clipboard-document-list` | `ClipboardDocumentListIcon` |
| Mermas | `trash` | `TrashIcon` |
| Pedidos | `shopping-cart` | `ShoppingCartIcon` |
| Caja Menor | `banknotes` | `BanknotesIcon` |
| Ventas / POS | `chart-bar` | `ChartBarIcon` |
| Demanda | `presentation-chart-line` | `PresentationChartLineIcon` |

Los paths SVG se obtienen de <https://heroicons.com> (versión outline, stroke-width=1.5).
No se modifica `nav-config.ts` — los nombres existentes son correctos.
