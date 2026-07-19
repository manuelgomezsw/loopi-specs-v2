---
description: "Surgically update spec, plan, and tasks to address the reported bug"
---

# Patch Spec Artifacts

Surgically update spec.md, plan.md, and tasks.md to address a reported bug — adds missing requirements, fixes conflicts, reopens false completions, and adds new tasks. Minimal changes only, never regenerates from scratch.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). The user may specify a bug report to patch (e.g., "BUG-001") or describe the fix directly.

## Prerequisites

1. Verify a spec-kit project exists by checking for `.specify/` directory
2. Locate the current feature's spec directory
3. Check for bug reports in `specs/{feature}/bugs/` — if a bug ID is provided, load that report
4. If no bug report exists, inform the user and suggest running `/speckit.bugfix.report` first

## Outline

1. **Load bug context**: Read the relevant bug report and all spec artifacts:
   - **Bug report**: `specs/{feature}/bugs/BUG-{NNN}.md` (if specified)
   - **Required**: `spec.md`, and at least one of `plan.md` or `tasks.md`
   - **Optional**: `research.md`, `data-model.md`

2. **Determine patches**: Based on the bug type, plan minimal changes:

   | Bug Type | spec.md Patch | plan.md Patch | tasks.md Patch |
   |----------|--------------|---------------|----------------|
   | Spec gap | Add missing requirement to affected user story | Add implementation note to relevant section | Add new task(s) for the missing requirement |
   | Spec conflict | Resolve conflict with strikethrough on superseded text + new clarified requirement | Update affected section | Update affected task descriptions |
   | Implementation drift | Add clarification note to requirement | No change (plan was correct) | Reopen drifted task with correction note |
   | Untested flow | Add success criterion for the edge case | Add edge case to complexity tracking | Add verification task |
   | Dependency issue | Update assumption about external dependency | Update technical context | Add dependency investigation task |

2.2. **[NEW - Level 2] Verify patches against all normative documents BEFORE proceeding**:

   *GATE: Validate patch compliance before designing implementation*

   Before proceeding to Step 3, verify the patch against:
   - ✅ **constitution.md** (P-I to P-VI): Does patch violate any principle?
   - ✅ **standards/backend.md** (BE-ARCH-01 to BE-OBS-01, if backend): Does patch comply?
   - ✅ **standards/frontend.md** (FE-STACK-01 to FE-CI-01, if frontend): Does patch comply?
   - ✅ **standards/environments-ci.md** (ENV-01, CI-01, CI-02): Does patch comply?

   **Checks**:
   1. **Constitutional violations**: Does patch violate P-III (RBAC), P-IV (Trazabilidad), P-V (Prevención)?
      - If YES → ABORT: Report constitutional violation to user
      - If NO → Continue
   
   2. **Backend standard impact** (if backend scope):
      - Will patch require new BE-* tasks for Phase 9 (Cumplimiento Constitucional)?
      - Will patch require changes to BE-ARCH-01 (layer separation)?
      - Will patch affect BE-TEST-01 (coverage thresholds)?
      - Add citations to affected BE-* IDs in new tasks
   
   3. **Frontend standard impact** (if frontend scope):
      - Will patch require new FE-* tasks for Phase 9?
      - Will patch affect FE-COMP-01 (transversal components)?
      - Will patch affect FE-RESP-01 (responsive design)?
      - Add citations to affected FE-* IDs in new tasks
   
   4. **CI/Environment impact**:
      - Does patch affect CI-01 (Gitflow procedures)?
      - Does patch introduce security concerns (CI-02)?

   **Regression check** (IF loading previous bugs):
   - For each previously patched BUG: Does this patch break or contradict the previous fix?
   - If potential regression: ABORT and flag

   **If violations detected**:
   ```
   ❌ CONSTITUTION VIOLATION DETECTED

   Patch violates: [List P-*, BE-*, FE-* IDs]
   
   ACTION: Do not proceed. Choose one:
   1. Modify patch to align with standards (and re-run this step)
   2. Document violation in Complexity Tracking (requires approval)
   3. Escalate to product team for constitutional amendment decision
   ```

   **If OK**:
   ```
   ✅ CONSTITUTION & STANDARDS VERIFIED

   Patch is compliant with:
   - All applicable principles (P-I to P-VI)
   - All applicable standards (BE-*, FE-*, CI-*)
   
   Standards affected that MUST be cited in Phase 9:
   - [List which BE-*, FE-*, CI-* the patch addresses]
   
   Proceed to Step 3 (Patch spec.md, plan.md, tasks.md)
   ```

