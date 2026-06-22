# Feature Specification: Sistema de Diseño Loopi v2

**Feature Branch**: `feature/000-design-system`

**Created**: 2026-05-27

**Status**: Cerrada

**Input**: User description: "Adoptar los estilos de loopi v1: paleta café, fuente Inter, 4 utilidades de componentes (btn-primary, btn-secondary, input-field, card) y optimizaciones móviles"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Identidad Visual Consistente (Priority: P1)

Un desarrollador que construye cualquier vista de Loopi v2 necesita
usar tokens de color, tipografía y componentes base que sean
consistentes con la identidad de marca Loopi (tono café, cálido,
profesional) sin depender de decisiones ad-hoc por vista.

**Why this priority**: Sin una base visual unificada, cada pantalla
nueva generará inconsistencias que degradan la experiencia del
usuario y multiplican el tiempo de diseño y corrección.

**Independent Test**: Se puede testear de forma independiente
construyendo la pantalla de login usando únicamente las clases del
design system y verificando que refleja la identidad de marca sin
CSS adicional.

**Acceptance Scenarios**:

1. **Given** un desarrollador crea una vista nueva, **When** aplica
   las clases `btn-primary`, `btn-secondary`, `input-field` y
   `card`, **Then** la vista tiene la paleta café, tipografía Inter
   y dimensiones definidas sin escribir CSS adicional.
2. **Given** la pantalla de login existe, **When** un usuario la
   abre en móvil (320 px) y en escritorio (1280 px), **Then** los
   colores, tipografía y espaciados son idénticos a la guía de
   diseño en ambos tamaños.

---

### User Story 2 - Accesibilidad en Componentes Base (Priority: P2)

Un usuario con discapacidad visual o que navega por teclado debe
poder interactuar con todos los componentes base (botones, campos,
tarjetas) sin barreras.

**Why this priority**: El cumplimiento WCAG 2.1 AA es un requisito
de la constitución y protege la inclusión digital de los usuarios
de tiendas que operan con Loopi.

**Independent Test**: Se puede testear de forma independiente
verificando contraste de color en botones y campos usando una
herramienta de auditoría de accesibilidad, sin necesidad de que
el resto de la aplicación esté implementado.

**Acceptance Scenarios**:

1. **Given** un componente `btn-primary` renderizado, **When** se
   ejecuta una auditoría de contraste WCAG 2.1 AA, **Then** la
   relación de contraste entre texto y fondo es ≥ 4.5:1.
2. **Given** un formulario con `input-field`, **When** el usuario
   navega con teclado (Tab), **Then** cada campo muestra un estado
   de foco visible y el orden de tabulación es lógico.
3. **Given** cualquier componente base, **When** el campo está en
   estado de error, **Then** el mensaje de error es visible en
   texto (no solo color) junto al campo.

---

### User Story 3 - Experiencia Móvil Fluida (Priority: P2)

Un barista o líder de tienda que usa Loopi en su teléfono móvil
debe poder interactuar con formularios y botones con la misma
facilidad que en escritorio, sin pellizcar ni hacer zoom.

**Why this priority**: El uso operacional de Loopi (inventario,
caja, pedidos) ocurre principalmente en dispositivos móviles en
el piso de la tienda.

**Independent Test**: Se puede testear abriendo la pantalla de
login en un dispositivo de 360 px de ancho y verificando que
todos los elementos son interactuables con el dedo sin
desplazamiento horizontal.

**Acceptance Scenarios**:

1. **Given** cualquier vista que use el design system, **When** se
   carga en un dispositivo de 320 px, **Then** no aparece scroll
   horizontal y todos los elementos son accesibles sin zoom.
2. **Given** un botón `btn-primary` en móvil, **When** el usuario
   intenta pulsarlo, **Then** el área táctil es ≥ 44 × 44 px
   según las pautas de accesibilidad móvil.

---

### User Story 4 - Estados de Interacción Predecibles (Priority: P3)

Un usuario que interactúa con la interfaz debe recibir retroalimentación
visual clara en cada acción: hover, foco, carga, error y éxito.

**Why this priority**: Los estados de interacción evitan que el
usuario repita acciones por falta de confirmación visual, lo que
reduce errores operacionales.

**Independent Test**: Se puede testear de forma independiente en
un componente de botón aislado, verificando que exhibe estados
distintos para normal, hover, foco, deshabilitado y carga.

**Acceptance Scenarios**:

