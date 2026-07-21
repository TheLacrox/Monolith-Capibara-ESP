---
name: capibara-create-pr
description: Use when a verified Capibara branch is ready to push and open as a pull request against TheLacrox/Monolith-Capibara-ESP main.
---

# Create Capibara Pull Request

## Load context

1. Read `AGENTS.md` completely.
2. Read `Common preflight`, `Pull request handoff`, and `Stop conditions` in
   `_Capibara/agent-workflows.md`.
3. Read `_Capibara/glossary.md` before correcting translation text exposed during final review.

## Execute

1. Run common preflight. Require a named branch other than `main` and preserve unrelated work.
2. Invoke `capibara-verify` and require fresh passing evidence for every changed path.
3. Review `git diff origin/main...HEAD`, changed paths, commit history, and working-tree status.
4. Commit only intended files in logical changes. Do not include generated noise or user-owned
   unrelated edits.
5. Push current branch to `origin`.
6. Create the PR with explicit target arguments:

   ```powershell
   gh pr create --repo TheLacrox/Monolith-Capibara-ESP --base main --head <current-branch>
   ```

7. Include summary, exact verification, known limitations, and deployment impact. State when work
   changes documentation/tooling only and leaves Dokploy runtime behavior unchanged.

## Stop conditions

Stop on dirty uncommitted scope, failed or stale validation, ambiguous base/head, missing `origin`
push, or any attempt to target `Monolith-Station/Monolith`. Never infer PR repository from GitHub's
default in a fork clone.
