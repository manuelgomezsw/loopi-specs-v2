# Reporte de Bug: Componentes Transversales NO Usados — Violación FE-COMP-01

**Tipo**: Implementation drift

**Severidad**: 🔴 Critical

**Feature**: 009-inventario-conteo (Frontend)

**Reportado**: 2026-07-13

**Status: ✅ Patched

**Patched**: 2026-07-13

---

## Descripción

El código **reimplementa manualmente filtros, tablas y listados** en lugar de usar los componentes transversales recomendados. CLAUDE.md [FE-COMP-01] **prohíbe explícitamente reimplementar**.

**Problema**:

- ❌ `inventario-historial.component.html` reimplementa filtros manualmente

- ❌ No usa `FilterBarComponent` (existe, está documentado, pero comentado)

- ❌ No usa `DataTableComponent` para listado

- ❌ No usa `PaginationComponent` para paginación

**Comparación**:

- `categorias/categorias.component.ts`: Usa `FilterBarComponent` ✅

- `items-lista/items-lista.component.ts`: Usa `DataTableComponent` ✅

---

## Trazabilidad

### CLAUDE.md

**[FE-COMP-01]** (Componentes Transversales — Catálogo Reutilizable):

> "**Prohibido reimplementar la funcionalidad** de componentes transversales."
>
> - `ListCardComponent`: Para listas de cards
> - `FilterBarComponent`: Para filtros (tipo, estado, rangos)
> - `PaginationComponent`: Para navegación de páginas
> - `FormCardComponent`: Para formularios
> - `StatusBadgeComponent`: Para badges de estado
>
> Si necesitas otra funcionalidad, **extends el componente existente**, no reimplementes.

---

## Análisis de Causa Raíz

### Problema 1: Filtros Reimplementados

**Archivo**: `inventario-historial.component.html` (línea 14-97)

**Código actual**:

```html
<!-- Reimplementa filtros manualmente -->

<div class="space-y-4">
  <label>Tipo
    <select [(ngModel)]="filtros.tipo" ...>
      <option value="">Todos</option>
      <option value="diario">Diario</option>
      <option value="semanal">Semanal</option>
      ...
    </select>
  </label>

  <label>Estado
    <select [(ngModel)]="filtros.estado" ...>
      <option value="">Todos</option>
      <option value="en_progreso">En Progreso</option>
      <option value="completado">Completado</option>
    </select>
  </label>

  <!-- Más filtros... -->

</div>

```text

**Debería ser** (línea 10-15 en categorias.component.html):

```html
<app-filter-bar
  [filters]="filtros$ | async"
  (filterChange)="onFilterChange($event)">
</app-filter-bar>

```text

### Problema 2: Tabla Reimplementada

**Archivo**: `inventario-historial.component.html` (línea 127-187)

**Código actual**:

```html
<!-- Reimplementa tabla manualmente -->

<div class="divide-y">
  @for (inventario of inventarios; track inventario.id) {
    <div class="p-4 hover:bg-gray-50">
      <div class="flex justify-between">
        <span>{{ inventario.fecha }}</span>
        <span>{{ inventario.tipo }}</span>
        <!-- Más columnas... -->
      </div>
    </div>
  }
</div>

```text

**Debería ser** (línea 18-35 en items-lista.component.html):

```html
<app-data-table
  [columns]="columns"
  [data]="inventarios"
  [loading]="loading"
  (rowClick)="onRowClick($event)">
</app-data-table>

```text

### Problema 3: Paginación Reimplementada

**Archivo**: `inventario-historial.component.html` (línea 203-220)

**Código actual**:

```html
<!-- Paginación manual -->

<div class="flex justify-between">
  <button [disabled]="pagina === 1" (click)="iraPagina(pagina - 1)">Anterior</button>
  <span>Página {{ pagina }} de {{ totalPaginas }}</span>
  <button [disabled]="pagina === totalPaginas" (click)="iraPagina(pagina + 1)">Siguiente</button>

</div>

```text

**Debería ser** (usar `PaginationComponent`):

```html
<app-pagination
  [currentPage]="pagina"
  [totalPages]="totalPaginas"
  (pageChange)="onPageChange($event)">
</app-pagination>

```text

---

## Impacto

- 🔴 **Violación explícita** de FE-COMP-01

- ❌ Duplicación de código (mantenimiento 3x)

- ❌ Inconsistencia visual: filtros en historial != filtros en categorías

- ❌ Pérdida de beneficios: accesibilidad, responsive, validación centralizada

- ❌ Deuda técnica: Si FilterBar cambia de diseño, hay que actualizar 2+ componentes

---

## Solución Recomendada

### Paso 1: Verificar Que Componentes Transversales Existan

```bash
ls loopi-web-v2/src/app/shared/components/
# Expected:
# - filter-bar/filter-bar.component.ts

# - data-table/data-table.component.ts

# - pagination/pagination.component.ts

# - list-card/list-card.component.ts

```text

### Paso 2: Reemplazar Implementación Manual en `inventario-historial.component.ts`

**Importar en componente**:

```typescript
import { FilterBarComponent } from '../shared/components/filter-bar/filter-bar.component';
import { DataTableComponent } from '../shared/components/data-table/data-table.component';
import { PaginationComponent } from '../shared/components/pagination/pagination.component';

@Component({
  standalone: true,
  imports: [
    FilterBarComponent,
    DataTableComponent,
    PaginationComponent,
    // ...
  ]
})

```text

**Template simplificado**:

```html
<app-filter-bar
  [filters]="filtros"
  (filterChange)="onFilterChange($event)">
</app-filter-bar>

<app-data-table
  [columns]="columns"
  [data]="inventarios"
  [loading]="loading"
  (rowClick)="onRowClick($event)">
</app-data-table>

<app-pagination
  [currentPage]="pagina"
  [totalPages]="totalPaginas"
  (pageChange)="onPageChange($event)">
</app-pagination>

```text

### Paso 3: Eliminar Código Manual

- Remover `<select>` manuales para filtros

- Remover `<div class="divide-y">` para listado

- Remover botones de paginación manual

---

## Archivos Afectados

- `inventario-historial.component.html`: Reemplazar lines 14-220 (207 líneas) con 15 líneas

- `inventario-historial.component.ts`: Actualizar métodos para trabajar con componentes

---

## Verificación

Después de la corrección:

```bash
# Componentes transversales deben estar importados
grep -n "FilterBarComponent\|DataTableComponent\|PaginationComponent" loopi-web-v2/src/app/inventario/*.component.ts

# Código manual no debe existir
grep -n "divide-y\|<select" loopi-web-v2/src/app/inventario/inventario-historial.component.html
# Expected: no matches

```text

---

## Impacto

- 🔴 **Critical**: Violación explícita de estándar FE-COMP-01

- ❌ Deuda técnica: 200+ líneas de código que no debería existir

- ⚠️ Riesgo: Si se actualiza FilterBar pero no aquí, inconsistencia visual
