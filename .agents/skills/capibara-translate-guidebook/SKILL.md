---
name: capibara-translate-guidebook
description: Use when upstream changes Resources/ServerInfo guidebook, rules, or intro text that must be retranslated from English into Spanish in place.
---

# Translate Capibara Guidebook And ServerInfo

## Load context

1. Read `AGENTS.md` completely.
2. Read `_Capibara/glossary.md` completely.
3. Read `Common preflight`, `Guidebook and ServerInfo maintenance`, and `Stop conditions` in
   `_Capibara/agent-workflows.md`.

## Execute

1. Run common preflight and identify exact ServerInfo paths changed by upstream.
2. Require a completed merge commit containing upstream English for every conflicted or new file.
   If merge remains in progress, take complete upstream files and finish that merge before
   translating.
3. Translate only human-readable text and player-facing labels. Preserve every `<...>` tag
   byte-for-byte, in identical order, including attributes and values.
4. Partition parallel work by complete file. Never let two workers edit one document.
5. Run `pwsh _Capibara/validate-guidebook.ps1 -BaselineRef HEAD` before committing Spanish output.
6. Run `dotnet test Content.IntegrationTests --filter "FullyQualifiedName~Guidebook"`.
7. Update `_Capibara/guidebook-manifest.json` only after both gates pass, hashing English files
   extracted from the merge baseline rather than translated working-tree files.
8. For guide-entry titles, prefer additive Fluent keys. Use raw Spanish YAML titles only for the
   approved invalid-Fluent-ID exception and retain `# Capibara ESP`.
9. Invoke `capibara-verify` before completion.

## Stop conditions

Stop if no clean English baseline exists, markup differs, an affected prototype change falls
outside the approved title exception, user edits overlap a document, or a parse failure is not
caused by the current translation.
