# Reporte de Bug: ChangeDetection Sin OnPush Strategy + Tabla No Responsive

**Tipo**: Implementation drift

**Severidad**: 🟠 High

**Feature**: 009-inventario-conteo (Frontend)

**Reportado**: 2026-07-13

**Status: ✅ Patched

**Patched**: 2026-07-13

---

## Descripción

Dos problemas de rendimiento/UX:

1. **ChangeDetection en Default Mode** — Componente pesado (50 items) sin optimización

2. **Tabla no responsive a móvil** — <640px tabla se corta horizontalmente

---

## Problema 1: ChangeDetection Sin OnPush

### Trazabilidad

**[FE-OPT-01]** (Optimización):

> "Heavy components (>20 elementos, listas, tablas) DEBEN usar `ChangeDetectionStrategy.OnPush`"

### Análisis

**inventario-conteo.component.ts** (línea 9-21):

```typescript
@Component({
  selector: 'app-inventario-conteo',
  templateUrl: './inventario-conteo.component.html',
  styleUrls: ['./inventario-conteo.component.css'],
  standalone: true,
  imports: [...]
  // ❌ Falta: changeDetection: ChangeDetectionStrategy.OnPush
})
export class InventarioConteoComponent { ... }

```text

**Impacto**:

- Componente declara 50 items en lista (línea 105)

- Default change detection corre en **cada evento del DOM** (click, input, timer)

- Sin OnPush, Angular recalcula binding de todos los 50 items × veces que event dispara

- **En lista de 50 items registrando valores**: hasta 50 × 50 = 2500 checks innecesarios

### Solución

```typescript
import { ChangeDetectionStrategy } from '@angular/core';

@Component({
  selector: 'app-inventario-conteo',
  templateUrl: './inventario-conteo.component.html',
  styleUrls: ['./inventario-conteo.component.css'],
  standalone: true,
  imports: [...],
  changeDetection: ChangeDetectionStrategy.OnPush  // ← Agrega
})
export class InventarioConteoComponent { ... }

```text

Con OnPush:

- Change detection solo corre cuando:

  - Input properties cambian

  - Events del componente

  - Observables marcan como changed

---

## Problema 2: Tabla No Responsive a Móvil

### Trazabilidad (B)

**[FE-RESP-01]** (Responsive — Mobile-first):

> "Breakpoint <640px: single column, cards. ≥1024px: table layout."

### Análisis (B)

**inventario-detalle.component.html** (línea 67-109):

```html
<!-- Tabla siempre visible -->

<div class="overflow-x-auto">
  <table>
    <thead>
      <tr>
        <th>Item</th>
        <th>Sugerido</th>
        <th>Esperado</th>
        <th>Real</th>
        <th>Diferencia</th>
      </tr>
    </thead>
    <tbody>
      @for (item of inventario.items) {
        <tr>
          <td>{{ item.nombre }}</td>
          <td>{{ item.valor_sugerido }}</td>
          <!-- ... -->
        </tr>
      }
    </tbody>
  </table>
</div>

```text

**Problema**:

- A 320px (móvil pequeño), tabla tiene 5 columnas

- Cada columna ~60px → total 300px

- Tabla se corta o hace scroll horizontal (violación: body no debe scrollear horizontalmente)

- Mejor solución: Cards en móvil, tabla en desktop

### Solución (B)

**Template**:

```html
<!-- Mobile: Cards -->

<div class="md:hidden space-y-4">
  @for (item of inventario.items) {
    <div class="bg-white p-4 rounded border">
      <div class="flex justify-between">
        <span class="font-semibold">{{ item.nombre }}</span>
        <span [class.text-green-600]="item.diferencia >= 0"
              [class.text-red-600]="item.diferencia < 0">
          {{ item.diferencia }}
        </span>
      </div>
      <div class="text-sm text-gray-600 mt-2">
        Sugerido: {{ item.valor_sugerido }}
        Esperado: {{ item.valor_esperado }}
        Real: {{ item.valor_real }}
      </div>
    </div>
  }
</div>

<!-- Desktop: Table -->

<div class="hidden md:block overflow-x-auto">
  <table>
    <!-- Tabla original -->
  </table>
</div>

```text

---

## Verificación

### ChangeDetection OnPush

```bash
# Inspeccionar cambios con Angular DevTools
# Extensión: Angular DevTools en Chrome
# Verificar que component solo cambia cuando input cambia

```text

### Responsive

```bash
# Mobile view
open -a "Google Chrome" --args --window-size=375,667 http://localhost:4200/inventario/detalle/1

# Verificar: NO hay scroll horizontal en body
# Solo cards, sin tabla

```text

---

## Archivos Afectados

- `inventario-conteo.component.ts`: Agregar `ChangeDetectionStrategy.OnPush`

- `inventario-historial.component.ts`: Agregar OnPush

- `inventario-detalle.component.html`: Agregar breakpoint mobile/desktop

---

## Impacto

- ⚠️ Performance: Componente pesado sin optimización

- ⚠️ Mobile UX: Tabla no es responsive

- ❌ Violación FE-RESP-01
