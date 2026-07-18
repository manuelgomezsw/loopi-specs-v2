---
status: pending
created: 2026-07-18
change_request: "Corrección de Flujo Conceptual: El flujo de iniciar conteo debe ser 1) Consultar items activos para tipo seleccionado 2) Validar hay items (sino 422) 3) Crear inventario 4) Cruzar items con stock_actual para obtener valor_sugerido 5) Crear detalles en detalle_inventario. Cambios: RF-INV-02.3 nueva para 'Determinación de Items', nuevas funciones en repository (GetItemsActivosPorTipo, GetStockSnapshot), refactorizar Service.Iniciar, agregar error code sin_items_contabilizar. Impacto: Frontend recibe items automáticamente, ErrorMapperService necesita código nuevo."
scope: "Feature-wide + Architecture Pivot"
---

## Change Summary

Corregir el orden conceptual del flujo de iniciar conteo: debe consultar items ANTES de crear inventario, validar que existan items, cruzarlos con stock_actual para obtener valor_sugerido, y ENTONCES crear inventario con detalles.

**Current Issue**: Service.Iniciar() crea inventario primero, luego intenta buscar items (pero no existe lógica) → respuesta con 0 items.

**Correction**: Query items activos → Validar existe stock → Crear inventario → Crear detalles con stock_sugerido.

---

## Implementation Progress

- **Tasks completed**: 30+ (ver tasks.md: T001-T003, T006-T008, T012-T015, T021-T028, T042-T049, T064-T075, T087-T098, etc.)
- **Tasks incomplete**: ~20 (T004-T005, T016-T020, T030-T041, T050-T063, T076-T086, T099-T110, etc.)
- **Current phase**: Phase 2 en progreso - Tests y casos edge
- **Files changed on branch**: 50+ (backend API, migrations, specs, tests, frontend, docs)
- **Adhoc work detected**: ErrorMapperService + error-handling improvements agregados fuera de tareas iniciales
- **Risk**: Tareas T021-T028 (Service.Iniciar + helpers) ya marcadas completas pero necesitan REFACTORIZAR con nuevo orden

---

## Impact Assessment

| Artifact | Action | Razón |
|----------|--------|-------|
| **spec.md** | Modificar + Agregar | Agregar RF-INV-02.3 "Determinación de Items" con paso a paso de consulta, validación y mapeo de stock |
| **plan.md** | Crear + Modificar | NO EXISTE ACTUALMENTE - Crear plan.md con fases y arquitectura; actualizar con reordenamiento de lógica en Service |
| **tasks.md** | Modificar + Agregar | Reabrir T021 (Service.Iniciar refactor), T023 (CreateDetalleInventario debe crearse aquí), agregar T0XX para nuevas funciones repository |

| **data-model.md** | Modificar | Agregar diagrama de flujo: items → detalle_inventario → stock_actual, indicando dónde obtiene valor_sugerido |
| **docs/ERROR-CODES.md** | Modificar | Agregar código nuevo `sin_items_contabilizar` (422) |
| **BUG-016.md** | Actualizar | Reconceptualizar de "items no se crean" a "flujo tiene orden invertido" con diagrama antes/después |

---

## Risk Checks

- **⚠️ ADVERTENCIA**: Tareas T021-T028 están marcadas `[x]` pero Service.Iniciar() necesita refactorización completa. Reabrirlas.
- **⚠️ ADVERTENCIA**: Cambio afecta endpoint POST /inventarios - respuesta 201 cambió de "0 items" a "N items". Frontend no se rompe (ya espera items) pero es breaking change en API.
- ✅ Sin conflictos de scope - cambio está dentro de feature intent (mejorar flujo de conteo)
- ✅ Sin dependency breaks - cambio es local a módulo inventarios, no afecta otros módulos
- ✅ Frontend ya implementado puede recibir items automáticamente (componente no se rompe)

---

## Planned Changes

### spec.md

