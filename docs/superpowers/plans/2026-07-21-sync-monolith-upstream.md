# Monolith Upstream Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merge current Monolith `upstream/main` into the Capibara fork, translate every affected Spanish surface, and leave the fork passing localization, guidebook, build, and integration gates.

**Architecture:** Treat `upstream` as read-only source and `origin` as the only writable remote. Create one upstream merge commit containing exact upstream English for changed ServerInfo documents, then add reviewable Spanish Fluent, guidebook, and entity maintenance commits. Preserve Capibara-only code, Docker, and localization behavior.

**Tech Stack:** Git, PowerShell 7, Project Fluent, XML guidebook documents, .NET 10, NUnit integration tests.

## Global Constraints

- Never push, open a pull request, or write any state to `Monolith-Station/Monolith`.
- Push only `codex/fix-spanish-communications` to `TheLacrox/Monolith-Capibara-ESP` (`origin`).
- Keep current rule-5 Spanish communication correction in `Resources/ServerInfo/Rules.txt` and its linked Monolith guidebook documents.
- Never edit `Resources/Locale/en-US/**`; Spanish Fluent changes remain additive under `Resources/Locale/es-ES/**`.
- Preserve approved `// Capibara ESP` code blocks and Capibara Docker/Dokploy files.
- Do not introduce another C# divergence without explicit user approval.
- Preserve every Fluent identifier/placeable and every ServerInfo markup tag byte-for-byte.
- Update manifests only after translated output passes its matching structural gate.
- Expected fetched upstream commit at plan time: `7d4b43d490287ea99439b07530d5c80b6f4b7726`.
- Expected merge base at plan time: `e1e3b602a604484a992267c95a7f3c96730c8e04`.

---

### Task 1: Merge Monolith into the fork

**Files:**
- Modify: upstream-owned paths changed between `e1e3b602a604484a992267c95a7f3c96730c8e04` and `7d4b43d490287ea99439b07530d5c80b6f4b7726`
- Preserve: `Resources/ServerInfo/Rules.txt`
- Preserve: `Resources/ServerInfo/_Mono/Guidebook/Rules/Five_Languages.xml`
- Preserve: `Resources/ServerInfo/_Mono/Guidebook/Rules/MonolithRuleset.xml`

**Interfaces:**
- Consumes: clean `codex/fix-spanish-communications` branch tracking `origin/codex/fix-spanish-communications`
- Produces: merge commit with upstream source plus ten changed ServerInfo files restored to exact upstream English

- [ ] **Step 1: Verify local and remote state**

```powershell
git status --short --branch
git remote get-url origin
git remote get-url upstream
git fetch upstream
$upstreamCommit = (git rev-parse upstream/main).Trim()
$mergeBase = (git merge-base HEAD upstream/main).Trim()
if ($upstreamCommit -ne '7d4b43d490287ea99439b07530d5c80b6f4b7726') {
    throw 'upstream/main advanced after planning; refresh inventory before merging.'
}
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
    throw 'Working tree must be clean before merge.'
}
```

Expected: correct remotes, expected upstream SHA, clean worktree.

- [ ] **Step 2: Merge upstream**

```powershell
git merge upstream/main
```

Expected dry-run conflicts:

- `Resources/ServerInfo/Guidebook/NewPlayer/CharacterCreation.xml`
- `Resources/ServerInfo/Guidebook/NewPlayer/NewPlayer.xml`
- `Resources/ServerInfo/_Mono/Guidebook/Factions/TSFMC.xml`
- `Resources/ServerInfo/_NF/Guidebook/SectorTopology.xml`

Stop on any conflict outside `Resources/ServerInfo/**`.

- [ ] **Step 3: Establish clean English ServerInfo baseline**

```powershell
$serverInfoChanges = @(
    'Resources/ServerInfo/Guidebook/Mobs/Moth.xml',
    'Resources/ServerInfo/Guidebook/Mobs/Tajaran.xml',
    'Resources/ServerInfo/Guidebook/Mobs/_DV/Felinid.xml',
    'Resources/ServerInfo/Guidebook/Mobs/_DV/Harpy.xml',
    'Resources/ServerInfo/Guidebook/NewPlayer/CharacterCreation.xml',
    'Resources/ServerInfo/Guidebook/NewPlayer/NewPlayer.xml',
    'Resources/ServerInfo/_CE/Flight.xml',
    'Resources/ServerInfo/_Mono/Guidebook/Factions/PDV.xml',
    'Resources/ServerInfo/_Mono/Guidebook/Factions/TSFMC.xml',
    'Resources/ServerInfo/_NF/Guidebook/SectorTopology.xml'
)
git checkout upstream/main -- $serverInfoChanges
git add -- $serverInfoChanges
git diff --name-only --diff-filter=U
```

