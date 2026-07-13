# Changelog

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