1. **Sección: Requisitos Funcionales - RF-INV-02 (Iniciar Conteo)**
   - Agregar subsección: **RF-INV-02.3: Determinación Automática de Items**
   - Documentar 5 pasos del flujo:
     1. Consultar items activos por tipo (frecuencia_inventario = tipo seleccionado)
     2. Validar items encontrados (sino retornar 422 `sin_items_contabilizar`)
     3. Crear registro en inventarios
     4. Cruzar items con stock_actual para obtener valor_sugerido
     5. Crear detalles en detalle_inventario con mapeo correcto
   - Agregar nota: "Este flujo garantiza que POST /inventarios siempre retorna items listos para contar"

2. **Sección: Escenarios de Aceptación - Historia 1 (Iniciar conteo)**
   - Agregar escenario 5: "**Dado** que la tienda tiene items con frecuencia_inventario=diario, **Cuando** se inicia conteo diario, **Entonces** se retornan todos los items diarios con valor_sugerido desde stock_actual"
   - Agregar escenario 6: "**Dado** que NO hay items con frecuencia_inventario=tipo, **Cuando** se intenta iniciar, **Entonces** retorna 422 sin_items_contabilizar"

### plan.md (CREAR NUEVO)

**Estructura mínima:**

- **Fase 1: Core API & DB** (completo - ya implementado)
  - Migrations, modelos, servicios básicos

- **Fase 2: Flujo Correcto de Iniciar Conteo** (EN PROGRESO - A CORREGIR)
  - Refactorizar Service.Iniciar() con nuevo orden
  - Implementar GetItemsActivosPorTipo(tiendaID, tipo) en repository
  - Implementar GetStockSnapshot(tiendaID, itemIDs) en repository
  - Llamar CreateDetalleInventario() en Iniciar()
  - Tests unitarios e integración

- **Fase 3: Registrar Valores & Confirmar** (pendiente)
  - RegistrarValor, Confirmar, historial

- **Nota de Arquitectura**: Service.Iniciar() orquesta: validaciones → GetItemsActivosPorTipo() → CreateInventario() → CreateDetalleInventario() → GetInventarioDetalle(). stock_actual.valor_snapshot es el "valor_sugerido" en respuesta

### tasks.md

1. **Reabrir Tareas**:
   - Cambiar T021 de `[x]` a `[ ]` con nota: "⚠️ (reopened — BUG-016) Refactorizar Service.Iniciar() con orden correcto: validar → GetItemsActivosPorTipo() → CreateInventario() → CreateDetalleInventario()"
   - Cambiar T023 de `[x]` a `[ ]` con nota: "⚠️ (reopened — BUG-016) CreateDetalleInventario() debe ser llamado desde Iniciar() DESPUÉS de crear inventario"

2. **Agregar Nuevas Tareas** (después de T028, antes de T030):
   - **T029 [P] [US1] Implementar repository method GetItemsActivosPorTipo()**: Query `SELECT id FROM items WHERE activo=1 AND frecuencia_inventario=?` para tipo seleccionado. Retorna lista de item IDs.
   - **T030 [P] [US1] Implementar repository method GetStockSnapshot()**: Query `SELECT item_id, valor_snapshot FROM stock_actual WHERE tienda_id=? AND item_id IN (?)` para mapear items → stock values. Si item no existe en stock_actual, default a 0.
   - **T031 [P] [US1] Refactorizar Service.Iniciar() - Paso 1: GetItemsActivosPorTipo**: Llamar repo.GetItemsActivosPorTipo(tiendaID, tipo) ANTES de CreateInventario(). Si 0 items, retornar 422 `sin_items_contabilizar`.
   - **T032 [P] [US1] Refactorizar Service.Iniciar() - Paso 2: Cruzar con stock_actual**: Llamar repo.GetStockSnapshot(tiendaID, itemIDs) para obtener mapeo de valor_sugerido. Mapear valores para cada item.
   - **T033 [P] [US1] Refactorizar Service.Iniciar() - Paso 3: Crear inventario y detalles**: AHORA crear inventario, crear detalles con valor_sugerido mapeado, tomar snapshot en stock_actual.
   - **T034 [P] [US1] Unit test GetItemsActivosPorTipo()**: Verificar retorna items activos del tipo correcto, excluye items inactivos.
   - **T035 [P] [US1] Unit test GetStockSnapshot()**: Verificar mapeo correcto de items a valores, maneja items inexistentes en stock_actual (default 0).
   - **T036 [P] [US1] Integration test Service.Iniciar() - flujo completo**: Crear tienda+items+stock_actual, iniciar conteo, verificar 201 con N items y valor_sugerido mapeado correctamente.

