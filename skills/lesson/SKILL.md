---
name: lesson
description: >-
  Records a correction from the user as a written rule that every crew member reads before its next
  task, so the same mistake isn't repeated. Use when the user corrects the crew ("no, don't...",
  "always...", "that's not how we..."), edits crew output, or states a preference that should outlive
  the task. Also supports a monthly prune.
argument-hint: "[<role>] <what went wrong and the rule> | prune"
---

# Lesson

Lessons live in `.shipcrew/lessons/` (seeded from the plugin's `lessons/`): `shared.md` for every role, and one file per role (`captain`, `implementer`, `reviewer`, `triager`, `tester`, `monitor`).

## When to record

Record when the user says a crew member did something wrong or should do it differently, rejects or edits output (a question, the ticket at the gate, code, a finding, a PR title), overrides a decision the crew made, or gives a preference that applies beyond this task. **If unsure, record it:** a redundant rule costs less than a repeated mistake. Don't record plain answers to questions (those go in `ticket.md`) or one-off choices (**Decisions taken**).

## How

1. **Immediately,** before going back to the work, so a context reset can't lose it. Use the corrected role's file, or `shared.md` if it applies to everyone.
2. **Check for an existing entry first.** If one covers it, raise `Seen`, tighten the rule, and don't add a duplicate.
3. Take the id from the `next id` comment at the top of the file, add the entry below, and bump the comment:

```markdown
### L-shared-004 · <short rule title>
- First seen: <date> · Run: <change>
- Mistake: <what was done, one line>
- Correction: <what the user said, paraphrased, no personal data>
- Rule: <imperative and checkable: "Always/Never <do X> when <Y>">
- Applies when: <trigger>
- Seen: 1
- Status: active
```

4. Tell the user in one line: `Logged L-shared-004: <title>.`

## Status values

- `active`: crew members apply it.
- `enforced (hook: <script>)`: a hook or lint rule blocks the mistake now. Kept as history; crew members skip it when reading.
- `promoted → <file>`: moved into an agent or skill file. Move the entry to `archive.md`.
- `retired · <date> · <reason>`: wrong or outdated. Move to `archive.md`.

## Promotion

`Seen` ≥ 2 or a broad rule makes it a promotion candidate: list it in the final report with the file it should move to (agent rules, a skill, the project's standards). Edit that file only after the user approves.

## Prune (`/shipcrew:lesson prune`, monthly)

For each `active` entry: is it already a hook, lint rule or agent line (mark `enforced` or `promoted`)? Has it stopped mattering and is followed by default (`retired`)? Does it apply to one role (move it out of `shared.md`)? Keep `shared.md` short, because every agent reads it before every task. Report counts in one line.

## Precedence

1. The user's instruction in the current conversation. 2. The project's standards and docs. 3. Active lessons. 4. Agent and skill defaults. If a lesson conflicts with the project's standards, follow the standards and tell the user so it gets resolved.
