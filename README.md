# shipcrew

A spec-first crew of [Claude Code](https://claude.com/claude-code) agents that takes a ticket to a reviewed, CI-green pull request, with guardrails that are enforced by scripts, not just written in a prompt.

```
ticket → interview → locked spec → tests first → build → review → local gate → draft PR → CI green → you merge
```

## Why

Agentic coding fails in predictable ways: vague specs, tests that never failed, "done" before CI is green, branch-name mess, a review that rubber-stamps. shipcrew is a small workflow that closes those gaps:

- **Interview, then a locked spec.** The captain asks until acceptance criteria, interfaces, edge states, rollback and monitoring are settled. You approve one `ticket.md`.
- **One writer at a time, read-only reviewers.** Implementers build per app, test first. The reviewer never edits.
- **Red proof.** Every test is shown failing without the change.
- **Reviewer with discipline.** Blind pass, acceptance-criteria pass, dedupe against existing threads, capped nits, and a hand-made mutation spot-check on risky diffs.
- **Guardrails as code.** A Claude Code hook and git hooks block bad branch names, pushes without a passing local gate, attribution lines, malformed PR titles, and branch renames that would close a PR.
- **Untrusted-input and sensitive-data hygiene** built into every agent.
- **Lessons.** Each correction becomes a rule the crew reads next time; rules that a hook now enforces get retired from the prompt.

## The crew

| Role | What it does |
|---|---|
| **Captain** (your main session) | Coordinates, decides, never writes product code |
| **Interviewer** (the captain, in interview mode) | Questions you until the spec is unambiguous |
| **Implementer** (subagent, one per app) | Tests first, then code, then a conventional commit |
| **Reviewer** (subagent, read-only) | Reviews against the ticket and your standards |
| **Triager** (subagent, one per PR) | Judges review comments: valid, why, how to fix, risk, effort |
| **Tester** (subagent) | Exercises a deployed change with a synthetic account |
| **Monitor** (subagent) | Reads your error tracker after deploy and gives a verdict |

## Install

```text
/plugin marketplace add gaboluque/shipcrew
/plugin install shipcrew@shipcrew
```

Requires `git`, `jq`, and (recommended) the GitHub CLI `gh`. Then, in your project:

```text
/shipcrew:init
```

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for a 10-minute walkthrough.

## Commands

| Command | Use |
|---|---|
| `/shipcrew:init` | Detect your apps and checks, write `.shipcrew/config.json`, install git hooks |
| `/shipcrew:spawn <ticket>` | Create a worktree on a correctly named branch |
| `/shipcrew:ship <ticket>` | Run the whole flow |
| `/shipcrew:ship fix <pr>` | Apply review feedback to an existing PR |
| `/shipcrew:triage-comments mine` | Triage unresolved review comments |
| `/shipcrew:retro [days]` | Mine past conversations for corrections and propose lessons, hooks and config changes |
| `/shipcrew:review [pr]` | Review a diff or PR |
| `/shipcrew:monitor <change>` | Check the error tracker after a deploy |
| `/shipcrew:lesson <what went wrong>` | Record a correction as a rule |

## Docs

- [Quickstart](docs/QUICKSTART.md)
- [Workflow, step by step](docs/WORKFLOW.md)
- [Configuration reference](docs/CONFIGURATION.md)
- [Customizing the crew](docs/CUSTOMIZING.md)
- [Adapters: trackers, worktrees, review bots, error trackers](docs/ADAPTERS.md)
- [Threat model and limits](docs/THREAT-MODEL.md)

## What it is not

- Not a compliance tool. The sensitive-data rules reduce exposure; they don't make a workflow compliant with any regulation. Check your own vendor agreements before letting any agent near regulated data.
- Not a sandbox. Hooks are guardrails for an agent that is trying to follow the rules, not a security boundary against a hostile one. See the threat model.
- Not autonomous merging. You mark the PR ready and you merge it.

## Contributing and license

See [CONTRIBUTING.md](CONTRIBUTING.md). Licensed under the MIT License ([LICENSE](LICENSE)).
