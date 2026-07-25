# Codex Agent Enablement Design

**Status:** Approved  
**Date:** 2026-07-21

## Objective

Make Monolith-Capibara-ESP a first-class repository for both Codex and Claude
without weakening the fork's localization safeguards or creating two divergent
sets of workflow documentation.

The resulting setup must help a fresh Codex session discover the repository's
rules, select the correct maintenance workflow, perform incremental work safely,
run the required checks, and open pull requests against this fork rather than
upstream.

## Current State

- `CLAUDE.md` is the tracked agent entrypoint and contains the fork's critical
  localization, merge, verification, and deployment rules.
- `AGENTS.md` exists locally as an untracked copy of `CLAUDE.md`, with only its
  title changed.
- `_Capibara/translate-workflow.md` describes the original full-tree translation
  through Claude's `Workflow` tool and 185 parallel batches.
- The initial locale, entity, and guidebook translation passes are complete.
  Ongoing work is incremental maintenance after upstream changes.
- No repository-scoped Codex skills or Codex project configuration exist.

## Design Decisions

1. Support Codex and Claude concurrently.
2. Use a shared workflow core with tool-specific entrypoints.
3. Optimize for incremental maintenance; retain the original Claude bulk
   workflow only as clearly marked historical/legacy documentation.
4. Use bounded subagent delegation only for independent file groups. Never let
   two agents edit the same file.
5. Do not add `.codex/config.toml`. The repository has no required MCP server,
   hook, model, permission, or reasoning default, and it must not impose personal
   Codex settings.
6. Do not edit upstream-owned files or add any C# divergence.

## Architecture

### Root agent entrypoints

`AGENTS.md` becomes the tracked Codex entrypoint. `CLAUDE.md` remains the Claude
entrypoint. Both stay self-contained for critical, high-risk rules:

- fork and upstream remote identity;
- pull-request target;
- additive localization policy;
- approved in-place exceptions and merge-conflict behavior;
- intentional C# divergences and approval boundary;
- Fluent preservation rules;
- required validation gates; and
- Capibara-owned deployment files.

Both entrypoints link to the shared workflows. `AGENTS.md` additionally provides
a compact repository map and task router so Codex can choose the matching skill
or workflow without loading every detailed procedure into initial context.

### Shared workflow core

Add `_Capibara/agent-workflows.md` as the operational source of truth. It covers:

1. common Git and environment preflight;
2. upstream synchronization and conflict classification;
3. incremental Fluent translation;
4. ServerInfo/guidebook maintenance;
5. entity localization refreshes;
6. change-sensitive verification; and
7. pull-request preparation and explicit fork targeting.

Update `_Capibara/translate-workflow.md` so its primary procedure is incremental
and tool-neutral. Keep the original Claude `Workflow` script in a legacy full-pass
section for reproducibility, not as the default maintenance path.

### Codex skills

Add six repository skills under `.agents/skills/`:

| Skill | Responsibility |
| --- | --- |
| `capibara-sync-upstream` | Fetch and merge `upstream/main`, resolve only documented conflict classes, then report translation drift. |
| `capibara-translate-fluent` | Translate new or changed `.ftl` content while preserving Fluent structure and glossary terminology. |
| `capibara-translate-guidebook` | Retranslate changed `Resources/ServerInfo/**` files after taking upstream versions and validate byte-identical markup. |
| `capibara-refresh-entities` | Refresh entity dumps, translation maps, generated FTL, and gender exceptions in the documented order. |
| `capibara-verify` | Select and run structural, culture, guidebook, and hygiene checks based on changed paths. |
| `capibara-create-pr` | Verify branch readiness and create a PR explicitly against `TheLacrox/Monolith-Capibara-ESP:main`. |

Each `SKILL.md` uses minimal `name` and `description` frontmatter. Descriptions
are short and trigger-focused. Skill bodies reference the shared workflow and
glossary, repeat only action-local stop conditions, and avoid duplicating the
entire repository policy.

### Agent setup validator

Add `_Capibara/validate-agent-setup.ps1`. It exits non-zero with actionable
messages when any invariant fails:

- required root entrypoints, shared docs, or skill files are missing;
- skill frontmatter lacks `name` or `description`;
- expected skill names are duplicated or mismatched;
- referenced repository paths do not exist;
- critical policy headings are missing from either root entrypoint; or
- current workflow instructions still present the Claude-only bulk process as
  the default path.

The validator remains structural. It does not attempt to run Codex or Claude or
modify user configuration.

## Operational Flow

1. Agent loads its root entrypoint.
2. Task routing selects a Codex skill or the equivalent shared workflow.
3. Workflow checks branch, remotes, working-tree state, and affected paths.
4. Existing scripts or manifests identify new or changed source material.
5. Agent reads `_Capibara/glossary.md` before translation.
6. Work stays incremental. Independent file groups may be delegated with
   concurrency bounded by the current environment; writes never overlap.
7. Main agent reviews all outputs and runs the relevant validators.
8. Source manifests update only after translation and validation succeed.
9. PR workflow uses an explicit repository and base branch.

## Safety and Error Handling

- Preserve unrelated user changes. Never reset, overwrite, or clean them.
- For `Resources/ServerInfo/**` conflicts, take upstream's version and
  retranslate it; never hand-merge Spanish and English hunks.
- For documented Capibara-owned files or marked C# blocks, retain the Capibara
  version during conflicts.
- Stop on unknown conflict classes or any proposed new C# divergence and request
  explicit user approval.
- Never update locale or guidebook manifests after failed validation.
- Never translate Fluent identifiers, attribute names, placeables, selector
  keys, function calls, or escapes.
- If translation cannot be completed safely, leave fallback English in effect
  and report the remaining item.
- Do not use broad parallel writes. Delegation is limited to disjoint file sets;
  the main agent owns integration and validation.

## Verification

The implementation is complete only after these checks pass from repository
root:

```powershell
pwsh _Capibara/validate-agent-setup.ps1
pwsh _Capibara/validate-locale.ps1
dotnet test Content.IntegrationTests --filter CapibaraCultureTest
git diff --check
```

Additional checks remain change-sensitive:

- Run `pwsh _Capibara/validate-guidebook.ps1` before committing guidebook work.
- Run the guidebook integration-test filter when `Resources/ServerInfo/**` or
  guide-entry localization changes.
- Run entity generation and culture checks after entity dump, map, generator,
  or generated entity FTL changes.

## Acceptance Criteria

- `AGENTS.md` is tracked and accurately describes current repository behavior.
- Critical safety rules remain available to both Codex and Claude.
- Six Codex skills are discoverable from `.agents/skills/` and route to shared,
  repository-relative workflows.
- Active maintenance documentation is incremental and platform-neutral.
- Legacy Claude bulk-translation instructions remain reproducible but clearly
  non-default.
- Structural agent-setup validation passes with actionable failure messages.
- Existing localization validation and culture boot test still pass.
- No upstream-owned file, product code, or project-level Codex preference is
  changed.

## Out of Scope

- New C# localization hooks or other product-code divergences.
- Re-running the completed full-tree translation.
- Changing model, sandbox, approval, MCP, hook, or user-level Codex settings.
- Packaging these repository skills as a distributable plugin.
- Rewriting historical plans or specifications that accurately describe the
  original Claude-based translation run.
