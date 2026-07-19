# Reporte de Bug: Memory Leak — Sin `takeUntil` en Subscripciones

**Tipo**: Implementation drift

**Severidad**: 🔴 Critical

**Feature**: 009-inventario-conteo (Frontend)

**Reportado**: 2026-07-13

**Status: ✅ Patched

**Patched**: 2026-07-13

---

## Descripción

Los componentes **no cancelan subscripciones** cuando se destruyen. Cada navegada al componente agrega nuevas subscripciones no terminadas, causando memory leaks críticos.

**Impacto**:

- Usuario entra a `/inventario/conteo` → crea 3 subscripciones

- Usuario navega fuera → subscripciones permanecen activas

- Usuario regresa a `/inventario/conteo` → crea 3 MÁS subscripciones (total: 6)

- Después de 10 visitas: 30 subscripciones activas consumiendo memoria

**Memory Impact**: ~1MB por visita × 10-50 visitas = posible 50MB+ memory leak en sesión

---

## Trazabilidad

### CLAUDE.md

**[FE-OPT-01]** (Optimización):

> "Cancelar subscripciones en OnDestroy usando `takeUntil(this.destroy$)` pattern. NO hay excepciones."

### plan.md

- **T040, T042**: Autosave en items — Implementar con `takeUntil` ✅

- **T067, T069**: Historial y detalle — Implementar con `takeUntil` ✅

### Comparación con otros componentes

**categorias/categorias.component.ts** (línea 33):

```typescript
private destroy$ = new Subject<void>();

ngOnInit() {
  this.categoriaService.listar()
    .pipe(takeUntil(this.destroy$))  // ✅ Cancela subscripción
    .subscribe(...)
}

ngOnDestroy() {
  this.destroy$.next();
  this.destroy$.complete();
}

```text

---

## Análisis de Causa Raíz

### Problemas Identificados

#### En `inventario-conteo.component.ts`

**Línea 48** (ngOnInit):

```typescript
this.route.queryParams.subscribe(params => {  // ❌ SIN takeUntil
  const inventarioId = params['inventario_id'];
  if (inventarioId) {
    this.recuperarSesion(parseInt(inventarioId, 10));
  } else {
    this.loadSugerencia();
  }
});

```text

**Línea 61** (loadSugerencia):

```typescript
this.inventarioService.getSugerencia().subscribe({  // ❌ SIN takeUntil
  next: (data) => { ... }
});

```text

**Línea 110** (iniciarConteo):

```typescript
this.inventarioService.iniciarConteo({...}).subscribe({  // ❌ SIN takeUntil
  next: (data) => { ... }
});

```text

**Línea 129** (registrarValor):

```typescript
this.inventarioService.registrarValorReal(...).subscribe({  // ❌ SIN takeUntil
  next: (data) => { ... }
});

```text

**Línea 162** (confirmarConteo):

```typescript
this.inventarioService.confirmarConteo(...).subscribe({  // ❌ SIN takeUntil
  next: (data) => { ... }
});

```text

#### En `inventario-historial.component.ts`

**Línea 73** (cargarHistorial):

```typescript
this.inventarioService.getHistorial(filtros).subscribe({  // ❌ SIN takeUntil
  next: (data) => { ... }
});

```text

#### En `inventario-detalle.component.ts`

**Línea 56** (ngOnInit):

```typescript
this.route.params.subscribe(params => {  // ❌ SIN takeUntil
  const id = +params['id'];
  this.cargarDetalle(id);
});

```text

**Línea 69** (cargarDetalle):

```typescript
this.inventarioService.getInventario(id).subscribe({  // ❌ SIN takeUntil
  next: (data) => { ... }
});

```text

### Impacto Acumulativo

```text

Visita 1: 3 subscripciones activas
Visita 2: 6 subscripciones activas (las de visita 1 aún escuchan)
Visita 3: 9 subscripciones activas
...
Visita 10: 30 subscripciones activas
Visita 50: 150 subscripciones activas  ← Usuario experience degradada

```text

---

## Solución Recomendada

### Paso 1: Agregar Destroy Subject en Componentes

En `inventario-conteo.component.ts`:

```typescript
import { Subject, takeUntil } from 'rxjs';

export class InventarioConteoComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}

```text

Lo mismo en `inventario-historial.component.ts` e `inventario-detalle.component.ts`.

### Paso 2: Agregar `takeUntil` a Todas las Subscripciones

**Ejemplo 1** (ngOnInit):

```typescript
ngOnInit(): void {
  this.route.queryParams
    .pipe(takeUntil(this.destroy$))  // ← Agrega aquí
    .subscribe(params => {
      const inventarioId = params['inventario_id'];
      // ...
    });
}

```text

**Ejemplo 2** (cargarHistorial):

```typescript
cargarHistorial(): void {
  this.inventarioService.getHistorial(filtros)
    .pipe(takeUntil(this.destroy$))  // ← Agrega aquí
    .subscribe({
      next: (data) => { ... }
    });
}

```text

### Paso 3: Verificar Implementación

Todos los `subscribe()` deben tener patrón:

```typescript
observable.pipe(takeUntil(this.destroy$)).subscribe(...)

```text

---

## Archivos Afectados

- `inventario-conteo.component.ts`: 5 subscripciones sin `takeUntil`

- `inventario-historial.component.ts`: 1 subscripción sin `takeUntil`

- `inventario-detalle.component.ts`: 2 subscripciones sin `takeUntil`

**Total**: 8 subscripciones no canceladas

---

## Verificación

Después de la corrección:
1. Abrir DevTools → Memory Profiler
2. Tomar heap snapshot 1
3. Navegar a `/inventario/conteo` → navegar fuera → navegar adentro 10 veces
4. Tomar heap snapshot 2
5. **Memoria debe ser similar** (no crecer 30 subscripciones)

---

## Impacto

- 🔴 **Critical**: Memory leaks afectan UX después de múltiples navegadas

- ❌ Violación CLAUDE.md [FE-OPT-01]

- ❌ Incumple patrones de otros componentes
