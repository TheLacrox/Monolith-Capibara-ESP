# Capibara translation workflow

Current default: incremental maintenance after an upstream merge.

Use `_Capibara/agent-workflows.md` for common preflight, conflict handling, validation, and PR
handoff. Read `_Capibara/glossary.md` completely before translating.

## Incremental maintenance

1. Detect source drift:

   ```powershell
   pwsh _Capibara/sync-locale.ps1
   Get-Content _Capibara/sync-report.txt
   ```

2. Locate each `NEW` or `CHANGED` ID in `Resources/Locale/en-US/` and edit only its mirrored
   `Resources/Locale/es-ES/` file.
3. Translate human-readable text only. Preserve every message ID, attribute name, variable, term,
   reference, selector key, function call, argument, escape, brace, and placeable boundary.
4. Review diffs file by file. Do not mix unrelated editorial cleanup into an upstream sync.
5. Validate before changing source hashes:

   ```powershell
   pwsh _Capibara/validate-locale.ps1
   dotnet test Content.IntegrationTests --filter CapibaraCultureTest
   pwsh _Capibara/sync-locale.ps1 -UpdateManifest
   pwsh _Capibara/sync-locale.ps1
   ```

6. Require the final sync report to contain no unhandled `NEW` or `CHANGED` IDs.

## Optional bounded delegation

Delegate only when multiple independent files need translation. Partition work by file, give every
worker its exact path list plus `_Capibara/glossary.md`, and bound concurrency to the available agent
slots. Never assign the same file to two workers. The main agent reviews all output and alone runs
validation and manifest updates.

For a small maintenance pass, edit inline; orchestration overhead is not useful for one file or a
few message IDs.

## Legacy full-tree Claude workflow

This section preserves the completed initial machine-translation process for reproducibility. It is
not the normal maintenance path. The 2026-07-01 run translated 1,437 files in 185 batches through
Claude's `Workflow` tool.

### Legacy inputs

- `_Capibara/batches.json` — ordered array of en-US-relative `.ftl` path batches, packed to roughly
  180 source lines per batch.
- `_Capibara/glossary.md` — canonical es-ES terms and Fluent-preservation rules.

### Legacy run

1. From a Claude session with the `Workflow` tool, invoke the script below with `args` equal to the
   batch count.
2. Each worker reads its batch from `_Capibara/batches.json`, reads the glossary, and writes only
   its assigned mirrored es-ES files.
3. After the run, validate locale structure, run `CapibaraCultureTest`, and update the manifest only
   when both pass.

### Legacy Workflow script

```javascript
export const meta = {
  name: 'capibara-translate-es',
  description: 'Machine-translate the en-US Fluent tree into es-ES, preserving placeables',
  phases: [{ title: 'Translate' }],
}
const N = args // integer: number of batches in _Capibara/batches.json
const RULES = `Translate Space Station 14 localization to Spanish (Spain, es-ES).
FIRST read _Capibara/glossary.md and follow it.
Get YOUR file list by running: pwsh -c "(Get-Content _Capibara/batches.json -Raw | ConvertFrom-Json)[INDEX] -join [Environment]::NewLine"
For EACH en-US relative path: Read Resources/Locale/en-US/<path>, translate, Write to Resources/Locale/es-ES/<path>.
HARD RULES — translate ONLY human-readable text. NEVER modify/translate/add/remove:
message IDs & attribute names (left of "=" and ".attr ="), { $var }, { -term }, { other-id },
selector syntax/keys ({ $n -> [one]... *[other]... }), function calls/args { CAPITALIZE($x) }, escapes \\n and { "" }.
Keep every placeable and its surrounding spaces identical. Output must be valid Fluent. Do not create files with no en-US counterpart.`
await pipeline(
  Array.from({ length: N }, (_, i) => i),
  (i) => agent(RULES.replace('INDEX', String(i)) + `\n\nYou are batch #${i}.`,
    { label: `translate:${i}`, phase: 'Translate' })
)
return { batches: N }
```

### Legacy resume

Reinvoke `Workflow` with the same script and `resumeFromRunId` from the earlier run. Completed
workers return cached results; only unfinished batches rerun.
