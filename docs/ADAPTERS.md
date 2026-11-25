# Adapters

shipcrew has no hard dependency on a tracker, a worktree manager, a review bot or an error tracker. Each integration is "use whatever tool you have, write the result to a file". This page lists what to provide.

## Ticket tracker

The captain fetches the ticket once and writes it to `.shipcrew/plans/<change>/ticket-source.md`. Any of these work:

| Source | How |
|---|---|
| GitHub issue | `gh issue view <n> --json title,body,labels` |
| Linear, Jira, Notion, Asana, Monday | The tracker's MCP server, if you have it installed; the captain uses whichever read tool is available |
| A file or pasted text | Pass the path or the text to `/shipcrew:ship` |

Contract: the captain needs an id, a title, a body, and (if present) acceptance criteria and links. Subagents never call the tracker.

## Worktrees

Default is plain `git worktree` (`worktree.mode: "git"`). Any manager works if the result is **a worktree on exactly the branch `/shipcrew:spawn` chose**, outside the main checkout. Check after creation:

```bash
git -C <path> branch --show-current      # must equal the chosen branch, with no numeric suffix
git -C <path> rev-parse --git-common-dir # must point to the main repo's .git
```

If your manager adds a suffix when a name clashes, run the preflight in the spawn skill first, and fix a local-only branch with `git branch -m`. The hooks work in any worktree because they resolve the config through the shared git directory.

## Automated PR review bots

Set `review.botRounds` to the number of rounds and list the bot logins in `policy.trustedReviewBots`. The captain waits for the bot (up to 15 minutes per round), triages its comments with the same rules as human ones, has the owner apply the valid ones, and re-requests. Without a bot, leave it at `0`; human review comments go through `/shipcrew:triage-comments`.

## Error tracker and logs

`/shipcrew:monitor` uses whatever read access exists: an MCP server for your tracker, a CLI, or a log query. Set `monitoring.tool` as a hint. The monitor needs: events by tag over a time window, new issues in a release, and a baseline for the same window before the deploy. It reports ids, counts and links only.

## CI

`gh pr checks <n> --watch` and `gh run list --branch <branch>` are used for GitHub. For other CI systems, give the captain the equivalent command in your project instructions (`CLAUDE.md`); the rule is only "watch it until it settles, fix red jobs from the logs".

## Review-comment platform

Triage and fix runs use `gh` (GitHub). For GitLab or others, the same flow works if you provide equivalent read commands for threads and authors; the hygiene rule (members and trusted bots only, HTML comments stripped) must survive the port.

## A different host agent

The skills and agents are plain markdown with a small frontmatter, and the guardrails are bash scripts. Porting to another coding agent means mapping the subagent dispatch and the PreToolUse hook; the git hooks and `gate.sh` work unchanged.

## Past conversations

`/shipcrew:retro` reads Claude Code transcripts from `$CLAUDE_CONFIG_DIR/projects` (or `~/.claude/projects`), any colon-separated folders in `SHIPCREW_TRANSCRIPT_DIRS`, and Orca profile folders when present. Project folders are matched by the repo path and `worktree.root`; use `--match` for other layouts.
