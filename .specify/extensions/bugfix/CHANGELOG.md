# Changelog

## 1.2.0 (2026-07-13)

**Focus**: Complete Constitutional & Standards Integration (Level 1 + Level 2)

### Level 1A: Constitutional Check Command (NEW)
- Add `/speckit.bugfix.constitution-check` — analyze bug against ALL four normative documents
  - constitution.md (P-I to P-VI)
  - standards/backend.md (BE-ARCH-01 to BE-OBS-01)
  - standards/frontend.md (FE-STACK-01 to FE-CI-01)
  - standards/environments-ci.md (ENV-01, CI-01, CI-02)
- Risk-based assessment: CRITICAL/WARNING/OK
- Recommend escalation BEFORE reporting if CRITICAL violations detected
- File: `.specify/extensions/bugfix/commands/speckit.bugfix.constitution-check.md`

### Level 1B: Enhanced Report Command
- Update `/speckit.bugfix.report` to load and run constitution-check automatically
- Load bug history: `specs/{feature}/bugs/BUG-*.md` for context
- Enhanced bug report template includes:
  - **Constitutional & Standards Compliance** section (from constitution-check)
  - Principle impact table (P-I to P-VI)
  - Backend standards impact (BE-ARCH-01 to BE-OBS-01, if applicable)
  - Frontend standards impact (FE-STACK-01 to FE-CI-01, if applicable)
  - CI/Environment standards impact (ENV-01, CI-01, CI-02)
  - Related previous bugs section (detect regression risks)
  - Overall risk level (CRITICAL/WARNING/OK)

### Level 2: Patch Validation Gate
- Enhance `/speckit.bugfix.patch` with **Step 2.2**: Constitutional & Standards Verification
- Validates patch BEFORE designing implementation:
  - Checks all P-I to P-VI principles
  - Checks applicable BE-*, FE-*, CI-* standards
  - Detects regression risks against previous bugs
  - Aborts if CRITICAL violations; documents if WARNING
- Enhanced Step 3.5 (Markdown Lint Validation):
  - Validates Constitution Check table format (if plan.md modified)
  - Validates Phase 9 task citations cite valid [ID] from standards
  - Validates all rule IDs exist in normative documents

### Level 2.5: Bug History Context
- Enhance `/speckit.bugfix.verify` to load and track related bugs
- Verify bug relationships are documented
- Check for regression risks: If patch touches previous fix, verify new tasks cover it
- Enhanced consistency checks:
  - Verify all P-*, BE-*, FE-*, CI-* IDs in Constitution Check exist in standards
  - Verify all Phase 9 task citations match Constitution Check IDs
  - Verify no orphaned bug references

### Updates to All Commands
- **constitutional-check.md**: Reference all 4 normative documents
- **report.md**: Pre-run constitution-check, load bug history
- **patch.md**: Step 2.2 (Level 2 validation gate) + enhanced Step 3.5
- **verify.md**: Bug history tracking + comprehensive standards verification
- **README.md**: Document all 4 normative sources + workflow diagram
- **lint-validator.md**: Reference all 4 normative documents in validation rules

### Impact
✅ Level 1A: Early warning of constitutional violations (before report)  
✅ Level 1B: Bug reports include standards compliance assessment + bug history  
✅ Level 2: Patch validation gate catches violations BEFORE design phase  
✅ Level 2.5: Historical context prevents regressions  
✅ CRITICAL violations escalated to product team  
✅ WARNING violations tracked in Complexity Tracking  
✅ All patches cite affected standards in Phase 9 (Cumplimiento Constitucional)  

## 1.1.0 (2026-07-13)

**Focus**: Markdown linting and constitutional compliance validation

- Add `lint-validator.md` — integrated markdown & constitutional compliance validator
- Enhance `/speckit.bugfix.patch` with Step 3.5: Markdown Lint Validation gate (prevents pre-commit failures)
  - Validates markdown syntax against `.markdownlint-cli2.jsonc` rules
  - Validates constitutional rule ID format (P-I to P-VI, BE-*, FE-*, CI-01)
  - Validates Constitution Check table format (plan.md)
  - Validates Phase 9 task citations (tasks.md) — all tasks must cite [ID]
  - Validates Bugfix note format (date, BUG-NNN)
  - Offers auto-fix for fixable violations (whitespace, alignment)
  - Reports specific violations before saving (eliminates downstream re-work)
- Enhance `/speckit.bugfix.verify` with Markdown & Constitutional Compliance check
  - Includes lint validation in consistency report
  - Verifies all rule IDs exist in standards documents
  - Confirms no orphaned or typo'd rule references
- Update README.md with Loopi v2-specific considerations
- **Impact**: Zero markdown/constitutional violations in saved patches; eliminates pre-commit hook failures and re-work cycles

## 1.0.0 (2026-04-09)

- Initial release
- Add `/speckit.bugfix.report` command for bug capture and artifact traceability
- Add `/speckit.bugfix.patch` command for surgical spec, plan, and task updates
- Add `/speckit.bugfix.verify` command for post-patch consistency verification
- Bug classification: spec gap, spec conflict, implementation drift, untested flow, dependency issue
- Sequential bug reports stored in `specs/{feature}/bugs/BUG-{NNN}.md`
- Optional `after_implement` hook for consistency checking
- Addresses community request in issue #619 (25+ upvotes, maintainer-approved)
