# Bug Report: Duplicate Inventory Error Message Misrepresents Closed Count as In-Progress

**Type**: Implementation drift (messaging)
**Severity**: High
**Feature**: 009-inventario-conteo
**Reported**: 2026-07-18

---

## Description

When the operator attempts to create a new inventory count for the same store, type, and schedule as an existing (already closed) inventory, the frontend displays the message:

**Current message**:
> "Ya existe un conteo en progreso para esta tienda, tipo y horario. Usa la opción Reanudar si deseas continuar."
> (There is already a count in progress for this store, type and schedule. Use the Resume option if you want to continue.)

**Problem**: The message is inaccurate. The actual backend error (logged) is `error_code=conteo_duplicado` and the backend knows the existing inventory is *closed* (completado), not "in progress". The message misleads the operator into thinking they can resume an interrupted count, when in fact the system is preventing duplicate counts (even if closed).

**Observed behavior**:

- Backend logs: `error_code=conteo_duplicado error_message="Ya existe un conteo en progreso para esta tienda, tipo y horario en esta fecha"`
- Frontend displays: "...en progreso... Usa la opción Reanudar" (suggesting resumption is possible)
- Actual state: Inventory already completed/closed; cannot resume
- User action: Operator tries to click "Resume" (if button shown) or is confused about what to do

**Impact**: User confusion, loss of trust in system clarity, inability to proceed with legitimate new count for different time window.

---

## Artifact Traceability

### spec.md

- **Affected user story**: HU1 — Iniciar un conteo de inventario (Priority P1)
- **Affected requirements**:
  - RF-INV-01.4: "Only puede existir un inventario `en_progreso` por tienda, tipo y horario en la misma fecha. El sistema bloquea intentos duplicados."
  - HU1 Scenario 3: "**Dado** que ya existe un conteo `diario / apertura` en progreso en esa tienda, **Cuando** otro usuario de la misma tienda intenta iniciar otro conteo del mismo tipo y horario en la misma fecha, **Entonces** el sistema bloquea la operación indicando que ya existe un conteo en curso en dicha tienda."
- **Gap identified**:
  - RF-INV-01.4 and HU1-AC3 only specify blocking when `en_progreso` exists, but the backend is also blocking duplicate types even if the existing one is `completado` (closed)
  - Spec does NOT define what message to show when the existing count is closed vs. open
  - The error handling per HTTP status codes (contracts/api.md likely returns 409 Conflict for both) doesn't differentiate between "in progress" and "already closed"

### plan.md

- **Affected sections**: Phase 3 (User Story 1) — Iniciar Conteo
  - "T029 [US1] Implement HTTP handler `PostInventario()`... return 409 si conteo_duplicado..."
  - Plan does not specify error message content or differentiation between states
- **Impact**: Error message mapping in Angular service is generic and doesn't distinguish duplicate states

### tasks.md

- **Affected tasks**:
  - T032: "Implement Angular POST /inventarios call in `inventario-conteo.component.ts`: on form submit, POST to service, handle 201 (transition to step 2: register items), handle errors (409 conteo_duplicado, etc.) per spec error format"
- **False completions**: Task marked `[x]` but error message is not user-friendly per FE-ERR-01 standards (Spanish, concise, actionable)

---

## Root Cause Analysis

**Backend issue**:

- Backend validation returns `error_code=conteo_duplicado` without differentiating whether the duplicate is `en_progreso` or `completado`
- Error message is hardcoded: "Ya existe un conteo en progreso..." which is only accurate for `en_progreso` state

**Frontend issue**:

- Angular `error-mapper.service.ts` maps `conteo_duplicado` to a generic message without checking the backend's full error details or state
- No logic to distinguish between "in progress" and "closed" scenarios

**Why this bug exists**:

- Spec gap: RF-INV-01.4 doesn't address what happens if user tries to create duplicate of a *closed* count (should it be allowed on different date? different time window?)
- Backend doesn't return enough detail in error response to distinguish states
- Frontend assumes all duplicates are "in progress" resumable situations

---

## Recommended Fix

### Option A: Clarify Spec Requirement

