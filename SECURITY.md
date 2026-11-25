# Security policy

## Reporting a vulnerability

Please report security problems privately, not in a public issue: use GitHub's "Report a vulnerability" (private advisories) on this repository, or email `<SECURITY CONTACT>` (set before publishing). Include what you found, how to reproduce it, and the impact. Expect an acknowledgement within a few days.

## Scope

In scope: the hooks and scripts (`hooks/`, `scripts/`), and instructions in skills or agents that could lead an agent to leak data, run attacker-supplied commands, or bypass a guardrail.

Out of scope: the host agent itself, and the limits documented in [docs/THREAT-MODEL.md](docs/THREAT-MODEL.md) (for example, that the hooks are guardrails and not a sandbox).

## Supported versions

Only the latest release.