Expected: no unresolved paths. The ten listed documents match upstream English in the merge index.

- [ ] **Step 4: Verify protected Capibara scope**

```powershell
rg -n "Capibara ESP" Content.Shared/Localizations/ContentLocalizationManager.cs Content.Client/_Crescent/SpaceBiomes/SpaceBiomeTextDisplaySystem.cs
rg -n "El español es el idioma requerido|debe ser en español" Resources/ServerInfo/Rules.txt Resources/ServerInfo/_Mono/Guidebook/Rules/Five_Languages.xml Resources/ServerInfo/_Mono/Guidebook/Rules/MonolithRuleset.xml
git diff --cached --check
```

Expected: both approved C# files retain markers, Spanish communication policy remains, index has no whitespace errors.

- [ ] **Step 5: Complete merge and update submodules**

```powershell
git commit --no-edit
git submodule update --init --recursive
git status --short --branch
```

Expected: merge commit exists, no merge operation remains, only submodule worktree state expected from checked-out recorded commits.

---

### Task 2: Retranslate changed ServerInfo documents

**Files:**
- Modify: `Resources/ServerInfo/Guidebook/Mobs/Moth.xml`
- Modify: `Resources/ServerInfo/Guidebook/Mobs/Tajaran.xml`
- Modify: `Resources/ServerInfo/Guidebook/Mobs/_DV/Felinid.xml`
- Modify: `Resources/ServerInfo/Guidebook/Mobs/_DV/Harpy.xml`
- Modify: `Resources/ServerInfo/Guidebook/NewPlayer/CharacterCreation.xml`
- Modify: `Resources/ServerInfo/Guidebook/NewPlayer/NewPlayer.xml`
- Modify: `Resources/ServerInfo/_CE/Flight.xml`
- Modify: `Resources/ServerInfo/_Mono/Guidebook/Factions/PDV.xml`
- Modify: `Resources/ServerInfo/_Mono/Guidebook/Factions/TSFMC.xml`
- Modify: `Resources/ServerInfo/_NF/Guidebook/SectorTopology.xml`
- Modify: `_Capibara/guidebook-manifest.json`

**Interfaces:**
- Consumes: merge commit with exact upstream English documents
- Produces: complete Spanish documents with identical markup and source-hash manifest entries

- [ ] **Step 1: Capture failing untranslated-content baseline**

```powershell
$mergeCommit = (git log --merges --first-parent -1 --format=%H).Trim()
rg -n "\b(the|and|with|from|your|you|is|are|can|will)\b" Resources/ServerInfo/Guidebook/Mobs/Moth.xml Resources/ServerInfo/Guidebook/Mobs/Tajaran.xml Resources/ServerInfo/Guidebook/Mobs/_DV/Felinid.xml Resources/ServerInfo/Guidebook/Mobs/_DV/Harpy.xml Resources/ServerInfo/Guidebook/NewPlayer/CharacterCreation.xml Resources/ServerInfo/Guidebook/NewPlayer/NewPlayer.xml Resources/ServerInfo/_CE/Flight.xml Resources/ServerInfo/_Mono/Guidebook/Factions/PDV.xml Resources/ServerInfo/_Mono/Guidebook/Factions/TSFMC.xml Resources/ServerInfo/_NF/Guidebook/SectorTopology.xml
```

Expected: English player-facing text found before translation.

- [ ] **Step 2: Translate disjoint complete files**

Translate all human-readable text to neutral es-ES using `_Capibara/glossary.md`. Never modify `<...>` tags, tag order, attributes, IDs, colors, priorities, or link targets. Assign each complete file to exactly one writer.

- [ ] **Step 3: Verify Spanish content and markup**

```powershell
pwsh _Capibara/validate-guidebook.ps1 -BaselineRef $mergeCommit
dotnet test Content.IntegrationTests --filter "FullyQualifiedName~Guidebook" --verbosity minimal
```

Expected: all guidebook files structurally intact; all matching tests pass.

- [ ] **Step 4: Update exact English-source hashes**

Apply these upstream blob-content SHA1 values to `_Capibara/guidebook-manifest.json`:

