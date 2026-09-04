# Translation progress

- [x] **Initial full machine-translation pass (es-ES)** — 2026-07-01
  - 1437 files, ~23.5k message keys, via a 185-agent Claude workflow (core-facing dirs first).
  - `paper/book-authorbooks.ftl` (31 long in-game books) re-translated separately — it exceeded
    one agent's 32k output limit in the main run, so it was written in chunks.
  - Verified: `validate-locale.ps1` exit 0 · sync `NEW=0 CHANGED=0` · `CapibaraCultureTest` boot passes.
- [x] **Entity (item/mob/structure) names + descriptions** — 2026-07-01
  - SS14 stores these in YAML prototypes (not `.ftl`); localized via additive `ent-<id>` Fluent overrides.
  - Extracted via engine dumper (`CapibaraEntityDumpTest`) → 16,843 entities / ~18k unique strings;
    translated by a 206-agent workflow; emitted by `generate-entity-ftl.ps1` to
    `Resources/Locale/es-ES/_Capibara/entities/*.ftl` (16,824 keys). 20 strings fell back to English.
  - Verified: `CapibaraCultureTest` boots with all entity keys loaded (parse-clean).
  - To refresh after upstream changes: re-run the dumper test, rebuild `strbatches.json` from unique
    strings, re-run the entity workflow, re-run `generate-entity-ftl.ps1`.
- [x] **Entity coverage completed to 100%** — 2026-07-01. The 14 key-mismatched strings (curly
  quotes/™/dashes) translated via `tmp/tr-fix.json`; `hud-chatbox-highlights-tooltip` (missing in
  ALL upstream locales) added to the fork seed file.
- [x] **Guidebook + server rules + ServerInfo texts** — 2026-07-01
  - 307 XML docs (~832k chars, incl. `_Mono/MonolithRuleset.xml` = the join-screen rules) + 4
    player-facing `.txt` translated IN PLACE (approved exception — engine has no per-locale docs).
  - 95-agent workflow + 10-agent `textlink=` label fix pass (434 link labels in 75 files).
  - Verified: `validate-guidebook.ps1` — all `<...>` tags byte-identical to English baseline;
    upstream `GuideEntryPrototypeTests` + `DocumentParsingTest` pass (every doc parses).
  - Merge rule: on ServerInfo conflict take upstream's English, retranslate that file
    (`guidebook-manifest.json` identifies changed docs).
- [x] **Spanish grammar functions + entity genders** — 2026-07-02
  - `es-ES/_Capibara/grammar.ftl`: zzzz-* overrides so POSS-ADJ/SUBJECT/OBJECT/THE/CONJUGATE-*
    render Spanish ("su" instead of "his"); INDEFINITE overridden in ContentLocalizationManager.
  - POSS-ADJ + plural-noun audit (9 fixes); `validate-locale.ps1` gained an intentional-drop
    allowlist for the 5 emotes whose only `$entity` use was replaced by an article.
  - `generate-entity-ftl.ps1` now tags `.gender` on entity overrides from a Spanish head-noun
    heuristic (15,874/16,823 tagged; plural heads left neuter) → THE()/INDEFINITE() emit
    correct el/la, un/una. Extend the in-script exception lists as errors surface.
- [x] **Upstream sync: merge upstream/main 3fb705f789 (2026-09-03)** — 2026-09-04
  - 618 upstream commits since merge-base e1e3b602a (2026-06-30). Only conflicts were ServerInfo
    docs → took upstream's English for all 42 added/changed docs, retranslated them in place.
  - Locale: sync reported NEW=1027 CHANGED=101 REMOVED=22 → 20-agent key-level workflow
    (33 new files, 88 files patched only at the listed ids), 2 upstream file moves mirrored,
    22 stale keys pruned. `validate-locale.ps1` exit 0, manifest updated → 0/0/0.
  - Guidebook: 42 docs (21 new, 21 changed) via a 10-agent workflow; 2 deleted docs dropped;
    `validate-guidebook.ps1 -BaselineRef 3fb705f789` clean; manifest now 327 entries.
  - Entities: fresh dump 17,027 rows; all strings already in `entities/tmp/tr-*.json`
    (incl. the 2026-07-21 refresh maps) → regenerated 17,007 keys, 0 English fallbacks.
  - Space-biome renames + 2 new biomes, 13 new vessel/POI splash keys, 9 new guide-entry titles.
- [ ] Human editorial review pass (machine output; proofread high-visibility strings first).
- [ ] NOT translated (deliberate): map names (proper nouns), random-flavor datasets
  (ion-storm laws, ship names — raw upstream YAML, no loc support), changelog, hardcoded C# strings.

## Maintenance after each upstream merge
1. `git fetch upstream && git merge upstream/main`
2. `pwsh _Capibara/sync-locale.ps1` — lists NEW / CHANGED / REMOVED keys.
3. Translate the NEW/CHANGED keys at key level (see `translate-workflow.md` → *Upstream sync*).
   ServerInfo conflicts: take upstream's English for every doc upstream touched, retranslate, re-hash into `guidebook-manifest.json`.
   Entities: re-dump with `es-ES/_Capibara/entities` moved out of the tree (the dumper reads the active culture), then `generate-entity-ftl.ps1`.
4. `pwsh _Capibara/validate-locale.ps1` (must exit 0) and re-run `CapibaraCultureTest`.
5. `pwsh _Capibara/sync-locale.ps1 -UpdateManifest` to record the new source hashes.

> Note: everything under `Resources/Locale/es-ES/_Capibara/` is fork-owned and excluded from REMOVED;
> a clean tree reports `NEW=0 CHANGED=0 REMOVED=0`.
