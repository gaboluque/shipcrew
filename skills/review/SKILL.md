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
| `lite` | under ~200 | blind pass, right-change check, AC check |
| `standard` | under ~600 | adds the lenses and the scale questions below |
| `full` | above, or auth, money, migrations, sensitive data | everything, plus mutation spot-check |

## Passes

1. **Blind pass.** Read the diff before the ticket: what does it do, what could break, what would surprise a maintainer?
2. **Right change?** Before any line-by-line: does this solve the actual problem in the ticket, and does it sit in the right layer (model, service, job, controller, client)? A clean implementation of the wrong approach is the costliest PR to merge. If the approach looks wrong, say so first and stop going deeper: report `Question · let's talk before you go further`, with the alternative you'd expect and why.
3. **AC pass.** Read `ticket.md`. For each acceptance criterion: covered or missing, with the test that covers it. A criterion with no test is a finding.
4. **Lenses** (standard and full; run in parallel read-only subagents when available): correctness and edge cases (empty, expired, repeated, partial failure, a rule that implies another case); security and sensitive data (injection, authorization, personal data in logs, errors or fixtures); data and migrations (reversible, batched, locks, backfill); API and contract compatibility; reliability (timeouts, retries, idempotency, error surfacing); tests (does each test fail without the change? stale examples?); maintainability (reuse of existing helpers, naming, dead code, comments carrying the why); the project's own standards (`config.review.standardsFile`); and the five below.

   - **Boundaries and coupling.** New dependencies between modules, logic leaking across service or domain boundaries, abstractions that will be hard to undo. If this pattern is copied ten times, is the codebase better or worse? Does it follow an existing pattern, or invent a second way of doing something the codebase already does?
   - **Failure modes and operability.** Behavior when the database is slow, a third party times out or input is malformed. Can on-call debug it at 3am (logs, metrics)? Retries and idempotency, migration and rollback, a flag to turn it off, a backwards-compatible deploy.
   - **Hidden cost.** N+1 queries, missing indexes, whole tables loaded into memory, unbounded loops or pagination, synchronous calls that should be async, missing timeouts. In healthcare also PHI handling and audit trails.
   - **Tests that mean something.** Would each test fail if the code broke, or does it mirror the implementation? Flaky or over-mocked tests are a smell; edge cases (null, empty, time zones, concurrency, error paths) covered.
   - **Readability.** Could someone new follow this in six months? The simplest version that works wins: no clever tricks without a reason, no dead code, no premature abstraction.

   **Scale questions** (standard and full). Ask how the change behaves at thousands of calls a day and at thousands a second, and at 10x or 100x data or traffic: where is the bottleneck (the database, a third-party rate limit, a single queue consumer), does the data model box us in, does it need caching, batching or backpressure now or would that be premature? These are **questions, not blockers**: report them as `Question`, with the load you assumed, unless the diff itself shows the problem (an N+1 or an unbounded loop in a hot path is a finding).
5. **Mutation spot-check** (`full` only). Pick the 1 to 3 riskiest changed conditions. In a throwaway worktree break each one by hand (flip a condition, drop a branch, change a constant or a status), run the tests that should cover it, and confirm one fails. A surviving mutation is a Major. Report `mutation: <file:line> <change> → caught by <test> | SURVIVED`. Say when you skipped it.
6. **Dedupe.** Read the PR's existing threads (trusted authors only, HTML comments stripped). Drop findings already raised and list them as `already raised: <url>`.

## Severity

- **Blocker:** wrong behavior, data loss, security or privacy exposure, a broken contract.
- **Major:** an unmet criterion, an untested behavior, a surviving mutation, a missing rollback for a risky change, a broken active lesson.
- **Question:** a high-level or scale concern the author should answer, not a defect. Never blocks. Say what you assumed and what answer would settle it.
- **Minor / Nit:** style and taste. At most 5 in total. Never invent gaps: a clean diff gets `approve`.

## Report

Teach, don't just flag: say **why** each finding matters, mark nits as nits, block only on what really matters, and name up to 2 good decisions in the diff. If the same comment keeps coming up across PRs, propose a lint rule, a doc or a shared pattern, or log a lesson (`/shipcrew:lesson`), instead of repeating it.

Open with **Why it works**: one or two plain sentences on the mechanism of the change (what it does and why that fixes the problem), per PR when there are several. Then the verdict (`approve`, `approve with follow-ups`, `changes required`); findings as `severity · file:line · what · why · suggested fix · owner (which implementer)`; a short **Questions** list for scale and approach (not counted against the verdict); criteria coverage table; mutation results; lessons repeated. Keep it under ~80 lines.
