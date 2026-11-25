# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/), and the project uses semantic versioning.

## [0.1.2] - 2026-11-25

### Added

- "Voice" rules for the captain and agents (result first, say it once, one question, 6-line cap) with a before/after example, and starter lesson L-shared-007.

## [0.1.1] - 2026-11-25

### Fixed

- Hook command and skill commands now quote `${CLAUDE_PLUGIN_ROOT}`, so installs under a path with spaces (for example `Application Support`) no longer fail with "Permission denied".

## [0.1.0] - Unreleased

### Added

- Plugin with skills `init`, `ship`, `spawn`, `review`, `triage-comments`, `monitor`, `lesson`.
- Agents: `implementer`, `reviewer`, `triager`, `tester`, `monitor`.
- Guardrails: PreToolUse guard, git `commit-msg` and `pre-push` hooks, and `scripts/gate.sh` with per-commit gate markers.
- Config-driven policy (`.shipcrew/config.json`) with examples for a generic repo, a Node monorepo and a Rails app in containers.
- Lessons system with `enforced`, `promoted` and `retired` statuses and a monthly prune.
- Docs: quickstart, workflow, configuration, customizing, adapters, threat model.
- `scripts/selftest.sh` and `scripts/scan-private.sh`.
