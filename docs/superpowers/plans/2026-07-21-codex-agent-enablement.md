# Codex Agent Enablement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add durable, dual Claude/Codex repository guidance and six Codex maintenance skills without changing upstream-owned game files or product behavior.

**Architecture:** Keep critical safety rules in both root entrypoints, centralize detailed procedures in `_Capibara/agent-workflows.md`, and make small `.agents/skills/*/SKILL.md` adapters route Codex to those shared procedures. A PowerShell structural validator protects discovery, frontmatter, shared references, critical headings, and incremental-first workflow wording.

**Tech Stack:** Markdown, Codex Agent Skills (`SKILL.md`), PowerShell 7, Git, Project Fluent validation, .NET 10 integration tests.

## Global Constraints

- Preserve concurrent support for Codex and Claude.
- Optimize active workflows for incremental maintenance; retain the 185-agent Claude bulk workflow only as legacy documentation.
- Never edit upstream-owned C#, YAML, `Resources/Locale/en-US/**`, `README.md`, or historical plans/specifications.
- Never add a new C# divergence without explicit user approval.
- Do not add `.codex/config.toml` or impose model, sandbox, approval, MCP, hook, or reasoning settings.
- Preserve unrelated working-tree changes; `AGENTS.md` is the only pre-existing untracked file in scope.
- PRs must target `TheLacrox/Monolith-Capibara-ESP:main`, never upstream.

---

## File Structure

**Create:**

- `_Capibara/agent-workflows.md` — shared operational source of truth.
- `.agents/skills/capibara-sync-upstream/SKILL.md` — upstream merge workflow adapter.
- `.agents/skills/capibara-translate-fluent/SKILL.md` — incremental Fluent translation adapter.
- `.agents/skills/capibara-translate-guidebook/SKILL.md` — ServerInfo translation adapter.
- `.agents/skills/capibara-refresh-entities/SKILL.md` — entity localization refresh adapter.
- `.agents/skills/capibara-verify/SKILL.md` — change-sensitive verification adapter.
- `.agents/skills/capibara-create-pr/SKILL.md` — fork PR adapter.
- `_Capibara/validate-agent-setup.ps1` — structural repository-agent validator.
- `_Capibara/tests/agent-setup/validate-agent-setup.tests.ps1` — positive and negative validator harness.

**Modify:**

- `AGENTS.md` — tracked Codex entrypoint, repository map, task routing, and critical rules.
- `CLAUDE.md` — retain critical rules and point to shared workflows.
- `_Capibara/translate-workflow.md` — incremental, platform-neutral default plus legacy Claude bulk section.

**Do not create:**

- `.codex/config.toml`
- `.claude/skills/**`

---

### Task 1: Root Guidance and Shared Workflows

**Files:**

- Create: `_Capibara/agent-workflows.md`
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Modify: `_Capibara/translate-workflow.md`

**Interfaces:**

- Consumes: existing `_Capibara/glossary.md`, scripts, manifests, `progress.md`, and documented fork rules.
- Produces: stable headings and paths consumed by all six skills and the validator.

- [ ] **Step 1: Record failing documentation preflight**

Run:

```powershell
$required = @('_Capibara/agent-workflows.md', '.agents/skills/capibara-sync-upstream/SKILL.md')
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_) })
if ($missing.Count -eq 0) { throw 'Expected agent enablement files to be absent before implementation.' }
$missing
```

Expected: output lists both paths.

- [ ] **Step 2: Expand and track `AGENTS.md`**

Keep existing critical policy verbatim in meaning. Add these compact sections:

```markdown
## Repository map
- `Resources/Locale/es-ES/` — additive Spanish Fluent tree.
- `Resources/ServerInfo/` — approved in-place translated guidebook/rules exception.
- `_Capibara/` — fork-owned workflows, scripts, manifests, glossary, and progress.
- `.agents/skills/` — Codex task workflows; select the matching skill before maintenance work.

## Task routing
- Upstream merge or locale drift → `capibara-sync-upstream`.
- New/changed `.ftl` strings → `capibara-translate-fluent`.
- Changed ServerInfo docs → `capibara-translate-guidebook`.
- Entity dump/maps/generated FTL → `capibara-refresh-entities`.
- Validation selection → `capibara-verify`.
- Branch handoff or PR → `capibara-create-pr`.

Detailed shared procedures: `_Capibara/agent-workflows.md`.
```

