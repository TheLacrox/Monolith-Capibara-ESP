---
name: capibara-refresh-entities
description: Use when entity prototypes or dump data changed and Capibara entity names, descriptions, generated FTL, or gender metadata must be refreshed.
---

# Refresh Capibara Entity Localization

## Load context

1. Read `AGENTS.md` completely.
2. Read `_Capibara/glossary.md` completely.
3. Read `Common preflight`, `Entity localization refresh`, and `Stop conditions` in
   `_Capibara/agent-workflows.md`.
4. Read `_Capibara/generate-entity-ftl.ps1` before changing generator behavior or gender
   exceptions.

## Execute

1. Run common preflight.
2. Run `CapibaraEntityDumpTest` in Release to regenerate
   `_Capibara/entities/entity-source.json`.
3. Compare the new dump with Git and derive only unique English names/descriptions absent from
   existing `tr-*.json` maps.
4. Batch pending strings in `_Capibara/entities/strbatches.json`. Translate exact string keys and
   write new `tr-refresh-<run>-<batch>.json` maps; never overwrite reviewed maps.
5. Delegate only disjoint batches. Require every worker to use the glossary.
6. Run `pwsh _Capibara/generate-entity-ftl.ps1`. Never hand-edit generated
   `Resources/Locale/es-ES/_Capibara/entities/*.ftl` files.
7. Run locale validation and `CapibaraCultureTest`.
8. For a wrong article, extend the smallest matching exception list in the generator, regenerate,
   and rerun both gates.
9. Invoke `capibara-verify` before completion.

## Stop conditions

Stop when the entity dump fails, a translation-map file is invalid, two English keys would be
collapsed, generated Fluent fails validation, or a grammar change would require new C# behavior.
Keep safe English fallback and report untranslated strings instead of inventing structural fixes.
