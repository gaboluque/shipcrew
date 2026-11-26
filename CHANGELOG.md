# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/), and the project uses semantic versioning.

## [0.3.4] - 2026-11-26

### Changed

- Report blocks are separated by a blank line, and `Changed`, `Proof` and `Need` hold their content as bullets.

## [0.3.3] - 2026-11-26

### Changed

- Report lines carry a fixed emoji for fast scanning: ✅/⏳/🙋/⛔/❌ by state on `Status`, 📝 `Changed`, 🧪 `Proof`, 👉 `Need`.

## [0.3.2] - 2026-11-26

### Changed

- Report voice: checkpoint messages use four labelled lines (`Status`, `Changed`, `Proof`, `Need`), about 80 words, overflow to a file, failures keep full detail in a linked file. The final report template opens with the same four lines.

## [0.3.1] - 2026-11-26

### Changed

- Draft PR bodies now follow the repo's own pull request template (searched in `.github/`, the repo root and `docs/`, app folder first) with headings verbatim, and a short fallback template when none exists. Rules live in `templates/pr-body.md`.

## [0.3.0] - 2026-11-25

### Added

- `scripts/usage.sh`: tokens per session, captain and subagent (by type), from local transcripts. `/shipcrew:retro` reports cost outliers; the final report's crew log gains a tokens column.

### Changed

- `implementer` is limited to `Read, Write, Edit, Bash, Grep, Glob`, so it no longer carries every connected MCP server's tool descriptions.
- `gate.sh` prints one line per passing check and only the tail of a failing one, with the full log on disk.
- CI and bot-review waits use a background command, not a polling subagent.

## [0.2.0] - 2026-11-25

### Added

- `/shipcrew:retro`: reads recent conversations of the project, clusters corrections and feedback, compares them with existing lessons and hooks, and proposes fixes (applied only on approval). Backed by `scripts/transcripts.sh`.

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
