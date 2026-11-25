# Quickstart (about 10 minutes)

## 1. Install

```text
/plugin marketplace add gaboluque/shipcrew
/plugin install shipcrew@shipcrew
```

You need `git` and `jq` (`brew install jq`). `gh` (GitHub CLI, authenticated) is recommended: PR checks, comment triage and CI watching use it.

## 2. Set up your repo

In the repository you want to ship from:

```text
/shipcrew:init
```

It detects your apps and their check commands, asks only what it can't detect (base branch, ticket id pattern, any path nobody should edit unasked, trusted review bots), writes `.shipcrew/config.json`, installs the git hooks, and seeds `.shipcrew/lessons/`. Review the config: each `check` should be a command your CI also runs. Commit the config if the team should share it.

Try the gate on a clean branch: `scripts/gate.sh auto` (from the plugin folder) should say there is nothing to check.

## 3. Ship something small

Pick a small ticket (a bug with clear steps is ideal) and create a worktree for it:

```text
/shipcrew:spawn <ticket id, url or one-line description>
```

Open Claude Code in the worktree it prints and run:

```text
/shipcrew:ship <ticket>
```

What happens:

1. The captain fetches the ticket once and checks the branch name.
2. **You are interviewed**, one question at a time, until the spec is clear.
3. The captain writes `.shipcrew/plans/<change>/ticket.md`. **You read it and say `go`** (gate G1).
4. An implementer writes failing tests, then the code, and proves the tests fail without the change.
5. The reviewer reviews the diff. Blockers and Majors go back to the implementer.
6. The local gate runs, a draft PR opens, CI is watched until it is green.
7. You get a final report starting with a risk tier and evidence. **You mark the PR ready** (gate G2) and merge.

## 4. Correct it

When the crew gets something wrong, say so. It records a lesson (`/shipcrew:lesson`), and every agent reads it before its next task. After a month, run `/shipcrew:lesson prune`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| A hook blocks a push: "no passing gate" | Run `scripts/gate.sh <app>` from the worktree with everything committed |
| Gate says a prerequisite failed | Start it (for example the container runtime), or push with `SHIPCREW_GATE=ci` if you chose to rely on CI |
| "refusing to push '<branch>'" | Rename the local branch to `<type>/<kebab>` (only if it has no PR), or push `HEAD:<the PR's branch>` |
| Hooks do nothing | The repo has no `.shipcrew/config.json` (hooks are a no-op without it), or `jq` is missing |
| Git hooks missing after a fresh clone | Run `scripts/install-git-hooks.sh` (hooks aren't cloned) |