1. **Given** un `btn-primary` habilitado, **When** el usuario hace
   hover, **Then** el botón cambia visualmente (oscurece o añade
   sombra) en ≤ 150 ms.
2. **Given** una acción en progreso, **When** el botón está en
   estado de carga, **Then** está deshabilitado y muestra un
   indicador de actividad.
3. **Given** un `input-field` con valor inválido, **When** el
   usuario sale del campo (blur), **Then** el campo muestra borde
   de error y mensaje de texto descriptivo debajo.

---

### Edge Cases

- ¿Qué ocurre si el sistema operativo del dispositivo tiene modo
  oscuro activado? La v1 no contempla dark mode; se asume que la
  v2 tampoco lo requiere en esta iteración.
- ¿Cómo se comportan los componentes si el navegador bloquea la
  carga de la fuente Inter? Se define una cadena de fuentes de
  respaldo (system-ui, sans-serif) para garantizar legibilidad.
- ¿Qué pasa si se necesita un componente que no está en el design
  system? Se construye con las primitivas de Tailwind siguiendo la
  paleta y tipografía definidas, y se propone su inclusión en el
  design system si es reutilizable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema de diseño DEBE proveer una paleta de colores
  de marca basada en tonos café-cálido, definida como tokens (variables
  CSS) reutilizables en toda la aplicación.
- **FR-002**: El sistema de diseño DEBE incluir la fuente Inter como
  tipografía principal, servida de forma autohosteada (archivos `.woff2`
  incluidos en el proyecto, sin dependencia de CDN externo), con una
  cadena de respaldo (system-ui, sans-serif) cuando no esté disponible.
- **FR-003**: El sistema de diseño DEBE proveer la clase utilitaria
  `btn-primary` para la acción principal de cada vista: color de fondo
  de marca, texto blanco, estados hover/foco/deshabilitado/carga.
- **FR-004**: El sistema de diseño DEBE proveer la clase utilitaria
  `btn-secondary` para acciones secundarias: estilo outline — borde
  del color primario, fondo transparente, texto del color primario;
  estados hover/foco/deshabilitado coherentes con la paleta.
- **FR-005**: El sistema de diseño DEBE proveer la clase utilitaria
  `input-field` para campos de formulario: borde sutil, padding
  táctil adecuado, estados normal/foco/error/deshabilitado.
- **FR-006**: El sistema de diseño DEBE proveer la clase utilitaria
  `card` para contenedores de información: fondo blanco, borde suave,
  sombra leve, radio de esquinas consistente.
- **FR-007**: Todos los componentes DEBEN cumplir la relación de
  contraste WCAG 2.1 AA (≥ 4.5:1 para texto normal, ≥ 3:1 para
  texto grande e iconos funcionales).
- **FR-008**: Los componentes DEBEN tener área táctil mínima de
  44 × 44 px en móvil.
- **FR-009**: Los estilos base globales DEBEN establecer: fondo de
  aplicación, color de texto, antialiasing y comportamiento de scroll.
- **FR-010**: El design system DEBE funcionar mobile-first: los estilos
  base son para pantallas ≥ 320 px y se adaptan hacia arriba.

### Key Entities

- **Token de Color**: Variable CSS reutilizable que representa un valor
  de la paleta de marca (ej. color primario, café claro, café oscuro,
  neutros). Cada token tiene un nombre semántico que describe su uso.
- **Utilidad de Componente**: Clase CSS de alto nivel que encapsula la
  apariencia y los estados interactivos de un elemento de interfaz
  (botón, campo, tarjeta). Se aplica directamente en el HTML/template.
- **Token de Tipografía**: Variable CSS que define la familia, tamaño
  y peso de fuente para uso consistente en títulos, cuerpo y etiquetas.
- **Estado de Interacción**: Representación visual de una condición
  del componente (normal, hover, foco, deshabilitado, error, carga).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-002**: El 100% de los componentes base pasa auditoría WCAG
  2.1 AA de contraste de color (herramienta automatizada).
- **SC-003**: Todas las vistas construidas con el design system se
  renderizan correctamente en pantallas de 320 px sin scroll
  horizontal.
- **SC-004**: Cada componente base exhibe los 5 estados de
  interacción (normal, hover, foco, deshabilitado, error/carga)
  verificables visualmente.
- **SC-005**: La fuente Inter carga en menos de 1 segundo en
  conexión estándar; en caso de fallo, la fuente de respaldo
  mantiene la legibilidad sin saltos de diseño (CLS = 0).
- **SC-006**: El tiempo de carga inicial de estilos no supera 50 KB
  en la hoja de estilos compilada.

