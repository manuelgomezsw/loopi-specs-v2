# spec-kit-bugfix

A [Spec Kit](https://github.com/github/spec-kit) extension that adds a structured bugfix workflow — capture bugs discovered during implementation, trace them to spec artifacts, and surgically patch specs without regenerating from scratch.

## Problem

When bugs surface during implementation, the SDD workflow breaks down:

- No structured way to capture bugs and trace them back to spec requirements
- Spec gaps and conflicts are discovered but not recorded anywhere
- Developers fix code without updating spec, plan, or tasks — causing artifact drift
- Tasks marked complete turn out to be wrong, but there is no reopen mechanism
- No way to verify that bugfix changes are consistent across all artifacts
- **[Loopi-specific]** Patched specs may violate constitutional principles (P-I to P-VI) or standards (BE-*, FE-*) without detection
- **[Loopi-specific]** Markdown linting errors in patches cause pre-commit hook failures downstream, requiring re-work cycles

## Solution

The Bugfix Workflow extension adds three commands that close the gap between bug discovery and spec correction:

| Command | Purpose | Modifies Files? |
|---------|---------|-----------------|
| `/speckit.bugfix.report` | Capture a bug and trace it back to the relevant spec, plan, and task artifacts | Yes — creates bug report file |
| `/speckit.bugfix.patch` | Surgically update spec, plan, and tasks to address the reported bug | Yes — spec.md, plan.md, tasks.md |
| `/speckit.bugfix.verify` | Verify that bugfix patches are consistent across all spec artifacts | No — read-only |

## Installation

```bash
specify extension add --from https://github.com/Quratulain-bilal/spec-kit-bugfix/archive/refs/tags/v1.0.0.zip
```

## Bug Types

The extension classifies bugs into five categories:

| Type | Description | Example |
|------|-------------|---------|
| Spec gap | Requirement missing from spec | Auth flow doesn't handle expired tokens |
| Spec conflict | Two requirements contradict | "Must be stateless" vs "Must track sessions" |
| Implementation drift | Code diverges from spec | Spec says REST, code uses GraphQL |
| Untested flow | Edge case not covered | Concurrent user updates not handled |
| Dependency issue | External dependency changed | API response format differs from assumption |

## Workflow

```
Bug discovered during /speckit.implement
       │
       ▼
/speckit.bugfix.constitution-check  ← [NEW] Analyze against all normative docs
       │                              (constitution.md + 3 standards/*.md)
       │ (Risk: CRITICAL/WARNING/OK)
       │
       ▼
/speckit.bugfix.report              ← Capture bug, trace to artifacts, classify
       │                              (Report includes standards compliance)
       │
       ▼
/speckit.bugfix.patch               ← [ENHANCED] Verify patch compliance (Level 2)
       │                              then surgically update spec, plan, tasks
       │                              (Step 2.2: Constitution & standards gate)
       │                              (Step 3.5: Markdown lint gate)
       │
       ▼
/speckit.bugfix.verify              ← Confirm consistency + standards alignment
       │                              (Includes historical bug relationships)
       │
       ▼
/speckit.implement                  ← Resume implementation with corrected specs
```

## Loopi v2: Four Normative Documents

Every bug is validated against Loopi v2's governance framework:

| Document | Scope | Rules | Updated |
|----------|-------|-------|---------|
| **constitution.md** | Principles | P-I, P-II, P-III, P-IV, P-V, P-VI | ✅ v2.0.0 |
| **standards/backend.md** | Backend implementation | BE-ARCH-01 to BE-OBS-01 (8 rules) | ✅ v1.0.0 |
| **standards/frontend.md** | Frontend implementation | FE-STACK-01 to FE-CI-01 (20 rules) | ✅ v1.0.0 |
| **standards/environments-ci.md** | Environments & CI | ENV-01, CI-01, CI-02 | ✅ v1.0.0 |

**All bugs are validated against all applicable documents**:
- Always check: P-I to P-VI + CI-01 (Gitflow)
- If backend: Check BE-* rules
- If frontend: Check FE-* rules
- If environment-related: Check ENV-*, CI-02

See `/speckit.bugfix.constitution-check` for detailed validation matrix.

## Commands

### `/speckit.bugfix.constitution-check` (NEW)

Analyze bug against ALL four normative documents **before** reporting it.

- Validates against constitution.md (P-I to P-VI)
- Validates against standards/backend.md (if backend)
- Validates against standards/frontend.md (if frontend)
- Validates against standards/environments-ci.md (CI/environment)
- Output: Risk assessment (CRITICAL/WARNING/OK) + affected standards
- **Recommendation**: Run this FIRST, before /speckit.bugfix.report

### `/speckit.bugfix.report`

Captures a bug and produces a structured report with full artifact traceability:

- Classifies the bug type (spec gap, conflict, drift, untested flow, dependency)
- Maps to affected user stories, requirements, and tasks by ID
- Identifies root cause (spec oversight, changed requirement, or implementation error)
- Saves report to `specs/{feature}/bugs/BUG-{NNN}.md`

### `/speckit.bugfix.patch`

Surgically updates spec artifacts based on a bug report:

- Adds missing requirements to spec.md under the affected user story
- Marks conflicting text with strikethrough and reason (never deletes)
- Reopens falsely completed tasks with `(reopened — BUG-NNN)` annotation
- Adds new tasks with sequential IDs and proper dependencies
- Updates Wave DAG if present
- Tracks all changes with bugfix notes and dates

**[NEW]** Validates markdown & constitutional compliance before writing to disk:

- ✅ Markdown syntax check (.markdownlint-cli2.jsonc rules)
- ✅ Constitutional rule ID validation (P-*, BE-*, FE-*, CI-01)
- ✅ Constitution Check table format validation (if plan.md modified)
- ✅ Phase 9 task citations validation (all tasks cite [ID])
- ✅ Bugfix note format validation
- ✅ Reports specific violations before saving (eliminates pre-commit hook failures)
- See `lint-validator.md` for complete validation rules

### `/speckit.bugfix.verify`

Read-only consistency check after patching:

- Verifies all bug reports are patched
- Checks spec requirements have corresponding plan sections and tasks
- Confirms reopened tasks are properly annotated
- Validates task ID sequencing and dependency DAG
- Reports cross-artifact traceability status

## Hooks

The extension registers an optional hook:

- **after_implement**: Runs bugfix consistency check after implementation completes

## Design Decisions

- **Report before patch** — always capture and classify the bug before modifying artifacts
- **Surgical updates** — only change what is necessary, never regenerate from scratch
- **Never delete content** — superseded text gets strikethrough, preserving history
- **Reopen, don't delete tasks** — falsely completed tasks are reopened with annotation
- **Bug report files** — each bug gets its own file for traceability and history
- **Consistent with Spec Kit patterns** — uses the same refinement note format and staleness tracking
- **[Loopi v2]** **Lint validation before save** — patches are validated against markdown linting and constitutional compliance rules before writing to disk, eliminating downstream pre-commit failures
- **[Loopi v2]** **Constitutional awareness** — bugfix patches verify that modified specs, plans, and tasks respect Loopi v2 principles (P-I to P-VI) and standards (BE-*, FE-*, CI-01)

## Requirements

- Spec Kit >= 0.4.0

## Related

- Issue [#619](https://github.com/github/spec-kit/issues/619) — New `/bugfix` Slash Command (25+ upvotes, maintainer-approved as extension)

## License

MIT
