# Threat model and limits

shipcrew gives agents the ability to read code and tickets, run commands, push branches and comment on pull requests. Read this before using it on a repository that matters.

## The risky combination

An agent that (1) can see private data, (2) can send data out, and (3) reads untrusted content can be steered by that content. Pull-request comments, titles, branch names, ticket text, issue bodies and bot output are all untrusted. Researchers have shown text in a PR title or a hidden HTML comment making coding agents leak secrets.

## What shipcrew does about it

| Risk | Mitigation | Strength |
|---|---|---|
| Injection through review comments | Triage reads only OWNER, MEMBER and COLLABORATOR authors plus `trustedReviewBots`; HTML comments stripped; skipped authors are listed | Instruction-level |
| Agent posts data back out | Default is **no replies** on the platform; pushes only to the PR's own branch, gated by hooks | Defaults plus hooks |
| Attribution or noise in commits and PRs | commit-msg hook and PreToolUse guard | Enforced |
| Wrong branch, renamed branch closing a PR, duplicate-suffix branches | pre-push hook, PreToolUse guard | Enforced |
| Unchecked code pushed | pre-push requires a gate marker for the exact commit | Enforced (bypassable by env var) |
| Sensitive data reaching an agent | Snippets return ids and counts; synthetic accounts; reports carry no identifiers | Instruction-level |
| Edits to code nobody owns | `askBeforeEditing` paths prompt you | Enforced |

## What it does not do

- **It is not a sandbox.** An agent can edit the hooks, set the override variables, or run commands outside the guarded patterns. The guardrails assume an agent trying to follow the rules. Use real controls for hard limits.
- **Credentials.** Give agents a token scoped to one repository, with push but without admin rights, and restrict network access with your sandbox or permission settings. shipcrew does not manage credentials.
- **Compliance.** Nothing here makes a workflow compliant with a regulation. If an agent could see regulated data, the vendors in the path may need agreements with you; ask your compliance team. The safest design keeps regulated data out of reach entirely.
- **Dependencies and supply chain.** The crew doesn't vet new dependencies. Treat a new package in a diff as a review item.
- **Prompt-level rules drift.** Anything not enforced by a script can be ignored by a model on a bad day. That is why the lesson process moves repeated mistakes into hooks.

## Overrides

`SHIPCREW_GATE=ci` and `SHIPCREW_SKIP_GUARD=1` exist for your decisions. The agents are told never to use them on their own. Review the shell history of a run if that matters to you.

## Reporting a vulnerability

See [SECURITY.md](../SECURITY.md).
