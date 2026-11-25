# Worker brief

Every subagent (implementer, reviewer, triager, tester, monitor) reads this once before its task spec.
The spec holds only what is specific to the task. `PLAN` and `WT` (the worktree) come from the spec.

## Before you start

1. Read your agent file's rules, then `PLAN/ticket.md` in full. It is the only ticket. Never call the tracker.
2. Read `lessons/<your role>.md` and `lessons/shared.md`, apply every `active` rule. Skip entries marked `promoted`, `retired` or `enforced` (a hook blocks those).
3. Read `.shipcrew/config.json` for your app's path and checks.

## Where you work

- Edit only inside your app's path under `WT`. Never touch the main checkout. Reviewers edit nothing.
- Pass `WT` explicitly to search tools. A search from elsewhere also hits other checkouts.

## Red proof (every test and every behavior change)

A test that never failed proves nothing. For every new or changed test, show it fails without the change and for the right reason (an assertion about the new behavior, not a load or setup error).

- **Tests task** (code not written yet): run the new tests once and keep the trimmed failing output.
- **Build or fix task** (tests and code together): after green, run the new tests against the base commit with the production code reverted: `git -C WT worktree add --detach <scratch>/base <base sha>`, copy only the new or changed test files in, run them there, then `git worktree remove --force` it.
- Write the trimmed output to `PLAN/reports/<task>-red.txt` and list each test with `fails without the change: yes/no` in your report. A test that passes without the change is rewritten or dropped, not reported as covered.

## Monitoring points

When the ticket's Monitoring table lists points, add them: failure paths only (an external call that failed, an unexpected state, retries exhausted, a payment or order step that didn't complete). Each capture carries the feature tag, a stable fingerprint per reason, and **ids only** (no personal or regulated data, no whole objects). One test per point that fails without the capture. Don't double-report an exception your framework already reports.

## Sensitive data

Never put personal or regulated data in code, tests, fixtures, logs, reports or PR text. Use synthetic values. Queries you suggest return counts, aggregates or ids only.

## Keep your context small

- Run tests and linters with quiet output and `| tail -n 60` on long logs. Read the full log only if the tail doesn't explain a failure.
- Read files in the ranges you need. Don't re-read a file you just edited.
- Let a read-only helper run a command whose output you only need summarized.

## Report

Write `PLAN/reports/<task>.md`, at most about 60 lines: result (green or red, one line), files changed, each command run with pass or fail (paste only failing output, trimmed), decisions taken, open blockers, lessons logged, and what the spec asks for. Then finish with `succeeded` or `failed`, the report path, and any open questions prefixed `Question:`.