## Assumptions

- Se adopta como referencia la paleta y componentes de Loopi v1
  (`--color-primary-*`, `--color-coffee-*`) sin cambios estructurales,
  ajustando únicamente lo necesario para Tailwind CSS v4.
- El design system v2 NO incluye dark mode en esta iteración;
  queda registrado como decisión diferida.
- Los componentes se implementan como clases utilitarias de Tailwind
  (via `@utility` o `@layer components`) en el archivo de estilos
  global, no como Web Components ni librerías externas.
- La fuente Inter se sirve de forma autohosteada (archivos `.woff2`
  incluidos en el proyecto); no se usa Google Fonts CDN para evitar
  requests externas y dependencias de terceros.
- Las especificaciones exactas de cada token de color (valores hex)
  se derivan de la paleta documentada en loopi v1 durante la fase
  de planificación.
- Este design system es la base para todas las specs de UI a partir
  de la `001-autenticacion`. La migración de vistas existentes es
  **completa**: los templates de login, logout y cualquier otra vista
  ya implementada deben actualizarse para usar `btn-primary`,
  `input-field`, `card` y demás utilidades del design system en lugar
  de clases Tailwind directas.

## Diseño de Interfaz (UX/UI)

### Paleta de Colores

La paleta se basa en tonos café-cálido de Loopi v1. Los tokens CSS
siguen la escala semántica:

| Token semántico | Descripción de uso |
|---|---|
| `--color-primary` | Color de marca principal (café intenso) |
| `--color-primary-hover` | Estado hover del primario |
| `--color-primary-light` | Fondo claro para áreas de énfasis suave |
| `--color-coffee-*` | Escala de grises cálidos (café claro a oscuro) |
| `--color-surface` | Fondo de tarjetas y paneles |
| `--color-error` | Estado de error en formularios |
| `--color-success` | Confirmación de acciones exitosas |

### Tipografía

- **Fuente principal**: Inter (autohosteada — archivos `.woff2` en el proyecto)
- **Escala**: headings h1–h4, body, label, caption — definidos
  como tokens de tamaño en la configuración de Tailwind
- **Peso**: Regular (400) para cuerpo, Medium (500) para labels,
  Semibold (600) para headings y botones

### Componentes Base

| Componente | Clase | Descripción |
|---|---|---|
| Botón primario | `btn-primary` | Acción principal; fondo primario, texto blanco |
| Botón secundario | `btn-secondary` | Acción secundaria; contorno primario |
| Campo de formulario | `input-field` | Input y textarea; borde suave, padding táctil |
| Tarjeta | `card` | Contenedor de información; fondo blanco, sombra leve |

### Responsive

- Mobile-first: breakpoints estándar Tailwind (`sm`: 640 px,
  `md`: 768 px, `lg`: 1024 px)
- Mínimo soportado: 320 px de ancho
- Sin scroll horizontal en ningún breakpoint

### Accesibilidad

- Contraste WCAG 2.1 AA en todos los componentes
- Navegación por teclado: Tab order lógico, estados de foco visibles
- Errores de campo: texto descriptivo (no solo color)
- Área táctil móvil: ≥ 44 × 44 px

## Clarifications

### Session 2026-05-27

- Q: ¿Debe el design system incluir dark mode? → A: No en esta iteración; queda como decisión diferida.
- Q: ¿Los componentes se implementan como utilidades Tailwind o como librerías de componentes? → A: Utilidades Tailwind en hoja de estilos global (`@utility`/`@layer components`).
- Q: ¿La fuente Inter se carga desde CDN o se sirve localmente? → A: Se decide en la fase de planificación según las restricciones de rendimiento y privacidad.

### Session 2026-05-28

- Q: ¿Qué nivel de migración aplica a las vistas ya implementadas (001-autenticacion)? → A: Migración completa — los templates de login/logout se actualizan para usar btn-primary, input-field, card en lugar de clases Tailwind directas.
- Q: ¿Qué estilo visual tendrá btn-secondary? → A: Outline — borde del color primario, fondo transparente, texto del color primario.
- Q: ¿Desde dónde se carga la fuente Inter? → A: Self-hosted — archivos .woff2 incluidos en el proyecto; sin Google Fonts CDN.

---

## Componentes Angular Transversales

### Filosofía de Implementación

Los componentes son **standalone**, usan **signals** de Angular 17+ para estado interno y
siguen el principio de **una responsabilidad**: cada componente resuelve exactamente un
problema de UX. La composición de componentes pequeños produce las vistas de lista y
formulario — no hay componentes monolíticos con decenas de inputs.