```text
Resources/ServerInfo/Guidebook/Mobs/Moth.xml = E02E22A1FB8A02159F7580C3289123881780D4B9
Resources/ServerInfo/Guidebook/Mobs/Tajaran.xml = E2CC2DB30F46BF7ADFA05B867030163BC3FC2E1E
Resources/ServerInfo/Guidebook/Mobs/_DV/Felinid.xml = 65CCDBE7859C6202661F5A9E999230699EFCC6FD
Resources/ServerInfo/Guidebook/Mobs/_DV/Harpy.xml = C8A64053D6697A05A146F3FB8611DDC0A1D1DE71
Resources/ServerInfo/Guidebook/NewPlayer/CharacterCreation.xml = A28633729C7FD1FEB472892A0774EC99A0FDC980
Resources/ServerInfo/Guidebook/NewPlayer/NewPlayer.xml = 03274F1DF81BBDDD22D35956C570CA296F62DEC6
Resources/ServerInfo/_CE/Flight.xml = F55A9278A8CCDDC38B6321EDC6E340D51FAB4551
Resources/ServerInfo/_Mono/Guidebook/Factions/PDV.xml = 45E1B3FA0C7D55F1ACB98F7DE6AAB4082C9DBD62
Resources/ServerInfo/_Mono/Guidebook/Factions/TSFMC.xml = A007D839BB89739BFE175D9E75B99BFCD98DB722
Resources/ServerInfo/_NF/Guidebook/SectorTopology.xml = 2A63713C7301E64C34972D82BED61921FEBA87D2
```

- [ ] **Step 5: Commit guidebook maintenance**

```powershell
git diff --check
git add -- Resources/ServerInfo _Capibara/guidebook-manifest.json
git commit -m "docs: translate updated Monolith guidebook"
```

Expected: commit contains only ten translated documents and manifest changes.

---

### Task 3: Translate Fluent drift

**Files:**
- Modify: mirrored files under `Resources/Locale/es-ES/**` reported as `NEW` or `CHANGED`
- Modify: `_Capibara/manifest.json`
- Inspect: 30 changed upstream files under `Resources/Locale/en-US/**`

**Interfaces:**
- Consumes: merged `Resources/Locale/en-US/**` plus current Spanish tree
- Produces: zero unhandled `NEW` or `CHANGED` IDs and updated source hashes

- [ ] **Step 1: Generate failing drift report**

```powershell
pwsh _Capibara/sync-locale.ps1
Get-Content _Capibara/sync-report.txt
```

Expected: report precisely identifies every new or changed message ID.

- [ ] **Step 2: Translate reported IDs only**

```powershell
$mode = $null
$ids = @(foreach ($line in Get-Content _Capibara/sync-report.txt) {
    if ($line -like '== NEW*') { $mode = 'NEW'; continue }
    if ($line -like '== CHANGED*') { $mode = 'CHANGED'; continue }
    if ($line -like '== REMOVED*') { $mode = $null; continue }
    if ($null -ne $mode -and $line -match '^[A-Za-z][A-Za-z0-9_-]*$') { $line }
})
$ids | ForEach-Object {
    rg -n --glob '*.ftl' "^$([regex]::Escape($_))\s*=" Resources/Locale/en-US
}
```

For each located ID, edit only its mirrored `Resources/Locale/es-ES` file and preserve IDs, attributes, variables, terms, references, selectors, functions, arguments, escapes, braces, and placeable spacing exactly. Translate both string arguments of `CONJUGATE-BASIC` into Spanish third-person singular.

- [ ] **Step 3: Validate before updating hashes**

```powershell
pwsh _Capibara/validate-locale.ps1
dotnet test Content.IntegrationTests --filter CapibaraCultureTest --verbosity minimal
```

Expected: structural validator exits 0; culture test passes.

- [ ] **Step 4: Update manifest and prove no drift remains**

```powershell
pwsh _Capibara/sync-locale.ps1 -UpdateManifest
pwsh _Capibara/sync-locale.ps1
Get-Content _Capibara/sync-report.txt
```

Expected: zero unhandled `NEW` and zero unhandled `CHANGED` IDs.

- [ ] **Step 5: Commit Fluent maintenance**

```powershell
git diff --check
git add -- Resources/Locale/es-ES _Capibara/manifest.json
git commit -m "localization: translate Monolith locale updates"
```

---

### Task 4: Refresh entity localization when prototype output changed

**Files:**
- Modify when generated: `_Capibara/entities/entity-source.json`
- Create when pending strings exist: `_Capibara/entities/tmp/tr-refresh-2026-07-21-*.json`
- Modify when generated: `Resources/Locale/es-ES/_Capibara/entities/*.ftl`
- Modify only for wrong article classification: `_Capibara/generate-entity-ftl.ps1`

**Interfaces:**
- Consumes: 531 upstream-changed prototype paths and existing translation maps
- Produces: resolved entity source, complete translation maps, regenerated entity FTL, correct Spanish gender metadata

- [ ] **Step 1: Regenerate source and inspect drift**

```powershell
dotnet test Content.IntegrationTests --filter FullyQualifiedName~CapibaraEntityDumpTest -c Release --verbosity minimal
git diff -- _Capibara/entities/entity-source.json
```

Expected: test passes. Continue translation only if source diff exists.

- [ ] **Step 2: Build exact pending-string batches**

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

Expected: deterministic unique strings and batches no larger than 100 entries.

