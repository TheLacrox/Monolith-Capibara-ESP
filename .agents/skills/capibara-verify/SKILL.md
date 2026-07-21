---
name: capibara-verify
description: Use when selecting and running Capibara validation gates for localization, guidebook, entity, agent-workflow, or pull-request changes.
---

# Verify Capibara Changes

## Load context

1. Read `AGENTS.md` completely.
2. Read `Common preflight`, `Change-sensitive verification`, and `Stop conditions` in
   `_Capibara/agent-workflows.md`.
3. Read `_Capibara/glossary.md` before correcting translation text exposed by a failed check.

## Execute

1. Run common preflight and list unstaged, staged, and branch-wide changed paths.
2. Run `git diff --check` for every change.
3. Select gates from changed paths:
   - agent docs, shared workflows, skills, or their validator → agent-setup validator and tests;
   - es-ES Fluent, glossary, manifest, grammar, or localization hook → locale validator and culture
     test;
   - ServerInfo → guidebook structural validator and guidebook integration tests;
   - entity source, maps, generator, gender rules, or generated FTL → regenerate, locale validator,
     and culture test; and
   - Docker/Dokploy files → `docker compose config` plus manual watched-branch/environment caveat.
4. Investigate failures before changing anything. Do not hide unrelated or baseline failures.
5. Rerun each failed relevant gate after its cause is fixed.

## Report

Report every command, exit status, pass count, warning, skipped gate, and known baseline issue.
Never claim completion or success from an earlier run. Stop when a required gate cannot run or a
failure lies outside authorized scope.