**Regla de oro**: si un feature necesita un listado, badge de estado, filtro o paginación,
DEBE usar los componentes de este catálogo. Crear una re-implementación ad-hoc es una
violación del principio de consistencia. Si el componente existente no cubre el caso,
extenderlo con un `@Input()` nuevo y actualizar esta spec.

---

### FilterStateService

**Propósito**: Almacena el estado de filtros por ruta durante la sesión. Cuando el usuario
navega de un listado a un formulario y regresa, sus filtros se preservan. Las instancias
con default Estado=Activo se inicializan a partir de las `FilterDefinition`.

**Ubicación**: `loopi-web/src/app/shared/services/filter-state.service.ts`

**Idea superadora**: el servicio usa signals de Angular y está keyed por `router.url`, de
modo que los filtros se preservan por ruta sin necesidad de que el componente padre gestione
el estado — simplemente inyecta el servicio y lee la señal.

**Modelos** (`loopi-web/src/app/shared/models/filter.model.ts`):

```typescript
export interface FilterOption {
  value: unknown;
  label: string;
}

export interface FilterDefinition {
  key: string;
  label: string;
  defaultValue: unknown;
  options?: FilterOption[];
}

export type ActiveFilters = Record<string, unknown>;

export interface ColumnDef {
  field: string;
  header: string;
  width?: string;
}

export interface BreadcrumbItem {
  label: string;
  route?: string;
}
```

**API pública del servicio**:

```typescript
@Injectable({ providedIn: 'root' })
export class FilterStateService {
  // Devuelve señal computada con los filtros activos para la ruta
  getActiveFilters(routeKey: string): Signal<ActiveFilters>;

  // Actualiza un filtro específico y persiste en el mapa de señales
  setFilter(routeKey: string, key: string, value: unknown): void;

  // Reinicia los filtros de la ruta aplicando los defaultValue de cada definición
  resetFilters(routeKey: string, definitions: FilterDefinition[]): void;
}
```

**Inicialización**: Al llamar `getActiveFilters` por primera vez para una ruta sin estado
previo, el servicio devuelve un objeto vacío. `FilterBarComponent` llama `resetFilters` en
`ngOnInit` cuando detecta ruta nueva, aplicando los `defaultValue` de cada `FilterDefinition`.

---

### ListCardComponent (`app-list-card`)

**Propósito**: Provee la capa 2 (card blanca) de la jerarquía visual de listados.
Es el wrapper estructural obligatorio de toda vista de lista.

**Ubicación**: `loopi-web/src/app/shared/components/list-card/`

**Inputs**: Ninguno — es puramente estructural.

**Clases aplicadas al host**: `bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden w-full`

**Uso**:

```html
<app-list-card>
  <app-filter-bar [filters]="filterDefs" [routeKey]="routeKey" (filtersChange)="onFilters($event)" />
  <app-data-table [columns]="cols" [rows]="rows()" (rowClick)="onRow($event)">
    <ng-template appCellTemplate="estado" let-row>
      <app-status-badge [activo]="row.activo" />
    </ng-template>
  </app-data-table>
  @if (!rows().length) {
    <app-empty-state title="..." actionLabel="..." (action)="onCreate()" />
  }
  <app-pagination [page]="page()" [total]="total()" (pageChange)="onPage($event)" />
</app-list-card>
```

---

### FilterBarComponent (`app-filter-bar`)

**Propósito**: Barra de filtros con chip pattern. Muestra filtros activos como pills removibles
y emite cambios para que el componente padre actualice la consulta al servidor.

**Ubicación**: `loopi-web/src/app/shared/components/filter-bar/`

**Inputs**:

| Input | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `filters` | `FilterDefinition[]` | Sí | Definiciones de filtros con valores por defecto |
| `routeKey` | `string` | Sí | Clave de ruta para `FilterStateService` (pasar `router.url`) |

**Outputs**:

| Output | Tipo | Descripción |
|--------|------|-------------|
| `filtersChange` | `EventEmitter<ActiveFilters>` | Emite al agregar, cambiar o quitar un filtro |

**Comportamiento**:

- En `ngOnInit`: carga estado desde `FilterStateService`. Si no hay estado para la ruta,
  aplica los `defaultValue` de cada `FilterDefinition` via `resetFilters`.
- Al remover un chip: si el filtro tiene `defaultValue`, vuelve al default en lugar de
  eliminarse. Los filtros sin default desaparecen al quitarlos.
