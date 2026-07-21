---
name: capibara-sync-upstream
description: Use when merging Monolith upstream into the Capibara ESP fork and identifying localization maintenance work; stop on undocumented conflicts or proposed new C# divergences.
---

# Sync Capibara With Upstream

## Load context

1. Read `AGENTS.md` completely.
2. Read `Common preflight`, `Upstream synchronization`, and `Stop conditions` in
   `_Capibara/agent-workflows.md`.
3. Read `_Capibara/glossary.md` before translating anything later in the workflow.

## Execute

1. Run common preflight. Confirm `origin` is the Capibara fork and `upstream` is Monolith.
2. Confirm this is an upstream merge. For a normal fork refresh from `origin`, use `git pull origin
   <current-branch>` instead and do not apply upstream conflict rules.
3. Require a clean tracked working tree. Preserve non-colliding untracked user files.
4. Fetch `upstream`, record the merge base, and list upstream changes under
   `Resources/ServerInfo` and `Resources/Locale/en-US` before merging.
5. Merge `upstream/main`.
6. Resolve only documented conflict classes:
   - take upstream English for `Resources/ServerInfo/**`, then finish the merge before translating;
   - keep Capibara-owned Docker/Dokploy files;
   - preserve marked `// Capibara ESP` blocks while integrating surrounding upstream code; and
   - take upstream guidebook prototype titles, then reapply approved Spanish exceptions after the
     merge.
7. Stop on every undocumented conflict or proposed new C# divergence. Do not guess.
8. After the merge commit, run `_Capibara/sync-locale.ps1` and inspect its report.
9. Route Fluent, guidebook, and entity drift to the matching Capibara skills. Delegate only
   disjoint files.
10. Invoke `capibara-verify` before reporting completion. Update manifests only after their
    translated outputs pass validation.

## Report

Report merge base, upstream commit, conflicts and resolutions, drift counts, validation evidence,
remaining English fallback, and next required skill. Never claim the sync is complete while
`NEW`, `CHANGED`, unresolved conflicts, or failed checks remain.
