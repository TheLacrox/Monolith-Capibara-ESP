# Capibara agent workflows

Shared procedures for Codex, Claude, and human maintainers. Root policy in `AGENTS.md` and
`CLAUDE.md` always wins. These workflows optimize for incremental maintenance after upstream
changes; they do not authorize new product-code divergence.

## Common preflight

Run from repository root before any write:

```powershell
git rev-parse --show-toplevel
git branch --show-current
git status --short --branch
git remote get-url origin
git remote get-url upstream
git diff --name-only
git diff --cached --name-only
```

Expected remotes:

- `origin`: `https://github.com/TheLacrox/Monolith-Capibara-ESP.git`
- `upstream`: `https://github.com/Monolith-Station/Monolith.git`

Stop when HEAD is detached, a remote is wrong, an in-progress Git operation is unrelated to the
requested task, or local changes overlap files the workflow must edit. Preserve unrelated changes;
never reset, clean, overwrite, or silently stash them.

Before translation, read `_Capibara/glossary.md` completely. Before parallel work, partition by
file so every path has exactly one writer. Keep the main agent responsible for integration and all
validation.

## Upstream synchronization

Use this only for merging Monolith into the fork, not for pulling `origin` changes.

1. Require a clean tracked working tree. Untracked files may remain only when they cannot collide
   with upstream paths.
2. Fetch and record upstream changes before merging:

   ```powershell
   git fetch upstream
   $upstreamBase = (git merge-base HEAD upstream/main).Trim()
   git diff --name-only $upstreamBase upstream/main -- Resources/ServerInfo
   git diff --name-only $upstreamBase upstream/main -- Resources/Locale/en-US
   git merge upstream/main
   ```

3. If conflicts occur, list them with:

   ```powershell
   git diff --name-only --diff-filter=U
   ```

4. Resolve only documented classes:

   - `Resources/ServerInfo/**`: take upstream English with
     `git checkout --theirs -- <path>`. Finish the merge commit before translating it.
   - `Dockerfile`, `.dockerignore`, `entrypoint.sh`, `docker-compose.yml`, and
     `Docker/server_config.prod.toml`: keep the Capibara version with
     `git checkout --ours -- <path>`.
   - The marked `// Capibara ESP` blocks in the two approved C# divergence files: integrate
     upstream around the block while preserving Capibara behavior and comments.
   - Approved `Resources/Prototypes/**/Guidebook/*.yml` title exceptions: take upstream first,
     finish the merge, then reapply the Spanish title and `# Capibara ESP` marker.
   - Any other upstream-owned conflict: inspect why the fork differs. Stop if it is not already
     documented; do not invent a resolution.

5. After the merge commit, identify maintenance work:

   ```powershell
   pwsh _Capibara/sync-locale.ps1
   Get-Content _Capibara/sync-report.txt
   ```

6. Run the matching incremental workflows below. Keep source updates, Spanish maintenance, and
   manifest updates reviewable in separate commits when practical.

## Incremental Fluent translation

1. Generate and read drift:

   ```powershell
   pwsh _Capibara/sync-locale.ps1
   Get-Content _Capibara/sync-report.txt
   ```

2. For each ID under `NEW` or `CHANGED`, locate its English file, then edit only the mirrored
   Spanish file:

   ```powershell
   rg -n "^message-id\s*=" Resources/Locale/en-US
   ```

   Replace `message-id` with the exact ID from the report. New files must mirror their en-US
   relative path under `Resources/Locale/es-ES/`.

3. Translate only human-readable text. Preserve message IDs, attribute names, variables, terms,
   message references, selectors, selector keys, functions, arguments, escapes, braces, and
   surrounding placeable spacing. Translate both string arguments of `CONJUGATE-BASIC` into
   Spanish third-person singular forms.

4. Delegate only when at least two independent files need work. Give each worker a disjoint file
   list plus `_Capibara/glossary.md`; bound concurrency to available agent slots. The main agent
   reviews every diff.

5. Validate before recording source hashes:

   ```powershell
   pwsh _Capibara/validate-locale.ps1
   dotnet test Content.IntegrationTests --filter CapibaraCultureTest
   pwsh _Capibara/sync-locale.ps1 -UpdateManifest
   pwsh _Capibara/sync-locale.ps1
   ```

   Final report must show no unhandled `NEW` or `CHANGED` IDs. Do not run `-UpdateManifest` after a
   failed validator or incomplete translation.

## Guidebook and ServerInfo maintenance

`Resources/ServerInfo/**` is Spanish in the working tree but upstream English in Monolith. Never
hand-merge Spanish and English hunks.

1. During an upstream conflict, take the complete upstream file with `--theirs` and finish the
   merge commit while it is still English. This merge commit becomes the validation baseline.
2. Retranslate only files changed by upstream, using the pre-merge `git diff --name-only
   $upstreamBase upstream/main -- Resources/ServerInfo` list.
3. Translate text nodes and player-facing labels only. Keep every `<...>` tag byte-identical to
   the English merge baseline, including tag order, attributes, attribute values, entity IDs,
   colors, and priorities.