- El chip de Estado=Activo se muestra con estilo azul (`bg-blue-100 text-blue-700
  border border-blue-200 rounded-full`); es visible de inmediato al cargar la vista.

**Ejemplo de definición de filtros** (en el componente padre):

```typescript
readonly filterDefs: FilterDefinition[] = [
  {
    key: 'estado',
    label: 'Estado',
    defaultValue: 'activo',
    options: [
      { value: 'activo', label: 'Activos' },
      { value: 'inactivo', label: 'Inactivos' },
      { value: 'todos', label: 'Todos' },
    ],
  },
];
```

---

### StatusBadgeComponent (`app-status-badge`)

**Propósito**: Badge visual para el campo `activo` de cualquier entidad. Único punto de
definición de los colores verde/gris para estado activo/inactivo en todo el sistema.

**Ubicación**: `loopi-web/src/app/shared/components/status-badge/`

**Inputs**:

| Input | Tipo | Descripción |
|-------|------|-------------|
| `activo` | `boolean` | Estado del registro |

**Renderizado**:

- `activo = true` → pill `bg-green-100 text-green-700` con texto "Activo"
- `activo = false` → pill `bg-gray-100 text-gray-500` con texto "Inactivo"

---

### DataTableComponent (`app-data-table`)

**Propósito**: Tabla genérica con filas clickeables, deemphasis automático de filas inactivas
y soporte de cell templates para renderizado personalizado por columna.

**Ubicación**: `loopi-web/src/app/shared/components/data-table/`

**Inputs**:

| Input | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `columns` | `ColumnDef[]` | — | Definición de columnas (field, header, width opcional) |
| `rows` | `T[]` | — | Array de datos a mostrar |
| `trackByField` | `string` | `'id'` | Campo usado en `trackBy` |

**Outputs**:

| Output | Tipo | Descripción |
|--------|------|-------------|
| `rowClick` | `EventEmitter<T>` | Emite el objeto de la fila al hacer clic o Enter |

**Idea superadora — Cell Template directive (`appCellTemplate`)**:
Para columnas con renderizado personalizado, el padre declara `<ng-template>` con la directiva
y el nombre de la columna en lugar de pasar funciones de renderizado como JSON. Esto permite
usar componentes Angular dentro de celdas (badges, formatted dates, links, etc.) con pleno
soporte de change detection y DX familiar de Angular:

```html
<app-data-table [columns]="columns" [rows]="tiendas()" (rowClick)="onRow($event)">
  <!-- Columna con renderizado personalizado -->
  <ng-template appCellTemplate="estado" let-row>
    <app-status-badge [activo]="row.activo" />
  </ng-template>
  <!-- Las demás columnas sin ng-template muestran el valor del campo como texto -->
</app-data-table>
```

**Comportamiento automático**:

- Las filas donde `row.activo === false` reciben `class="opacity-60"` automáticamente.
  El badge dentro de la fila NO hereda la opacity (es un elemento hijo con opacity propia).
- Cada `<tr>` lleva `tabindex="0"`, `role="button"`, `(keydown.enter)` para accesibilidad.
- El componente NO gestiona paginación — delega en `PaginationComponent`.

---

### EmptyStateComponent (`app-empty-state`)

**Propósito**: Estado vacío obligatorio para toda lista sin resultados.

**Ubicación**: `loopi-web/src/app/shared/components/empty-state/`

**Inputs**:

| Input | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `title` | `string` | Sí | Mensaje principal en primera persona |
| `description` | `string` | No | Texto de apoyo explicativo |
| `actionLabel` | `string` | No | Texto del botón de acción sugerida |
| `icon` | `string` | No | Nombre del ícono en `app-icon` |

**Outputs**:

| Output | Tipo | Descripción |
|--------|------|-------------|
| `action` | `EventEmitter<void>` | Emite al hacer clic en el botón de acción |

---

### PaginationComponent (`app-pagination`)

**Propósito**: Controles de navegación server-side entre páginas de un listado.

**Ubicación**: `loopi-web/src/app/shared/components/pagination/`

**Inputs**:

| Input | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `page` | `number` | — | Página actual (1-based) |
| `pageSize` | `number` | `20` | Registros por página |
| `total` | `number` | — | Total de registros en el servidor |

**Outputs**:

| Output | Tipo | Descripción |
|--------|------|-------------|
| `pageChange` | `EventEmitter<number>` | Emite el número de página solicitada |