1. **Update RF-INV-01.4** to explicitly state the blocking rule:
   - "A new inventory count is blocked if an inventory of the same (store, type, schedule, **date**) exists in state `en_progreso`."
   - OR: "... exists in state `en_progreso` **or** `completado` on the same date." (if blocking is permanent per date)
   - Clarify whether user can retry on a different time window or different date.

2. **Update RF-INV-01.3** to define: "User can manually change the type/schedule to differentiate if needed."

### Option B: Improve Error Messaging (Short-term, aligns with current backend behavior)

**Backend fix** (loopi-api-v2):

- Modify error response to include state of conflicting inventory:

```json
{
  "error": "conteo_duplicado",
  "mensaje": "Ya existe un conteo...",
  "detalles": {
    "conflicting_inventory_id": 123,
    "conflicting_state": "en_progreso" | "completado",
    "conflicting_fecha": "2026-07-18"
  }
}
```

**Frontend fix** (loopi-web-v2):

- Update `error-mapper.service.ts` to check `detalles.conflicting_state`:

```typescript
if (error.code === 'conteo_duplicado') {
  const state = error.detalles?.conflicting_state;
  if (state === 'en_progreso') {
    return "Ya existe un conteo en progreso para esta tienda, tipo y horario. Usa la opción Reanudar si deseas continuar.";
  } else if (state === 'completado') {
    return "Ya existe un conteo completado para esta tienda, tipo y horario en esta fecha. No se pueden crear conteos duplicados en el mismo día.";
  }
  return "Ya existe un conteo para esta tienda, tipo y horario. Por favor intenta con parámetros diferentes.";
}
```

**Frontend component fix** (loopi-web-v2):

- Show different action buttons based on state:
  - If `en_progreso`: Show "Reanudar" button + "Cancelar" button
  - If `completado`: Show "Aceptar" button (no resume option)

**Testing**:

- Test scenario 1: Duplicate `en_progreso` → message includes "Resume" option
- Test scenario 2: Duplicate `completado` → message indicates closed status, no resume
- Verify both messages are friendly-human and actionable

### Option C: Desired Long-term (combines spec clarity + messaging)

1. Update spec to allow retries on different time windows (if user selects different horario, allow count)
2. Backend returns detailed error with conflicting inventory details + suggestion to retry with different schedule
3. Frontend offers smart action: "Reanudar Conteo Anterior" (if in progress) or "Iniciar Conteo Diferente" (offer horario options if closed)

---

## Recommended Priority

**Choose Option B** (Improve Error Messaging) for immediate fix:

- Lowest risk (no spec change, minimal backend change, frontend logic only)
- Addresses FE-ERR-01 standard (Spanish, clear, actionable)
- Aligns with current backend behavior while improving UX

**Then run** `/speckit.bugfix.patch` to document the improvement and prep for Option A (spec clarification) in a future iteration.

---

**Next steps**:

1. Backend returns conflicting inventory state in error response
2. Frontend maps error to user-friendly message per state
3. Frontend shows appropriate action button ("Reanudar" vs. "Aceptar")
4. Mark T032 as reopened until messaging is verified

---

**Status**: ✅ Patched
**Patched**: 2026-07-18
**Assigned to**: Backend + Frontend + UX
**Dependencies**: Backend error response must include `conflicting_state` in detalles; spec may need clarification on duplicate blocking rules

---

**Patches Applied**:

- ✅ spec.md: Updated RF-INV-01.4 to clarify blocking applies to any state (en_progreso or completado) and specify differentiated error messages per state
- ✅ spec.md: Added FE-BUG-010 entry to "Nuevos Bugs Identificados" section
- ✅ tasks.md: Reopened T032 with note to differentiate error messages by duplicate state (en_progreso vs completado) per RF-INV-01.4

---

## Additional Context

**FE-ERR-01 Standards** (from user memory):

- Messages must be in Spanish ✓
- Messages must be concise ✓ (current message is, but inaccurate)
- Messages must be actionable ✗ (current message suggests "Resume" which is not possible for closed counts)

**Related specs**:

- RF-INV-01.4: Duplicate blocking rule
- RF-INV-02.5: Reopen/resume rights (only original responsable can resume)
- contracts/api.md endpoint 2: POST /inventarios error responses