4. Validate before committing Spanish output:

   ```powershell
   pwsh _Capibara/validate-guidebook.ps1 -BaselineRef HEAD
   dotnet test Content.IntegrationTests --filter "FullyQualifiedName~Guidebook"
   ```

5. Update `_Capibara/guidebook-manifest.json` only after validation. Its values are SHA1 hashes of
   English files from the merge baseline, never hashes of translated working-tree files. Extract
   baseline files with `git archive HEAD Resources/ServerInfo` or use a clean temporary worktree,
   then hash them with `Get-FileHash -Algorithm SHA1`.
6. Keep any raw guide-entry title changes in the approved prototype exception separate and marked
   `# Capibara ESP`. Prefer additive keys in
   `Resources/Locale/es-ES/_Capibara/guide-entries.ftl` whenever the raw name is a valid Fluent ID.

## Entity localization refresh

Use this when entity prototypes changed, names/descriptions drifted, or article gender is wrong.

1. Regenerate resolved English entity data:

   ```powershell
   dotnet test Content.IntegrationTests --filter FullyQualifiedName~CapibaraEntityDumpTest -c Release
   git diff -- _Capibara/entities/entity-source.json
   ```

2. Merge existing translation maps and derive only untranslated unique strings:

   ```powershell
   $source = Get-Content _Capibara/entities/entity-source.json -Raw | ConvertFrom-Json
   $all = @($source | ForEach-Object { $_.name; $_.desc } |
       Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
   $translated = @{}
   Get-ChildItem _Capibara/entities/tmp -Filter 'tr-*.json' | ForEach-Object {
       $map = Get-Content $_.FullName -Raw | ConvertFrom-Json -AsHashtable
       foreach ($key in $map.Keys) { $translated[$key] = $map[$key] }
   }
   $pending = @($all | Where-Object { -not $translated.ContainsKey($_) })
   $batches = [System.Collections.Generic.List[object]]::new()
   for ($i = 0; $i -lt $pending.Count; $i += 100) {
       $end = [Math]::Min($i + 99, $pending.Count - 1)
       $batches.Add(@($pending[$i..$end]))
   }
   $batches | ConvertTo-Json -Depth 3 | Set-Content _Capibara/entities/strbatches.json
   "Pending entity strings: $($pending.Count); batches: $($batches.Count)"
   ```

3. Translate each pending batch using the glossary. Write new maps as
   `_Capibara/entities/tmp/tr-refresh-<run>-<batch>.json`; never overwrite a prior reviewed map.
   Map exact English strings to exact Spanish strings.
4. Regenerate additive entity FTL:

   ```powershell
   pwsh _Capibara/generate-entity-ftl.ps1
   pwsh _Capibara/validate-locale.ps1
   dotnet test Content.IntegrationTests --filter CapibaraCultureTest
   ```

5. If an article is wrong, extend the smallest appropriate exception list in
   `_Capibara/generate-entity-ftl.ps1`, regenerate, and rerun both gates. Do not hand-edit generated
   `Resources/Locale/es-ES/_Capibara/entities/*.ftl` files.

## Change-sensitive verification

Inspect changed paths first:

```powershell
git status --short
git diff --name-only
git diff --cached --name-only
```

Run `git diff --check` for every change, then select additional gates:

| Changed paths | Required checks |
| --- | --- |
| `AGENTS.md`, `CLAUDE.md`, `.agents/skills/**`, `_Capibara/*workflow*`, `_Capibara/validate-agent-setup.ps1` | `pwsh _Capibara/validate-agent-setup.ps1` |
| `Resources/Locale/es-ES/**/*.ftl`, locale manifest, glossary, grammar, or localization hooks | `pwsh _Capibara/validate-locale.ps1`; `dotnet test Content.IntegrationTests --filter CapibaraCultureTest` |
| `Resources/ServerInfo/**` | `pwsh _Capibara/validate-guidebook.ps1 -BaselineRef HEAD`; guidebook integration-test filter |
| Entity source, maps, generator, gender rules, or generated entity FTL | regenerate entity FTL; locale validator; culture test |
| Docker/Dokploy files | `docker compose config`; document whether watched branch or environment settings need manual confirmation |

Report exact commands, exit status, pass counts, warnings, skipped checks, and any known baseline
failure. Never describe a check as passing unless it ran in the current session.

## Pull request handoff

1. Require a named non-`main` branch and a clean, verified working tree.
2. Review complete scope:

   ```powershell
   git status --short --branch
   git diff origin/main...HEAD --stat
   git diff origin/main...HEAD --name-only
   git log --oneline origin/main..HEAD
   ```

3. Push the current branch to `origin`.
4. Create the PR explicitly against the fork:

   ```powershell
   gh pr create --repo TheLacrox/Monolith-Capibara-ESP --base main --head <branch>
   ```

5. Include summary, verification evidence, known limitations, deployment impact, and any merge
   ordering or follow-up work. Never target `Monolith-Station/Monolith`.

## Stop conditions

Stop and request user direction when:

- a new C# divergence appears necessary;
- a merge conflict does not match a documented class;
- local user work overlaps required edits;
- validation fails for reasons unrelated to the requested change;
- a translation would require changing Fluent structure rather than text;
- manifest source provenance is unclear; or
- PR target, base branch, or deployment behavior cannot be verified.
