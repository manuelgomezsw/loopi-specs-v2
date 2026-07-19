---
description: "Analyze bug against Loopi v2 constitution and standards before reporting"
---

# Constitutional & Standards Impact Check

Analyze a bug or feature request against Loopi v2's four normative documents **before** reporting it. Identifies violations, affected standards, and risk level to guide the reporting and patching workflow.

## Purpose

Prevents bugs that violate constitutional principles from being reported and patched without awareness. Surfaces CRITICAL violations early so they can be escalated to product/legal before engineering effort is spent.

## User Input

```text
$ARGUMENTS
```

Describe the bug or feature: "Barista should be able to delete inventories", "Conteo doesn't handle concurrent updates", etc.

## Prerequisites

1. Verify a spec-kit project exists by checking for `.specify/` directory
2. Verify `.specify/memory/constitution.md` exists
3. Verify `.specify/memory/standards/` directory contains:
   - `backend.md`
   - `frontend.md`
   - `environments-ci.md`

## Outline

### 1. Load Normative Documents

Read the four authoritative sources:
- **constitution.md** → Principles P-I to P-VI
- **standards/backend.md** → Rules BE-ARCH-01 to BE-OBS-01
- **standards/frontend.md** → Rules FE-STACK-01 to FE-CI-01
- **standards/environments-ci.md** → Rules ENV-01, CI-01, CI-02

### 2. Classify Bug Type

From user input, classify into one of five categories:

| Type | Description | Example |
|------|-------------|---------|
| Spec gap | Requirement missing from spec | "Auth flow doesn't handle token expiration" |
| Spec conflict | Two requirements contradict | "Stateless" vs "Track sessions" |
| Implementation drift | Code diverges from spec | "Spec says REST, code uses GraphQL" |
| Untested flow | Edge case not covered | "Concurrent updates not handled" |
| Dependency issue | External dependency changed | "API response format changed" |

### 3. Determine Scope

Identify what domain(s) are affected:
- **Backend-only** → Will use standards/backend.md rules
- **Frontend-only** → Will use standards/frontend.md rules
- **Full-stack** → Will use both
- **CI/Environment** → Will use standards/environments-ci.md

### 4. Validate Against Constitutional Principles

Check all bugs against P-I to P-VI (always applicable):

| Principle | Check | Violation Example |
|-----------|-------|---|
| **P-I: Spec-First** | Is the gap/conflict documented in spec? | Gap not in spec.md → potential issue |
| **P-II: Multi-Tienda** | Does bug affect tienda_id isolation? | "List without tienda_id filter" → P-II violation |
| **P-III: RBAC** | Does bug affect role permissions? | "Barista can delete" → violates RBAC matrix |
| **P-IV: Trazabilidad** | Does bug affect audit trail? | "Modify without recording who/when" → P-IV violation |
| **P-V: Prevención Pérdidas** | Does bug create fraud opportunity? | "Unrestricted deletion" → P-V violation |
| **P-VI: Monitoreo** | Does bug affect observability? | "Critical endpoint without metrics" → P-VI violation |

### 5. Validate Against Backend Standards (IF backend scope)

If bug affects `loopi-api-v2`, check:

| Standard | Check |
|----------|-------|
| **BE-ARCH-01** | Will fix require changes to layer separation? (handler/service/repository) |
| **BE-CACHE-01** | Will fix affect caching? (TTL, invalidation strategy) |
| **BE-TEST-01** | Will fix require ≥95% logic coverage, ≥90% infrastructure coverage? |
| **BE-API-01** | Does endpoint follow `/api/v1/` prefix, error format, status codes? |
| **BE-DATA-01** | Do new columns follow PK BIGINT UNSIGNED, snake_case, timestamps conventions? |
| **BE-JOBS-01** | Will fix require scheduled jobs? Do they follow pattern? |
| **BE-OBS-01** | Will fix require OpenTelemetry spans/metrics? Are labels correct (no user_id)? |
| **BE-CI-01** | Will fix require new CI gates? (tests, coverage, lint) |

### 6. Validate Against Frontend Standards (IF frontend scope)

If bug affects `loopi-web-v2`, check:

| Standard | Check |
|----------|-------|
| **FE-STACK-01** | Uses Tailwind v4, not Material/PrimeNG? |
| **FE-RESP-01** | Mobile-first (<640px) + desktop (≥1024px)? |
| **FE-A11Y-01** | WCAG 2.1 AA? Labels, keyboard nav, contrast? |
| **FE-COMP-01** | Uses transversal components (ListCard, FilterBar, Pagination)? |
| **FE-LIST-01/FORMSURF-01** | 3-layer visual hierarchy? |
| **FE-FILTER-01** | Uses FilterBarComponent with Estado=Activo default? |
| **FE-CI-01** | Will fix pass ng test, lint, build? |

### 7. Validate Against CI/Environment Standards (ALWAYS)

Check affects on deployment and continuous integration:

