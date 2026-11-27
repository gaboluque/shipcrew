# Ticket: <title>

## Source
- Tracker: <name> · Id: <ID> · URL: <url>
- Fetched: <date> (raw copy in `PLAN/ticket-source.md`)
- References (always with URLs): <design, docs, related PRs, error tracker issues>

## Context
<Why this matters, who is affected, 2 to 5 lines. Plain language: what is going on and what needs to happen. No class or method names.>

## Acceptance criteria
1. <observable, testable>
2. <...>

## Out of scope
- <explicitly not doing>

## Approach (when prototyped)
- Chosen: <option and why>
- Rejected: <option: reason>

## Test strategy
- <layer per criterion: unit, request or integration, component, end to end>
- Dev/staging test plan: <yes | no>
- Scale check for query-shape changes: <yes | no>

## Interfaces (when more than one app or service is touched)
- <endpoint or event, request, response, status codes, error cases. Agreed before building.>

## UI design (when a user sees a change)
- <design link or description, states, copy, accessibility notes>

## Routing
- <app or area> → <implementer owns it>. Order: <provider before consumer>.

## Monitoring
Failure points only. Each is tagged `feature:<change>`, uses ids only, and has one test.

| Point | Reason | Level |
|---|---|---|
| <file or flow> | <why it can fail> | error / warning |

Or: `No monitoring needed: <reason>`.

## Rollback
- Revert path: <revert the PR | turn off flag `<name>` | other>. Is reverting alone safe?
- Migration or backfill: <none | reversible how | not reversible, and who approves it>. Backfills run in batches and are reviewed by a human before they run.
- Trigger: a `bad` (or persistent `watch`) monitor verdict means this section is executed, and the user decides.
- Feature flag: <none, with the reason | name, default off>

## Ship defaults
- Push when CI is green · resolve fixed threads · no replies · no bot re-review on fix rounds
- Overrides from the user: <none | reply | no push | no commit>

## Decisions taken
- <filled during the run>

## Open questions
- <left after the interview, if any>

## Run
- Branch: <type>/<kebab> · Worktree: <path> · Plan: `.shipcrew/plans/<change>/`