3. **Patch spec.md**:
   - Add missing requirements under the affected user story
   - Mark conflicting text with `~~strikethrough~~` and reason
   - Add success criteria for untested flows
   - Update assumptions if dependencies changed
   - Add a bugfix note:
     ```
     **Bugfix**: [DATE] — [BUG-NNN] [Brief description of what was patched]
     ```

4. **Patch plan.md** (if it exists):
   - Update affected sections with new context
   - Add complexity notes for newly discovered edge cases
   - Preserve all existing content — only add or annotate
   - Add a bugfix note:
     ```
     **Bugfix**: [DATE] — [BUG-NNN] Updated from bugfix patch
     ```

5. **Patch tasks.md** (if it exists):
   - **Add new tasks**: Assign next sequential IDs, proper dependencies, and story labels
   - **Reopen tasks**: Change `[x]` back to `[ ]` with a note: `(reopened — BUG-NNN)`
   - **Mark false completions**: Add `⚠️ Reopened` prefix to task description
   - **Update Wave DAG**: If present, regenerate to include new tasks
   - Add a bugfix note:
     ```
     **Bugfix**: [DATE] — [BUG-NNN] Updated from bugfix patch
     ```

6. **Markdown Lint Validation** (NEW — Step 3.5):

   *GATE: Validates patches before writing to disk*

   Before proceeding to save files, validate markdown syntax and constitutional compliance:

   1. **Run lint validation** (see `lint-validator.md` for full details):
      ```
      Lint patched spec.md, plan.md, tasks.md against:
      - .markdownlint-cli2.jsonc rules (MD001-MD051)
      - Constitution Check table format (if plan.md modified)
      - Rule ID validity (all P-*, BE-*, FE-*, CI-01 exist in standards/)
      - Phase 9 task citations (all tasks cite [ID] in brackets)
      - Bugfix note format (date, BUG-NNN, description)
      ```

   2. **Handle violations**:
      - **Markdown syntax errors**: Offer auto-fix for fixable issues (whitespace, alignment)
        - Accept auto-fix → proceed to save
        - Reject auto-fix → abort patch, suggest `/speckit.bugfix.report` for clarification
      - **Constitutional violations** (invalid IDs, missing citations, orphaned references):
        - Report specific violations (which line, which rule ID)
        - Do NOT auto-fix (requires human judgment)
        - Suggest correction and abort → require user to fix and re-patch

   3. **Success criteria**:
      ```
      ✅ Markdown Lint Validation PASSED
      
      All patches validated:
        • spec.md: Syntax ✅, Constitutional compliance ✅
        • plan.md: Syntax ✅, Constitution Check valid ✅, Rule IDs valid ✅
        • tasks.md: Syntax ✅, Phase 9 citations valid ✅, No orphaned IDs ✅
      
      Ready to proceed with save step.
      ```

   **Impact**: Eliminates pre-commit hook failures downstream. All files written to disk are guaranteed markdown-compliant and constitutionally-aligned.

7. **Update bug report**: Mark the bug report file as patched:
   ```
   **Status**: Patched
   **Patched**: [DATE]
   ```

8. **Report**: Output a summary:
   - What changed in each artifact
   - How many requirements were added or updated
   - How many tasks were added or reopened
   - Lint validation result (pass/fail + specific issues fixed)
   - Suggest next step: `/speckit.bugfix.verify` to confirm consistency, then `/speckit.implement` to apply the code fix

## Rules

- **Surgical updates only** — never regenerate artifacts from scratch, only modify affected sections
- **Never delete content** — use strikethrough for superseded text, preserve history
- **Preserve formatting** — match existing artifact style exactly
- **Track changes** — always add bugfix notes with dates and bug IDs
- **Reopen, don't delete tasks** — falsely completed tasks get reopened, not removed
- **Require bug report** — if no bug report or user description is provided, refuse to patch and suggest `/speckit.bugfix.report` first
- **Minimal changes** — change only what is necessary to address the specific bug
