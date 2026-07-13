---
description: "Validate markdown syntax and constitutional compliance in bugfix patches"
---

# Markdown Lint Validator

Validates that bugfix patches maintain markdown compliance and constitutional rule format before committing changes.

## Purpose

Prevents markdown lint errors and constitutional violations from being written to disk, eliminating downstream pre-commit hook failures and re-work cycles.

## Validation Layers

### Layer 1: Markdown Syntax Validation

Checks against `.markdownlint-cli2.jsonc` rules:

- **MD001** to MD051: Standard markdown lint rules (headings, lists, tables, etc.)
- **Custom**: Line endings, trailing whitespace, consistent indentation
- **Disabled in project**: MD013 (line length), MD041 (first h1), MD060 (table alignment)

**Applies to**: Any `.md` file being patched (spec.md, plan.md, tasks.md)

### Layer 2: Constitutional Format Validation

Checks that modified sections respect Loopi v2 governance format:

#### **Constitution Check Tables (plan.md)**
```
| ID | Principio | Estado | Nota |
|----|-----------|--------|------|
| P-I | Spec-First | ✅ PASA | notes |
```

Rules:
- ✅ All IDs must be from approved set: P-I, P-II, P-III, P-IV, P-V, P-VI
- ✅ Estado must be one of: ✅ PASA, ⚠️ Requiere justificación, N/A
- ✅ Table structure: exactly 4 columns with | separator
- ❌ Invalid IDs (e.g., "P-VII", "BE-X-99", orphaned IDs)

#### **Backend Standards (plan.md)**
```
| ID | Regla | Estado | Nota |
|----|-------|--------|------|
| BE-ARCH-01 | Separación de capas | ✅ PASA | notes |
```

Rules:
- ✅ All IDs from `standards/backend.md`: BE-ARCH-01, BE-CACHE-01, BE-TEST-01, BE-API-01, BE-DATA-01, BE-JOBS-01, BE-OBS-01
- ✅ Conditional on task type (backend-only vs full-stack)
- ❌ Typos like "BE-ARCH-001" or "BE-ARCHI-01"

#### **Frontend Standards (plan.md)**
```
| ID | Regla | Estado | Nota |
|----|-------|--------|------|
| FE-COMP-01 | Componentes Transversales | ✅ PASA | notes |
```

Rules:
- ✅ All IDs from `standards/frontend.md`: FE-COMP-01, FE-LIST-01, FE-FILTER-01, FE-LISTFORM-01, FE-A11Y-01, FE-RESP-01
- ✅ Conditional on task type (frontend-only vs full-stack)
- ❌ Typos like "FE-COMP-001" or "FE-COMPONENT-01"

#### **CI Standards (plan.md)**
```
| ID | Regla | Estado | Nota |
|----|-------|--------|------|
| CI-01 | Gitflow | ✅ PASA | notes |
```

Rules:
- ✅ Must include CI-01 in every plan
- ❌ CI-02, CI-03, etc. (only CI-01 exists)

#### **Phase 9: Constitutional Compliance (tasks.md)**

Task format:
```
- [ ] TXXX Verificar [BE-ARCH-01] Description...
```

Rules:
- ✅ Each task must cite exactly one ID in [brackets]: [ID]
- ✅ Valid IDs: P-I to P-VI, BE-ARCH-01 to BE-OBS-01, FE-COMP-01 to FE-A11Y-01, CI-01
- ✅ Format: `[ID]` not `(ID)` or `{ID}`
- ❌ Missing bracket citations: "Verificar BE-ARCH-01 without [brackets]"
- ❌ Invalid IDs: "[BE-UNKNOWN]"
- ⚠️ Multiple IDs in one task: "Verificar [BE-ARCH-01] and [BE-TEST-01]" → split into two tasks

#### **Bugfix Notes**

Format (spec.md, plan.md, tasks.md):
```
**Bugfix**: [DATE] — [BUG-NNN] [Brief description]
```

Rules:
- ✅ Date format: YYYY-MM-DD
- ✅ Bug ID format: BUG-###
- ✅ Description: 1-2 sentences
- ❌ Missing format elements

#### **Rule ID Validity**

Checks that every BE-*, FE-*, P-* ID in patched content exists in:
- `constitution.md` (for P-I to P-VI)
- `standards/backend.md` (for BE-*)
- `standards/frontend.md` (for FE-*)
- `standards/environments-ci.md` (for CI-01)

---

## Validation Workflow

### Input
- **Patched spec.md** (in-memory, not yet saved)
- **Patched plan.md** (in-memory, not yet saved)
- **Patched tasks.md** (in-memory, not yet saved)
- **Bug report metadata**: BUG-NNN, date, type

### Process

1. **Parse each file for markdown syntax errors**
   ```
   File: spec.md
   Line 45: MD003 (heading style inconsistent: # vs #)
   Line 200: MD022 (headings not surrounded by blank lines)
   → Collect all violations
   ```

2. **Parse Constitution Check sections**
   - Extract all tables in "Constitution Check" section
   - Validate table structure (4 columns, separator rows)
   - Validate all IDs against approved sets
   - Validate Estado values against allowed set