3. **Agregar Error Code**:
   - **T037 [P] [US1] Handler: Mapear error code sin_items_contabilizar a 422**: En handler.go, mapear `sin_items_contabilizar` → HTTP 422. Actualizar ErrorResp.

### data-model.md (CREAR/ACTUALIZAR)

Agregar sección: **Flujo de Datos: Iniciar Conteo**

```text
items (activo=1, frecuencia_inventario)
  ↓ GetItemsActivosPorTipo(tienda, tipo)
  ├→ [item_501, item_502, ..., item_510]

stock_actual (valor_snapshot, tienda_id, item_id)
  ↓ GetStockSnapshot(tienda, itemIDs)
  ├→ {item_501: 50, item_502: 45, item_503: 0, ...}

inventarios (nuevo registro, estado=en_progreso)
  ↓ CreateInventario()
  ├→ inventario_id = 123

detalle_inventario (10 registros con valor_sugerido mapeado)
  ↓ CreateDetalleInventario([
      {inventario_id: 123, item_id: 501, valor_sugerido: 50},
      {inventario_id: 123, item_id: 502, valor_sugerido: 45},
      ...
    ])
  ├→ 10 detalles insertados

stock_actual (snapshot al iniciar)
  ↓ SnapshotStockActual(inventario_id, itemIDs, values)
  ├→ Registra snapshot de cantidad disponible
```

### docs/ERROR-CODES.md

Agregar en tabla **POST /api/v1/inventarios (Iniciar Conteo)**:

| Código | Status | Mensaje | Causa |
|--------|--------|---------|-------|
| `sin_items_contabilizar` | 422 | "No hay items activos para contabilizar en esta tienda para el tipo {tipo_seleccionado}" | GetItemsActivosPorTipo() retorna lista vacía |

### BUG-016.md (ACTUALIZAR)

- Cambiar estado de `Discovered` a `Patched`
- Actualizar descripción raíz: De "Items no se crean automáticamente" → "Flujo de Iniciar Conteo tiene orden conceptual invertido"
- Agregar diagrama ANTES vs DESPUÉS:

  ```text
  ANTES (❌): Create inv → Query items (logic doesn't exist) → 0 items
  DESPUÉS (✅): Query items → Validate → Create inv → Create detalles with stock
  ```

- Agregar nota: "Correción aplicada en iteration 2026-07-18, tareas T029-T037 planificadas"

### Frontend ErrorMapperService

Agregar código error:

```typescript
sin_items_contabilizar: "No hay items activos para contabilizar en esta tienda para el tipo {tipo}"
```

---

## Backward Compatibility

**BREAKING CHANGE**:

- Endpoint POST /inventarios ahora SIEMPRE retorna 201 con items (antes podría retornar 201 sin items)
- Cliente debe estar preparado para recibir `items: []` en respuesta (nunca sucede ahora, pero es válido)
- Clients esperando "0 items" en POST /inventarios se rompen (ahora mínimo 1 item o 422)

---

## Next Steps

1. **Review this iteration** (`pending-iteration.md`)
2. **Confirm** que el orden y cambios son correctos
3. **Run** `/speckit.iterate.apply` para actualizar spec.md, plan.md, tasks.md
4. **Run** `/speckit.implement` para comenzar implementación de T029-T037
5. **Mark T021, T023 as blocked** hasta que T031-T033 se implementen