Also state: inspect working-tree changes before edits; preserve unrelated work;
delegate only disjoint file groups; main agent integrates and validates; manifests
update only after passing validation.

- [ ] **Step 3: Align `CLAUDE.md`**

Retain its existing high-risk rules. Add the same shared-workflow pointer and
incremental maintenance/default behavior. Do not add Codex-specific invocation
syntax to `CLAUDE.md`.

- [ ] **Step 4: Create `_Capibara/agent-workflows.md`**

Use these exact top-level operational sections:

```markdown
# Capibara agent workflows
## Common preflight
## Upstream synchronization
## Incremental Fluent translation
## Guidebook and ServerInfo maintenance
## Entity localization refresh
## Change-sensitive verification
## Pull request handoff
## Stop conditions
```

Each section must include exact commands, expected ordering, relevant manifest,
conflict policy, validation gate, and explicit PR repository/base. Common
preflight must verify branch, remotes, status, and changed paths before writes.

- [ ] **Step 5: Rewrite active `_Capibara/translate-workflow.md` routing**

Make incremental maintenance the first and default procedure:

```markdown
# Capibara translation workflow

Current default: incremental maintenance after an upstream merge.

## Incremental maintenance
...

## Optional bounded delegation
...

## Legacy full-tree Claude workflow
...
```

Move the existing `Workflow` JavaScript into the legacy section unchanged except
for surrounding explanation. State that it documents the completed initial pass
and is not the normal update path.

- [ ] **Step 6: Verify documentation paths and hygiene**

Run:

```powershell
Test-Path AGENTS.md
Test-Path CLAUDE.md
Test-Path _Capibara/agent-workflows.md
rg -n "Current default: incremental maintenance|Legacy full-tree Claude workflow" _Capibara/translate-workflow.md
rg -n "capibara-sync-upstream|capibara-create-pr" AGENTS.md
git diff --check
```

Expected: all `Test-Path` calls return `True`; both `rg` commands find their
terms; `git diff --check` emits no output and exits 0.

- [ ] **Step 7: Commit shared guidance**

```powershell
git add -- AGENTS.md CLAUDE.md _Capibara/agent-workflows.md _Capibara/translate-workflow.md
git commit -m "docs: add shared agent maintenance workflows"
```

---

### Task 2: Codex Repository Skills

**Files:**

- Create: `.agents/skills/capibara-sync-upstream/SKILL.md`
- Create: `.agents/skills/capibara-translate-fluent/SKILL.md`
- Create: `.agents/skills/capibara-translate-guidebook/SKILL.md`
- Create: `.agents/skills/capibara-refresh-entities/SKILL.md`
- Create: `.agents/skills/capibara-verify/SKILL.md`
- Create: `.agents/skills/capibara-create-pr/SKILL.md`

**Interfaces:**

- Consumes: `AGENTS.md`, `_Capibara/agent-workflows.md`, and task-specific existing scripts.
- Produces: six uniquely named, implicitly discoverable Codex workflows.

- [ ] **Step 1: Verify skills are initially absent**

Run:

```powershell
$names = @('capibara-sync-upstream','capibara-translate-fluent','capibara-translate-guidebook','capibara-refresh-entities','capibara-verify','capibara-create-pr')
$present = @($names | Where-Object { Test-Path ".agents/skills/$_/SKILL.md" })
if ($present.Count -ne 0) { throw "Expected no implemented skills; found: $($present -join ', ')" }
```

Expected: exit 0 with no output.

- [ ] **Step 2: Create minimal frontmatter for every skill**

Every file starts with only:

```yaml
---
name: capibara-sync-upstream
description: Use when merging Monolith upstream into the Capibara ESP fork and identifying localization maintenance work; stop on undocumented conflicts or proposed new C# divergences.
---
```

Use each skill's exact name and description from the table below. No model, tool
allowlist, invocation, or platform-specific metadata.