| Standard | Check |
|----------|-------|
| **ENV-01** | Does bug affect dev/stage/prod separation? |
| **CI-01: Gitflow** | Bug reported in correct branch? (feature/*, not main/develop) |
| **CI-02: Security** | Will fix pass Trivy security scan? |

### 8. Generate Impact Report

Output structured analysis:

```markdown
# Constitutional & Standards Impact Analysis

**Bug/Feature**: [User description]
**Type**: [Spec gap | Spec conflict | Implementation drift | Untested flow | Dependency issue]
**Scope**: [Backend-only | Frontend-only | Full-stack | CI/Environment]

## Principle Impact (constitution.md)

| ID | Principle | Status | Details |
|----|-----------|--------|---------|
| P-I | Spec-First | ✅/⚠️/❌ | [Specific finding] |
| P-II | Multi-Tienda | ✅/⚠️/❌ | [Specific finding] |
| P-III | RBAC | ✅/⚠️/❌ | [Specific finding] |
| P-IV | Trazabilidad | ✅/⚠️/❌ | [Specific finding] |
| P-V | Prevención Pérdidas | ✅/⚠️/❌ | [Specific finding] |
| P-VI | Monitoreo | ✅/⚠️/❌ | [Specific finding] |

## Backend Standards Impact (standards/backend.md) [IF APPLICABLE]

| ID | Standard | Status | Details |
|----|----------|--------|---------|
| BE-ARCH-01 | Separación capas | ✅/⚠️/❌ | [Specific finding] |
| BE-CACHE-01 | Patrón decorador | ✅/⚠️/❌ | [Specific finding] |
| [... etc] | | | |

## Frontend Standards Impact (standards/frontend.md) [IF APPLICABLE]

| ID | Standard | Status | Details |
|----|----------|--------|---------|
| FE-STACK-01 | Stack | ✅/⚠️/❌ | [Specific finding] |
| FE-RESP-01 | Responsive | ✅/⚠️/❌ | [Specific finding] |
| [... etc] | | | |

## CI/Environment Impact (standards/environments-ci.md)

| ID | Standard | Status | Details |
|----|----------|--------|---------|
| ENV-01 | Ambientes | ✅/⚠️/❌ | [Specific finding] |
| CI-01 | Gitflow | ✅/⚠️/❌ | [Specific finding] |
| CI-02 | Security | ✅/⚠️/❌ | [Specific finding] |

## Risk Assessment

**Overall Risk Level**: 🔴 CRITICAL / 🟡 WARNING / 🟢 OK

**Affected Standards Summary**:
- P-* violations: [List]
- BE-* violations: [List]
- FE-* violations: [List]
- CI-* violations: [List]

### If CRITICAL
```
⛔ CRITICAL VIOLATION(S) DETECTED

This bug violates one or more CRITICAL principles:
- [List which P-* violated]
- [Impact on RBAC, trazabilidad, or loss prevention]

RECOMMENDATION: Escalate to product/legal team
This may require constitutional amendment or policy override.
Do NOT proceed to /speckit.bugfix.report until decision is made.
```

### If WARNING
```
⚠️ WARNING: Standards Violations Detected

This bug requires attention to the following standards:
- [List which BE-*/FE-* standards violated]
- [What patch must verify]

RECOMMENDATION: Proceed with /speckit.bugfix.report
BUT: Patch must document violations in Complexity Tracking
and add tasks to verify compliance (per Phase 9).
```

### If OK
```
✅ COMPLIANT: No constitutional violations detected

This bug aligns with all applicable principles and standards.

RECOMMENDATION: Proceed to /speckit.bugfix.report
Patch should cite relevant standards in Phase 9 (Cumplimiento Constitucional).
```

## References

Affected documents (for manual review):
- constitution.md: [Link to principles]
- standards/backend.md: [Link to affected BE-* rules]
- standards/frontend.md: [Link to affected FE-* rules]
- standards/environments-ci.md: [Link to affected CI-* rules]
```

### 9. Output and Recommendations

Print the impact report and suggest next step based on risk level:

- **CRITICAL** → "Escalate to product team before proceeding"
- **WARNING** → "Proceed to /speckit.bugfix.report, but document violations in Complexity Tracking"
- **OK** → "Proceed to /speckit.bugfix.report"

## Rules

- **Always check all four documents** — constitution.md + three standards/ files
- **Classify accurately** — choose correct bug type to apply correct validation matrix
- **Be specific about violations** — cite exact principle/standard that is violated
- **Risk-based escalation** — flag CRITICAL violations early, before engineering effort
- **Read-only** — this command never modifies any files
- **Context-aware** — scope determines which standards to check (backend-only vs full-stack)

## Output Format

Always output structured table format:
- Row per principle/standard
- Column for Status: ✅ OK / ⚠️ WARNING / ❌ CRITICAL
- Column for Details: specific finding or reference

## References

- **constitution.md** — Principles P-I to P-VI
- **standards/backend.md** — Backend rules BE-ARCH-01 to BE-OBS-01
- **standards/frontend.md** — Frontend rules FE-STACK-01 to FE-CI-01
- **standards/environments-ci.md** — Environment & CI rules ENV-01, CI-01, CI-02
- **lint-validator.md** — Markdown/format validation rules
