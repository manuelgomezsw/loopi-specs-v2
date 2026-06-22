# Plan de Implementación: Mejoras del Menú Lateral Admin

**Branch**: `017-sidebar-icons-collapse` | **Fecha**: 2026-06-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification desde `specs/017-sidebar-icons-collapse/spec.md`

---

## Resumen

El menú lateral del shell admin requiere tres mejoras: (1) reemplazar los emojis por íconos
SVG Heroicons v2 outline centralizados en un nuevo componente `app-icon`; (2) agregar colapso
manual en desktop con persistencia en `localStorage`; (3) refactorizar el layout del shell
para que el sidebar sea la columna exterior full-height (patrón moderno: sidebar ocupa
`h-screen` completo, topbar y contenido van en la columna derecha). La implementación es
**frontend-only** en `loopi-web`; no requiere cambios en `loopi-api`.

Las mejoras P1 (íconos + colapso) y P2 (layout full-height) son independientes y pueden
mergearse por separado.

---

## Contexto Técnico

| Campo | Valor |
|-------|-------|
| **Lenguaje/Versión** | TypeScript 5.x — Angular 19+ (standalone, signals) |
| **Dependencias principales** | `@angular/router`, Tailwind CSS v4 |
| **Almacenamiento** | `localStorage` (preferencia de colapso); sin cambios en JWT/sesión |
| **Testing** | Karma/Jasmine (`ng test`) |
| **Plataforma destino** | Web SPA — Firebase Hosting (GCP); navegadores modernos |
| **Tipo de proyecto** | Frontend Angular — modificaciones al shell en `loopi-web` |
| **Metas de rendimiento** | Transición colapso/expansión < 200ms |
| **Restricciones** | Responsive desde 320px; WCAG 2.1 AA; sin librerías de componentes externas; Tailwind CSS v4 únicamente |
| **Escala/Alcance** | 11 módulos en menú; 1 nuevo componente; 4 archivos modificados (P1) + 3 adicionales (P2) |

---

## Verificación de Constitución

*GATE: Debe superarse antes de Phase 0. Re-verificado después de Phase 1.*

| # | Principio | Estado | Nota |
|---|-----------|--------|------|
| I | Spec-First | ✅ | `spec.md` completa y commitada en branch `017-sidebar-icons-collapse` |
| II | Multi-Tienda | ✅ | N/A — no hay datos operacionales en esta feature |
| III | RBAC | ✅ | N/A — no se modifican permisos ni guards; el filtrado de menú por rol ya implementado en 016 no cambia |
| IV | Trazabilidad | ✅ | N/A — no hay movimientos de inventario ni stock |
| V | Prevención de Pérdidas | ✅ | N/A — no hay operaciones financieras ni de stock |
| VI | Monitoreo Preventivo | ✅ | Feature de UI pura; no hay endpoints críticos nuevos |
| UI | Diseño de Interfaz §IV | ✅ | Mobile-first (base → sm: → lg:); Tailwind CSS v4; componentes propios; WCAG 2.1 AA (aria-label en íconos); `app-icon` en `shared/components/` |

**Sin violaciones. Sin registro de complejidad requerido.**

---

## Estructura del Proyecto

### Documentación (esta feature)

```text
specs/017-sidebar-icons-collapse/
├── plan.md              # Este archivo
├── research.md          # Phase 0: decisiones técnicas de diseño
├── data-model.md        # Phase 1: tipos TypeScript y estado de UI
├── quickstart.md        # Phase 1: orden de implementación y checklist manual
├── contracts/
│   └── ui-shell-v2.md  # Phase 1: contratos de componentes modificados y nuevos
└── tasks.md             # Phase 2: generado por /speckit-tasks (no creado aquí)
```

### Código fuente (loopi-web)

Feature exclusiva de `loopi-web`. No requiere cambios en `loopi-api`.

```text
loopi-web/src/app/
├── shared/
│   └── components/
│       ├── icon/
│       │   ├── icon.component.ts          # NUEVO — app-icon: @switch con paths Heroicons v2 + fallback
│       │   └── icon.component.spec.ts     # NUEVO — tests de renderizado por nombre
│       └── shell/
│           ├── shell.component.ts         # MODIFICAR — + sidebarCollapsed signal + toggleCollapse() + localStorage
│           ├── shell.component.html       # MODIFICAR — P2: layout flex-row raíz (sidebar como columna exterior)
│           ├── shell.component.spec.ts    # MODIFICAR — + tests sidebarCollapsed, toggleCollapse, persistencia
│           ├── sidebar/
│           │   ├── sidebar.component.ts   # MODIFICAR — + @Input() collapsed + @Output() collapseToggled; elimina iconEmoji()
│           │   ├── sidebar.component.html # MODIFICAR — usa app-icon; + botón chevron; texto condicional al colapso
│           │   └── sidebar.component.spec.ts  # MODIFICAR — + tests collapsed; actualiza tests de ícono
│           └── topbar/
│               ├── topbar.component.html  # MODIFICAR (P2) — eliminar logo; ajustar para layout sin sticky
│               └── topbar.component.spec.ts   # MODIFICAR (P2) — si había test del logo
```