3. **Parse Phase 9 sections (tasks.md)**
   - Extract all tasks in "Phase 9: Constitutional Compliance"
   - Validate each task cites exactly one ID in [brackets]
   - Validate ID exists in standards/

4. **Parse Bugfix notes**
   - Extract all **Bugfix** entries
   - Validate format and date
   - Cross-check BUG-NNN matches report file

5. **Validate rule ID existence**
   - For each ID found in Constitution Check or Phase 9
   - Check it exists in corresponding standards document
   - Report orphaned or typo'd IDs

### Output

**Success Case:**
```
✅ Markdown Lint Validation PASSED

All patches validated:
  • spec.md: Syntax ✅, Constitutional compliance ✅
  • plan.md: Syntax ✅, Constitution Check valid ✅, Rule IDs valid ✅
  • tasks.md: Syntax ✅, Phase 9 citations valid ✅, No orphaned IDs ✅

Ready to proceed with save step.
```

**Failure Case (Markdown Syntax):**
```
⚠️ Markdown Syntax Violations Found:

tasks.md:
  Line 45: MD003 Heading style inconsistent (used # and ## mixed)
  Line 200: Table format invalid (column separator incomplete)
  Line 256: MD022 Heading not surrounded by blank lines

spec.md:
  Line 150: Trailing whitespace detected

→ Auto-fixable? Some violations can be corrected automatically.
→ Action: Review above errors. Use --auto-fix to correct, or abort and clarify.
```

**Failure Case (Constitutional Compliance):**
```
❌ Constitutional Compliance Violations Found:

plan.md Constitution Check:
  Row 3: Invalid rule ID "BE-ARCH-001" (should be "BE-ARCH-01")
  Row 5: Estado value "✅ N/A" invalid (use "N/A" without emoji)

tasks.md Phase 9:
  T109 Line 215: Missing rule ID citation. Found: "Verificar Separación de capas"
         Expected: "[ ] T109 Verificar [BE-ARCH-01] Separación de capas"
  T110 Line 218: Unknown rule ID "[BE-CACHE-002]" (should be "BE-CACHE-01")

→ Action: Correct the errors above and re-run validation.
```

**Failure Case (Rule ID Not Found):**
```
❌ Orphaned Rule ID Reference:

tasks.md Phase 9:
  T111 Line 225: Rule ID "[FE-UNKNOWN-01]" does not exist in standards/frontend.md
  
Available FE-* IDs: FE-COMP-01, FE-LIST-01, FE-FILTER-01, FE-LISTFORM-01, 
                   FE-A11Y-01, FE-RESP-01

→ Action: Use an ID from the approved list, or open PR to amend standards/frontend.md.
```

---

## Integration Points

### Called by: `speckit.bugfix.patch`

**Timing**: Step 3.5 (after patches applied in-memory, before writing to disk)

```
[Load bug report] → [Apply patches in-memory] 
  → [RUN LINT VALIDATOR] ← Step 3.5
    ├─ If PASS: Continue to save step
    └─ If FAIL: Report errors and decide (abort/retry/--auto-fix)
  → [Write files to disk]
```

### Called by: `speckit.bugfix.verify`

**Timing**: Step 5 (consistency checks)

Includes lint validation in the "Consistency Checks" table to confirm patched files pass markdown + constitutional compliance.

---

## Auto-Fix Capability

**Fixable violations** (can be corrected automatically with --auto-fix):
- Trailing whitespace
- Inconsistent heading delimiters (normalize to #)
- Table column alignment
- Missing blank lines around headings
- Consistent indentation

**Unfixable violations** (require human review):
- Invalid rule IDs (e.g., "BE-ARCH-001" vs "BE-ARCH-01")
- Missing citations in Phase 9 tasks
- Constitutional violations (spec gap that conflicts with P-I)
- Orphaned bug references

---

## Rules Summary

| Category | Check | Auto-fixable? |
|----------|-------|---|
| **Markdown Syntax** | No MD violations | Some (whitespace, delimiters) |
| **Constitution Check** | Valid table structure | No (requires human review) |
| **Rule IDs (BE-*, FE-*)** | All IDs exist in standards/ | No (requires human review) |
| **Estado values** | ✅ PASA / ⚠️ Requiere justificación / N/A | No (requires human review) |
| **Phase 9 Citations** | All tasks cite [ID] format | No (requires human review) |
| **Bugfix Notes** | Correct **Bugfix** format | Some (date normalization) |

---

## Usage

This validator is invoked automatically by `speckit.bugfix.patch` and `speckit.bugfix.verify`. It is not intended for direct user invocation, but can be called explicitly for testing:

```bash
# Validate current working directory's spec artifacts
speckit.bugfix.lint-validator <path-to-feature>

# With auto-fix attempt
speckit.bugfix.lint-validator <path-to-feature> --auto-fix
```

---

## References

- `.markdownlint-cli2.jsonc` — Project markdown lint configuration
- `constitution.md` — Rule IDs P-I to P-VI
- `standards/backend.md` — Rule IDs BE-*
- `standards/frontend.md` — Rule IDs FE-*
- `standards/environments-ci.md` — Rule ID CI-01
