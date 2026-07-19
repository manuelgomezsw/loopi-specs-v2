# Bug Report: Difference Indicator Shows Green Checkmark Instead of Alert

**Type**: Implementation drift
**Severity**: High
**Feature**: 009-inventario-conteo
**Reported**: 2026-07-18

---

## Description

When there is a difference between the suggested (expected) value and the entered (actual) value, the UI displays a green checkmark in the top right instead of a warning or alert. This masks the difference and makes the operator unaware that they have counted a quantity different from the system expectation.

**Observed behavior**:

- Difference exists (e.g., expected 5000 ml, entered 4600 ml = -400 ml difference)
- UI shows: Green checkmark ✓ (misleading success indicator)
- Expected behavior: Display difference value with warning color/icon, alert text such as "⚠️ Diferencia: -400 ml" or similar

**Impact**: Operator loses visibility of inventory discrepancies, defeats the purpose of real-time difference reporting per RF-INV-02.3.

---

## Artifact Traceability

### spec.md

- **Affected user story**: HU2 — Registrar el conteo físico item por item (Priority P1)
- **Affected requirements**:
  - RF-INV-02.3: "La diferencia (real − esperado) se recalcula y muestra en pantalla en tiempo real al ingresar cada valor."
  - HU2 Scenario 1: "the system shows a difference of −400 ml de inmediato, sin necesidad de guardar manualmente."
  - **Criterion of success**: "El 100% de los conteos interrumpidos se pueden retomar sin pérdida de datos ya ingresados." (indirectly — if differences aren't visible, user can't audit their own work)
- **Gap identified**: Spec defines *that* differences must be shown but does NOT specify *how* — no UI pattern for visually distinguishing differences (e.g., color, icon, alert style).

### plan.md

- **Affected sections**: Phase 4 (User Story 2) — Registrar Valores del Conteo
  - "Create Angular component HTML for item registration: input type=number per item, show diferencia calculated locally (real - esperado) below each input, apply Tailwind classes for color (red if negative, green if positive per FE-RESP-01 mobile-first)"
  - Plan explicitly calls for red/green coloring but green checkmark in UI suggests implementation misunderstood "green = positive difference" as "success"
- **Impact**: Frontend component styling is incorrect or misapplied

### tasks.md

- **Affected tasks**:
  - T041: "Create Angular component HTML for item registration: input type=number per item, show diferencia calculated locally (real - esperado) below each input, apply Tailwind classes for color (red if negative, green if positive per FE-RESP-01 mobile-first)"
  - T042: "Implement Angular autosave in `inventario-conteo.component.ts`: on-blur (or debounce 500ms) emit PATCH /inventarios/{id}/items/{item_id}, update UI with response diferencia, handle 403 conteo_bloqueado (show error toast, lock form)"
- **False completions**: Both marked `[x]` but the visual indicator (green checkmark) is not aligned with spec intent (real-time difference visibility, color coding red/green for values not outcomes)

---

## Root Cause Analysis

The frontend component is likely using a "success checkmark" icon that displays whenever any difference is calculated, rather than:

1. Displaying the *value* of the difference (e.g., "-400 ml")
2. Applying conditional color to that value (red for negative, green for positive)

**Why this bug exists**:

- Spec gap: RF-INV-02.3 does not define the visual UX pattern for showing differences (only that they must be "shown in real time")
- Task T041 calls for color coding but doesn't detail the visual component (number vs. icon vs. both)
- Frontend developer may have interpreted "show difference" as "confirm that a difference was calculated" (hence checkmark) rather than "make the difference value visible to the user"

---

## Recommended Fix

1. **Spec clarification**: Update RF-INV-02.3 to specify the visual pattern:
   - Example: "The system displays the difference value (real − esperado) as a number below the input field, color-coded: red text for negative differences (loss), green text for positive differences (gain), gray if no difference (0)."
   - Optionally add icon: "Accompanied by a ⚠️ warning icon if difference ≠ 0, or ✓ if difference = 0."

2. **Frontend fix**:
   - Replace green checkmark with displayed difference value
   - Apply red/green text coloring to the value based on sign
   - Show the unit (e.g., "ml", "unidades") so operator understands the magnitude
   - Example HTML: `<span [ngClass]="{ 'text-red-600': diferencia < 0, 'text-green-600': diferencia > 0 }">{{ diferencia }} {{ item.unidad_medida }}</span>`

3. **Testing**: Verify in T041-T042 tests that:
   - Difference value is visible and readable
   - Color changes based on sign (not static green)
   - Unit of measure is displayed
   - Accessibility: aria-label describes the difference for screen readers

4. **Task reopening**: Mark T041 and T042 as incomplete.

**Next steps**:

- Run `/speckit.bugfix.patch` to update RF-INV-02.3 with visual pattern
- Update `inventario-conteo.component.html` to display difference value with conditional styling
- Add unit of measure to display
- Add accessibility labels

---

**Status**: ✅ Patched
**Patched**: 2026-07-18
**Assigned to**: Frontend + Design + UX
**Dependencies**: Backend must return `unidad_medida` in item response for display; spec must clarify visual pattern

---

**Patches Applied**:

- ✅ spec.md: Updated RF-INV-02.3 with visual pattern specification (color conditional, value display, unit, icons)
- ✅ tasks.md: Reopened T041 with note to display difference as VALUE with conditional color (already reopened for FE-BUG-008, enhanced)
- ✅ tasks.md: Reopened T042 with note to update difference UI per RF-INV-02.3 specification

---

## Additional Context

Per FE-LISTFORM-01 (referenced in task T041 and plan.md T070), the pattern for color-coding should align with:

- Red for losses/negative values (operator sees actual < expected)
- Green for gains/positive values (operator sees actual > expected)
- This is a **difference value display**, not a "success/failure" indicator
