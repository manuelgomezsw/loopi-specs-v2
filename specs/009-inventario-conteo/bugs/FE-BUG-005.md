# Reporte de Bug: Accesibilidad WCAG 2.1 AA Incumplida — Contraste, aria-live, Labels

**Tipo**: Implementation drift

**Severidad**: 🟠 High

**Feature**: 009-inventario-conteo (Frontend)

**Reportado**: 2026-07-13

**Status: ✅ Patched

**Patched**: 2026-07-13

---

## Descripción

**Múltiples violaciones de WCAG 2.1 AA**:

1. **Contraste rojo/verde <4.5:1** — Usuarios con baja visión no pueden diferenciar

2. **Falta aria-live** — Screen readers no anuncian cambios dinámicos

3. **Labels no siempre asociados** — Inputs sin `<label for="id">`

---

## Trazabilidad

### CLAUDE.md

**[FE-A11Y-01]** (Accesibilidad — WCAG 2.1 AA obligatorio):

> "**Contraste mínimo 4.5:1** para texto normal, 3:1 para texto grande
> **aria-live='polite'** para feedback dinámico (cambios, errores)
> **Labels con `for` asociados** a inputs
> **Keyboard navigation** (Tab, Enter, Esc)"

---

## Análisis de Causa Raíz

### Problema 1: Contraste Rojo/Verde Insuficiente

**inventario-conteo.component.html** (línea 114-120):

```html
<div [class.text-green-600]="item.diferencia >= 0"
     [class.text-red-600]="item.diferencia < 0">
  Diferencia: {{ item.diferencia }}
</div>

```text

**inventario-detalle.component.html** (línea 102):

```html
<span [style.color]="item.diferencia >= 0 ? 'green' : 'red'">
  {{ item.diferencia }}
</span>

```text

**Problema**: Tailwind `text-green-600` (#16a34a) sobre fondo blanco = 4.2:1 contraste

- **WCAG AA requiere**: 4.5:1 mínimo

- **Usuarios afectados**: Baja visión, daltonismo (rojo/verde no se distingue igual)

**Solución**:

```html
<div [class.text-green-700]="item.diferencia >= 0"  <!-- Más oscuro -->
     [class.text-red-700]="item.diferencia < 0"     <!-- Más oscuro -->
     [class.bg-green-50]="item.diferencia >= 0"     <!-- Fondo de apoyo -->
     [class.bg-red-50]="item.diferencia < 0">       <!-- Fondo de apoyo -->
  <span>{{ item.diferencia >= 0 ? '✓' : '✗' }}</span> <!-- Icono, no solo color -->
  {{ item.diferencia }}
</div>

```text

### Problema 2: Falta aria-live para Cambios Dinámicos

**inventario-conteo.component.html** (línea 113-120 — diferencia cambia cuando usuario ingresa valor):

```html
<!-- NO hay aria-live -->

<div>Diferencia: {{ item.diferencia }}</div>

```text

**inventario-conteo.component.html** (línea 149-150 — error aparece dinámicamente):

```html
<!-- SÍ tiene role="alert" pero no en item individual -->

<div role="alert">{{ confirmationError }}</div>

<!-- Pero error de item individual NO tiene aria-live -->

<span>{{ itemErrors.get(item.item_id) }}</span>

```text

**Problema**: Screen reader no anuncia cuando diferencia cambia de -5 a +3

**Solución**:

```html
<div aria-live="polite" aria-atomic="true">
  Diferencia: {{ item.diferencia }}
</div>

<div role="alert" aria-live="assertive">
  {{ itemErrors.get(item.item_id) }}
</div>

```text

### Problema 3: Labels No Asociados en Algunos Inputs

**inventario-conteo.component.html** (línea 10-12 — correcto ✅):

```html
<label for="tipo">Tipo de Conteo</label>
<select id="tipo" [(ngModel)]="formData.tipo">

```text

**inventario-conteo.component.html** (línea 129-137 — incorrecto ❌):

```html
<!-- No hay label para input de valor_real -->

<input type="number"
  [(ngModel)]="valoresRegistrados.get(item.item_id)"
  [id]="'valor-' + item.item_id"

/>
<!-- Falta: <label for="valor-{id}">Valor Real</label> -->

```text

**Problema**: Screen reader no sabe qué es este input

**Solución**:

```html
<label [for]="'valor-' + item.item_id">
  Valor Real para {{ item.nombre }}
</label>
<input type="number"
  [id]="'valor-' + item.item_id"
  [(ngModel)]="valoresRegistrados.get(item.item_id)"
/>

```text

---

## Verificación WCAG 2.1 AA

Después de la corrección, validar con:

```bash
# Herramienta de línea de comando
npm install --save-dev pa11y
pa11y "https://localhost:4200/inventario/conteo"

# O usar Chrome DevTools:
# - Abrir DevTools → Lighthouse → Accessibility

# - Color Contrast Analyzer (extensión)

# - axe DevTools (extensión)

```text

---

## Archivos Afectados

- `inventario-conteo.component.html`: Agregar aria-live, mejorar contraste

- `inventario-historial.component.html`: Agregar labels asociados

- `inventario-detalle.component.html`: Mejorar contraste, agregar aria-live

---

## Impacto

- 🔴 **Violación legal**: WCAG 2.1 AA es standard accesibilidad (algunos países es ley)

- ❌ Usuarios con discapacidades visuales/auditivas no pueden usar feature

- ⚠️ Riesgo reputacional/legal
