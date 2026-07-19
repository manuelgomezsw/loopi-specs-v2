# Reporte de Bug: NgModule Mixto — No Cumple FE-STACK-01 Standalone

**Tipo**: Implementation drift

**Severidad**: 🔴 Critical

**Feature**: 009-inventario-conteo (Frontend)

**Reportado**: 2026-07-13

**Status: ✅ Patched

**Patched**: 2026-07-13

---

## Descripción

El módulo `inventario.module.ts` mezcla NgModule con componentes standalone, violando el estándar CLAUDE.md [FE-STACK-01] que ordena: **"Todos los componentes Angular DEBEN ser standalone. Sin NgModules."**

**Problema**:

```typescript
// inventario.module.ts
@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    // Components comentados (deberían estar en los componentes mismos)
    // FormCardComponent,
    // PageHeaderComponent,
  ]
})
export class InventarioModule { }

```text

Mientras que los componentes individuales usan `standalone: true`:

```typescript
// inventario-conteo.component.ts
@Component({
  selector: 'app-inventario-conteo',
  standalone: true,  // ← Conflicto: NgModule + standalone
  imports: [...]
})

```text

---

## Trazabilidad

### CLAUDE.md

**[FE-STACK-01]** (Stack tecnológico):

> "Angular: **Componentes standalone obligatorio. SIN NgModules.**
> - Todo componente: `standalone: true`
> - Imports a nivel componente, NO en NgModule
> - Proveedores: nivel aplicación o componente, NO en NgModule"

### Comparación con otros módulos

**categorias.module.ts**: NO EXISTE (no hay NgModule)

- Componentes se importan directamente en `categorias.component.ts` ✅

**items.module.ts**: NO EXISTE (no hay NgModule)

- Componentes se importan directamente en `items-lista.component.ts` ✅

**inventario.module.ts**: EXISTE ❌

- Contradice el estándar

---

## Análisis de Causa Raíz

### Problemas

1. **NgModule coexiste con componentes standalone** (línea 16-30 en inventario.module.ts)

   - Módulo declara `@NgModule` pero importa componentes standalone

   - Angular permite esto pero es ambiguo y viola FE-STACK-01

2. **Transversal components comentados** (línea 23-27)

   - FormCardComponent, PageHeaderComponent, etc. están importados en NgModule

   - Pero deberían estar en cada componente individual (si standalone)

   - O el módulo debería existir pero exportar un barrel

3. **Routing se registra en NgModule, no en componente**

   - `inventario.routes.ts` existe pero NgModule no lo usa

   - Routing debe estar en componentes standalone

### Impacto

- ❌ Incumple FE-STACK-01

- ❌ Confusión: ¿qué imports van dónde?

- ❌ Dificulta lazy loading (feature modules no son patrón moderno)

- ❌ Aumenta boilerplate innecesario

---

## Solución Recomendada

### Opción 1: Eliminación de NgModule (Recomendado)

**Paso 1**: Eliminar `inventario.module.ts`

**Paso 2**: Cada componente importa lo que necesita

**inventario-conteo.component.ts**:

```typescript
@Component({
  selector: 'app-inventario-conteo',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    FormCardComponent,
    PageHeaderComponent,
    ListCardComponent,
    // ... otros transversals
  ]
})
export class InventarioConteoComponent { }

```text

**Paso 3**: Routing en componente (si aplica)

**app.routes.ts** o en componente padre:

```typescript
const inventarioRoutes: Routes = [
  {
    path: 'inventario',
    children: [
      { path: 'conteo', component: InventarioConteoComponent },
      { path: 'historial', component: InventarioHistorialComponent },
      { path: 'detalle/:id', component: InventarioDetalleComponent },
    ]
  }
];

```text

### Opción 2: Mantener NgModule (No Recomendado)

Si hay constraint de no poder eliminar NgModule:

```typescript
@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    InventarioConteoComponent,  // ← Importar componentes standalone
    InventarioHistorialComponent,
    InventarioDetalleComponent,
    FormCardComponent,
    PageHeaderComponent,
  ],
  exports: [
    InventarioConteoComponent,
    InventarioHistorialComponent,
    InventarioDetalleComponent,
  ]
})
export class InventarioModule { }

```text

Pero esto aún viola FE-STACK-01 (se prefiere no tener NgModule).

---

## Archivos Afectados

- ❌ `inventario.module.ts`: Debe eliminarse

- ✅ `inventario-conteo.component.ts`: Ya standalone, solo agregar imports

- ✅ `inventario-historial.component.ts`: Ya standalone, solo agregar imports

- ✅ `inventario-detalle.component.ts`: Ya standalone, solo agregar imports

- ✅ `inventario.service.ts`: Sin cambios

---

## Verificación

Después de la corrección:

```bash
# No debe existir archivo
ls -la loopi-web-v2/src/app/inventario/inventario.module.ts
# Expected: file not found

# Componentes deben ser importables directamente
grep -n "standalone: true" loopi-web-v2/src/app/inventario/*.component.ts
# Expected: todos retornan true

```text

---

## Impacto

- 🔴 **Critical**: Violación FE-STACK-01

- ❌ Incumple estándares del proyecto

- ⚠️ Posible conflicto si otros módulos también importan NgModule
