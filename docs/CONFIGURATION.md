# Configuration reference

`.shipcrew/config.json` at the repository root (or the main checkout of a worktree setup). Hooks and the gate do nothing in a repo without it. Examples: [`examples/`](../examples).

```json
{
  "baseBranch": "main",
  "apps": [ { "name": "web", "path": "apps/web", "requires": "", "checks": [ { "name": "lint", "run": "npx eslint {files}", "files": "\\.tsx?$" } ] } ],
  "policy": { },
  "worktree": { "mode": "git", "root": "../worktrees" },
  "review": { "botRounds": 0, "standardsFile": "" },
  "monitoring": { "tool": "" }
}
```

## Top level

| Key | Default | Meaning |
|---|---|---|
| `baseBranch` | `main` | Branch new work is cut from and diffs are measured against (`origin/<baseBranch>`) |
| `apps[]` | none | The deployable parts of the repo (see below). A single-app repo has one entry with `path: "."` |
| `policy` | see below | Rules the hooks enforce |
| `worktree` | `{ "mode": "git", "root": "../<repo>-worktrees" }` | How `/shipcrew:spawn` creates workspaces |
| `review.botRounds` | `0` | Rounds of automated PR-bot review to triage and fix after the PR opens |
| `review.standardsFile` | none | A file of team standards the reviewer grades against |
| `monitoring.tool` | none | Hint for the monitor: `sentry`, `datadog`, `logs`, or any MCP/CLI name |

## `apps[]`

| Key | Meaning |
|---|---|
| `name` | Short id used in marker files and commands (`scripts/gate.sh <name>`) |
| `path` | Folder relative to the repo root. Changes under it make the app "touched" |
| `requires` | Optional command that must succeed first (for example `docker info`). If it fails the gate stops and the captain asks you: use CI or fix it |
| `env` | Optional map of environment variables exported to `requires`, `setup` and the checks. `{slug}` becomes this worktree's folder name (lowercase, `a-z0-9_`, max 40), so each worktree can have its own database, port or cache key. Example: `{ "TEST_ENV_NUMBER": "_{slug}" }`. A check has to pass the variable on (for Docker: `-e TEST_ENV_NUMBER`) |
| `setup` | Optional command run once before the checks, from the app's folder, with `env` set (for example create the per-worktree test database). Must be safe to repeat. If it fails the app fails the gate |
| `teardown` | Optional command run after the checks, pass or fail, with `env` set (for example drop the per-worktree test database). A failure is reported and ignored, so it never changes the gate result |
| `checks[]` | Commands to run, in order, from the app's folder |

Each check: `name`, `run` (a shell command), optional `files` (a regex). When `files` is set the check runs only if changed files in the app match, and `{files}` in `run` is replaced with them (shell-quoted, relative to the app folder). Use the same commands your CI runs.

## `gate`

Optional. `lock` (default `true`): only one gate runs at a time per repo, across all its worktrees, so parallel agents don't oversubscribe the CPU or fight over shared services; the others wait. A lock left by a dead run is cleared. `lockTimeout` (seconds, default `1800`): how long to wait before giving up. Set `"lock": false` to run gates in parallel.

## `prototype`

Optional. `mode` controls phase 1b of `ship`, where the crew sketches 2 or 3 approaches as throwaway code before the ticket is locked: `ask` (default) asks you when a ticket looks complex, `auto` prototypes complex tickets without asking, `off` never prototypes and the captain just recommends one approach. `options` (default `3`, max `3`): how many approaches to sketch. Saying "prototype this" or "no prototypes" in the interview overrides the setting for that run.

## `policy`

| Key | Default | Meaning |
|---|---|---|
| `branchTypes` | `feat fix chore refactor docs test` | Allowed branch and PR-title prefixes |
| `forbidNumericSuffix` | `true` | Reject branches ending in `-<digit>` (a tool's duplicate suffix) |
| `protectedBranches` | `main master develop development` | Never subject to branch-name or gate checks on push (merges there are yours) |
| `forbidAttribution` | `true` | Reject co-author trailers and "generated with" lines in commits and PR bodies |
| `ticketPattern` | none | Regex for your ticket ids, for example `[A-Z]+-[0-9]+` |
| `ticketPosition` | `suffix` | `suffix` puts the id at the end of a PR title (`feat: x [ABC-1]`) and rejects a prefix |
| `requireTicketInTitle` | `false` | PR titles must end with `[<id>]` |
| `askBeforeEditing` | `[]` | Paths nobody on the crew owns; edits there ask you first |
| `trustedReviewBots` | `[]` | Bot logins whose review comments agents may read, besides repository members |

## `worktree`

`mode: "git"` uses plain `git worktree`. `root` is where worktrees are created. See [ADAPTERS.md](ADAPTERS.md) for other managers.

## Environment overrides (only on your explicit word)

| Variable | Effect |
|---|---|
| `SHIPCREW_GATE=ci` | Pre-push skips the gate-marker check (you chose to rely on CI) |
| `SHIPCREW_SKIP_GUARD=1` | Skips every shipcrew hook for that command |

## Files shipcrew creates

| Path | Contents | In git? |
|---|---|---|
| `.shipcrew/config.json` | This file | Yes, if the team shares it |
| `.shipcrew/lessons/` | Rules from corrections | Yes, if the team shares them |
| `.shipcrew/plans/<change>/` | Ticket, specs, reports, progress | No (excluded by init) |
| `.shipcrew/spawn/<name>/` | Briefs for free-text work | No |
| `<git dir>/shipcrew-gate/` | Gate markers per commit and app | No (inside `.git`) |
