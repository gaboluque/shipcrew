---
name: spawn
description: >-
  Creates a worktree on a correctly named branch for a task and tells the user how to start the
  captain in it. Chooses the branch the smart way: the open PR's head branch when there is one,
  otherwise <type>/<kebab> with a preflight that never lets a tool add a numeric suffix. Use when the
  user runs /shipcrew:spawn or wants a task in its own workspace.
disable-model-invocation: true
argument-hint: "<ticket | pr number | free text> [--name <kebab>]"
---

# Spawn

You are a launcher, not the captain: create the worktree, report, stop. Never interview, never edit product code, never fetch the ticket (the captain does that).

Read `.shipcrew/config.json` for `baseBranch`, `policy` and `worktree`.

## 1. Choose the branch

| Situation | Branch | Base |
|---|---|---|
| Work on an existing PR (a PR number or URL, or a fix run) | The PR's head branch: `gh pr view <n> --json headRefName -q .headRefName` | `origin/<head>` (fetch it first) |
| A ticket that already has an open PR of the user's (`gh pr list --search "<id>" --author @me --state open --json number,headRefName`) | That PR's head branch (several matches: ask) | `origin/<head>` |
| A branch the user names | That branch | `origin/<branch>` |
| A slice that depends on another (stacked PR) | `<type>/<kebab>` | `origin/<previous slice's branch>` |
| New work | `<type>/<kebab>` | `origin/<baseBranch>` (fetch it first) |

**Naming new work.** `<type>`: `fix` if the input says bug, fix, crash, error or regression; `chore` for refactor, tooling, docs, tests, deps or cleanup; otherwise `feat`. `<kebab>`: 2 to 5 words from the ticket or brief title, with no ticket id and never the worktree folder name verbatim. When all you have is an id (you can't read the tracker here), use `<type>/<id-lowercased>`; the captain renames it at intake once he has read the ticket (safe: no PR exists yet).

**Preflight, before creating anything:**

1. The name matches `policy.branchTypes` as `<type>/<kebab>` and doesn't end in `-<digit>`.
2. It is free locally (`git branch --list <branch>`) and on the remote (`git ls-remote --heads origin <branch>`). If it exists with an open PR, switch to the PR rows above. If it exists without a PR, stop and ask: reuse it or pick another name. **Never let a tool resolve a clash by adding `-2`.**
3. If the branch is already checked out in another worktree (`git worktree list`), say so and stop, or reuse that worktree if it is the one the user means.

## 2. Create the worktree

Default (`worktree.mode` = `git`):

```bash
git fetch origin <base>
git worktree add "<worktree.root>/<name>" -b <branch> origin/<base>      # new branch
git worktree add "<worktree.root>/<name>" <branch>                        # existing local branch
```

`worktree.root` defaults to `../<repo>-worktrees`. For an existing remote branch use `git worktree add --track -b <branch> <path> origin/<branch>`. Using another worktree manager is fine as long as the result is a worktree on exactly `<branch>`; `docs/ADAPTERS.md` lists what to check.

After creation verify `git -C <path> branch --show-current` equals `<branch>`. If a tool added a suffix and the branch is local-only, fix it with `git branch -m`; otherwise report it.

## 3. Free-text work

Write `.shipcrew/spawn/<name>/brief.md` (what, why, known facts with paths and links, out of scope), from what the user said plus what you know. Nothing invented. The captain treats it as an unverified starting point.

## 4. Report (three lines at most)

```text
Created <path> on <branch> (base <base>).
Start the captain there:  cd <path> && claude   then   /shipcrew:ship <ref | brief path>
Brief: .shipcrew/spawn/<name>/brief.md   (free text only)
```

Never start the next step yourself. One worktree per task; don't create a second for a task already running.
