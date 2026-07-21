---
name: capibara-translate-fluent
description: Use when translating new or changed en-US Fluent messages into es-ES while preserving every Fluent identifier and placeable.
---

# Translate Capibara Fluent Messages

## Load context

1. Read `AGENTS.md` completely.
2. Read `_Capibara/glossary.md` completely.
3. Read `Common preflight`, `Incremental Fluent translation`, and `Stop conditions` in
   `_Capibara/agent-workflows.md`.

## Execute

1. Run common preflight and preserve unrelated work.
2. Run `pwsh _Capibara/sync-locale.ps1`; scope work to exact `NEW` and `CHANGED` IDs.
3. Locate each ID in `Resources/Locale/en-US/` and edit only its mirrored
   `Resources/Locale/es-ES/` path. Never edit en-US source.
4. Translate human-readable text only. Preserve message IDs, attribute names, variables, terms,
   references, selectors, selector keys, functions, arguments, escapes, braces, and placeable
   spacing. Translate both string arguments of `CONJUGATE-BASIC` into Spanish third-person
   singular forms.
5. For parallel work, partition by file and give each worker a disjoint path list plus the
   glossary. Keep validation and manifest updates in the main agent.
6. Review every changed file against its English source.
7. Run locale validation and `CapibaraCultureTest`.
8. Only after both pass, run `_Capibara/sync-locale.ps1 -UpdateManifest`, rerun the sync report,
   and confirm no handled ID still appears under `NEW` or `CHANGED`.

## Stop conditions

Stop when a translation requires changing Fluent structure, source and target IDs do not match,
another worker owns the file, unrelated edits overlap the target, or validation fails for an
unrelated reason. Leave English fallback active and report any string that cannot be translated
safely.