- [ ] **Step 3: Translate pending entity maps**

Write exact English-to-Spanish key/value mappings into new `tr-refresh-2026-07-21-*.json` files. Never overwrite prior reviewed maps. Use glossary terms and preserve proper nouns.

- [ ] **Step 4: Regenerate and validate entity FTL**

```powershell
pwsh _Capibara/generate-entity-ftl.ps1
pwsh _Capibara/validate-locale.ps1
dotnet test Content.IntegrationTests --filter CapibaraCultureTest --verbosity minimal
```

Expected: generator succeeds, locale structure valid, culture test passes.

- [ ] **Step 5: Commit entity maintenance**

```powershell
git diff --check
git add -- _Capibara/entities Resources/Locale/es-ES/_Capibara/entities _Capibara/generate-entity-ftl.ps1
git commit -m "localization: refresh translated entities"
```

Skip commit only when entity dump produces no tracked diff.

---

### Task 5: Run complete verification

**Files:**
- Inspect: all branch-wide changes against `origin/main`

**Interfaces:**
- Consumes: completed merge and translation commits
- Produces: fresh evidence for structural, targeted, build, and full integration correctness

**Pre-sync full-suite baseline:** `1150` passed, `22` skipped, `9` failed in `9m34s`. Seven failures share the existing `PostMapInitTest`/`GameDataScrounger` `ResPath` assertion path (`GameMapsLoadableTest`, `GridsLoadableTest`, `NonGameMapsLoadableTest`, `NoSavedPostMapInitTest`, `ShuttlesLoadableTest`, `AllMapsTested`, and `ScroungeByPatternInVfs`). `SaveLoadReparentTest` expects raw prototype name `HumanBodyDummy` while active es-ES entity localization changes the displayed name. `PrototypeSaveTest.UninitializedSaveTest` reports existing `MobCatCrispy` spawn mutation of `DeepFried`. These failures predate the upstream merge and must not be hidden or expanded.

- [ ] **Step 1: Check repository state and scope**

```powershell
git status --short --branch
git diff --check origin/main...HEAD
git diff --name-only origin/main...HEAD
git log --oneline --decorate origin/main..HEAD
git diff --name-only --diff-filter=U
```

Expected: clean worktree, no whitespace errors, no unresolved conflicts.

- [ ] **Step 2: Run localization and guidebook gates**

```powershell
pwsh _Capibara/validate-locale.ps1
$mergeCommit = (git log --merges --first-parent -1 --format=%H).Trim()
pwsh _Capibara/validate-guidebook.ps1 -BaselineRef $mergeCommit
dotnet test Content.IntegrationTests --filter CapibaraCultureTest --verbosity minimal
dotnet test Content.IntegrationTests --filter "FullyQualifiedName~Guidebook" --verbosity minimal
```

Expected: both validators exit 0; culture and guidebook filters pass.

- [ ] **Step 3: Build integration project**

```powershell
dotnet build Content.IntegrationTests/Content.IntegrationTests.csproj --verbosity minimal
```

Expected: build exits 0. Record existing warnings separately from new errors.

- [ ] **Step 4: Run full integration suite**

```powershell
dotnet test Content.IntegrationTests --no-build --no-restore --verbosity minimal
```

Expected target: suite exits 0. Minimum sync acceptance: no failures beyond the exact nine-test pre-sync baseline above. Isolate every remaining failure with targeted reruns and compare against pre-sync evidence before changing unrelated code. Any new C# divergence still requires explicit user approval.

---

### Task 6: Publish only to the Capibara fork

**Files:**
- Remote update only: `origin/codex/fix-spanish-communications`
- Pull request update only: `TheLacrox/Monolith-Capibara-ESP#12`

**Interfaces:**
- Consumes: clean, verified branch
- Produces: updated fork branch and PR; no upstream write

- [ ] **Step 1: Reconfirm remote boundary**

```powershell
git remote get-url origin
git remote get-url upstream
git status --short --branch
```

Expected: `origin` is `TheLacrox/Monolith-Capibara-ESP`; `upstream` is `Monolith-Station/Monolith`; worktree clean.

- [ ] **Step 2: Push current branch only to origin**

```powershell
git push origin codex/fix-spanish-communications
```

- [ ] **Step 3: Update existing fork PR**

```powershell
gh pr edit 12 --repo TheLacrox/Monolith-Capibara-ESP --title "chore: sync latest Monolith and refresh Spanish localization"
gh pr view 12 --repo TheLacrox/Monolith-Capibara-ESP --json url,state,isDraft,baseRefName,headRefName,mergeable,statusCheckRollup
```

Expected: open PR targets `main` in `TheLacrox/Monolith-Capibara-ESP` from `codex/fix-spanish-communications`. No command targets upstream.
