# CLAUDE.md — Monolith-Capibara-ESP

Spanish (es-ES) edition of Monolith Station (a Space Station 14 downstream).
This fork's purpose: a fully Spanish translation kept mergeable with upstream.

## Upstream
- `upstream` = https://github.com/Monolith-Station/Monolith.git (`origin` = this fork).
- Merge loop: `git fetch upstream && git merge upstream/main` →
  `pwsh _Capibara/sync-locale.ps1` → translate NEW/CHANGED keys →
  `pwsh _Capibara/sync-locale.ps1 -UpdateManifest` → commit.
- PRs: ALWAYS target this fork (`TheLacrox/Monolith-Capibara-ESP`), NEVER upstream.
  `gh` defaults to upstream in fork clones — the default is pinned via `gh repo set-default`,
  but still pass `--repo TheLacrox/Monolith-Capibara-ESP` explicitly to `gh pr create`.

## Localization architecture
- Engine: Project Fluent. All UI text is in `.ftl` files under `Resources/Locale/<culture>/`.
- Active culture is build-time: `Content.Shared/Localizations/ContentLocalizationManager.cs`.
- Spanish lives in `Resources/Locale/es-ES/`, mirroring `en-US/`. `en-US` is the fallback:
  untranslated keys render English automatically (active → fallback → raw key id).
- Engine grammar functions (`THE`, `SUBJECT`, `OBJECT`, `POSS-ADJ`, `CONJUGATE-*`…) resolve
  `zzzz-*` messages from the active culture — Spanish versions live ADDITIVELY in
  `es-ES/_Capibara/grammar.ftl` (mirrors RobustToolbox `en-US/_engine_lib.ftl`). `CONJUGATE-BASIC`
  string args in es-ES files must be translated Spanish 3ª-persona-singular forms (both args).

## Iron rules (keep merges conflict-free)
- NEVER edit upstream files (C#, YAML, or `Resources/Locale/en-US/**`). All Spanish is ADDITIVE
  in `Resources/Locale/es-ES/`. Fork tooling/docs live in `_Capibara/`.
- The ONLY intentional code divergences (each bracketed with `// Capibara ESP` comments;
  **on a merge conflict there, keep the Capibara block**):
  1. `Content.Shared/Localizations/ContentLocalizationManager.cs` — culture switch + fallback,
     plus es-ES registrations of the language-specific Fluent functions (`MANY`, `MAKEPLURAL`)
     and an es-ES `INDEFINITE` override (engine hardcodes English "a/an").
  2. `Content.Client/_Crescent/SpaceBiomes/SpaceBiomeTextDisplaySystem.cs` — biome splash
     names/descs are raw YAML strings with no upstream Loc hook; looks up additive
     `space-biome-<ID>-name/-desc` keys (`es-ES/_Capibara/space-biomes.ftl`), falls back to YAML.
  Adding ANY new C# divergence requires explicit user approval first.
- EXCEPTION (approved): `Resources/ServerInfo/**` (guidebook, rules, intro texts) is translated
  IN PLACE — the engine has no per-locale mechanism for these docs. **On a merge conflict there:
  take UPSTREAM's version (`git checkout --theirs`), then retranslate that file** — see
  `_Capibara/sync-guidebook` notes below. Never try to hand-merge Spanish vs English hunks.
- EXCEPTION (approved, tiny): guideEntry `name:` lines in `Resources/Prototypes/**/Guidebook/*.yml`
  whose value can't be a Fluent id (spaces/dots) carry the Spanish title directly, marked with
  `# Capibara ESP` comments. Raw names that ARE valid Fluent ids are instead localized additively
  in `Resources/Locale/es-ES/_Capibara/guide-entries.ftl` (the raw name doubles as the loc key).

## Fluent-preservation rules (any translation, human or agent)
Translate only human-readable text. Never modify/translate/add/remove: message IDs, attribute
names, `{ $var }`, `{ -term }`, `{ other-id }`, selector keys (`[one] *[other]`), function
calls/args (`{ CAPITALIZE($x) }`), or escapes (`\n`, `{ "" }`). Keep placeables and spacing identical.

## Tooling (`_Capibara/`)
- `glossary.md` — canonical es-ES terms; inject into every translation agent.
- `validate-locale.ps1` — structural gate (dropped/renamed vars, hallucinated IDs, braces). Must exit 0.
- `sync-locale.ps1` — en-US↔es-ES diff + hash manifest. `-UpdateManifest` after translating.
- `generate-entity-ftl.ps1` — regenerates `es-ES/_Capibara/entities/*.ftl` from the entity dump +
  translation maps (entity names/descs live in YAML prototypes, localized via `ent-<id>` overrides;
  dump via `CapibaraEntityDumpTest`). Also emits `.gender` attributes (Spanish head-noun heuristic)
  that drive THE()/INDEFINITE() article choice — extend its exception lists to fix a wrong article.
- `validate-guidebook.ps1` — ServerInfo translation gate: every `<...>` tag must be byte-identical
  to the English baseline (`-BaselineRef`, default HEAD). Run BEFORE committing a guidebook pass.
- `guidebook-manifest.json` — SHA1 of each English ServerInfo doc at translation time. After an
  upstream merge, hash upstream's docs against it to find which files changed → retranslate those.
- `translate-workflow.md` — how to run/resume the bulk translation workflow.
- `progress.md` — translation status.
- Guidebook parse gate: `dotnet test Content.IntegrationTests --filter "FullyQualifiedName~Guidebook"`.

## Verify
- `dotnet test Content.IntegrationTests --filter CapibaraCultureTest` — culture es-ES + fallback.
- `pwsh _Capibara/validate-locale.ps1` — es-ES tree structurally sound.

## Deployment (Docker / Dokploy)
- Capibara-owned, additive (not upstream) — on a merge conflict, keep ours:
  `Dockerfile`, `.dockerignore`, `entrypoint.sh`, `docker-compose.yml`, `Docker/server_config.prod.toml`.
- Multi-stage build on .NET 10 (`sdk:10.0` → `runtime:10.0`): inits submodules, packages a
  `linux-x64 --hybrid-acz` server, runs as non-root, exposes `1212/udp` + `1212/tcp`.
- Baked config in `Docker/server_config.prod.toml`; per-deploy overrides via env in `entrypoint.sh`
  (`SS14_HOSTNAME`, `SS14_DOMAIN`, `SS14_HUB_ADVERTISE`, `SS14_AUTH_MODE`, `SS14_HOST_USER`).
- No TTS/redis (this fork has no `tts.*` cvars). Add a tts-worker service only after porting TTS.
- Requires .NET 10 SDK to build locally (`global.json` pins 10.0.100, rollForward latestFeature).
