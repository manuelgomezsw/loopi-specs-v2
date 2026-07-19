---
description: "Capture a bug and trace it back to the relevant spec, plan, and task artifacts"
---

# Report Bug

Capture a bug discovered during implementation and trace it back to the relevant specification artifacts. Produces a structured bug report that maps the issue to spec requirements, plan sections, and tasks.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). The user describes the bug — what went wrong, error messages, unexpected behavior, or a gap discovered during implementation.

## Prerequisites

1. Verify a spec-kit project exists by checking for `.specify/` directory
2. Locate the current feature's spec directory (by branch name or most recently modified)
3. Verify at least `spec.md` exists

## Outline

1. **[NEW] Load bug history and run constitutional check**:
   - Load all previous bug reports: `specs/{feature}/bugs/BUG-*.md` for context
   - Run `/speckit.bugfix.constitution-check <bug-description>` to validate against:
     - constitution.md (P-I to P-VI)
     - standards/backend.md (BE-ARCH-01 to BE-OBS-01, if backend)
     - standards/frontend.md (FE-STACK-01 to FE-CI-01, if frontend)
     - standards/environments-ci.md (ENV-01, CI-01, CI-02)
   - If CRITICAL violations: Recommend escalation before proceeding
   - If WARNING: Document violations for Complexity Tracking
   - If OK: Proceed with confidence

2. **Load artifacts**: Read from the current feature directory:
   - **Required**: `spec.md` (the specification)
   - **Optional**: `plan.md`, `tasks.md`, `research.md`, `data-model.md`

3. **Analyze the bug**: From the user's description, classify the bug:

   | Bug Type | Description | Example |
   |----------|-------------|---------|
   | Spec gap | Requirement missing from spec | Auth flow doesn't handle expired tokens |
   | Spec conflict | Two requirements contradict | "Must be stateless" vs "Must track sessions" |
   | Implementation drift | Code diverges from spec | Spec says REST, code uses GraphQL |
   | Untested flow | Edge case not covered in success criteria | Concurrent user updates not handled |
   | Dependency issue | External dependency behaves differently than assumed | API response format changed |

4. **Trace to artifacts**: Map the bug to specific sections in each artifact:
   - **spec.md**: Which user story, requirement, or success criterion is affected?
   - **plan.md**: Which plan section covers this area?
   - **tasks.md**: Which task(s) relate to this area? Are any marked complete that shouldn't be?
   - **Related bugs**: Reference any previous BUG-NNN that this is related to

5. **Generate bug report**: Output a structured report:

   ```markdown
   # Bug Report: [Short Title]

   **Type**: [Spec gap | Spec conflict | Implementation drift | Untested flow | Dependency issue]
   **Severity**: [Critical | High | Medium | Low]
   **Feature**: [Feature name/branch]
   **Reported**: [DATE]

   ## Description
   [User's bug description, clarified and structured]

   ## Constitutional & Standards Compliance (from /speckit.bugfix.constitution-check)

   ### Principle Impact (constitution.md)
   | Principle | Status | Details |
   |-----------|--------|---------|
   | P-I: Spec-First | ✅/⚠️/❌ | [From constitution-check output] |
   | P-II: Multi-Tienda | ✅/⚠️/❌ | [From constitution-check output] |
   | P-III: RBAC | ✅/⚠️/❌ | [From constitution-check output] |
   | P-IV: Trazabilidad | ✅/⚠️/❌ | [From constitution-check output] |
   | P-V: Prevención Pérdidas | ✅/⚠️/❌ | [From constitution-check output] |
   | P-VI: Monitoreo | ✅/⚠️/❌ | [From constitution-check output] |

   ### Backend Standards Impact (standards/backend.md) [IF APPLICABLE]
   | Standard | Status | Details |
   |----------|--------|---------|
   | BE-ARCH-01 | ✅/⚠️/❌ | [From constitution-check output] |
   | BE-CACHE-01 | ✅/⚠️/❌ | [From constitution-check output] |
   | BE-TEST-01 | ✅/⚠️/❌ | [From constitution-check output] |
   | BE-API-01 | ✅/⚠️/❌ | [From constitution-check output] |
   | [... other BE-* as applicable] | | |

   ### Frontend Standards Impact (standards/frontend.md) [IF APPLICABLE]
   | Standard | Status | Details |
   |----------|--------|---------|
   | FE-STACK-01 | ✅/⚠️/❌ | [From constitution-check output] |
   | FE-RESP-01 | ✅/⚠️/❌ | [From constitution-check output] |
   | FE-A11Y-01 | ✅/⚠️/❌ | [From constitution-check output] |
   | [... other FE-* as applicable] | | |

   ### CI/Environment Impact (standards/environments-ci.md)
   | Standard | Status | Details |
   |----------|--------|---------|
   | CI-01: Gitflow | ✅/⚠️/❌ | [From constitution-check output] |
   | CI-02: Security | ✅/⚠️/❌ | [From constitution-check output] |

   ### Overall Risk Level
   **🔴 CRITICAL / 🟡 WARNING / 🟢 OK** — [From constitution-check output]

   ## Artifact Traceability

   ### spec.md
   - **Affected user story**: [Story N — title]
   - **Affected requirements**: [List specific requirements]
   - **Gap identified**: [What is missing or wrong in the spec]

   ### plan.md
   - **Affected sections**: [List plan sections]
   - **Impact**: [What needs to change in the plan]

   ### tasks.md
   - **Affected tasks**: [Task IDs and descriptions]
   - **False completions**: [Tasks marked done that need reopening]
   - **Missing tasks**: [New tasks needed to fix the bug]

   ### Related Previous Bugs
   - **BUG-NNN**: [Status] [Description] — [Relationship: "same root cause" / "regression risk" / "dependency"]

   ## Root Cause Analysis
   [Why this bug exists — was it a spec oversight, changed requirement, or implementation error?]

   ## Recommended Fix
   1. If CRITICAL violations: Escalate to product/legal before proceeding
   2. If WARNING violations: Document in Complexity Tracking before patching
   3. Run `/speckit.bugfix.patch` to update spec artifacts with standards compliance
   4. Run `/speckit.bugfix.verify` to confirm consistency and standards alignment
   5. Resume `/speckit.implement` to apply the code fix
   ```

5. **Save report**: Write the bug report to `specs/{feature}/bugs/BUG-{NNN}.md` where `{NNN}` is the next sequential bug number. Create the `bugs/` directory if it does not exist.

6. **Report**: Output the bug report and suggest next steps.

## Rules

- **Always trace to artifacts** — every bug must map to at least one spec section
- **Never modify spec artifacts** — this command only reports, use `/speckit.bugfix.patch` to make changes
- **Sequential numbering** — bug reports are numbered BUG-001, BUG-002, etc.
- **Classify accurately** — distinguish between spec gaps (missing requirements) and implementation drift (code doesn't match spec)
- **Be specific** — reference exact user story numbers, requirement text, and task IDs
