# Bug Report: Item Title Display Shows ID Instead of Name

**Type**: Implementation drift
**Severity**: High
**Feature**: 009-inventario-conteo
**Reported**: 2026-07-18

---

## Description

When registering inventory count values in the item list, the item title displayed is showing the internal item identifier (ID) instead of the item's human-readable name. This makes it impossible for the operator to identify which item they are counting without cross-referencing the catalog.

**Observed behavior**:

- Item displays as: "123" (internal ID)
- Expected behavior: "Leche Entera 1L" (item name)

**Impact**: User confusion, longer conteo time, risk of counting wrong items.

---

## Artifact Traceability

### spec.md

- **Affected user story**: HU2 — Registrar el conteo físico item por item (Priority P1)
- **Affected requirements**:
  - RF-INV-02.1: "Para cada item del conteo, el sistema muestra: valor sugerido (stock proyectado), valor esperado y un campo para ingresar el valor real."
  - The requirement does NOT explicitly state which item identifier to display (ID vs. name), but context implies human-readable display
- **Gap identified**: Spec is silent on which field should be displayed for item identification. RF-INV-02.1 should clarify that item **name** (not ID) must be displayed.

### plan.md

- **Affected sections**: Phase 4 (User Story 2) — Registrar Valores del Conteo
  - "inventario-conteo.component.ts step 2: Display items list"
  - "Create Angular component HTML for item registration: input type=number per item..."
- **Impact**: Frontend component rendering wrong field from item response

### tasks.md

- **Affected tasks**:
  - T040: "Create Angular component step 2 in `inventario-conteo.component.ts`: Display items list (valor_sugerido, valor_esperado)"
  - T041: "Create Angular component HTML for item registration: input type=number per item"
- **False completions**: Tasks marked `[x]` completed but implementation uses wrong field for item display
- **Missing tasks**: None (task description just lacks detail on which field to use)

---

## Root Cause Analysis

The frontend component (`inventario-conteo.component.html`) is likely binding to `item.id` instead of `item.nombre` when rendering the item list. This is an implementation drift — the spec didn't explicitly call out the field, but the natural assumption (name for human display) was not implemented.

**Why this bug exists**:

- Spec gap: RF-INV-02.1 focuses on *what values* to show (sugerido, esperado) but doesn't specify the item identifier field
- Task description didn't enforce which field to bind
- Frontend developer took shortcut using `item.id` without catching the gap

---

## Recommended Fix

1. **Spec clarification**: Update RF-INV-02.1 to explicitly state: "For each item, the system displays the item **name** (nombre), value suggested, expected value, and a field for actual value."

2. **Frontend fix**: In `inventario-conteo.component.html`, change binding from `{{ item.id }}` to `{{ item.nombre }}` in the item display label.

3. **Testing**: Verify POST /inventarios response includes `nombre` field in item object; if not, backend needs update.

4. **Task reopening**: Mark T040 and T041 as incomplete until this renders correctly.

**Next steps**:

- Run `/speckit.bugfix.patch` to update spec.md (RF-INV-02.1 clarification)
- Fix frontend component binding
- Verify backend includes `nombre` in response DTO

---

**Status**: ✅ Patched
**Patched**: 2026-07-18
**Assigned to**: Frontend Team
**Dependencies**: Backend must return item.nombre in POST /inventarios response

---

**Patches Applied**:

- ✅ spec.md: Updated RF-INV-02.1 to explicitly require displaying item.nombre
- ✅ spec.md: Added FE-BUG-008 entry to "Nuevos Bugs Identificados" section
- ✅ tasks.md: Reopened T040 with note to display item.nombre
- ✅ tasks.md: Reopened T041 with note to display item.nombre (also reopened for FE-BUG-009)