**Decisión de estructura**: Nuevo componente `icon/` en `shared/components/` porque es
transversal a todos los módulos. Su selector `app-icon` podrá usarse en cualquier vista
futura sin depender del sidebar.

---

## Seguimiento de Complejidad

*No aplica — sin violaciones de constitución.*

---

## Phase 0: Investigación

Ver [research.md](research.md) para el detalle completo. Decisiones principales:

| ID | Decisión |
|----|----------|
| D-01 | SVG paths Heroicons v2 inline — sin paquete npm |
| D-02 | `@switch (name)` en template del `IconComponent` |
| D-03 | `sidebarCollapsed` `WritableSignal` en `ShellComponent` + try/catch `localStorage` |
| D-04 | Refactor P2: `flex-row` raíz con sidebar como primera columna |
| D-05 | Botón chevron en el pie del sidebar, solo `lg:` |
| D-06 | `transition-[width] duration-200 ease-in-out` en el `<nav>` del sidebar |
| D-07 | Mapeo completo de 11 módulos → Heroicons v2 outline (nombres ya coinciden con nav-config.ts) |

---

## Phase 1: Diseño y Contratos

### Artefactos generados

| Artefacto | Descripción |
|-----------|-------------|
| [data-model.md](data-model.md) | Tipo `IconName`, modificación opcional de `NavItem.icon`, estado `localStorage` |
| [contracts/ui-shell-v2.md](contracts/ui-shell-v2.md) | Contratos de `IconComponent` (nuevo), `SidebarComponent`, `ShellComponent` y `TopbarComponent` (modificados) |
| [quickstart.md](quickstart.md) | Archivos a crear/modificar, orden de implementación, checklist manual, paths de Heroicons |

### Decisiones de diseño clave

**Componente `app-icon`** (ver D-02 en research.md):

```typescript
// Interfaz pública
@Component({ selector: 'app-icon', standalone: true })
export class IconComponent {
  @Input({ required: true }) name: string = '';
}
```

El SVG usa `stroke="currentColor"` para heredar el color del enlace padre automáticamente.
No necesita `@Input()` para el color.

**Signal de colapso con persistencia** (ver D-03 en research.md):

```typescript
// ShellComponent
readonly sidebarCollapsed = signal<boolean>(
  (() => {
    try { return localStorage.getItem('loopi_sidebar_collapsed') === 'true'; }
    catch { return false; }
  })()
);

toggleCollapse(): void {
  const next = !this.sidebarCollapsed();
  this.sidebarCollapsed.set(next);
  try { localStorage.setItem('loopi_sidebar_collapsed', String(next)); }
  catch { /* degradación silenciosa */ }
}
```

**Responsive sidebar con colapso manual** (D-05, D-06):

| Breakpoint | `collapsed=false` | `collapsed=true` | Trigger |
|------------|-------------------|------------------|---------|
| `< 640px` | `w-64` (drawer) | N/A | Hamburguesa |
| `≥ 640px` (`sm:`) | `w-16` (íconos) | `w-16` (íconos) | CSS (siempre colapsado) |
| `≥ 1024px` (`lg:`) | `w-64` (expandido) | `w-16` (íconos) | Botón chevron |

**Layout P2** (ver D-04 en research.md):

```text
ANTES (016):
  flex-col                     h-screen
    app-topbar                 h-16, full-width
    flex-row                   flex-1
      app-sidebar              h-fill (empieza a 64px del tope)
      main

DESPUÉS (017 P2):
  flex-row                     h-screen
    app-sidebar                h-screen completo (tope a fondo)
    flex-col                   flex-1
      app-topbar               h-16 (solo en columna derecha)
      main                     flex-1
```

---

## Notas de Implementación

- **No crear backend**: toda la feature vive en `loopi-web`.
- **P1 y P2 son independientes**: `IconComponent` + colapso (P1) pueden mergearse sin el
  refactor de layout (P2). El refactor de P2 no bloquea a P1.
- **Tests requeridos**:
  - `IconComponent`: ≥ 1 test por ícono registrado + test del fallback.
  - `ShellComponent`: tests para `sidebarCollapsed` signal, `toggleCollapse()`, lectura/escritura
    de `localStorage` (mockear `localStorage` en el test).
  - `SidebarComponent`: test que `collapsed=true` oculta el texto y muestra solo íconos;
    test que el botón chevron emite `collapseToggled`.
- **Accesibilidad**: En modo colapsado, cada `<a>` del sidebar debe tener `[attr.title]` y
  `[attr.aria-label]` con el nombre del módulo (ya existen en 016; verificar que persisten).
- **`iconEmoji()` método**: al eliminarlo de `SidebarComponent`, actualizar el spec de tests
  para no referenciar el método.
