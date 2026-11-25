# Publishing checklist

Do these before the repository goes public. Delete this file afterwards.

## 1. Permission (blocker)

- [ ] This project was derived from a workflow built at a company, on company time. Get written approval from the company (engineering leadership and legal) to release it, and confirm your contract's IP clause allows it.
- [ ] Decide where it lives (a personal account or an organization) and who owns it.
- [ ] Confirm that no company standards document, lesson, ticket text, review comment, customer or patient data, or internal URL was copied in. This repo was written from scratch with generic content; verify that again with the scan below.

## 2. Scrub

- [ ] Create `.scanignore-patterns` (git-ignored) with one regex per line for your company name, product names, internal hostnames, ticket prefixes, teammates' names and handles.
- [ ] `scripts/scan-private.sh` is clean.
- [ ] Publish from a fresh repository, not from this folder's history if it was ever shared: `git log` should show only commits you intend to publish.
- [ ] Search the docs and examples for screenshots, links and sample ids that point at private systems.

## 3. Fill in the placeholders

- [x] `LICENSE`, plugin metadata, README install commands (done 2026-11-25).
- [ ] Enable private vulnerability reporting on the repo (Settings, Code security), because `SECURITY.md` points to it.
- [ ] `CODE_OF_CONDUCT.md`: optionally replace with the full Contributor Covenant 2.1 text.

## 4. Verify

- [ ] `scripts/selftest.sh` passes on macOS and Linux.
- [ ] Install the plugin in a clean Claude Code profile, run `/shipcrew:init` on a scratch repository, and complete one small ticket end to end.
- [ ] Confirm that hooks are a no-op in a repository without `.shipcrew/config.json`.

## 5. Launch hygiene

- [ ] Tag `v0.1.0` and copy the changelog entry into the release notes.
- [ ] Turn on issue templates, private vulnerability reporting and branch protection.
- [ ] Decide what you promise on support (none is fine; say it in the README).
- [ ] Say plainly in the README what it is not (compliance tool, sandbox, autonomous merger). It does already; keep it.
