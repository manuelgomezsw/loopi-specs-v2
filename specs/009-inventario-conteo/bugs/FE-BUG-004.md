# Reporte de Bug: Validación de Formularios Incompleta — Campos Sin Validadores

**Tipo**: Implementation drift

**Severidad**: 🟠 High

**Feature**: 009-inventario-conteo (Frontend)

**Reportado**: 2026-07-13

**Status: ✅ Patched

**Patched**: 2026-07-13

---

## Descripción

Los formularios **carecen de validadores**, permitiendo que el usuario envíe datos inválidos. Esto viola FE-FORM-01 y RF-INV-01.

**Problemas Específicos**:

1. **Campo `tipo` puede estar vacío** — Inicial es `''` (línea 29 en inventario-conteo.component.ts)

2. **Campo `horario` es opcional pero sin lógica** — Si `tipo='diario'`, `horario` debería ser requerido

3. **Números sin restricciones** — Campo `valor_real` puede ser negativo o inválido

---

## Trazabilidad

### spec.md

**RF-INV-01.2** (línea 142-147):

> "Al iniciar, el sistema sugiere el tipo y horario según la hora actual"

**Implícitamente**: Usuario DEBE seleccionar o aceptar un tipo válido.

**RF-INV-02.1** (línea 160-163):

> "Para cada item del conteo, el sistema muestra: valor sugerido... y un campo para ingresar el valor real."

**Implícitamente**: El valor real debe ser validado (no negativo, no vacío).

---

## Análisis de Causa Raíz

### Problema 1: Campo `tipo` Sin Validación

**inventario-conteo.component.ts** (línea 29):

```typescript
formData = {
  tienda_id: 1,
  tipo: '',  // ← Inicial vacío, puede enviarse así
  horario: '' as string | undefined
};

```text

**Template** (línea 20-25):

```html
<select [(ngModel)]="formData.tipo" ...>
  <option value="">-- Seleccionar --</option>
  <option value="diario">Diario</option>
  <!-- ... -->

</select>
<!-- NO hay validador ni mensaje de error -->

```text

**Resultado**: Usuario puede presionar "Iniciar Conteo" sin seleccionar tipo.

### Problema 2: Campo `horario` Condicionalmente Requerido

**Template** (línea 29-47):

```html
@if (formData.tipo === 'diario' || formData.tipo === 'semanal') {
  <select [(ngModel)]="formData.horario" ...>
    <option value="">-- Seleccionar --</option>
    <option value="apertura">Apertura</option>
    <!-- ... -->
  </select>
}
<!-- NO hay validación que si tipo=diario, horario es requerido -->

```text

**Resultado**: Usuario puede seleccionar `tipo='diario'` pero dejar `horario` vacío.

### Problema 3: Campo `valor_real` Sin Restricciones

**Template** (línea 129-137):

```html
<input type="number"
  [(ngModel)]="valoresRegistrados.set(item.item_id, $event)"
  [disabled]="loadingItems.has(item.item_id)"
/>
<!-- NO hay min="0", NO hay required, NO hay error message -->

```text

**Resultado**: Usuario puede ingresar negativos (-100) o dejar vacío.

---

## Comparación con Estándares

**Otros componentes** (items-lista, categorias):

- Usan `ReactiveFormsModule` + FormGroup + Validators ✅

- Tienen `required`, `minLength`, `pattern` en FormControl

- Template muestra errores si inválido

**Inventario**:

- Usa `[(ngModel)]` sin validadores ❌

- Template no muestra errores de validación ❌

- Mixtura de `FormsModule` + `ReactiveFormsModule` sin usar reactive ❌

---

## Solución Recomendada

### Opción 1: Usar ReactiveFormsModule (Recomendado)

**En componente**:

```typescript
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

export class InventarioConteoComponent {
  formData: FormGroup;

  constructor(private fb: FormBuilder) {
    this.formData = this.fb.group({
      tienda_id: [1, [Validators.required]],
      tipo: ['', [Validators.required]],  // Requerido
      horario: ['', [Validators.required]]  // Requerido (o condicional)
    });
  }

  iniciarConteo(): void {
    if (this.formData.invalid) {
      console.error('Formulario inválido');
      return;
    }
    // Proceder con POST
  }
}

```text

**En template**:

```html
<form [formGroup]="formData" (ngSubmit)="iniciarConteo()">
  <select formControlName="tipo">
    <option value="">-- Seleccionar --</option>
    <option value="diario">Diario</option>
  </select>
  @if (formData.get('tipo')?.hasError('required') && formData.get('tipo')?.touched) {
    <span class="text-red-600">Tipo es requerido</span>
  }

  <button type="submit" [disabled]="formData.invalid">
    Iniciar Conteo
  </button>
</form>

```text

### Opción 2: Validadores Template-Driven (Si se usa [(ngModel)])

Agregar validadores en template:

```html
<select [(ngModel)]="formData.tipo"
  required
  [disabled]="!formData.tipo">
  <option value="">-- Seleccionar --</option>
  <option value="diario">Diario</option>
</select>

```text

Pero esto es incompleto sin component-level validation.

### Paso 3: Validar `valor_real` en Items

```html
<input type="number"
  [(ngModel)]="valoresRegistrados.get(item.item_id)"
  min="0"
  required
  (blur)="validarValorReal(item.item_id, $event)"
/>
@if (itemErrors.has(item.item_id)) {
  <span class="text-red-600">{{ itemErrors.get(item.item_id) }}</span>
}

```text

---

## Archivos Afectados

- `inventario-conteo.component.ts`: Agregar FormBuilder, Validators

- `inventario-conteo.component.html`: Usar formControlName, mostrar errores

- `inventario-conteo.component.spec.ts`: Agregar tests de validación

---

## Verificación

Después de la corrección:

```html
<!-- Botón deshabilitado si formulario inválido -->

<button [disabled]="formData.invalid">Iniciar Conteo</button>

<!-- Errores mostrados -->

<span *ngIf="formData.get('tipo')?.invalid">Tipo requerido</span>

```text

---

## Impacto

- ❌ RF-INV-01 no se cumple: Usuario puede iniciar conteo sin tipo

- ❌ Backend retorna 400 en lugar de bloquear en frontend

- ⚠️ Pobre UX: Usuario no sabe por qué POST falló
