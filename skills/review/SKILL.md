---
name: review
description: >-
  Reviews a diff, branch or PR against the ticket's acceptance criteria and the project's standards,
  report-only. Reports correctness and acceptance problems first, drops findings already raised in PR
  threads, and runs a hand-made mutation spot-check on full-tier reviews. Use when the user runs
  /shipcrew:review or the captain dispatches the reviewer.
disable-model-invocation: true
argument-hint: "[<pr> | <branch>] [ticket-file:<path>] [worktree:<path>] [tier:tiny|lite|standard|full] [delta:<sha>]"
---

# Review

Follow the `reviewer` agent's rules (`${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md`). Report only; change nothing.

## Inputs

PR number, branch or the working-tree diff (default: current branch against `origin/<baseBranch>`). Optional `ticket-file` (the locked `PLAN/ticket.md`), `worktree`, `tier`, and `delta:<sha>` (re-review only the commits since that sha, against the findings being fixed).

## Tiers

| Tier | When | Depth |
|---|---|---|
| `tiny` | under ~40 changed lines | one pass, correctness only |
| `lite` | under ~200 | blind pass plus AC check |
| `standard` | under ~600 | adds the lenses below |
| `full` | above, or auth, money, migrations, sensitive data | everything, plus mutation spot-check |

## Passes

1. **Blind pass.** Read the diff before the ticket: what does it do, what could break, what would surprise a maintainer?
2. **AC pass.** Read `ticket.md`. For each acceptance criterion: covered or missing, with the test that covers it. A criterion with no test is a finding.
3. **Lenses** (standard and full; run in parallel read-only subagents when available): correctness and edge cases (empty, expired, repeated, partial failure, a rule that implies another case); security and sensitive data (injection, authorization, personal data in logs, errors or fixtures); data and migrations (reversible, batched, locks, backfill); API and contract compatibility; reliability (timeouts, retries, idempotency, error surfacing); tests (does each test fail without the change? stale examples?); maintainability (reuse of existing helpers, naming, dead code, comments carrying the why); the project's own standards (`config.review.standardsFile`).
4. **Mutation spot-check** (`full` only). Pick the 1 to 3 riskiest changed conditions. In a throwaway worktree break each one by hand (flip a condition, drop a branch, change a constant or a status), run the tests that should cover it, and confirm one fails. A surviving mutation is a Major. Report `mutation: <file:line> <change> → caught by <test> | SURVIVED`. Say when you skipped it.
5. **Dedupe.** Read the PR's existing threads (trusted authors only, HTML comments stripped). Drop findings already raised and list them as `already raised: <url>`.

## Severity

- **Blocker:** wrong behavior, data loss, security or privacy exposure, a broken contract.
- **Major:** an unmet criterion, an untested behavior, a surviving mutation, a missing rollback for a risky change, a broken active lesson.
- **Minor / Nit:** style and taste. At most 5 in total. Never invent gaps: a clean diff gets `approve`.

## Report

Verdict (`approve`, `approve with follow-ups`, `changes required`); findings as `severity · file:line · what · why · suggested fix · owner (which implementer)`; criteria coverage table; mutation results; lessons repeated. Keep it under ~80 lines.