| Skill | Exact description |
| --- | --- |
| `capibara-sync-upstream` | Use when merging Monolith upstream into the Capibara ESP fork and identifying localization maintenance work; stop on undocumented conflicts or proposed new C# divergences. |
| `capibara-translate-fluent` | Use when translating new or changed en-US Fluent messages into es-ES while preserving every Fluent identifier and placeable. |
| `capibara-translate-guidebook` | Use when upstream changes Resources/ServerInfo guidebook, rules, or intro text that must be retransformed from English into Spanish in place. |
| `capibara-refresh-entities` | Use when entity prototypes or dump data changed and Capibara entity names, descriptions, generated FTL, or gender metadata must be refreshed. |
| `capibara-verify` | Use when selecting and running Capibara validation gates for localization, guidebook, entity, agent-workflow, or pull-request changes. |
| `capibara-create-pr` | Use when a verified Capibara branch is ready to push and open as a pull request against TheLacrox/Monolith-Capibara-ESP main. |

- [ ] **Step 3: Implement task-specific skill bodies**

Every body must:

1. read `AGENTS.md` and `_Capibara/agent-workflows.md`;
2. read `_Capibara/glossary.md` before any translation;
3. run common preflight before writes;
4. follow only its named shared-workflow section;
5. state task-specific stop conditions;
6. run or delegate to `capibara-verify` before completion; and
7. avoid manifest updates until relevant validation passes.

`capibara-create-pr` must require:

```powershell
gh pr create --repo TheLacrox/Monolith-Capibara-ESP --base main
```

and must never infer upstream as the PR repository.

- [ ] **Step 4: Run direct skill structure checks**

Run:

```powershell
$expected = @('capibara-sync-upstream','capibara-translate-fluent','capibara-translate-guidebook','capibara-refresh-entities','capibara-verify','capibara-create-pr')
foreach ($name in $expected) {
    $path = ".agents/skills/$name/SKILL.md"
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing $path" }
    $raw = Get-Content -LiteralPath $path -Raw
    if ($raw -notmatch "(?ms)^---\s*\r?\nname:\s*$([regex]::Escape($name))\s*\r?\ndescription:\s*\S.+?\r?\n---") {
        throw "Invalid minimal frontmatter: $path"
    }
}
```

Expected: exit 0 with no output.

- [ ] **Step 5: Commit skills**

```powershell
git add -- .agents/skills
git commit -m "feat: add Codex localization maintenance skills"
```

---

### Task 3: Agent Setup Validator With Failure Tests

**Files:**

- Create: `_Capibara/validate-agent-setup.ps1`
- Create: `_Capibara/tests/agent-setup/validate-agent-setup.tests.ps1`

**Interfaces:**

- Consumes: repository root through optional `-RepositoryRoot`.
- Produces: exit 0 plus success summary, or exit 1 plus one `FAIL:` line per invariant.

- [ ] **Step 1: Write validator test harness first**

Test harness requirements:

```powershell
#requires -Version 7
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

# 1. Run validator against real repository; require exit 0.
# 2. Copy only AGENTS.md, CLAUDE.md, .agents/skills, and required _Capibara docs
#    into a unique directory below [System.IO.Path]::GetTempPath().
# 3. Remove capibara-verify/SKILL.md from copied fixture; require exit 1 and
#    output containing "Missing required skill file".
# 4. Restore fixture, replace capibara-create-pr frontmatter name; require exit 1
#    and output containing "Skill name mismatch".
# 5. Restore fixture, remove "## Iron rules" from CLAUDE.md; require exit 1 and
#    output containing "Missing critical heading".
# 6. In finally, resolve and verify the temp fixture remains under the system
#    temp directory before Remove-Item -Recurse.
```

- [ ] **Step 2: Run harness and confirm red state**

Run:

```powershell
pwsh _Capibara/tests/agent-setup/validate-agent-setup.tests.ps1
```

Expected: FAIL because `_Capibara/validate-agent-setup.ps1` does not exist.

- [ ] **Step 3: Implement `_Capibara/validate-agent-setup.ps1`**

Required public interface:

```powershell
#requires -Version 7
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)
```

Implementation invariants:

- Resolve `RepositoryRoot` and use only `Join-Path`/`Test-Path -LiteralPath`.
- Accumulate failures instead of stopping after first problem.
- Require `AGENTS.md`, `CLAUDE.md`, `_Capibara/agent-workflows.md`,
  `_Capibara/translate-workflow.md`, and six exact skill paths.
- Require `## Upstream`, `## Iron rules`, `## Fluent-preservation rules`,
  `## Verify`, and `## Deployment` in both root entrypoints.
- Parse each skill's first YAML block; permit exactly `name` and `description`;
  require frontmatter `name` to equal its directory name and description to be
  non-empty.
- Require active translation workflow phrases `Current default: incremental maintenance`
  and `## Legacy full-tree Claude workflow`.
- Prefix every diagnostic with `FAIL:` and exit 1 when failures exist.
- Print `Agent setup valid: 2 entrypoints, 6 skills, shared workflows.` and exit 0 otherwise.

- [ ] **Step 4: Run harness and confirm green state**

Run:

```powershell
pwsh _Capibara/tests/agent-setup/validate-agent-setup.tests.ps1
```

Expected: `Agent setup validator tests passed.` and exit 0.

- [ ] **Step 5: Run validator directly**

Run:

```powershell
pwsh _Capibara/validate-agent-setup.ps1
```

Expected: `Agent setup valid: 2 entrypoints, 6 skills, shared workflows.` and exit 0.

- [ ] **Step 6: Commit validator and tests**

```powershell
git add -- _Capibara/validate-agent-setup.ps1 _Capibara/tests/agent-setup/validate-agent-setup.tests.ps1
git commit -m "test: validate repository agent setup"
```

---

### Task 4: Full Verification and Fork PR

**Files:** none expected; fix only defects exposed by checks in files already in scope.

**Interfaces:**

- Consumes: all previous task deliverables.
- Produces: verified branch and PR against this fork's `main` branch.

- [ ] **Step 1: Run agent setup tests and validator**

```powershell
pwsh _Capibara/tests/agent-setup/validate-agent-setup.tests.ps1
pwsh _Capibara/validate-agent-setup.ps1
```

Expected: both exit 0.

- [ ] **Step 2: Run locale structural gate**

```powershell
pwsh _Capibara/validate-locale.ps1
```

Expected: `All es-ES files structurally valid.` and exit 0.

- [ ] **Step 3: Run culture integration test**

```powershell
dotnet test Content.IntegrationTests --filter CapibaraCultureTest
```

Expected: exit 0 with `CapibaraCultureTest` passing.

- [ ] **Step 4: Run repository hygiene checks**

```powershell
git diff --check
git status --short
git diff origin/main...HEAD --name-only
```

Expected: no whitespace errors; changed paths limited to approved design, plan,
root agent docs, `_Capibara` agent docs/tooling/tests, and `.agents/skills`.

- [ ] **Step 5: Review commit history and push branch**

```powershell
git log --oneline origin/main..HEAD
git push -u origin codex/codex-agent-enablement
```

Expected: logical design/guidance/skills/validator commits and successful push.

- [ ] **Step 6: Create fork PR**

```powershell
$body = @"
## Summary
- add tracked Codex guidance while preserving Claude support
- centralize incremental Capibara maintenance workflows
- add six repository-scoped Codex skills and structural validation

## Verification
- `pwsh _Capibara/tests/agent-setup/validate-agent-setup.tests.ps1`
- `pwsh _Capibara/validate-agent-setup.ps1`
- `pwsh _Capibara/validate-locale.ps1`
- `dotnet test Content.IntegrationTests --filter CapibaraCultureTest`
- `git diff --check`

## Deployment
Documentation and maintenance tooling only. Runtime and Dokploy deployment behavior are unchanged.
"@
gh pr create --repo TheLacrox/Monolith-Capibara-ESP --base main --head codex/codex-agent-enablement --title "feat: add Codex agent workflows" --body $body
```

PR body must summarize dual Claude/Codex support, six skills, validator, commands
run, and state deployment impact: documentation/tooling only; Dokploy behavior and
runtime deployment remain unchanged.
