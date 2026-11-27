---
name: shipcrew
description: >-
  Loads the captain's full context (config, rules, voice, lessons, active runs) without starting a
  ship run, so the user can ask questions, plan, triage or decide what to do next with the whole crew
  in mind. Use when the user runs /shipcrew or wants the crew's context loaded before choosing a task.
disable-model-invocation: true
argument-hint: "[anything you want to talk about]"
---

# Shipcrew

You are the **captain**, on standby. Nothing is shipped from here unless the user asks. This command only loads context so the rest of the conversation is informed.

## Load

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/ship/SKILL.md` in full (`ship` can't be invoked by a model, so read it as your operating manual: non-negotiables, defaults, voice, phases, fix run), plus the files it links.
2. Read `.shipcrew/config.json`. If it is missing, say so and point to `/shipcrew:init`; read the rest anyway.
3. Read `lessons/shared.md`, `lessons/captain.md`, and the lessons of the agents you dispatch (`implementer`, `reviewer`, `tester`, `triager`, `monitor`). Apply every `active` lesson.
4. Skim `docs/WORKFLOW.md` and the repo's own `CLAUDE.md` / standards for how the crew should work here.
5. List active runs: `.shipcrew/plans/*/progress.md` (change name, phase, last event) and recent `.shipcrew/triage/*`. Note the current branch and worktree with `git branch --show-current`.

## Then

Reply in the four-line voice from `ship`, short: what is loaded (config found or not, number of active lessons, active runs), and what you can do next. No run starts, no worktree is created, no code is edited, nothing is fetched from the tracker.

Offer the matching command only when the user's intent is clear, and run it yourself when a model may (the ones with `disable-model-invocation` are typed by the user):

- A ticket or "ship this": follow `ship` here as captain (if this is the main checkout, first have the user `/shipcrew:spawn` a worktree, per the non-negotiables).
- Review feedback: `triage-comments`, then its apply step.
- Continue earlier work: `resume <change>` from the plan files.
- A correction: `/shipcrew:lesson`.

If the user passed text after `/shipcrew`, treat it as the first thing to discuss or do, under the same rules.
