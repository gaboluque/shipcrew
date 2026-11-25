---
name: retro
description: >-
  Reads this project's recent Claude Code conversations, finds what the user corrected, pushed back on
  or confirmed, and proposes project-level improvements: lessons, hooks, config checks, agent or skill
  edits, and project docs. Report first; changes only after the user approves. Use when the user runs
  /shipcrew:retro or asks what the crew keeps getting wrong.
disable-model-invocation: true
argument-hint: "[days] [--match <text>] [--all]"
---

# Retro

Turns the user's past corrections into fixes that stop them recurring. Report first, apply only what the user approves.

## 1. Collect

Run `"${CLAUDE_PLUGIN_ROOT}/scripts/transcripts.sh" --days <N> --cues` (default 14 days, this repo and its worktrees; `--match <text>` widens or narrows the project folders, `--dir` adds a projects folder). It prints the user's messages per session, each with the start of the assistant message it answered. `--cues` keeps only messages that read like a correction, a rule or a confirmation. Run it without `--cues` only if the result looks too thin, or with `--all` from the arguments.

Also run `"${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" --days <N>` and note any role or session whose `new + out` tokens dominate (a worker spawned many times, a captain far above its workers). Mention it as a cost theme beside the corrections.

If the output is over ~60 KB, split it by session and give each chunk to a subagent that returns only clustered themes (no raw messages), then merge.

## 2. Find the signal

A message counts when the user:

- **Corrects**: "no", "don't", "I said", "that's not what I asked", undoes or rewrites crew output.
- **Sets a rule**: "always", "never", "from now on", "remember".
- **Pushes back on form**: too long, too technical, wrong format, wrong question.
- **Repeats a request** the crew didn't carry out the first time.
- **Confirms an unusual choice** ("yes, exactly like that"): worth keeping, as a rule or a default.

Ignore plain answers, one-off choices and task content. Group by theme. Count the sessions a theme appears in, not the messages.

## 3. Compare with what exists

Read `.shipcrew/lessons/`, `.shipcrew/config.json`, the hooks, and the project's `CLAUDE.md` or `AGENTS.md`. Drop a theme that is already covered, **unless it was corrected again after the rule existed**: then the rule is ineffective, so propose enforcing it (a hook or check) or moving it somewhere agents read first.

## 4. Pick the lever

| Theme is | Lever |
|---|---|
| A mechanical, checkable rule | Hook or `.shipcrew/config.json` check, then mark the lesson `enforced` |
| A preference or judgment | Lesson (`/shipcrew:lesson`), in the role's file or `shared.md` |
| How an agent or the captain behaves | Edit that agent or skill file (keep it short) |
| A project convention | The project's `CLAUDE.md` or `AGENTS.md` |
| The same failure in many sessions | A ticket template or interview question |

## 5. Report

Lead with the top themes, ranked by sessions affected times cost of the mistake. At most 7 rows:

| # | Theme | Evidence | Fix | Where |
|---|---|---|---|---|

- **Evidence**: `N sessions` and one short quote, trimmed. No names, patient or customer data, secrets or ticket text beyond the id.
- **Fix**: the exact rule or change, in one line.
- Below the table, one line each for: themes already covered, themes that look like one-offs, and what you could not judge.

End with: `Apply which? (numbers, "all", or "none")`.

## 6. Apply (only what the user picks)

- Lessons: follow `/shipcrew:lesson` (check duplicates, take the next id, bump the comment).
- Hooks and config: make the change, then run `"${CLAUDE_PLUGIN_ROOT}/scripts/selftest.sh"` if you touched a hook.
- Skill, agent and docs edits: show the diff in short form.
- Do not commit or push. Say which files changed.

## Privacy

Transcripts can hold patient data, credentials and private messages. Read them only to extract themes. Never write raw messages to a file, a lesson, a ticket or a PR. Never send them to an outside service. Quote the minimum.
