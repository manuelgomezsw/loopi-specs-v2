# Quickstart: Mejoras del Menú Lateral Admin

**Feature**: 017-sidebar-icons-collapse
**Fecha**: 2026-06-21

---

## Archivos a crear

```text
loopi-web/src/app/shared/components/icon/
├── icon.component.ts          # Nuevo — app-icon con @switch y paths Heroicons v2
└── icon.component.spec.ts     # Nuevo — test de renderizado por nombre
```

## Archivos a modificar

```text
loopi-web/src/app/shared/components/shell/
├── shell.component.ts         # + sidebarCollapsed signal + toggleCollapse() + localStorage
├── shell.component.html       # + nuevo layout flex-row (P2)
├── shell.component.spec.ts    # + tests sidebarCollapsed + toggleCollapse()
├── sidebar/
│   ├── sidebar.component.ts   # + @Input() collapsed + @Output() collapseToggled; elimina iconEmoji()
│   ├── sidebar.component.html # + app-icon en lugar de emoji; + botón chevron; + texto condicional
│   └── sidebar.component.spec.ts  # + tests collapsed; actualizar tests de ícono
└── topbar/
    ├── topbar.component.html  # (P2) eliminar logo; ajustar sticky→flex-child
    └── topbar.component.spec.ts    # (P2) actualizar si había test del logo
```

---

## Orden de implementación recomendado

### Fase P1 — Íconos + Colapso (sin cambio de layout)

1. **Crear `IconComponent`** — base de todo lo demás.
   - Implementar `@switch (name)` con los 11 paths de Heroicons v2 outline + fallback.
   - Escribir `icon.component.spec.ts`: verificar que cada nombre registrado renderiza el SVG
     correcto y que un nombre inválido usa el fallback.

2. **Modificar `SidebarComponent`**:
   - Agregar `@Input() collapsed = false` y `@Output() collapseToggled`.
   - Importar y usar `<app-icon [name]="item.icon" />` en lugar de `{{ iconEmoji(...) }}`.
   - Agregar botón chevron en el pie del sidebar (visible solo en `lg:`).
   - Agregar clases de transición al `<nav>`: `transition-[width] duration-200 ease-in-out`.
   - Ocultar texto de ítems cuando `collapsed && lg:`.
   - Actualizar `sidebar.component.spec.ts`.

3. **Modificar `ShellComponent`**:
   - Agregar `sidebarCollapsed` signal con lectura de `localStorage`.
   - Agregar `toggleCollapse()` con escritura a `localStorage`.
   - Pasar `[collapsed]` y `(collapseToggled)` al `<app-sidebar>` en el template.
   - Actualizar `shell.component.spec.ts`.

### Fase P2 — Layout Full-Height (refactor de estructura)

1. **Modificar `shell.component.html`**: cambiar de `flex-col` raíz a `flex-row` raíz
   con sidebar como primera columna y columna derecha con topbar + main.

2. **Modificar `sidebar.component.html`**: reemplazar secciones de logo desktop/tablet
   para que funcionen sin topbar encima.

3. **Modificar `topbar.component.html`**: eliminar logo; quitar `sticky top-0` (ya no
   necesario con el nuevo layout flex).

4. **Verificación de regresión responsive**:
   - Confirmar mobile: overlay + drawer funcionan igual.
   - Confirmar tablet: sidebar `sm:w-16` sin hamburguesa.
   - Confirmar desktop expandido y colapsado con el layout nuevo.

---

## Checklist de verificación manual

### P1 — Íconos

- [ ] Los 11 ítems del menú muestran SVG line-icons (no emojis)
- [ ] En Chrome/macOS y Chrome/Windows los íconos se ven idénticos
- [ ] El ícono del ítem activo adopta el color `text-blue-700`
- [ ] El ícono del ítem normal tiene color `text-gray-500`
- [ ] En modo colapsado (tablet), el `title` del enlace muestra el nombre del módulo en hover
- [ ] Un nombre de ícono inválido muestra el fallback sin romper el layout

### P1 — Colapso

- [ ] En desktop (≥ 1024px) aparece el botón chevron en el pie del sidebar
- [ ] Clic en chevron colapsa el sidebar; ícono cambia a "expandir"
- [ ] Clic nuevamente expande el sidebar; ícono cambia a "colapsar"
- [ ] La transición dura ~200ms y es visualmente suave
- [ ] El área de contenido se expande al colapsar y se contrae al expandir
- [ ] Recargar la página mantiene el estado colapsado
- [ ] En tablet (640–1023px) el botón chevron NO aparece
- [ ] En mobile (< 640px) el botón chevron NO aparece

### P2 — Layout Full-Height

- [ ] El sidebar llega al borde superior de la ventana en desktop (no hay topbar encima)
- [ ] El logo "Loopi" o "L" aparece en la parte superior del propio sidebar
- [ ] La topbar ocupa solo el ancho de la columna de contenido (a la derecha del sidebar)
- [ ] En tablet y mobile el comportamiento es idéntico al de 016-admin-nav
- [ ] El drawer mobile (hamburguesa) sigue abriendo y cerrando correctamente
- [ ] El overlay negro semitransparente en mobile sigue apareciendo al abrir el drawer

---

## Comandos de desarrollo

```bash
# Desde loopi-web/
ng serve                        # Dev server
ng test --watch=false           # Tests unitarios
ng build                        # Build de producción
```

---

## Heroicons v2 — paths de referencia

Los paths SVG se copian desde <https://heroicons.com> (seleccionar: Outline, stroke-width 1.5).
Todos comparten el `viewBox="0 0 24 24"` y `fill="none"`.

El componente `app-icon` solo incluye el `<path>` interno; el `<svg>` wrapper lo provee
el propio componente con sus atributos fijos (`class="h-5 w-5 shrink-0"`, etc.).
