---
name: init
description: >-
  Sets shipcrew up in the current repository: detects apps and their check commands, writes
  .shipcrew/config.json, installs the git hooks, and seeds the lessons folder. Use when the user runs
  /shipcrew:init or asks to set up the crew for a repo.
disable-model-invocation: true
---

# Init

Run once per clone. Never overwrite an existing `.shipcrew/config.json` without asking.

1. **Preconditions.** `git rev-parse --show-toplevel` succeeds, and `jq` and `gh` are installed (`gh` is optional but used for PR checks). Say what is missing.
2. **Detect.** Look for app roots and their commands:
   - `package.json` (scripts `lint`, `typecheck` or `check-types`, `test`), `pnpm-lock.yaml`, `yarn.lock`
   - `Gemfile` (rubocop, rspec), `pyproject.toml` or `requirements.txt` (ruff, pytest), `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`
   - a monorepo layout (`apps/*`, `packages/*`, `services/*`): one app entry per deployable folder
   - CI files under `.github/workflows` to copy the real check commands
3. **Ask** (one question at a time, with a recommendation) only what you can't detect: the base branch, the ticket id pattern (for example `[A-Z]+-[0-9]+`) and whether PR titles must carry it, any path nobody on the crew owns (becomes `policy.askBeforeEditing`), and the trusted review bots.
4. **Write `.shipcrew/config.json`** following `${CLAUDE_PLUGIN_ROOT}/docs/CONFIGURATION.md` and the closest file in `${CLAUDE_PLUGIN_ROOT}/examples/`. Each check is a command CI also runs. A check that needs a prerequisite (a container runtime, a database) goes in the app's `requires`.
5. **Keep local state out of git:** append `.shipcrew/plans/` and `.shipcrew/spawn/` to `.git/info/exclude`. The config itself may be committed so the team shares it.
6. **Install git hooks:** `${CLAUDE_PLUGIN_ROOT}/scripts/install-git-hooks.sh`.
7. **Seed lessons:** copy `${CLAUDE_PLUGIN_ROOT}/lessons/*.md` to `.shipcrew/lessons/` if missing (the skills read lessons from there).
8. **Verify:** run `${CLAUDE_PLUGIN_ROOT}/scripts/gate.sh auto` on a clean branch (it should say nothing to check), and show the user the config in a short summary: apps, checks, policy.

End with the one command to try next: `/shipcrew:ship <ticket>`.