---

### PageHeaderComponent (`app-page-header`)

**Propósito**: Encabezado de vista con `<h1>`, breadcrumb opcional y slot para acción primaria.
Aplica la regla "un `<h1>` único y descriptivo por vista" de la constitución.

**Ubicación**: `loopi-web/src/app/shared/components/page-header/`

**Inputs**:

| Input | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `title` | `string` | Sí | Texto del `<h1>` de la vista |
| `breadcrumb` | `BreadcrumbItem[]` | No | Items del breadcrumb `[{label, route?}]` |

**Slots (ng-content)**:

- `[slot="actions"]` — botones de acción primaria (ej. `<button class="btn-primary">+ Nueva tienda</button>`)

---

### FormCardComponent (`app-form-card`)

**Propósito**: Card blanca para formularios de creación y edición. Provee la capa 2 de la
jerarquía visual de formularios con el ancho correcto según la densidad del formulario.

**Ubicación**: `loopi-web/src/app/shared/components/form-card/`

**Inputs**:

| Input | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `size` | `'sm' \| 'md' \| 'lg'` | `'md'` | Ancho: sm=`max-w-lg`, md=`max-w-2xl`, lg=`max-w-4xl` |

**Slots (ng-content)**:

- Default — contenido del formulario
- `[slot="danger-zone"]` — sección destructiva; se renderiza al pie con `<hr>` separador

---

### ReadonlyFieldComponent (`app-readonly-field`)

**Propósito**: Muestra un campo no editable con label y valor, aplicando los estilos de
read-only que comunican al usuario que el campo no puede modificarse.

**Ubicación**: `loopi-web/src/app/shared/components/readonly-field/`

**Inputs**:

| Input | Tipo | Descripción |
|-------|------|-------------|
| `label` | `string` | Label del campo |
| `value` | `string \| null \| undefined` | Valor a mostrar (null/undefined → "–") |

**Renderizado**: Label con `LockClosedIcon` (14 px, `text-gray-400`) + `<div>` con
`bg-gray-100 border border-gray-200 text-gray-500 rounded-lg px-3 py-2 cursor-not-allowed`.

---

### DangerZoneComponent (`app-danger-zone`)

**Propósito**: Implementación del concepto "Zona de precaución" de la constitución.
Sección para acciones destructivas (inactivar, eliminar) al pie de formularios de edición.

**Ubicación**: `loopi-web/src/app/shared/components/danger-zone/`

**Inputs**:

| Input | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `title` | `string` | `'Zona de precaución'` | Título de la sección |

**Slots (ng-content)**: botones de acción destructiva y textos de impacto en lenguaje de usuario.

**Renderizado**: `<div class="mt-8 pt-6 border-t-2 border-red-200 bg-red-50/30 rounded-b-xl p-6">`

---

### Estructura de Archivos

```text
loopi-web/src/app/shared/
├── components/
│   ├── danger-zone/
│   │   ├── danger-zone.component.ts
│   │   ├── danger-zone.component.html
│   │   └── danger-zone.component.spec.ts
│   ├── data-table/
│   │   ├── cell-template.directive.ts
│   │   ├── data-table.component.ts
│   │   ├── data-table.component.html
│   │   └── data-table.component.spec.ts
│   ├── empty-state/
│   ├── filter-bar/
│   ├── form-card/
│   ├── list-card/
│   ├── page-header/
│   ├── pagination/
│   ├── readonly-field/
│   └── status-badge/
├── models/
│   └── filter.model.ts
└── services/
    └── filter-state.service.ts
```

Todo componente DEBE tener su `*.spec.ts` con cobertura ≥ 90% (gate de infraestructura).

### Requisitos de la nueva sección

- **FR-011**: Todo componente de este catálogo DEBE ser `standalone: true` y usar signals
  (`Signal`, `computed`, `effect`) para estado interno en lugar de propiedades mutables.
- **FR-012**: `DataTableComponent` DEBE exponer la directiva `appCellTemplate` como API
  pública. Los paths SVG de celdas personalizadas se agregan via ng-template, no via callbacks.
- **FR-013**: `FilterBarComponent` DEBE coordinar con `FilterStateService` para persistir
  el estado de filtros por ruta durante la sesión de usuario.
- **FR-014**: `FilterStateService` DEBE inicializar los filtros con los `defaultValue` de
  cada `FilterDefinition` cuando la ruta no tiene estado previo, garantizando que el filtro
  Estado=Activo esté activo al cargar cualquier listado por primera vez.
