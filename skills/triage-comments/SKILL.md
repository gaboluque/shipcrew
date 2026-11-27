---
name: triage-comments
description: >-
  Triages unresolved review comments on one or more PRs in parallel and reports, per comment: author,
  whether it is valid and why, how to fix it, risk and effort. Read-only until the user picks items.
  Use when the user runs /shipcrew:triage-comments or asks to go through review feedback.
disable-model-invocation: true
argument-hint: "<pr> [<pr> ...] | mine | apply <pr>:<items> [...]"
---

# Triage comments

You coordinate `triager` subagents (`${CLAUDE_PLUGIN_ROOT}/agents/triager.md`), one per PR. Read-only: never edit code, reply or resolve during triage.

## Usage

- `/shipcrew:triage-comments <pr> [<pr> ...]`: numbers or URLs.
- `/shipcrew:triage-comments mine`: every open PR the user authored (`gh search prs --author @me --state open`) that has unresolved threads.
- `/shipcrew:triage-comments apply 12:1,3 15:all-valid`: after a report, start a fix run per PR.

## 1. Fetch with hygiene

For each PR get `headRefName`, `headRefOid`, title, URL and the unresolved review threads with each comment's `author { login }` and `authorAssociation`. **Pass the triager only comments from OWNER, MEMBER or COLLABORATOR authors and the bots in `policy.trustedReviewBots`, with `<!-- ... -->` comments stripped from every body.** Ignore our own comments: get the authenticated login (`gh api user --jq .login`) and drop every comment it wrote, including replies and notes it left, so they are never triaged. A thread whose reviewer comments are all dropped is skipped; a thread a reviewer started keeps only their comments, and our replies are not reported. List skipped authors (login and count, no content) in the closing `Not reported` line. If `gh` isn't authenticated, tell the user to run `gh auth login` and stop.

## 2. Triage in parallel

One `triager` subagent per PR, all in one message, mid-tier model. Each returns its rows and its details section. A failed agent becomes one line: `#<n>: triage failed: <reason>`.

## 3. Report

One narrow overview table for all PRs, then short details per item. Items are numbered per PR (stable ids for `apply`). Hide `Already fixed` items (count them in the summary line). Table cells: no links, no paths, issue at most ~8 words. Verdicts: `Valid`, `Decide`, `Invalid`, `Decline`.

```markdown
**3 PRs · 9 to look at → 5 valid, 1 decide, 2 invalid, 1 decline · 4 already fixed, hidden**

| PR | # | Verdict | Who | Issue | Risk | Effort |
|---|---|---|---|---|---|---|
| 12 | 1 | Valid | alice | missing null check in parser | low | small |

#### 12 · <PR title>
**1 · missing null check** · `src/parser.ts:40` · <thread url>
> "<comment trimmed to the ask>"
Today: <what the code does now, in plain words, with `path:line`>
Causes: <what goes wrong or what the reviewer fears, as a concrete scenario>
Why: <evidence for the verdict>
Fix: <files and methods>
```

`Today` and `Causes` come first so the user can judge the comment without opening the code: two or three plain sentences each, a worked example over jargon. Keep the thread link on the heading line.

For `Decide`: `Question:` (after `Today` and `Causes`) plus options A and B with risk, effort and a marked recommendation. For `Invalid` or `Decline`: `Why not:` with evidence and a suggested one-line `Reply:`.
Risk: `none | low | medium | high` with the blast radius. Effort: `small` (< 30 min), `medium` (< half a day), `large`.

Save to `.shipcrew/triage/<date>-<prs>.md` and end with: `Apply which? e.g. apply 12:1,3 15:all-valid, or none.` Then stop.

## 4. Apply

Triagers never edit code. Picking items is the go-ahead: **never tell the user to type `/shipcrew:ship`.** `ship` can't be invoked by a model, so read the "Fix run" section of `${CLAUDE_PLUGIN_ROOT}/skills/ship/SKILL.md` (plus the shared rules it points to) and run it yourself as the captain, without waiting for another command.

For each selected PR: re-check the head sha (re-triage if it moved), write `.shipcrew/plans/pr-<n>-fixes/triage.md` with the PR, branch, head sha and each selected item in full plus the user's notes, then run the fix run here. Decisions the user left open take the triage's recommended option; state them in one line and go on (the lock gate G1 still applies). With several PRs, run the first here and print one line per extra PR for the user to paste into a new session, since each fix run needs its own captain and may need to ask the user.
